import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree_create_placement.dart';
import 'package:niman/src/ui/tree_create_row.dart';
import 'package:niman/src/ui/tree_cursor.dart';
import 'package:niman/src/ui/tree_drag.dart';
import 'package:niman/src/ui/tree_drag_scroll.dart';
import 'package:niman/src/ui/tree_key_walk.dart';
import 'package:niman/src/ui/tree_listing.dart';
import 'package:niman/src/ui/tree_marks.dart';
import 'package:niman/src/ui/tree_pages.dart';
import 'package:niman/src/ui/tree_pinned_heading.dart';
import 'package:niman/src/ui/tree_range_reader.dart';
import 'package:niman/src/ui/tree_reveal.dart';
import 'package:niman/src/ui/tree_row_list.dart';
import 'package:niman/src/ui/tree_row_metrics.dart';
import 'package:niman/src/ui/tree_row_tile.dart';
import 'package:niman/src/ui/tree_rows.dart';
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
    dropMarks: () => _marks.dropOutside(widget.expanded, widget.controller),
    onPageLanded: () => setState(() {}),
  );

  /// The tree's scroll, which a rename in place moves to its row (#707).
  final ScrollController _scroll = ScrollController();

  /// The closed folders a drag has dwelt on and opened (#1071).
  late final TreeSpringLoad _spring = TreeSpringLoad(
    isOpen: (path) => widget.expanded.contains(path),
    toggle: (path) => widget.onToggle(path),
  );

  /// The keyboard's own focus (#727): the pane takes it when a row is
  /// clicked, and the arrows walk the rows while it holds it.
  late final FocusNode _focus =
      widget.focusNode ?? FocusNode(debugLabel: 'note-tree');

  /// The rows marked together (#712).
  final TreeMarks _marks = TreeMarks();

  /// The jump to a row by the name typed (#712).
  late final TreeTypeAhead _letters = TreeTypeAhead(
    walk: _walk,
    move: _move,
    cursorAt: _cursor.atAsync,
    mounted: () => mounted,
  );

  /// The keyboard's cursor and its ring (#727).
  late final TreeCursor _cursor = TreeCursor(
    walk: _walk,
    selectedPath: () => widget.selectedPath,
  );

  /// The rows of the last build as the keyboard walks them (#727).
  final TreeWalk _walk = TreeWalk();

  /// What a plain key does on the rows (#727).
  late final TreeKeyWalk _keyWalk = TreeKeyWalk(
    walk: _walk,
    scroll: _scroll,
    move: _move,
    mounted: () => mounted,
  );

  /// Brings the row being renamed and the keyboard's cursor into view.
  late final TreeReveal _reveal = TreeReveal(
    walk: _walk,
    scroll: _scroll,
    mounted: () => mounted,
  );

  /// Where the row being made goes in the listing (#712).
  late final TreeCreatePlacement _placement = TreeCreatePlacement(
    walk: _walk,
    creating: () => widget.creating,
    mounted: () => mounted,
    update: setState,
  );

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
    if (_walk.length == 0 || !TreeKeyWalk.owns(event)) {
      return KeyEventResult.ignored;
    }
    final here = _cursor.here();
    if (here != null) return _keyAt(event, here);
    unawaited(
      _cursor.resolved().then((here) {
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
    final handled = _keyWalk.handle(
      cursor,
      event.logicalKey,
      expanded: widget.expanded,
      select: widget.onSelect,
      toggle: widget.onToggle,
      rename: widget.onRename,
      delete: widget.onDelete,
    );
    // The keyboard is in use: the ring comes back if a pointer had put it
    // away — and stays off for a key the walk does not own.
    if (handled == KeyEventResult.handled && !_cursor.ring) {
      setState(() => _cursor.ring = true);
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
    if (!_cursor.ring) setState(() => _cursor.ring = true);
    final marked = widget.onMarkedMenu;
    if (marked != null && !row.pinned && _marks.isAmongSeveral(row.path)) {
      marked(_marks.toList(), anchor);
      return KeyEventResult.handled;
    }
    final menu = widget.onLongPress;
    if (menu == null) return KeyEventResult.ignored;
    if (_marks.isNotEmpty) setState(_marks.clear);
    menu(row.note, anchor);
    return KeyEventResult.handled;
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
      setState(() => _marks.toggle(row.path));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _marks.isNotEmpty) {
      setState(_marks.clear);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete && _marks.isNotEmpty) {
      // As a right click does (#979): on a marked row, `Delete` is the
      // marks'; on any other it is that row's alone, and the marks let go
      // rather than wait to be deleted by a later key.
      if (!row.pinned && _marks.isAmongSeveral(row.path)) {
        final delete = widget.onDeleteMarked;
        if (delete == null) return KeyEventResult.ignored;
        delete(_marks.toList());
        setState(_marks.clear);
        return KeyEventResult.handled;
      }
      setState(_marks.clear);
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
      setState(() => _marks.addAll(held));
      return;
    }
    unawaited(
      reader.paths(first, last).then((paths) {
        if (mounted) setState(() => _marks.addAll(paths));
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
    if (marked != null && _marks.isAmongSeveral(note.path)) {
      marked(_marks.toList(), menuAnchorAt(details.globalPosition));
      return;
    }
    if (_marks.isNotEmpty) setState(_marks.clear);
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
      _reveal.scrollTo(
        _walk.treeTop(rows.listing.listIndexOf(at)),
        _walk.rowHeight,
      );
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
    setState(() => _cursor.moveTo(row.path, pinned: row.pinned, ring: true));
    _reveal.ensureVisible(row);
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
      final from = _cursor.at();
      if (from != null) {
        _markRange(from, to);
      } else {
        // Asked before the cursor is moved to this row.
        unawaited(
          _cursor.atAsync().then(
            (from) => _markRange(from, to),
            onError: _logReadFailure,
          ),
        );
      }
      setState(() => _cursor.moveTo(note.path, pinned: false));
      _focus.requestFocus();
      return;
    }
    setState(() {
      _marks.clear();
      _cursor.moveTo(
        row?.path ?? note.path,
        pinned: row?.pinned ?? false,
        ring: false,
      );
    });
    if (note.isDir) _focus.requestFocus();
    widget.onSelect(note);
  }

  /// A folder's chevron: the cursor follows the folder that was opened or
  /// closed, and the pane takes the keyboard.
  void _rowToggled(String path, {required bool pinned}) {
    setState(() => _cursor.moveTo(path, pinned: pinned, ring: false));
    _focus.requestFocus();
    widget.onToggle(path);
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
            _placement.place(listing);
            _reveal.renamed(widget.renaming?.path);
            final header = _walk.pinnedHeights.length;
            final list = TreeRowList(
              controller: _scroll,
              pinnedCount: header,
              // What the keyboard walks on this item: its place, and the row
              // a key on it acts upon (#727).
              pinnedItem: (context, index) =>
                  _pinnedItem(rows.pinned, index, _walk.pinnedAt(index)),
              rowCount: listing.length,
              rowHeight: rowHeight,
              row: (context, index) => _treeItem(listing, index, rowHeight),
              onLaidOut: _reader.onLaidOut,
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
      selected: note.path == widget.selectedPath || _marks.contains(note.path),
      focused: _cursor.isOn(walked, focused: _focus.hasPrimaryFocus),
      onSelect: (note) => _rowActivated(note, walked),
      onToggle: (path) => _rowToggled(path, pinned: false),
      onLongPress: widget.onLongPress,
      onSecondaryTapDown: widget.onSecondaryTapDown == null
          ? null
          : _secondaryTap,
      onMiddleClick: widget.onOpenInNewTab,
      onMove: widget.onMove,
      spring: _spring,
      dragPaths: _marks.dragPaths(note.path),
      renaming: widget.renaming?.path == note.path ? widget.renaming : null,
    );
  }

  /// One item of the pinned block: the heading, a pinned note, or the
  /// divider that closes it off from the tree. [walked] is what the
  /// keyboard walks on it, for the row's ring and its cursor (#727).
  Widget _pinnedItem(List<Note> pinned, int index, TreeWalkRow? walked) {
    if (index == 0) {
      return TreePinnedHeading(
        count: pinned.length,
        collapsed: _reader.collapsed,
        onToggle: () => _togglePinned(collapsed: !_reader.collapsed),
      );
    }
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
      focused: _cursor.isOn(walked, focused: _focus.hasPrimaryFocus),
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

  /// Rolls the pinned section up or down, and remembers it for the
  /// library. The repaint does not wait on the write.
  void _togglePinned({required bool collapsed}) {
    setState(() => _reader.collapsed = collapsed);
    unawaited(widget.controller.setPinnedCollapsed(collapsed: collapsed));
  }
}
