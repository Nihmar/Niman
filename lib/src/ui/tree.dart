import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderAbstractViewport, ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/toolbar.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/lazy_drag_paths.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree_create_row.dart';
import 'package:niman/src/ui/tree_drag.dart';
import 'package:niman/src/ui/tree_drag_scroll.dart';
import 'package:niman/src/ui/tree_listing.dart';
import 'package:niman/src/ui/tree_pages.dart';
import 'package:niman/src/ui/tree_range_reader.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';
import 'package:niman/src/ui/tree_row_tile.dart';
import 'package:niman/src/ui/tree_rows.dart';
import 'package:niman/src/ui/tree_rows_delegate.dart';
import 'package:niman/src/ui/tree_rows_reader.dart';
import 'package:niman/src/ui/tree_spring_load.dart';
import 'package:niman/src/ui/tree_type_ahead.dart';
import 'package:niman/src/ui/tree_walk.dart';
import 'package:niman/src/ui/tree_walk_row.dart';

export 'package:niman/src/ui/tree_create_row.dart' show TreeCreate;
export 'package:niman/src/ui/tree_row_tile.dart'
    show TreeRename, displayNameOf, isoDate;

/// Lazy tree of the library's folders/notes.
///
/// The list is a model of the rows (counts and ranks, `VisibleTree`) and the
/// pages of rows around the viewport (`TreePages`), drawn by index in a
/// fixed-extent sliver, so a library of a million notes holds the rows on
/// screen and not the rows ever scrolled past (T-M1-04, #1200).
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
    this.pageSize = defaultPageSize,
    this.pages,
    super.key,
  });

  /// The pages the tree reads its rows into (#1200); null makes the tree's
  /// own, [pageSize] rows to a page. A test gives its own to look at what is
  /// held as the list scrolls; its page size is the tree's.
  @visibleForTesting
  final TreePages? pages;

  /// How many children of a folder one page holds: the pages around the
  /// viewport are read, and the rest are read as the list scrolls to them
  /// (#1064, #1200).
  final int pageSize;

  /// The page a folder is read in.
  static const int defaultPageSize = 2000;

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
  /// What the tree reads: the rows of the visible tree, the pages around the
  /// viewport and the pinned block's roll-up (#1200).
  late final TreeRowsReader _reader = TreeRowsReader(
    pages: widget.pages ?? TreePages(pageSize: widget.pageSize),
    scroll: _scroll,
    walk: _walk,
    session: () => widget.controller,
    expanded: () => widget.expanded,
    sort: () => widget.sort,
    dropMarks: _dropMarksOutside,
    onPageLanded: () => setState(() {}),
  );

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
  /// when [path] is one of several marked rows, else null, the row's own.
  ///
  /// The marks are copied when a drag looks at them, not when the row is
  /// built (#1234): a range can mark a million rows, and every marked row on
  /// screen is built with these.
  List<String>? _dragPaths(String path) =>
      _marked.length > 1 && _marked.contains(path)
      ? LazyDragPaths(_marked.toList)
      : null;

  /// The jump to a row by the name typed (#712).
  late final TreeTypeAhead _letters = TreeTypeAhead(
    walk: _walk,
    move: _move,
    cursorAt: _cursorAtAsync,
    mounted: () => mounted,
  );

  /// The row the keyboard's cursor is on, by path, and whether that is the
  /// pinned block's copy of the note. Held by path rather than by place:
  /// the walk follows the row while the tree grows and shrinks around it.
  String? _cursorPath;
  bool _cursorPinned = false;

  /// Whether the ring is on the cursor — the keyboard put it there, a
  /// pointer takes it away — as on a grid tile (#727).
  bool _keyboardFocus = false;

  /// The rows of the last build as the keyboard walks them (#727).
  final TreeWalk _walk = TreeWalk();

  /// The listing and the folder the row being made is being placed for, so
  /// that one lookup is asked for each.
  TreeListing? _placingListing;
  String? _placingFolder;

  /// Brings the row being renamed into view: a row the list has not built
  /// has no field to show. The field puts itself fully in view once it is
  /// built.
  void _revealRenamed() {
    final path = widget.renaming?.path;
    if (path == _revealed) return;
    _revealed = path;
    if (path == null) return;
    unawaited(_revealPath(path));
  }

  /// Scrolls to the row at [path], wherever it is in the tree: its index is
  /// worked out from its rank, and the list builds the page it lands on.
  Future<void> _revealPath(String path) async {
    final listing = _walk.rows?.listing;
    if (listing == null) return;
    final index = await listing.modelIndexOfPath(path);
    if (index == null || !mounted || !_scroll.hasClients || _revealed != path) {
      return;
    }
    final top = _walk.treeTop(listing.listIndexOf(index));
    final position = _scroll.position;
    if (top >= position.pixels &&
        top + _walk.rowHeight <= position.pixels + position.viewportDimension) {
      return;
    }
    _scroll.jumpTo(
      (top - position.viewportDimension / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  /// Runs [then] with the walk's row at [index]: at once when it is loaded,
  /// else when its page has landed.
  void _whenRow(int index, void Function(TreeWalkRow row) then) {
    final row = _walk.rowAt(index);
    if (row != null) {
      then(row);
      return;
    }
    unawaited(
      _walk.rowAtAsync(index).then((row) {
        if (row != null && mounted) then(row);
      }),
    );
  }

  /// The cursor's place in the walk from the rows loaded: the row it is on,
  /// or the selected row — a walk begun with the keyboard starts where the
  /// tree already is — or the first row. Null when the row it is on is not
  /// in a page that is loaded: see [_cursorAtAsync].
  int? _cursorAtSync() {
    final path = _cursorPath;
    if (path != null) return _walk.find(path, inPinned: _cursorPinned);
    final selected = widget.selectedPath;
    return selected == null ? 0 : _walk.find(selected);
  }

  /// The cursor's place in the walk, asking the index for a row whose page
  /// is not loaded.
  Future<int> _cursorAtAsync() async {
    final held = _cursorAtSync();
    if (held != null) return held;
    final path = _cursorPath;
    final selected = widget.selectedPath;
    final cursor = path == null
        ? null
        : await _walk.findAsync(path, inPinned: _cursorPinned);
    if (cursor != null) return cursor;
    final chosen = selected == null ? null : await _walk.findAsync(selected);
    return chosen ?? 0;
  }

  /// The cursor and the row it is on, when both are loaded.
  TreeWalkCursor? _cursorHere() {
    final at = _cursorAtSync();
    final row = at == null ? null : _walk.rowAt(at);
    return at == null || row == null ? null : (at: at, row: row);
  }

  /// The cursor and the row it is on, loading the page it is in.
  Future<TreeWalkCursor?> _cursorResolved() async {
    final at = await _cursorAtAsync();
    final row = await _walk.rowAtAsync(at);
    return row == null ? null : (at: at, row: row);
  }

  /// Whether the keyboard's ring is on [row] (#727): the cursor's own look,
  /// apart from the selection's fill, so the two are told apart and can be
  /// worn together.
  bool _isCursor(TreeWalkRow? row) =>
      row != null &&
      _keyboardFocus &&
      _focus.hasPrimaryFocus &&
      row.path == _cursorPath &&
      row.pinned == _cursorPinned;

  /// The keys the walk may take, whatever the rows: a superset of what it
  /// does take, so that a key that is not one of them is left to the app
  /// before the cursor's row is looked for.
  static final Set<LogicalKeyboardKey> _walkKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.f2,
    LogicalKeyboardKey.f10,
    LogicalKeyboardKey.contextMenu,
  };

  /// Whether the walk may take [event], by the key and the modifiers alone.
  bool _ownsKey(KeyEvent event) {
    final keys = HardwareKeyboard.instance;
    final key = event.logicalKey;
    if (keys.isAltPressed) return false;
    if (keys.isControlPressed || keys.isMetaPressed) {
      return key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter;
    }
    if (_walkKeys.contains(key)) return true;
    return !keys.isShiftPressed && TreeTypeAhead.letterOf(event) != null;
  }

  /// The keyboard (#727): the arrows walk the rows, `Home`/`End` and
  /// `PgUp`/`PgDn` jump, `Enter` opens a note or expands a folder, the left
  /// and right arrows close and open folders, and `F2` and `Delete` act on
  /// the cursor — the grid's own walk, in the tree's shape.
  ///
  /// The cursor's row is looked up in the pages loaded; when it is in one
  /// that is not, the key waits for the page, and is answered `handled` at
  /// once, as the keys have to be synchronous.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.active) return KeyEventResult.ignored;
    // Ancestor of the rows' own rename field too: keys reach here from it,
    // and a Backspace in a name must not walk the tree.
    if (!_focus.hasPrimaryFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_walk.length == 0 || !_ownsKey(event)) return KeyEventResult.ignored;
    final here = _cursorHere();
    if (here != null) return _keyAt(event, here);
    unawaited(
      _cursorResolved().then((here) {
        if (here != null && mounted) _keyAt(event, here);
      }),
    );
    return KeyEventResult.handled;
  }

  /// [event] with the keyboard's cursor on [cursor].
  KeyEventResult _keyAt(KeyEvent event, TreeWalkCursor cursor) {
    final marking = _markKey(event, cursor);
    if (marking != null) return marking;
    final keys = HardwareKeyboard.instance;
    // The menu key and `Shift`+`F10` open the cursor row's menu (#1072), as
    // the editor's do: the only way to the row's actions without a pointer.
    if (!keys.isControlPressed &&
        !keys.isAltPressed &&
        !keys.isMetaPressed &&
        (event.logicalKey == LogicalKeyboardKey.contextMenu ||
            (event.logicalKey == LogicalKeyboardKey.f10 &&
                keys.isShiftPressed))) {
      return _openRowMenu(cursor.row);
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
    final handled = _walkKey(cursor, event.logicalKey);
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
  KeyEventResult _openRowMenu(TreeWalkRow row) {
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

  /// One key of the walk: [cursor] is the cursor's place in it, and what the
  /// key does is decided here.
  KeyEventResult _walkKey(TreeWalkCursor cursor, LogicalKeyboardKey key) {
    final (:at, :row) = cursor;
    final length = _walk.length;
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
      if (!row.pinned && at + 1 < length) {
        _whenRow(at + 1, (next) {
          if (next.depth > row.depth) _move(at + 1);
        });
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
      if (!row.pinned) _stepOut(at, row);
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

  /// The left arrow on a tree row that is not an open folder: to the file a
  /// sidecar is drawn under, else to the folder row that holds the row — the
  /// model knows where it is without any row loaded. The tree's own rows
  /// only: the pinned block above them is no folder of theirs.
  void _stepOut(int at, TreeWalkRow row) {
    final pinned = _walk.pinnedWalked;
    if (row.sidecar) {
      // Nested within the page, right under its file: the nearest row above
      // that is not a sidecar.
      for (var up = at - 1; up >= pinned; up--) {
        final above = _walk.rowAt(up);
        if (above == null) return;
        if (!above.sidecar) {
          _move(up);
          return;
        }
      }
      return;
    }
    final folder = _walk.rows?.listing.model.rowIndexOf(row.note.parent);
    if (folder != null) _move(pinned + folder);
  }

  /// The keys of several rows and of a name (#712): `Shift`+`↑`/`↓` marks
  /// on, `Space` marks or unmarks the cursor's row, `Esc` lets the marks
  /// go, `Delete` deletes the marked rows, `Ctrl`+`Enter` opens the note
  /// in a new tab, and letters jump to the next row whose name starts with
  /// them. Null for a key that is not one of these.
  KeyEventResult? _markKey(KeyEvent event, TreeWalkCursor cursor) {
    final keys = HardwareKeyboard.instance;
    final key = event.logicalKey;
    final (:at, :row) = cursor;
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
        _walk.length - 1,
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
    final typed = TreeTypeAhead.letterOf(event);
    return typed == null ? null : _letters.type(typed, at);
  }

  /// Marks every tree row from [from] to [to] in the walk, and [from]'s
  /// own when nothing was marked yet. The rows are read a page at a time
  /// when they are not all loaded.
  void _markRange(int from, int to) {
    // Asked after the cursor was found, which may have waited on the index.
    if (!mounted) return;
    final listing = _walk.rows?.listing;
    if (listing == null) return;
    final pinned = _walk.pinnedWalked;
    final first = math.max(math.min(from, to), pinned) - pinned;
    final last = math.max(from, to) - pinned;
    if (last < first) return;
    final reader = TreeRangeReader(listing);
    final held = reader.heldPaths(first, last);
    if (held != null) {
      setState(() => _marked.addAll(held));
      return;
    }
    unawaited(
      reader.paths(first, last).then((paths) {
        if (mounted) setState(() => _marked.addAll(paths));
      }, onError: _logReadFailure),
    );
  }

  /// A read of the index that failed under a gesture that did not wait for
  /// it: the marks are simply not made, and the gesture can be made again.
  void _logReadFailure(Object error) {
    const AppLogger(name: 'tree.ui').debug('read failed ($error)');
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
  /// and brings it into view. A row whose page is not loaded is scrolled to
  /// first, so that the list asks for the page, and the cursor lands when
  /// the page has.
  KeyEventResult _move(int index) {
    final to = index.clamp(0, _walk.length - 1);
    final row = _walk.rowAt(to);
    if (row != null) {
      _land(row);
      return KeyEventResult.handled;
    }
    final rows = _walk.rows;
    final at = to - _walk.pinnedWalked;
    if (rows != null && at >= 0 && _scroll.hasClients) {
      _scrollTo(_walk.treeTop(rows.listing.listIndexOf(at)), _walk.rowHeight);
    }
    unawaited(
      _walk.rowAtAsync(to).then((row) {
        if (row != null && mounted) _land(row);
      }),
    );
    return KeyEventResult.handled;
  }

  /// The cursor on [row].
  void _land(TreeWalkRow row) {
    setState(() {
      _cursorPath = row.path;
      _cursorPinned = row.pinned;
      _keyboardFocus = true;
    });
    _ensureCursorVisible(row);
  }

  /// A row's own click: the cursor follows it — the arrows go on from where
  /// the pointer left — and a folder takes the keyboard for the walk. A note
  /// does not: it opens for writing, and the shell gives the caret to it
  /// (#727) — taking the keys here would leave the note unable to be typed
  /// into.
  void _rowActivated(Note note, TreeWalkRow? row) {
    // `Shift`+click marks the rows from the cursor's to this one (#712),
    // and opens nothing.
    if (widget.onMarkedMenu != null &&
        HardwareKeyboard.instance.isShiftPressed &&
        row != null &&
        !row.pinned &&
        _walk.length > 0) {
      final to = row.index;
      final from = _cursorAtSync();
      if (from != null) {
        _markRange(from, to);
      } else {
        // Asked before the cursor is moved to this row.
        unawaited(
          _cursorAtAsync().then(
            (from) => _markRange(from, to),
            onError: _logReadFailure,
          ),
        );
      }
      setState(() {
        _cursorPath = note.path;
        _cursorPinned = false;
      });
      _focus.requestFocus();
      return;
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
  void _ensureCursorVisible(TreeWalkRow row) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (row.top >= position.pixels &&
          row.top + row.height <=
              position.pixels + position.viewportDimension) {
        return;
      }
      _scrollTo(row.top, row.height);
    });
  }

  /// Scrolls the item at [top], [height] tall, to the middle of the list.
  void _scrollTo(double top, double height) {
    final position = _scroll.position;
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
    _reader.dispose();
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
      _reader.reset();
      _walk.clear();
    }
    // Hidden under the grid the pane lets the keyboard go: the rows it
    // would walk are not the ones on screen (#727).
    if (!widget.active && oldWidget.active) _focus.unfocus();
  }

  /// Lets go of the marks on rows that are no longer in the tree — deleted,
  /// moved, renamed or folded away — so a `Delete` never goes to paths that
  /// are not on screen (#979). Once per read, not per frame.
  ///
  /// A row is folded away when a folder above it is not expanded; one that
  /// is gone is asked of the index, whatever page it was in.
  Future<void> _dropMarksOutside() async {
    if (_marked.isEmpty) return;
    final expanded = widget.expanded;
    _marked.removeWhere((path) => !_isUnderOpenFolders(path, expanded));
    if (_marked.isEmpty) return;
    final gone = await widget.controller.missingPaths(_marked.toList());
    _marked.removeWhere(gone.contains);
  }

  /// Whether every folder above [path] is in [expanded].
  static bool _isUnderOpenFolders(String path, Set<String> expanded) {
    for (var cut = path.lastIndexOf('/'); cut > 0;) {
      if (!expanded.contains(path.substring(0, cut))) return false;
      cut = path.lastIndexOf('/', cut - 1);
    }
    return true;
  }

  /// Puts the row being made in [listing], one under its folder's row. The
  /// folder is usually on screen, its row in a loaded page; when it is not,
  /// its place is asked of the index and the row shows when it answers.
  void _placeCreating(TreeListing listing) {
    final creating = widget.creating;
    if (creating == null || creating.folder.isEmpty) {
      // At the root the row being made tops the tree, outside the list.
      listing.placeCreating(null);
      return;
    }
    final folder = creating.folder;
    void place(int at) => listing.placeCreating(
      at,
      // One in from the folder's row.
      depth: listing.model.slotAt(at).depth + 1,
    );
    final held = listing.modelIndexOfLoaded(folder);
    if (held != null) {
      place(held);
      return;
    }
    listing.placeCreating(null);
    if (listing.isFrozen ||
        (identical(_placingListing, listing) && _placingFolder == folder)) {
      return;
    }
    _placingListing = listing;
    _placingFolder = folder;
    unawaited(
      listing.modelIndexOfPath(folder).then((at) {
        if (at == null ||
            !mounted ||
            !identical(_walk.rows?.listing, listing) ||
            widget.creating?.folder != folder) {
          return;
        }
        setState(() => place(at));
      }),
    );
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
        _reader
          ..rowHeightHint = TreeRowMetrics.of(context).height
          ..viewportHint = MediaQuery.sizeOf(context).height;
        return FutureBuilder<TreeRows>(
          future: _reader.rowsFor(
            snapshot.data ?? revision,
            followsContents: followsContents,
          ),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data!;
            if (rows.isEmpty) {
              _walk.clear();
              return Center(child: Text(AppStrings.treeEmpty));
            }
            // The pinned notes sit above the tree with a heading of their
            // own; below the divider the tree is unchanged, so a pinned
            // note appears twice — once where it is kept, once where it
            // is wanted. Rolled up, the heading and the divider stay: the
            // count is still worth seeing, and the tree keeps the room.
            final rowHeight = TreeRowMetrics.of(context).height;
            final listing = rows.listing;
            _walk.layout(
              rows,
              rowHeight: rowHeight,
              collapsed: _reader.collapsed,
            );
            _placeCreating(listing);
            _revealRenamed();
            final header = _walk.pinnedHeights.length;
            // What a list does for the system's insets when it is given no
            // padding of its own: the main axis's go around the slivers, and
            // the rows below see the cross axis's alone.
            final media = MediaQuery.of(context);
            final list = CustomScrollView(
              key: const Key('note-tree-list'),
              controller: _scroll,
              // The cache extent the pages are read for, named: the list and
              // the window of rows kept agree on it.
              scrollCacheExtent: const ScrollCacheExtent.pixels(
                RenderAbstractViewport.defaultCacheExtent,
              ),
              semanticChildCount: header + listing.length,
              slivers: [
                SliverPadding(
                  padding: media.padding.copyWith(left: 0, right: 0),
                  sliver: MediaQuery(
                    data: media.copyWith(
                      padding: media.padding.copyWith(top: 0, bottom: 0),
                    ),
                    child: SliverMainAxisGroup(
                      slivers: [
                        if (header > 0)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              // What the keyboard walks on this item: its
                              // place, and the row a key on it acts upon
                              // (#727).
                              (context, index) => _pinnedItem(
                                rows.pinned,
                                index,
                                _walk.pinnedAt(index),
                              ),
                              childCount: header,
                            ),
                          ),
                        // Every row of the tree is the same height, so the
                        // list lays out and jumps by arithmetic, however
                        // many rows there are.
                        SliverFixedExtentList(
                          itemExtent: rowHeight,
                          delegate: TreeRowsDelegate(
                            (context, index) =>
                                _treeItem(listing, index, rowHeight),
                            childCount: listing.length,
                            onLaidOut: _reader.onLaidOut,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
            final move = widget.onMove;
            final creating = widget.creating;
            // At the root, the row being made tops the tree (#712).
            final listed = creating != null && creating.folder.isEmpty
                ? Column(
                    children: [
                      TreeCreateRow(creating: creating, depth: 0),
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

  /// The tree's row at list index [index]: a tile, the row being made, or —
  /// while its page is not loaded — an empty row of the same height, whose
  /// page is asked for after the frame.
  Widget _treeItem(TreeListing listing, int index, double rowHeight) {
    final entry = listing.entryAt(index);
    if (entry.creating) {
      final creating = widget.creating;
      return creating == null
          ? SizedBox(height: rowHeight)
          : TreeCreateRow(creating: creating, depth: entry.depth);
    }
    final note = entry.note;
    if (note == null) {
      final page = entry.page;
      if (page != null && !listing.isFrozen) _reader.wantPage(page);
      return SizedBox(height: rowHeight);
    }
    final walked = _walk.treeRow(listing.modelIndexOf(index)!, entry);
    return TreeRowTile(
      note: note,
      depth: entry.depth,
      sidecar: entry.sidecar,
      ocrQueue: widget.ocrQueue,
      isExpanded: widget.expanded.contains(note.path),
      selected: note.path == widget.selectedPath || _marked.contains(note.path),
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
      dragPaths: _dragPaths(note.path),
      renaming: widget.renaming?.path == note.path ? widget.renaming : null,
    );
  }

  /// One item of the pinned block: the heading, a pinned note, or the
  /// divider that closes it off from the tree. [walked] is what the
  /// keyboard walks on it, for the row's ring and its cursor (#727).
  Widget _pinnedItem(List<Note> pinned, int index, TreeWalkRow? walked) {
    if (index == 0) return _pinnedHeading(pinned.length);
    if (index == (_reader.collapsed ? 1 : pinned.length + 1)) {
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
    return TreeRowTile(
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
          onTap: () => _togglePinned(collapsed: !_reader.collapsed),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Row(
              children: [
                Icon(
                  _reader.collapsed ? Icons.chevron_right : Icons.expand_more,
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
    setState(() => _reader.collapsed = collapsed);
    unawaited(widget.controller.setPinnedCollapsed(collapsed: collapsed));
  }
}
