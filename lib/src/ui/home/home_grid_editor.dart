/// The desktop Home being edited (#535): a tile is dragged by its body,
/// resized by its corner, hidden by its ✕ and moved or sized a cell at a
/// time from its menu, for whoever works without a pointer. The tiles to
/// add, and the hidden ones, wait beside the grid.
///
/// Every drop is written at once, settled first: the tile just placed
/// keeps its place and the ones it lands on move down.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/home/home_tile_move.dart';
import 'package:niman/src/ui/home/home_add_panel.dart';
import 'package:niman/src/ui/home/home_editing.dart';
import 'package:niman/src/ui/home/home_grid.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/home/home_tile_settings.dart';
import 'package:niman/src/ui/strings.dart';

/// The grid in edit mode, with the add panel at its side.
final class HomeGridEditor extends StatefulWidget {
  /// Edits [editing]'s layout; [tile] draws a tile's content.
  const new({required this.editing, required this.tile, super.key});

  /// The Home being edited.
  final HomeEditing editing;

  /// Draws one tile.
  final Widget Function(HomeTile tile, {bool fit}) tile;

  /// The add panel's width.
  static const double panelWidth = 248;

  @override
  State<HomeGridEditor> createState() => _HomeGridEditorState();
}

final class _HomeGridEditorState extends State<HomeGridEditor> {
  /// The tile under the pointer, and whether its corner is what moves.
  String? _dragging;
  bool _resizing = false;
  Offset _delta = Offset.zero;

  /// The grid's width at the last layout, for the drop.
  double _width = 0;

  HomeEditing get _editing => widget.editing;

  void _start(String id, {required bool resize}) => setState(() {
    _dragging = id;
    _resizing = resize;
    _delta = Offset.zero;
  });

  void _update(DragUpdateDetails details) =>
      setState(() => _delta += details.delta);

  void _end() {
    final id = _dragging;
    final tile = id == null ? null : _editing.layout[id];
    final target = tile == null ? null : _targetFor(tile);
    setState(() {
      _dragging = null;
      _delta = Offset.zero;
    });
    if (tile == null || target == null || target == tile.cell) return;
    unawaited(_place(tile, target));
  }

  Future<void> _place(HomeTile tile, HomeCell cell) => _editing.change(
    _editing.layout.put(tile.copyWith(cell: cell)).settled(first: tile.id),
  );

  /// Where the dragged tile would land, as the pointer has moved it.
  HomeCell _targetFor(HomeTile tile) {
    const columns = HomeTile.columns;
    const gap = HomeGridMetrics.gap;
    const row = HomeGridMetrics.rowHeight;
    final column = HomeGridMetrics.cellWidth(_width);
    final base = HomeGridMetrics.rectOf(tile.cell, _width);
    final (:x, :y, :w, :h) = tile.cell;
    if (_resizing) {
      return (
        x: x,
        y: y,
        w: ((base.width + _delta.dx + gap) / (column + gap)).round().clamp(
          1,
          columns - x,
        ),
        h: ((base.height + _delta.dy + gap) / (row + gap)).round().clamp(
          1,
          columns,
        ),
      );
    }
    return (
      x: ((base.left + _delta.dx) / (column + gap)).round().clamp(
        0,
        columns - w,
      ),
      y: max(0, ((base.top + _delta.dy) / (row + gap)).round()),
      w: w,
      h: h,
    );
  }

  /// Where [tile] is drawn: its cell, or under the pointer while dragged.
  Rect _rectOf(HomeTile tile) {
    final base = HomeGridMetrics.rectOf(tile.cell, _width);
    if (tile.id != _dragging) return base;
    if (!_resizing) return base.shift(_delta);
    return Rect.fromLTWH(
      base.left,
      base.top,
      max(HomeGridMetrics.cellWidth(_width), base.width + _delta.dx),
      max(HomeGridMetrics.rowHeight, base.height + _delta.dy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = _editing.layout.settled();
    final tiles = layout.column;
    final dragged = _dragging == null ? null : layout[_dragging!];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              _width = box.maxWidth;
              final target = dragged == null ? null : _targetFor(dragged);
              // One row more than the tiles hold: room to drop below them.
              final rows =
                  max(layout.bottom, target == null ? 0 : target.y + target.h) +
                  1;
              return SizedBox(
                height: HomeGridMetrics.heightOf(rows),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (target != null)
                      Positioned.fromRect(
                        rect: HomeGridMetrics.rectOf(target, _width),
                        child: const _DropGhost(),
                      ),
                    for (final t in [
                      for (final t in tiles)
                        if (t.id != _dragging) t,
                      ?dragged,
                    ])
                      Positioned.fromRect(
                        key: ValueKey(t.id),
                        rect: _rectOf(t),
                        child: _EditableTile(
                          tile: t,
                          content: widget.tile(t),
                          lifted: t.id == _dragging,
                          onStart: ({required resize}) =>
                              _start(t.id, resize: resize),
                          onUpdate: _update,
                          onEnd: _end,
                          onMove: (move) =>
                              unawaited(_place(t, move.apply(t.cell))),
                          onHide: () => unawaited(
                            _editing.change(layout.hide(t.id).settled()),
                          ),
                          onSettings: hasTileSettings(t)
                              ? () => unawaited(
                                  openTileSettings(context, _editing, t),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: HomeGridEditor.panelWidth,
          child: HomeAddPanel(editing: _editing),
        ),
      ],
    );
  }
}

/// Where the dragged tile will land.
final class _DropGhost extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const Key('home-drop-ghost'),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        border: Border.all(color: scheme.primary, width: 2),
        borderRadius: BorderRadius.circular(HomeTileFrame.radius),
      ),
    );
  }
}

/// A tile on the grid in edit mode: its content dimmed and inert, its
/// tools on top, its corner a handle.
final class _EditableTile extends StatelessWidget {
  const new({
    required this.tile,
    required this.content,
    required this.lifted,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onMove,
    required this.onHide,
    required this.onSettings,
  });

  final HomeTile tile;
  final Widget content;
  final bool lifted;
  final void Function({required bool resize}) onStart;
  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;
  final ValueChanged<HomeTileMove> onMove;
  final VoidCallback onHide;
  final VoidCallback? onSettings;

  /// The corner handle's touch target: larger than what it draws, for a
  /// finger on a tablet.
  static const double _handle = 32;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tool = IconButton.styleFrom(
      backgroundColor: scheme.surface,
      visualDensity: VisualDensity.compact,
      iconSize: 16,
    );
    return Material(
      key: Key('home-edit-${tile.id}'),
      elevation: lifted ? 8 : 0,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(HomeTileFrame.radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MouseRegion(
            cursor: lifted
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            child: _Grab(
              key: Key('home-drag-${tile.id}'),
              onStart: () => onStart(resize: false),
              onUpdate: onUpdate,
              onEnd: onEnd,
              child: IgnorePointer(
                child: Opacity(opacity: 0.55, child: content),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outline),
                borderRadius: BorderRadius.circular(HomeTileFrame.radius),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onSettings case final settings?)
                  IconButton(
                    key: Key('home-settings-${tile.id}'),
                    style: tool,
                    tooltip: AppStrings.homeTileSettings,
                    onPressed: settings,
                    icon: const Icon(Icons.tune),
                  ),
                PopupMenuButton<HomeTileMove>(
                  key: Key('home-move-${tile.id}'),
                  tooltip: AppStrings.homeTileMove,
                  style: tool,
                  icon: const Icon(Icons.more_horiz),
                  onSelected: onMove,
                  itemBuilder: (context) => [
                    for (final move in HomeTileMove.values)
                      PopupMenuItem(value: move, child: Text(_label(move))),
                  ],
                ),
                IconButton(
                  key: Key('home-hide-${tile.id}'),
                  style: tool,
                  tooltip: AppStrings.homeTileHide,
                  onPressed: onHide,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            width: _handle,
            height: _handle,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpLeftDownRight,
              child: _Grab(
                key: Key('home-resize-${tile.id}'),
                onStart: () => onStart(resize: true),
                onUpdate: onUpdate,
                onEnd: onEnd,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.south_east,
                      size: 16,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(HomeTileMove move) => switch (move) {
    HomeTileMove.left => AppStrings.homeMoveLeft,
    HomeTileMove.right => AppStrings.homeMoveRight,
    HomeTileMove.up => AppStrings.homeMoveUp,
    HomeTileMove.down => AppStrings.homeMoveDown,
    HomeTileMove.wider => AppStrings.homeWider,
    HomeTileMove.narrower => AppStrings.homeNarrower,
    HomeTileMove.taller => AppStrings.homeTaller,
    HomeTileMove.shorter => AppStrings.homeShorter,
  };
}

/// What a tile or its corner is grabbed with: at once by a mouse, a
/// trackpad or a pen, after a long press by a finger — so a finger that
/// only means to scroll the Home still scrolls it.
///
/// A plain pan would lose to the page's scroll on a touch screen: the
/// scroll claims a vertical move first.
final class _Grab extends StatelessWidget {
  const new({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
    super.key,
  });

  final VoidCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;
  final Widget child;

  Drag _start(Offset _) {
    onStart();
    return _TileDrag(onUpdate: onUpdate, onEnd: onEnd);
  }

  @override
  Widget build(BuildContext context) {
    const precise = {
      PointerDeviceKind.mouse,
      PointerDeviceKind.trackpad,
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
    };
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        ImmediateMultiDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              ImmediateMultiDragGestureRecognizer
            >(
              () => ImmediateMultiDragGestureRecognizer(
                supportedDevices: precise,
              ),
              (recognizer) => recognizer.onStart = _start,
            ),
        DelayedMultiDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              DelayedMultiDragGestureRecognizer
            >(
              () => DelayedMultiDragGestureRecognizer(
                supportedDevices: {PointerDeviceKind.touch},
              ),
              (recognizer) => recognizer.onStart = _start,
            ),
      },
      child: child,
    );
  }
}

/// One drag of a tile, handed to the editor.
final class _TileDrag extends Drag {
  new({required this.onUpdate, required this.onEnd});

  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;

  @override
  void update(DragUpdateDetails details) => onUpdate(details);

  @override
  void end(DragEndDetails details) => onEnd();

  @override
  void cancel() => onEnd();
}
