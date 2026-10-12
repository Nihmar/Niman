/// The Files pane as a grid (#727): the folder shown, its children as
/// tiles, folders first and in the tree's own order.
///
/// A tile carries an icon, the name on up to two lines and the date of
/// the field the folder is sorted by. Everything a tile draws comes from
/// the index — no file is read or stat'ed, so a large folder costs the
/// same as a small one and Android pays no FUSE round trips for it: a
/// picture wears its outline icon, not a thumbnail.
///
/// A tap opens a note or enters a folder, a long press (right-click with
/// a pointer) opens the row's own menu, a drag moves what is dropped on a
/// tile or a breadcrumb crumb, and a rename in place lays the tree's own
/// field over the tile being renamed. The keyboard walks the tiles; Enter
/// opens, Backspace or Alt+Up goes up, F2 renames and Delete deletes the
/// focused tile.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kMiddleMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/file_icon.dart';
import 'package:niman/src/ui/folder_crumbs.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_tree_order.dart';
import 'package:niman/src/ui/ocr/ocr_tree_ring.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree.dart' show TreeRename, displayNameOf, isoDate;
import 'package:niman/src/ui/tree_drag.dart';
import 'package:niman/src/ui/tree_rename_field.dart';
import 'package:path/path.dart' as p;

/// A tile's height, and the least width one takes: the columns follow the
/// pane's width at roughly these.
const double _tileHeight = 110;
const double _minTileWidth = 88;

const double _gap = 4;
const double _padding = 8;

/// What the grid reads: the folder it settled on — the asked one, or the
/// nearest ancestor that still exists — and its children.
final class _GridRows {
  const new({required this.folder, required this.rows});

  final String folder;
  final List<(Note, bool)> rows;
}

/// The folder grid: the Files pane's second view.
final class FolderGrid extends StatefulWidget {
  /// Creates the grid of [folder]'s children.
  const new({
    required this.controller,
    required this.folder,
    required this.sort,
    required this.selectedPath,
    required this.onOpen,
    required this.onGoTo,
    required this.onUp,
    this.active = true,
    this.onFolderResolved,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onOpenInNewTab,
    this.onBackgroundSecondaryTapUp,
    this.onMove,
    this.onRename,
    this.onDelete,
    this.ocrQueue,
    this.renaming,
    super.key,
  });

  /// The session providing the index and the change-event stream.
  final LibrarySession controller;

  /// The folder shown, library-relative; '' is the root.
  final String folder;

  /// The order the tiles come in (T-UI-03, #726).
  final TreeSort sort;

  /// Library-relative path of the note open in the pane, or null.
  final String? selectedPath;

  /// Called when a tile is activated with a tap or Enter: a folder to
  /// enter, or a note to open.
  final void Function(Note note) onOpen;

  /// Called when a breadcrumb crumb is chosen; the shell moves the grid.
  final ValueChanged<String> onGoTo;

  /// Called when the way up is taken; no-op at the root.
  final VoidCallback onUp;

  /// Whether the grid is the pane on screen. Hidden under the tree it
  /// keeps its folder and its scroll, but lets go of the keyboard.
  final bool active;

  /// Called when the folder asked for is gone and the grid settled on an
  /// ancestor instead (#727), so the shell can align its own state.
  final ValueChanged<String>? onFolderResolved;

  /// Called with a tile's note on long-press (the row menu), and the
  /// tile's place on screen for a pointer's menu to grow from.
  final void Function(Note note, Rect? anchor)? onLongPress;

  /// Called with a tile's note on right-click: the desktop's menu at the
  /// cursor.
  final void Function(Note note, TapDownDetails details)? onSecondaryTapDown;

  /// Called with a note's tile on a middle click: the note in a tab of
  /// its own.
  final void Function(Note note)? onOpenInNewTab;

  /// Called on a right click on the grid's empty space: the shown folder
  /// is "here" for the menu it opens.
  final Future<void> Function(String folder, TapUpDetails details)?
  onBackgroundSecondaryTapUp;

  /// Moves a dragged tile's note or folder (#567); null leaves the tiles
  /// where they are.
  final TreeMove? onMove;

  /// Starts renaming the tile at `path`: `F2` and the tile menu's
  /// Rename.
  final ValueChanged<String>? onRename;

  /// Deletes the tile at `path`: the Delete key.
  final ValueChanged<String>? onDelete;

  /// The text recognition jobs: a file being read wears a ring (#595);
  /// null shows none.
  final OcrQueue? ocrQueue;

  /// The tile whose name is being edited in place (#707), and what its
  /// field does; null while none is.
  final TreeRename? renaming;

  @override
  State<FolderGrid> createState() => _FolderGridState();
}

final class _FolderGridState extends State<FolderGrid> {
  /// The rows currently being shown, and the inputs they were built from:
  /// reused across the shell's rebuilds so a selection or a toggle does
  /// not re-query the folder.
  Future<_GridRows>? _rows;
  int? _rowsRevision;
  bool _rowsFollowContents = false;
  String? _rowsFolder;
  TreeSort _rowsSort = TreeSort.nameAsc;

  /// The rows of the last build, for the keyboard to walk.
  _GridRows? _current;

  /// The grid's scroll, the focus the keyboard walks with, the tile it is
  /// on, and whether that ring was arrived at by keyboard (a pointer puts
  /// the ring away).
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode(debugLabel: 'folder-grid');
  int? _focusIndex;
  bool _keyboardFocus = false;

  /// The columns and viewport height of the last build, for key steps.
  int _columns = 1;
  double _viewportHeight = 0;

  /// The tile a rename has been revealed for, so it is scrolled to once.
  String? _revealed;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FolderGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _rows = null;
    }
    if (widget.folder != oldWidget.folder) {
      _focusIndex = null;
      _revealed = null;
    }
    if (!widget.active && oldWidget.active) _focus.unfocus();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  /// The rows for [revision], recomputed only when the index revision,
  /// the folder or the sort changed — the tree's own cache key (#371).
  ///
  /// Hidden under the tree — [FolderGrid.active] false — the revision is
  /// not part of the key: the pane is kept for its scroll and its folder
  /// (#727), not to keep a folder nobody is looking at fresh, and with a
  /// field order (every save carries one) it would otherwise re-query on
  /// every write. Becoming active again asks for the rows once, with the
  /// revision of that moment.
  Future<_GridRows> _rowsFor(int revision, {required bool followsContents}) {
    final cached = _rows;
    if (cached != null &&
        _rowsSort == widget.sort &&
        _rowsFolder == widget.folder &&
        (!widget.active ||
            (_rowsRevision == revision &&
                _rowsFollowContents == followsContents))) {
      return cached;
    }
    _rowsRevision = revision;
    _rowsFollowContents = followsContents;
    _rowsSort = widget.sort;
    _rowsFolder = widget.folder;
    return _rows = _load();
  }

  /// The folder's children from the index, falling back to the nearest
  /// ancestor that still exists.
  ///
  /// The folder and the sort are read once, before the first await: a
  /// load the grid has already moved on from must neither query with the
  /// new inputs nor report its own folder as a fallback, which would pull
  /// the grid back to where it was (#727).
  Future<_GridRows> _load() async {
    final asked = widget.folder;
    final sort = widget.sort;
    var at = asked;
    Note? dir;
    while (at.isNotEmpty) {
      final found = await widget.controller.ops?.find(at);
      if (found != null && found.isDir) {
        dir = found;
        break;
      }
      at = parentOf(at);
    }
    final children = await widget.controller.children(dir?.id ?? 0, sort: sort);
    final rows = _GridRows(
      folder: at,
      rows: nestOcrSidecars(children, (note) => note.name).toList(),
    );
    if (rows.folder != asked &&
        asked == widget.folder &&
        widget.onFolderResolved != null) {
      final resolved = widget.onFolderResolved!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) resolved(rows.folder);
      });
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    // A save writes size and time and nothing a name-ordered grid draws:
    // those tiles stand, and only the field orders follow every change
    // (#751).
    final followsContents = widget.sort.contentMovesRows;
    final controller = widget.controller;
    final revision = followsContents
        ? controller.revision
        : controller.treeRevision;
    return Column(
      children: [
        FolderCrumbs(
          folder: widget.folder,
          onOpen: widget.onGoTo,
          onUp: widget.onUp,
          onMove: widget.onMove ?? (_, _) {},
        ),
        // The walk's focus holds the pane whatever it shows: an empty
        // folder, or one still loading, keeps the keyboard and its way up.
        Expanded(
          child: Focus(
            focusNode: _focus,
            onKeyEvent: _onKey,
            child: StreamBuilder<int>(
              key: ValueKey<bool>(followsContents),
              stream: followsContents
                  ? controller.events
                  : controller.treeEvents,
              initialData: revision,
              builder: (context, snapshot) => FutureBuilder<_GridRows>(
                future: _rowsFor(
                  snapshot.data ?? revision,
                  followsContents: followsContents,
                ),
                builder: (context, snap) {
                  final rows = snap.data;
                  if (rows == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  _current = rows;
                  if (rows.rows.isEmpty) return _empty(context, rows.folder);
                  return _grid(context, rows);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// The invitation an empty folder shows: the folder's name, and how to
  /// fill it.
  Widget _empty(BuildContext context, String folder) {
    final theme = Theme.of(context);
    final label = folder.isEmpty ? AppStrings.libraryCrumb : p.basename(folder);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              folder.isEmpty
                  ? AppStrings.treeEmpty
                  : AppStrings.folderEmpty(label),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.folderEmptyHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The grid itself, with the rename field over the tile it edits.
  Widget _grid(BuildContext context, _GridRows rows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _viewportHeight = constraints.maxHeight;
        _columns = math.max(
          1,
          ((width - _padding * 2 + _gap) / (_minTileWidth + _gap)).floor(),
        );
        final renaming = widget.renaming;
        final renameIndex = renaming == null
            ? -1
            : rows.rows.indexWhere((row) => row.$1.path == renaming.path);
        if (renameIndex >= 0) _revealRenaming(renameIndex, _columns);
        return Stack(
          children: [
            _scrollable(context, rows),
            if (renameIndex >= 0)
              _renameOverlay(context, rows, renameIndex, width, _columns),
          ],
        );
      },
    );
  }

  Widget _scrollable(BuildContext context, _GridRows rows) {
    final background = widget.onBackgroundSecondaryTapUp;
    final grid = GridView.builder(
      key: const Key('folder-grid-scroll'),
      controller: _scroll,
      padding: const EdgeInsets.all(_padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisExtent: _tileHeight,
        crossAxisSpacing: _gap,
        mainAxisSpacing: _gap,
      ),
      itemCount: rows.rows.length,
      itemBuilder: (context, index) {
        final (note, sidecar) = rows.rows[index];
        return _tile(context, note: note, sidecar: sidecar, index: index);
      },
    );
    // The empty space is the folder shown: a drop there is the folder a
    // child already sits in, so nothing moves — and it must claim the
    // drop, or it would reach nothing at all.
    final move = widget.onMove;
    return GestureDetector(
      key: const Key('folder-grid-background'),
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: background == null
          ? null
          : (details) => unawaited(background(rows.folder, details)),
      child: Listener(
        onPointerDown: (_) {
          if (_keyboardFocus) setState(() => _keyboardFocus = false);
        },
        child: move == null
            ? grid
            : DragTarget<String>(
                onWillAcceptWithDetails: (details) =>
                    treeDropMoves(details.data, rows.folder),
                onAcceptWithDetails: (details) =>
                    move(details.data, rows.folder),
                builder: (context, _, _) => grid,
              ),
      ),
    );
  }

  /// One tile: its icon, its name and its date, its pin, and the ways it
  /// is opened, dragged and dropped on.
  Widget _tile(
    BuildContext context, {
    required Note note,
    required bool sidecar,
    required int index,
  }) {
    final theme = Theme.of(context);
    final selected = !note.isDir && note.path == widget.selectedPath;
    final focused =
        _keyboardFocus && _focus.hasPrimaryFocus && _focusIndex == index;
    final middle = widget.onOpenInNewTab;
    final longPress = widget.onLongPress == null
        ? null
        : () => widget.onLongPress!(note, menuAnchorOf(context));
    final date = widget.sort.order == TreeOrder.created
        ? note.created
        : note.modified;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: sidecar ? 12 : 12.5,
      height: 16 / 12.5,
      color: sidecar ? theme.colorScheme.onSurfaceVariant : null,
    );
    Widget icon = Icon(
      sidecar
          ? Icons.document_scanner_outlined
          : (note.isDir ? Icons.folder_outlined : fileIconFor(note.name)),
      size: sidecar ? 24 : 32,
      color: sidecar ? theme.colorScheme.onSurfaceVariant : null,
    );
    final queue = widget.ocrQueue;
    if (queue != null && !note.isDir && isRecognizableFile(note.name)) {
      icon = OcrTreeRing(queue: queue, path: note.path, placeholder: icon);
    }
    Widget tile = InkWell(
      key: Key('grid-tile-${note.path}'),
      // The walk owns the keyboard here (#727), as in the tree: a tile
      // that took the focus itself would leave the arrows to nobody.
      canRequestFocus: false,
      onTap: () {
        setState(() {
          _focusIndex = index;
          _keyboardFocus = false;
        });
        // A folder takes the keyboard for the walk; a note opens for
        // writing and the shell gives the caret to it (#727), so taking
        // the keys here would leave the note unable to be typed into.
        if (note.isDir) _focus.requestFocus();
        widget.onOpen(note);
      },
      onLongPress: TreeRowDrag.holdToDrag ? null : longPress,
      onSecondaryTapDown: widget.onSecondaryTapDown == null
          ? null
          : (details) => widget.onSecondaryTapDown!(note, details),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? theme.highlightColor.withValues(alpha: 0.4) : null,
          border: focused
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 7),
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 32, child: Center(child: icon)),
                const SizedBox(height: 5),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      displayNameOf(note),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ),
                ),
                Text(
                  isoDate(date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (note.pinned && !note.isDir)
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.push_pin, size: 13),
              ),
          ],
        ),
      ),
    );
    final move = widget.onMove;
    // A tile being renamed is not dragged: a drag in its field selects
    // text.
    if (move != null && widget.renaming?.path != note.path) {
      tile = TreeRowDrag(
        note: note,
        onMove: move,
        onLongPress: longPress,
        child: tile,
      );
    }
    if (middle == null || note.isDir) return tile;
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton) middle(note);
      },
      child: tile,
    );
  }

  /// The rename field over the tile at [index]: at least 220 px wide,
  /// growing past the tile over its neighbours, and staying inside the
  /// pane.
  Widget _renameOverlay(
    BuildContext context,
    _GridRows rows,
    int index,
    double width,
    int columns,
  ) {
    final note = rows.rows[index].$1;
    final tileWidth = _tileWidth(width, columns);
    // The field is wider than a tile — a name needs the room — and never
    // leaves the pane.
    const fieldMin = 220.0;
    final fieldWidth = math.min(math.max(fieldMin, tileWidth), width - 8);
    final center =
        _padding + (index % columns) * (tileWidth + _gap) + tileWidth / 2;
    final left = (center - fieldWidth / 2).clamp(4.0, width - fieldWidth - 4);
    final top = _padding + (index ~/ columns) * (_tileHeight + _gap) + 40;
    final renaming = widget.renaming!;
    return AnimatedBuilder(
      animation: _scroll,
      builder: (context, child) {
        final at = top - (_scroll.hasClients ? _scroll.offset : 0);
        if (at + 48 < 0 || at > _viewportHeight) return const SizedBox.shrink();
        return Positioned(
          left: left,
          top: at,
          width: fieldWidth,
          child: child!,
        );
      },
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(6),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: TreeRenameField(
            name: note.name,
            isDir: note.isDir,
            style: Theme.of(context).textTheme.bodyMedium,
            onSubmit: renaming.submit,
            onCancel: renaming.cancel,
          ),
        ),
      ),
    );
  }

  /// Brings the tile being renamed into view, so its field is on screen
  /// when it opens.
  void _revealRenaming(int index, int columns) {
    final path = widget.renaming?.path;
    if (path == null || path == _revealed) return;
    _revealed = path;
    _ensureVisible(index, columns);
  }

  /// The keyboard: the arrows, Home/End and PgUp/PgDn walk the tiles,
  /// Enter opens, Backspace or Alt+Up goes up, F2 renames and Delete
  /// deletes the focused tile.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.active) return KeyEventResult.ignored;
    // Ancestor of the rename field too: keys reach here from it, and a
    // Backspace in a name must not walk the grid up.
    if (!_focus.hasPrimaryFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final keys = HardwareKeyboard.instance;
    // Alt+Up is the pane's own way up (#727) — the one modified key the
    // walk keeps.
    if (key == LogicalKeyboardKey.arrowUp && keys.isAltPressed) return _up();
    // Every other modified key belongs to the app's accelerators (#23):
    // Alt+Left and Alt+Right walk the notes' history, Ctrl+Shift+PageUp
    // and PageDown the journal — the walk claims the plain key or none.
    if (keys.isControlPressed ||
        keys.isAltPressed ||
        keys.isMetaPressed ||
        keys.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    // The way up needs no tile: an empty folder is left as a full one is.
    if (key == LogicalKeyboardKey.backspace) return _up();
    final rows = _current;
    if (rows == null || rows.rows.isEmpty) return KeyEventResult.ignored;
    final count = rows.rows.length;
    final columns = _columns;
    int? next;
    if (key == LogicalKeyboardKey.arrowLeft) {
      next = (_focusIndex ?? 0) - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      next = (_focusIndex ?? 0) + 1;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      next = (_focusIndex ?? 0) - columns;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      next = (_focusIndex ?? 0) + columns;
    } else if (key == LogicalKeyboardKey.home) {
      next = 0;
    } else if (key == LogicalKeyboardKey.end) {
      next = count - 1;
    } else if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final perPage = math.max(
        1,
        (_viewportHeight / (_tileHeight + _gap)).floor(),
      );
      final step = columns * perPage;
      next =
          (_focusIndex ?? 0) +
          (key == LogicalKeyboardKey.pageUp ? -step : step);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return _activate(rows);
    } else if (key == LogicalKeyboardKey.f2) {
      final path = _focusedPath(rows);
      if (path == null) return KeyEventResult.ignored;
      widget.onRename?.call(path);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.delete) {
      final path = _focusedPath(rows);
      if (path == null) return KeyEventResult.ignored;
      widget.onDelete?.call(path);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
    final target = next.clamp(0, count - 1);
    setState(() {
      _focusIndex = target;
      _keyboardFocus = true;
    });
    _ensureVisible(target, columns);
    return KeyEventResult.handled;
  }

  /// Backspace or Alt+Up: up one folder, or nothing at the root.
  KeyEventResult _up() {
    if (widget.folder.isEmpty) return KeyEventResult.ignored;
    widget.onUp();
    return KeyEventResult.handled;
  }

  /// Enter on the focused tile: a folder to enter, a note to open.
  KeyEventResult _activate(_GridRows rows) {
    final index = _focusIndex;
    if (index == null || index < 0 || index >= rows.rows.length) {
      return KeyEventResult.ignored;
    }
    widget.onOpen(rows.rows[index].$1);
    return KeyEventResult.handled;
  }

  /// The path of the focused tile, or null while none is focused.
  String? _focusedPath(_GridRows rows) {
    final index = _focusIndex;
    if (index == null || index < 0 || index >= rows.rows.length) return null;
    return rows.rows[index].$1.path;
  }

  /// Scrolls the tile at [index] into view, a third down the pane when it
  /// has to move: the focused tile, or the one being renamed.
  void _ensureVisible(int index, int columns) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final top = _padding + (index ~/ columns) * (_tileHeight + _gap);
      final position = _scroll.position;
      if (top >= position.pixels &&
          top + _tileHeight <= position.pixels + position.viewportDimension) {
        return;
      }
      _scroll.jumpTo(
        (top - position.viewportDimension / 3).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }
}

/// The width of one tile in a pane [width] wide with [columns] columns.
double _tileWidth(double width, int columns) =>
    (width - _padding * 2 - (columns - 1) * _gap) / columns;
