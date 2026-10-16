import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/toolbar.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/file_icon.dart';
import 'package:niman/src/ui/marquee_text.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_tree_order.dart';
import 'package:niman/src/ui/ocr/ocr_tree_ring.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree_drag.dart';
import 'package:niman/src/ui/tree_drag_scroll.dart';
import 'package:niman/src/ui/tree_rename_field.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';
import 'package:niman/src/ui/tree_spring_load.dart';

/// One row of the flattened tree (note/folder + its depth).
final class _Row {
  const new({required this.note, required this.depth, this.sidecar = false});

  final Note note;
  final int depth;

  /// A text recognition sidecar shown under its file (#595).
  final bool sidecar;
}

/// What the tree renders: the pinned notes, then the folder tree.
final class _Rows {
  const new({required this.pinned, required this.tree});

  final List<Note> pinned;
  final List<_Row> tree;

  bool get isEmpty => pinned.isEmpty && tree.isEmpty;
}

/// One row the tree's keyboard walks (#727): the note it draws, where the
/// list puts it, and what a key on it acts on.
final class _WalkRow {
  const new({
    required this.note,
    required this.path,
    required this.pinned,
    required this.depth,
    required this.top,
    required this.height,
  });

  final Note note;
  final String path;

  /// The pinned block's copy of the note, rather than its own row in the
  /// tree: a pinned note is drawn twice, and the cursor is on one of them.
  final bool pinned;

  /// How deep the row sits, for the left arrow's walk out to its parent.
  /// A pinned row is drawn at the root: its depth means nothing there.
  final int depth;

  /// Where the list draws the row, and how tall it is.
  final double top;
  final double height;
}

/// Lazy tree of the library's folders/notes.
///
/// Rows are flattened from per-level `NoteDao.children` queries and rendered
/// in a single [ListView.builder], so a 10k-note library only materializes
/// the visible rows (T-M1-04).
final class NoteTree extends StatefulWidget {
  /// Creates the note tree.
  const new({
    required this.controller,
    required this.selectedPath,
    required this.expanded,
    required this.onToggle,
    required this.onSelect,
    this.active = true,
    this.onRename,
    this.onDelete,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onOpenInNewTab,
    this.onBackgroundSecondaryTapUp,
    this.onMarkedMenu,
    this.onDeleteMarked,
    this.focusNode,
    this.creating,
    this.onMove,
    this.sort = TreeSort.nameAsc,
    this.ocrQueue,
    this.renaming,
    super.key,
  });

  /// Whether the tree is the pane on screen. Hidden under the grid (#727)
  /// it keeps its expansion and its scroll, but lets go of the keyboard.
  final bool active;

  /// Starts renaming the row at `path`: `F2` on the keyboard's cursor, as
  /// the grid's tiles do (#727). Null leaves the rename to the menu.
  final ValueChanged<String>? onRename;

  /// Deletes the row at `path`: `Delete` on the keyboard's cursor (#727).
  final ValueChanged<String>? onDelete;

  /// The row whose name is being edited in place (#707), and what its
  /// field does; null while none is.
  final TreeRename? renaming;

  /// The text recognition jobs: a file being read wears a ring (#595);
  /// null shows none.
  final OcrQueue? ocrQueue;

  /// Moves the dragged rows' notes or folders into the folder they were
  /// dropped on (#567): the row alone, or every marked row when the drag
  /// started on one of several (#996); null leaves the rows where they are.
  final TreeMove? onMove;

  /// The session providing the index and the change-event stream.
  final LibrarySession controller;

  /// The order the rows come in (T-UI-03, #726).
  final TreeSort sort;

  /// Library-relative path of the selected note/folder, or null.
  final String? selectedPath;

  /// Paths of the expanded folders.
  final Set<String> expanded;

  /// Called when a folder's chevron is tapped (expand/collapse).
  final ValueChanged<String> onToggle;

  /// Called with the row's note when the row is selected.
  final void Function(Note note) onSelect;

  /// Called with the row's note on long-press (context menu, T-UI-05), and
  /// the row's place on screen, for a pointer's menu to grow from.
  final void Function(Note note, Rect? anchor)? onLongPress;

  /// Called with the row's note on right-click (context menu at the
  /// cursor, T-PP-20): the desktop twin of [onLongPress], which stays
  /// for touchscreens.
  final void Function(Note note, TapDownDetails details)? onSecondaryTapDown;

  /// Called with a note's row on a middle click: the note in a tab of its
  /// own, as a browser opens a link (0.0.8 test round).
  final void Function(Note note)? onOpenInNewTab;

  /// Called on a right click on the tree's empty space, below or between
  /// the rows: where a new note or folder at the root is asked for.
  ///
  /// On the button's release, where a row's menu opens on its press: a
  /// press is told to every detector still in the running once it is held
  /// past the tap's deadline, the tree's background with the row it is
  /// on, and a click held that long opened both menus — the row's over the
  /// tree's, which was left up when a delete closed the row's. A release
  /// goes to the one detector that won, the row when it was on one.
  final void Function(TapUpDetails details)? onBackgroundSecondaryTapUp;

  /// The menu of several rows marked together (#712): a right click on one
  /// of them, with their paths and where it was clicked. Null leaves the
  /// tree to one row at a time — `Shift`+click and the marking keys do
  /// nothing.
  final void Function(List<String> paths, Rect anchor)? onMarkedMenu;

  /// Deletes the rows marked together, on `Delete` (#712).
  final ValueChanged<List<String>>? onDeleteMarked;

  /// The row being made, its name a field under its folder's row or at
  /// the top of the tree (#712); null while none is.
  final TreeCreate? creating;

  /// The keyboard's focus, when the shell asks for it (`Ctrl+Shift+E`,
  /// #712); null keeps one of the tree's own.
  final FocusNode? focusNode;

  @override
  State<NoteTree> createState() => _NoteTreeState();
}

final class _NoteTreeState extends State<NoteTree> {
  /// The rows currently being shown, and the inputs they were built from.
  ///
  /// The flatten runs one `children` query per expanded level, so it must
  /// not be restarted by every rebuild: selecting a note, toggling a
  /// button — any `setState` above this widget — used to re-query the
  /// whole visible tree, over a hundred queries a second on a real
  /// library. Reusing the same future also keeps [FutureBuilder] from
  /// flashing its spinner between rebuilds.
  Future<_Rows>? _rows;
  int? _rowsRevision;

  /// Which counter [_rowsRevision] came from: the library's revision when
  /// true, its tree revision when false. The two count apart, so the same
  /// number from each is not the same index (#760).
  bool _rowsFollowContents = false;
  Set<String> _rowsExpanded = const <String>{};

  /// The sort direction the cached rows were flattened with. It decides the
  /// order `_flatten` asks the index for, so a change of direction alone
  /// must rebuild the rows — a revision bump does not necessarily follow,
  /// and never does when the settings write that would have caused it fails.
  TreeSort _rowsSort = TreeSort.nameAsc;

  /// Whether the pinned section is rolled up, once the library has been
  /// asked. Null until then, and the section builds expanded — the common
  /// answer, and the one that does not make the tree jump when the real
  /// value lands.
  bool? _pinnedCollapsed;

  bool get _collapsed => _pinnedCollapsed ?? false;

  /// The tree's scroll, which a rename in place moves to its row (#707).
  final ScrollController _scroll = ScrollController();

  /// The closed folders a drag has dwelt on and opened (#1071).
  late final TreeSpringLoad _spring = TreeSpringLoad(
    isOpen: (path) => widget.expanded.contains(path),
    toggle: (path) => widget.onToggle(path),
  );

  /// The row a rename has scrolled to, so it is scrolled to once.
  String? _revealed;

  /// The keyboard's own focus (#727): the pane takes it when a row is
  /// clicked, and the arrows walk the rows while it holds it.
  late final FocusNode _focus =
      widget.focusNode ?? FocusNode(debugLabel: 'note-tree');

  /// The rows marked together (#712), by path: `Shift`+click, `Shift`+the
  /// arrows and `Space` mark, a plain click or `Esc` lets go; so does a row
  /// leaving the tree (#979). The tree's own rows only, not the pinned
  /// block's copies.
  final Set<String> _marked = {};

  /// The paths a drag started on [path] carries (#996): every marked row's
  /// when [path] is one of several marked rows, else the row's own.
  List<String> _dragPaths(String path) =>
      _marked.length > 1 && _marked.contains(path) ? _marked.toList() : [path];

  /// What has been typed to jump to a row by its name, and when the last
  /// letter came: a pause starts a new name (#712).
  String _typed = '';
  DateTime _typedAt = DateTime(0);

  /// The row the keyboard's cursor is on, by path, and whether that is the
  /// pinned block's copy of the note. Held by path rather than by place:
  /// the walk follows the row while the tree grows and shrinks around it.
  String? _cursorPath;
  bool _cursorPinned = false;

  /// Whether the ring is on the cursor — the keyboard put it there, a
  /// pointer takes it away — as on a grid tile (#727).
  bool _keyboardFocus = false;

  /// The rows of the last build, the height each pinned item takes and the
  /// height of a row: what the keyboard walks (#727). The walk itself is
  /// built when a key is pressed, not on every frame.
  _Rows? _current;
  List<double> _pinnedHeights = const <double>[];
  double _rowHeight = 0;

  /// The room the divider that closes the pinned block takes: its hairline
  /// and the breathing space under it.
  static const double _pinnedDividerHeight = 9;

  /// Brings the row being renamed into view: a row the list has not built
  /// has no field to show. Rows are [height] tall, near enough for the
  /// pinned block above them; the field puts itself fully in view once
  /// it is built.
  void _revealRenamed(_Rows rows, int header, double height) {
    final path = widget.renaming?.path;
    if (path == _revealed) return;
    _revealed = path;
    if (path == null) return;
    final index = rows.tree.indexWhere((row) => row.note.path == path);
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      final top = (header + index) * height;
      if (top >= position.pixels &&
          top + height <= position.pixels + position.viewportDimension) {
        return;
      }
      _scroll.jumpTo(
        (top - position.viewportDimension / 2).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  /// The heights of the pinned block's items, in the order the list draws
  /// them: the heading, the notes (none when it is rolled up) and the
  /// divider that closes it off. Empty when nothing is pinned.
  List<double> _pinnedHeightsOf(_Rows rows, double rowHeight) {
    if (rows.pinned.isEmpty) return const <double>[];
    return [
      editorToolbarHeight,
      if (!_collapsed)
        for (final _ in rows.pinned) rowHeight,
      _pinnedDividerHeight,
    ];
  }

  /// What the keyboard walks at the list's [index] (#727): the item's place
  /// and height, and the row it draws — null for the pinned heading and its
  /// divider, which are not rows. Reads the rows of the last build.
  _WalkRow? _walkAt(int index) {
    final rows = _current;
    if (rows == null) return null;
    final header = _pinnedHeights.length;
    var top = 0.0;
    if (index < header) {
      final note = index > 0 && index < header - 1
          ? rows.pinned[index - 1]
          : null;
      if (note == null) return null;
      for (var at = 0; at < index; at++) {
        top += _pinnedHeights[at];
      }
      return _WalkRow(
        note: note,
        path: note.path,
        pinned: true,
        // The pinned block draws every note at the root: its own depth
        // would say nothing there.
        depth: 0,
        top: top,
        height: _pinnedHeights[index],
      );
    }
    final at = index - header;
    if (at >= rows.tree.length) return null;
    for (final height in _pinnedHeights) {
      top += height;
    }
    final row = rows.tree[at];
    return _WalkRow(
      note: row.note,
      path: row.note.path,
      pinned: false,
      depth: row.depth,
      top: top + at * _rowHeight,
      height: _rowHeight,
    );
  }

  /// How many of the pinned block's items are rows the keyboard walks: its
  /// notes, without the heading and the divider — none while rolled up.
  int get _pinnedWalked =>
      _pinnedHeights.isEmpty ? 0 : _pinnedHeights.length - 2;

  /// How many rows the keyboard walks, in the order the list draws them:
  /// the pinned notes first, then the tree's own rows (#727).
  int get _walkLength {
    final rows = _current;
    return rows == null ? 0 : _pinnedWalked + rows.tree.length;
  }

  /// The walk's row at [index]: the list's item it is, read as
  /// [_walkAt] reads it. Only the rows a key reaches are made — a tree of
  /// a million rows is not copied for each key press.
  _WalkRow _walkRow(int index) {
    final pinned = _pinnedWalked;
    return _walkAt(
      index < pinned ? index + 1 : _pinnedHeights.length + index - pinned,
    )!;
  }

  /// The cursor's place in the walk: the row it is on, or the selected
  /// row — a walk begun with the keyboard starts where the tree already
  /// is — or the first row.
  int _cursorAt() {
    final rows = _current!;
    final pinned = _pinnedWalked;
    int? find(String path, {bool? inPinned}) {
      if (inPinned != false) {
        for (var at = 0; at < pinned; at++) {
          if (rows.pinned[at].path == path) return at;
        }
      }
      if (inPinned != true) {
        final at = rows.tree.indexWhere((row) => row.note.path == path);
        if (at >= 0) return pinned + at;
      }
      return null;
    }

    final path = _cursorPath;
    final selected = widget.selectedPath;
    return (path == null ? null : find(path, inPinned: _cursorPinned)) ??
        (selected == null ? null : find(selected)) ??
        0;
  }

  /// Whether the keyboard's ring is on [row] (#727): the cursor's own look,
  /// apart from the selection's fill, so the two are told apart and can be
  /// worn together.
  bool _isCursor(_WalkRow? row) =>
      row != null &&
      _keyboardFocus &&
      _focus.hasPrimaryFocus &&
      row.path == _cursorPath &&
      row.pinned == _cursorPinned;

  /// The keyboard (#727): the arrows walk the rows, `Home`/`End` and
  /// `PgUp`/`PgDn` jump, `Enter` opens a note or expands a folder, the left
  /// and right arrows close and open folders, and `F2` and `Delete` act on
  /// the cursor — the grid's own walk, in the tree's shape.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.active) return KeyEventResult.ignored;
    // Ancestor of the rows' own rename field too: keys reach here from it,
    // and a Backspace in a name must not walk the tree.
    if (!_focus.hasPrimaryFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_walkLength > 0) {
      final marking = _markKey(event);
      if (marking != null) return marking;
    }
    final keys = HardwareKeyboard.instance;
    // The menu key and `Shift`+`F10` open the cursor row's menu (#1072), as
    // the editor's do: the only way to the row's actions without a pointer.
    if (_walkLength > 0 &&
        !keys.isControlPressed &&
        !keys.isAltPressed &&
        !keys.isMetaPressed &&
        (event.logicalKey == LogicalKeyboardKey.contextMenu ||
            (event.logicalKey == LogicalKeyboardKey.f10 &&
                keys.isShiftPressed))) {
      return _openRowMenu(_walkRow(_cursorAt()));
    }
    // A modified key belongs to the app's accelerators (#23): Alt+Left and
    // Alt+Right walk the notes' history, Ctrl+Shift+PageUp/Down the
    // journal — the walk claims the plain key or none.
    if (keys.isControlPressed ||
        keys.isAltPressed ||
        keys.isMetaPressed ||
        keys.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (_walkLength == 0) return KeyEventResult.ignored;
    final handled = _walkKey(_cursorAt(), event.logicalKey);
    // The keyboard is in use: the ring comes back if a pointer had put it
    // away — and stays off for a key the walk does not own.
    if (handled == KeyEventResult.handled && !_keyboardFocus) {
      setState(() => _keyboardFocus = true);
    }
    return handled;
  }

  /// The menu of [row] from the keyboard (#1072), anchored at the row
  /// itself: the marked rows' menu when the row is one of several marked,
  /// the row's own otherwise — a right click's two answers.
  KeyEventResult _openRowMenu(_WalkRow row) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return KeyEventResult.ignored;
    final scrolled = _scroll.hasClients ? _scroll.position.pixels : 0.0;
    final origin = box.localToGlobal(Offset(0, row.top - scrolled));
    final anchor = origin & Size(box.size.width, row.height);
    if (!_keyboardFocus) setState(() => _keyboardFocus = true);
    final marked = widget.onMarkedMenu;
    if (marked != null &&
        _marked.length > 1 &&
        !row.pinned &&
        _marked.contains(row.path)) {
      marked(_marked.toList(), anchor);
      return KeyEventResult.handled;
    }
    final menu = widget.onLongPress;
    if (menu == null) return KeyEventResult.ignored;
    if (_marked.isNotEmpty) setState(_marked.clear);
    menu(row.note, anchor);
    return KeyEventResult.handled;
  }

  /// One key of the walk: [at] is the cursor's place in it, and what the
  /// key does is decided here.
  KeyEventResult _walkKey(int at, LogicalKeyboardKey key) {
    final row = _walkRow(at);
    final length = _walkLength;
    if (key == LogicalKeyboardKey.arrowUp) return _move(at - 1);
    if (key == LogicalKeyboardKey.arrowDown) return _move(at + 1);
    if (key == LogicalKeyboardKey.home) return _move(0);
    if (key == LogicalKeyboardKey.end) return _move(length - 1);
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final viewport = _scroll.hasClients
          ? _scroll.position.viewportDimension
          : 0.0;
      final page = math.max(1, viewport ~/ math.max(1.0, row.height));
      return _move(at + (key == LogicalKeyboardKey.pageUp ? -page : page));
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      widget.onSelect(row.note);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      // A closed folder opens; anything else steps into the rows drawn
      // under it, as a file manager's right arrow does.
      if (row.note.isDir && !widget.expanded.contains(row.path)) {
        widget.onToggle(row.path);
        return KeyEventResult.handled;
      }
      if (!row.pinned &&
          at + 1 < length &&
          _walkRow(at + 1).depth > row.depth) {
        return _move(at + 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      // An open folder closes; anything else steps out to the row that
      // holds it.
      if (row.note.isDir && widget.expanded.contains(row.path)) {
        widget.onToggle(row.path);
        return KeyEventResult.handled;
      }
      if (!row.pinned) {
        // The tree's own rows only: the pinned block above them is no
        // folder of theirs.
        final rows = _current!.tree;
        final pinned = _pinnedWalked;
        for (var i = at - pinned - 1; i >= 0; i--) {
          if (rows[i].depth < row.depth) return _move(pinned + i);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f2) {
      final rename = widget.onRename;
      if (rename == null) return KeyEventResult.ignored;
      rename(row.path);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      final delete = widget.onDelete;
      if (delete == null) return KeyEventResult.ignored;
      delete(row.path);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The keys of several rows and of a name (#712): `Shift`+`↑`/`↓` marks
  /// on, `Space` marks or unmarks the cursor's row, `Esc` lets the marks
  /// go, `Delete` deletes the marked rows, `Ctrl`+`Enter` opens the note
  /// in a new tab, and letters jump to the next row whose name starts with
  /// them. Null for a key that is not one of these.
  KeyEventResult? _markKey(KeyEvent event) {
    final keys = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final at = _cursorAt();
    final row = _walkRow(at);
    final ctrl = keys.isControlPressed || keys.isMetaPressed;
    final marks = widget.onMarkedMenu != null;
    if (ctrl &&
        !keys.isShiftPressed &&
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter)) {
      if (row.note.isDir) return KeyEventResult.ignored;
      widget.onOpenInNewTab?.call(row.note);
      return KeyEventResult.handled;
    }
    if (ctrl || keys.isAltPressed) return null;
    if (marks &&
        keys.isShiftPressed &&
        (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown)) {
      final to = (at + (key == LogicalKeyboardKey.arrowUp ? -1 : 1)).clamp(
        0,
        _walkLength - 1,
      );
      _markRange(at, to);
      return _move(to);
    }
    if (keys.isShiftPressed) return null;
    if (marks && key == LogicalKeyboardKey.space && !row.pinned) {
      setState(() {
        if (!_marked.remove(row.path)) _marked.add(row.path);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _marked.isNotEmpty) {
      setState(_marked.clear);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete && _marked.isNotEmpty) {
      // As a right click does (#979): on a marked row, `Delete` is the
      // marks'; on any other it is that row's alone, and the marks let go
      // rather than wait to be deleted by a later key.
      if (_marked.length > 1 && !row.pinned && _marked.contains(row.path)) {
        final delete = widget.onDeleteMarked;
        if (delete == null) return KeyEventResult.ignored;
        delete(_marked.toList());
        setState(_marked.clear);
        return KeyEventResult.handled;
      }
      setState(_marked.clear);
    }
    final typed = event.character;
    if (typed != null &&
        typed.length == 1 &&
        typed.trim().isNotEmpty &&
        typed.codeUnitAt(0) >= 0x20 &&
        typed.codeUnitAt(0) != 0x7f) {
      return _typeAhead(typed, at);
    }
    return null;
  }

  /// Jumps to the next row, from the cursor's, whose name starts with what
  /// has been typed: a second letter within a second narrows the name, the
  /// same letter again moves to the next row that starts with it, and a
  /// letter that narrows it to nothing starts a name of its own.
  KeyEventResult _typeAhead(String letter, int at) {
    final now = DateTime.now();
    final fresh = now.difference(_typedAt) > const Duration(seconds: 1);
    _typedAt = now;
    final repeat = !fresh && _typed == letter;
    if (!fresh && !repeat && _jumpTo('$_typed$letter', at, from: 0)) {
      _typed += letter;
      return KeyEventResult.handled;
    }
    _typed = letter;
    // A letter on its own looks past the cursor's row.
    _jumpTo(letter, at, from: 1);
    return KeyEventResult.handled;
  }

  /// Moves to the first row from [at] + [from] on, wrapping, whose name
  /// starts with [name]; false when none does.
  bool _jumpTo(String name, int at, {required int from}) {
    final wanted = name.toLowerCase();
    final length = _walkLength;
    for (var step = from; step < length + from; step++) {
      final index = (at + step) % length;
      if (_walkRow(index).note.name.toLowerCase().startsWith(wanted)) {
        _move(index);
        return true;
      }
    }
    return false;
  }

  /// Marks every tree row from [from] to [to] in the walk, and [from]'s
  /// own when nothing was marked yet.
  void _markRange(int from, int to) {
    final lo = math.min(from, to);
    final hi = math.max(from, to);
    setState(() {
      for (var i = lo; i <= hi; i++) {
        final row = _walkRow(i);
        if (!row.pinned) _marked.add(row.path);
      }
    });
  }

  /// A right click on [note]: on one of several marked rows, their menu;
  /// on any other row, its own, the marks let go.
  void _secondaryTap(Note note, TapDownDetails details) {
    final marked = widget.onMarkedMenu;
    if (marked != null && _marked.length > 1 && _marked.contains(note.path)) {
      marked(_marked.toList(), menuAnchorAt(details.globalPosition));
      return;
    }
    if (_marked.isNotEmpty) setState(_marked.clear);
    widget.onSecondaryTapDown?.call(note, details);
  }

  /// Puts the cursor on the row at [index], clamped to the rows there are,
  /// and brings it into view.
  KeyEventResult _move(int index) {
    final row = _walkRow(index.clamp(0, _walkLength - 1));
    setState(() {
      _cursorPath = row.path;
      _cursorPinned = row.pinned;
      _keyboardFocus = true;
    });
    _ensureCursorVisible(row);
    return KeyEventResult.handled;
  }

  /// A row's own click: the cursor follows it — the arrows go on from where
  /// the pointer left — and a folder takes the keyboard for the walk. A note
  /// does not: it opens for writing, and the shell gives the caret to it
  /// (#727) — taking the keys here would leave the note unable to be typed
  /// into.
  void _rowActivated(Note note, _WalkRow? row) {
    // `Shift`+click marks the rows from the cursor's to this one (#712),
    // and opens nothing.
    if (widget.onMarkedMenu != null &&
        HardwareKeyboard.instance.isShiftPressed &&
        row != null &&
        !row.pinned &&
        _walkLength > 0) {
      final rows = _current!.tree;
      final to = rows.indexWhere((r) => r.note.path == note.path);
      if (to >= 0) {
        _markRange(_cursorAt(), _pinnedWalked + to);
        setState(() {
          _cursorPath = note.path;
          _cursorPinned = false;
        });
        _focus.requestFocus();
        return;
      }
    }
    setState(() {
      _marked.clear();
      _cursorPath = row?.path ?? note.path;
      _cursorPinned = row?.pinned ?? false;
      _keyboardFocus = false;
    });
    if (note.isDir) _focus.requestFocus();
    widget.onSelect(note);
  }

  /// A folder's chevron: the cursor follows the folder that was opened or
  /// closed, and the pane takes the keyboard.
  void _rowToggled(String path, {required bool pinned}) {
    setState(() {
      _cursorPath = path;
      _cursorPinned = pinned;
      _keyboardFocus = false;
    });
    _focus.requestFocus();
    widget.onToggle(path);
  }

  /// Scrolls [row] into view, as the grid's walk does.
  void _ensureCursorVisible(_WalkRow row) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (row.top >= position.pixels &&
          row.top + row.height <=
              position.pixels + position.viewportDimension) {
        return;
      }
      _scroll.jumpTo(
        (row.top - position.viewportDimension / 2).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    const AppLogger(name: 'tree.ui').debug('mount');
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _focus.dispose();
    _scroll.dispose();
    _spring.dispose();
    const AppLogger(name: 'tree.ui').debug('dispose');
    super.dispose();
  }

  /// The ring follows the focus, so the pane redraws as it comes and goes.
  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(NoteTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      // A new library: the rows belong to the old one, and so does the
      // pinned section's roll-up — asked once per library, so it has to be
      // asked again rather than carried over.
      _rows = null;
      _pinnedCollapsed = null;
    }
    // Hidden under the grid the pane lets the keyboard go: the rows it
    // would walk are not the ones on screen (#727).
    if (!widget.active && oldWidget.active) _focus.unfocus();
  }

  /// The flattened rows for [revision], recomputed only when the index
  /// revision, the sort direction or the set of expanded folders changed.
  ///
  /// The direction is part of the key: `_flatten` feeds it to the query, so
  /// reusing rows across a direction change would show the old order — the
  /// chevron flips and the list stays put.
  ///
  /// So is the counter [revision] was read from ([followsContents]): a
  /// save bumps one and not the other, so a number from each can match
  /// while the index between them moved (#760).
  Future<_Rows> _rowsFor(int revision, {required bool followsContents}) {
    final cached = _rows;
    if (cached != null &&
        _rowsRevision == revision &&
        _rowsFollowContents == followsContents &&
        _rowsSort == widget.sort &&
        _setEquals(_rowsExpanded, widget.expanded)) {
      return cached;
    }
    _rowsRevision = revision;
    _rowsFollowContents = followsContents;
    _rowsExpanded = Set<String>.of(widget.expanded);
    _rowsSort = widget.sort;
    return _rows = _flatten();
  }

  /// Flattens the visible tree from the index, and reads the pinned notes
  /// alongside it — one revision, one build, so the two never disagree.
  ///
  /// The three waits are timed apart (#315): the first read after a library
  /// opens is where a cold index connection's open used to land, and the
  /// line has to say whether it is the query, the pinned read or the
  /// settings file that a frame waited for.
  Future<_Rows> _flatten() async {
    final started = DateTime.now();
    final allNodes = await widget.controller.tree(
      widget.expanded,
      sort: widget.sort,
    );
    final treeMs = DateTime.now().difference(started).inMilliseconds;
    final pinnedAt = DateTime.now();
    final fields = await widget.controller.fieldSource;
    final pinned = await fields?.pinnedNotes() ?? const <Note>[];
    final pinnedMs = DateTime.now().difference(pinnedAt).inMilliseconds;
    // Asked once per session, not per flatten: after the first answer the
    // state lives here, so a toggle repaints instead of round-tripping
    // through the settings file.
    final settingsAt = DateTime.now();
    _pinnedCollapsed ??= await widget.controller.pinnedCollapsed;
    final settingsMs = DateTime.now().difference(settingsAt).inMilliseconds;

    final nodesByParent = <int, List<Note>>{};
    for (final node in allNodes) {
      nodesByParent.putIfAbsent(node.parent, () => []).add(node);
    }

    final out = <_Row>[];
    _walkSync(0, 0, nodesByParent, out);
    _dropMarksOutside(out);

    const AppLogger(name: 'tree.ui').debug(
      'flatten: ${DateTime.now().difference(started).inMilliseconds}ms '
      '(${out.length} rows, ${pinned.length} pinned) '
      '[tree $treeMs, pinned $pinnedMs, settings $settingsMs]',
    );
    return _Rows(pinned: pinned, tree: out);
  }

  /// Lets go of the marks on rows that are no longer in [rows] — deleted,
  /// moved, renamed or folded away — so a `Delete` never goes to paths that
  /// are not on screen (#979). Once per flatten, not per frame.
  void _dropMarksOutside(List<_Row> rows) {
    if (_marked.isEmpty) return;
    final present = {for (final row in rows) row.note.path};
    _marked.removeWhere((path) => !present.contains(path));
  }

  void _walkSync(
    int parentId,
    int depth,
    Map<int, List<Note>> nodesByParent,
    List<_Row> out,
  ) {
    final children = nodesByParent[parentId] ?? const [];
    for (final (note, sidecar) in nestOcrSidecars(children, (n) => n.name)) {
      out.add(
        _Row(note: note, depth: sidecar ? depth + 1 : depth, sidecar: sidecar),
      );
      if (note.isDir && widget.expanded.contains(note.path)) {
        _walkSync(note.id, depth + 1, nodesByParent, out);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.onBackgroundSecondaryTapUp;
    final tree = _tree(context);
    if (background == null) return tree;
    // The rows answer their own right click (theirs is the inner detector);
    // anywhere else in the pane is the tree's background.
    return GestureDetector(
      key: const Key('note-tree-background'),
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: background,
      child: tree,
    );
  }

  Widget _tree(BuildContext context) {
    // A save writes the note's size and time and nothing a name-ordered tree
    // draws: those rows stand, and only a change to their shape asks for the
    // query again (#751). The field orders read size and times, so they
    // follow every change.
    final followsContents = widget.sort.contentMovesRows;
    final controller = widget.controller;
    final revision = followsContents
        ? controller.revision
        : controller.treeRevision;
    return StreamBuilder<int>(
      // A builder of its own per counter: one switched to the other stream
      // keeps the last number the old one sent, which is no revision of the
      // new counter (#760).
      key: ValueKey<bool>(followsContents),
      stream: followsContents ? controller.events : controller.treeEvents,
      initialData: revision,
      builder: (context, snapshot) {
        return FutureBuilder<_Rows>(
          future: _rowsFor(
            snapshot.data ?? revision,
            followsContents: followsContents,
          ),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data!;
            if (rows.isEmpty) {
              _current = null;
              return Center(child: Text(AppStrings.treeEmpty));
            }
            // The pinned notes sit above the tree with a heading of their
            // own; below the divider the tree is unchanged, so a pinned
            // note appears twice — once where it is kept, once where it
            // is wanted. Rolled up, the heading and the divider stay: the
            // count is still worth seeing, and the tree keeps the room.
            final rowHeight = TreeRowMetrics.of(context).height;
            _current = rows;
            _pinnedHeights = _pinnedHeightsOf(rows, rowHeight);
            _rowHeight = rowHeight;
            final header = _pinnedHeights.length;
            _revealRenamed(rows, header, rowHeight);
            final list = ListView.builder(
              key: const Key('note-tree-list'),
              controller: _scroll,
              itemCount: header + rows.tree.length,
              itemBuilder: (context, index) {
                // What the keyboard walks on this item: its place, and the
                // row a key on it acts upon (#727).
                final walked = _walkAt(index);
                if (index < header) {
                  return _pinnedItem(rows.pinned, index, walked);
                }
                final row = rows.tree[index - header];
                final tile = _RowTile(
                  note: row.note,
                  depth: row.depth,
                  sidecar: row.sidecar,
                  ocrQueue: widget.ocrQueue,
                  isExpanded: widget.expanded.contains(row.note.path),
                  selected:
                      row.note.path == widget.selectedPath ||
                      _marked.contains(row.note.path),
                  focused: _isCursor(walked),
                  onSelect: (note) => _rowActivated(note, walked),
                  onToggle: (path) => _rowToggled(path, pinned: false),
                  onLongPress: widget.onLongPress,
                  onSecondaryTapDown: widget.onSecondaryTapDown == null
                      ? null
                      : _secondaryTap,
                  onMiddleClick: widget.onOpenInNewTab,
                  onMove: widget.onMove,
                  spring: _spring,
                  dragPaths: _dragPaths(row.note.path),
                  renaming: widget.renaming?.path == row.note.path
                      ? widget.renaming
                      : null,
                );
                // A row being made sits under its folder's (#712).
                final creating = widget.creating;
                if (creating == null ||
                    !row.note.isDir ||
                    creating.folder != row.note.path) {
                  return tile;
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    tile,
                    _CreateRow(creating: creating, depth: row.depth + 1),
                  ],
                );
              },
            );
            final move = widget.onMove;
            final creating = widget.creating;
            // At the root, the row being made tops the tree (#712).
            final listed = creating != null && creating.folder.isEmpty
                ? Column(
                    children: [
                      _CreateRow(creating: creating, depth: 0),
                      Expanded(child: list),
                    ],
                  )
                : list;
            final tree = move == null
                ? listed
                : TreeDragScroll(
                    controller: _scroll,
                    onEnd: _spring.finish,
                    child: TreeRootDrop(onMove: move, child: listed),
                  );
            return Focus(focusNode: _focus, onKeyEvent: _onKey, child: tree);
          },
        );
      },
    );
  }

  /// One item of the pinned block: the heading, a pinned note, or the
  /// divider that closes it off from the tree. [walked] is what the
  /// keyboard walks on it, for the row's ring and its cursor (#727).
  Widget _pinnedItem(List<Note> pinned, int index, _WalkRow? walked) {
    if (index == 0) return _pinnedHeading(pinned.length);
    if (index == (_collapsed ? 1 : pinned.length + 1)) {
      // The hairline sits directly under the heading — aligned with the
      // editor toolbar's divider across the pane boundary — with the
      // breathing room kept below it, so the block keeps its metrics.
      return const TreeDropShield(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Divider(height: 1), SizedBox(height: 8)],
        ),
      );
    }
    final note = pinned[index - 1];
    return _RowTile(
      key: Key('pinned-${note.path}'),
      note: note,
      // No indentation and no chevron: a pinned note is shown regardless
      // of where it lives, so its folder depth would mean nothing here.
      depth: 0,
      isExpanded: false,
      selected: note.path == widget.selectedPath,
      focused: _isCursor(walked),
      onSelect: (note) => _rowActivated(note, walked),
      onToggle: (path) => _rowToggled(path, pinned: true),
      onLongPress: widget.onLongPress,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      onMiddleClick: widget.onOpenInNewTab,
      // A drop here goes into the note's folder, as on its tree row (#574).
      onMove: widget.onMove,
      icon: Icons.push_pin_outlined,
    );
  }

  /// The pinned section's heading: a chevron, the word, and how many are
  /// in there. Tapping it rolls the section up or down.
  ///
  /// The count is what makes rolling it up bearable — closed, the heading
  /// still says how much is behind it, so the section is a thing you put
  /// away rather than a thing you lose.
  ///
  /// The row is exactly [editorToolbarHeight] tall, matching the editor
  /// toolbar across the pane boundary so the rows below start together
  /// (user, 2026-09-09).
  Widget _pinnedHeading(int count) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return TreeDropShield(
      child: SizedBox(
        height: editorToolbarHeight,
        child: InkWell(
          key: const Key('pinned-heading'),
          onTap: () => _togglePinned(collapsed: !_collapsed),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Row(
              children: [
                Icon(
                  _collapsed ? Icons.chevron_right : Icons.expand_more,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(AppStrings.pinnedSectionCount(count), style: style),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Rolls the pinned section up or down, and remembers it for the
  /// library. The repaint does not wait on the write.
  void _togglePinned({required bool collapsed}) {
    setState(() => _pinnedCollapsed = collapsed);
    unawaited(widget.controller.setPinnedCollapsed(collapsed: collapsed));
  }
}

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

/// A row being made in the tree (#712): a note or a folder in `folder`
/// ('' the root), its name typed where it will be, `initial` proposed;
/// `submit` and `cancel` as a rename's.
typedef TreeCreate = ({
  String folder,
  bool isDir,
  String initial,
  Future<String?> Function(String name) submit,
  VoidCallback cancel,
});

/// One row tile: chevron (folders) or doc icon (files), then the name —
/// the name column is shared, per the mockup.
/// A rename in place (#707): the row at `path` shows a field, which
/// renames through `submit` — null once done, or why the name cannot be —
/// or gives up through `cancel`.
typedef TreeRename = ({
  String path,
  Future<String?> Function(String name) submit,
  VoidCallback cancel,
});

/// The row of a note or a folder being made (#712): its icon, and its
/// name in a field, at the [depth] it will sit.
final class _CreateRow extends StatelessWidget {
  const new({required this.creating, required this.depth});

  final TreeCreate creating;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final metrics = TreeRowMetrics.of(context);
    final theme = Theme.of(context);
    return Container(
      key: const Key('tree-create-row'),
      constraints: BoxConstraints(minHeight: metrics.height),
      padding: EdgeInsets.only(left: depth * metrics.indent + 8),
      child: Row(
        children: [
          SizedBox(
            width: metrics.leading,
            child: Icon(
              creating.isDir
                  ? Icons.create_new_folder_outlined
                  : Icons.note_add_outlined,
              size: 16,
            ),
          ),
          Expanded(
            child: TreeRenameField(
              name: creating.initial,
              isDir: creating.isDir,
              keepsUnchanged: true,
              style: theme.textTheme.bodyMedium,
              onSubmit: creating.submit,
              onCancel: creating.cancel,
            ),
          ),
        ],
      ),
    );
  }
}

final class _RowTile extends StatelessWidget {
  const new({
    required this.note,
    required this.depth,
    required this.isExpanded,
    required this.selected,
    required this.onSelect,
    required this.onToggle,
    this.focused = false,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onMiddleClick,
    this.onMove,
    this.spring,
    this.dragPaths,
    this.icon,
    this.sidecar = false,
    this.ocrQueue,
    this.renaming,
    super.key,
  });

  /// The rename under way on this row, or null.
  final TreeRename? renaming;

  /// Whether the keyboard's cursor is on this row (#727): a ring of its
  /// own, apart from the selection's fill, as a grid tile's is.
  final bool focused;

  /// Moves this row by dragging it, and takes drops (#567).
  final TreeMove? onMove;

  /// Opens this row, if a closed folder, when a drag dwells on it (#1071).
  final TreeSpringLoad? spring;

  /// The paths this row's drag carries when it is dragged (#996): the
  /// marked rows' when this row is one of several, else null — the row's
  /// own path alone.
  final List<String>? dragPaths;

  /// A text recognition sidecar under its file: dimmed, with the scan's
  /// icon (#595).
  final bool sidecar;

  /// The recognition jobs, for the ring on a file being read.
  final OcrQueue? ocrQueue;

  final Note note;
  final int depth;
  final bool isExpanded;
  final bool selected;
  final void Function(Note note) onSelect;
  final ValueChanged<String> onToggle;
  final void Function(Note note, Rect? anchor)? onLongPress;
  final void Function(Note note, TapDownDetails details)? onSecondaryTapDown;

  /// A middle click on a note's row (not a folder's).
  final void Function(Note note)? onMiddleClick;

  /// Replaces the file-type icon; the pinned block uses it to say why the
  /// row is there.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = TreeRowMetrics.of(context);
    final middle = onMiddleClick;
    final move = onMove;
    final longPress = onLongPress == null
        ? null
        : () => onLongPress!(note, menuAnchorOf(context));
    // By touch the hold drags the row, and a hold that does not move is the
    // long press: the drag gives it back.
    final held = move != null && TreeRowDrag.holdToDrag;
    Widget row = InkWell(
      // The walk owns the keyboard here (#727): a row that took the focus
      // itself would leave the arrows to nobody — a key pressed with the
      // scope focused lands on the first focusable descendant, and that
      // would be a row rather than the pane's own node.
      canRequestFocus: false,
      onTap: () => onSelect(note),
      onLongPress: held ? null : longPress,
      onSecondaryTapDown: onSecondaryTapDown == null
          ? null
          : (details) => onSecondaryTapDown!(note, details),
      child: Container(
        // A field with something to say under it takes the room it needs.
        constraints: renaming == null
            ? BoxConstraints.tightFor(height: metrics.height)
            : BoxConstraints(minHeight: metrics.height),
        color: selected ? theme.highlightColor.withValues(alpha: 0.4) : null,
        // Over the child, and no part of its size: the rows keep the
        // height the list and the walk measured them at (#727).
        foregroundDecoration: focused
            ? BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              )
            : null,
        padding: EdgeInsets.only(left: depth * metrics.indent + 8),
        child: Row(
          children: [
            if (note.isDir)
              IconButton(
                // The chevron fills its slot and no more: the button's own
                // 48 px minimum, and its padded tap target, would widen a
                // pointer's row back out.
                constraints: BoxConstraints.tightFor(
                  width: metrics.leading,
                  height: metrics.height,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: metrics.chevronSize,
                ),
                onPressed: () => onToggle(note.path),
              )
            else
              SizedBox(
                width: metrics.leading,
                child: Icon(
                  icon ??
                      (sidecar
                          ? Icons.document_scanner_outlined
                          : fileIconFor(note.name)),
                  size: sidecar ? 14 : 16,
                  color: sidecar ? theme.colorScheme.onSurfaceVariant : null,
                ),
              ),
            Expanded(
              child: renaming != null
                  ? TreeRenameField(
                      // On disk: the file is what is renamed, whatever the
                      // row shows for its title.
                      name: note.name,
                      isDir: note.isDir,
                      style: theme.textTheme.bodyMedium,
                      onSubmit: renaming!.submit,
                      onCancel: renaming!.cancel,
                    )
                  : MarqueeText(
                      text: displayNameOf(note),
                      style: sidecar
                          ? theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : theme.textTheme.bodyMedium,
                    ),
            ),
            if (ocrQueue case final queue?
                when !note.isDir && isRecognizableFile(note.name))
              OcrTreeRing(queue: queue, path: note.path),
            if (note.date case final DateTime date)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 12),
                child: Text(
                  isoDate(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    // A row being renamed is not dragged: a drag in its field selects text.
    if (move != null && renaming == null) {
      row = TreeRowDrag(
        note: note,
        paths: dragPaths,
        onMove: move,
        spring: spring,
        onLongPress: longPress,
        child: row,
      );
    }
    if (middle == null || note.isDir) return row;
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton) middle(note);
      },
      child: row,
    );
  }
}

/// What a note is called on screen: its frontmatter `title:` when it has
/// one, else its filename (T-M4-02).
///
/// The title is the note's own name for itself, so it wins wherever the
/// note is listed. The filename still decides the file on disk and still
/// resolves `[[links]]` — this changes what is shown, not what anything
/// points at.
String displayNameOf(Note note) {
  final title = note.title;
  return (title == null || title.isEmpty) ? note.name : title;
}

/// A frontmatter date as `YYYY-MM-DD` — the form it is written in.
String isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
