/// The library's root as a place to drop a row, and the tree scrolled
/// under a drag held at its edges (#580).
///
/// The root takes a drop on the tree's empty space below the rows. The tree
/// always ends on some of it (`NoteTree` pads its list's end), so even a
/// tree longer than its pane has a root to drop on: held at the bottom edge,
/// the drag scrolls there — as it scrolls to a folder out of sight.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/tree_drag.dart';

/// [child], the tree scrolled by [scroll], taking a drop into the root.
final class TreeRootDrop extends StatefulWidget {
  /// Makes [child] take a drop into the root by [onMove].
  const new({
    required this.onMove,
    required this.scroll,
    required this.child,
    super.key,
  });

  /// Runs a drop.
  final TreeMove onMove;

  /// The tree's scroll, run while a drag is held at an edge.
  final ScrollController scroll;

  /// The tree.
  final Widget child;

  @override
  State<TreeRootDrop> createState() => _TreeRootDropState();
}

final class _TreeRootDropState extends State<TreeRootDrop> {
  /// How deep into the tree an edge reaches.
  static const double _edge = 48;

  /// The most it scrolls a frame, the pointer at the very edge.
  static const double _speed = 16;

  /// Whether a row is on the move: only then do the edges scroll.
  bool _dragging = false;

  /// The scroll a frame, signed; zero away from the edges.
  double _step = 0;

  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Where the pointer last was. A move reaches this listener before the
  /// gesture it starts a drag for, so the drag's first position is the one
  /// read before it began.
  Offset? _pointer;

  void _follow(PointerMoveEvent event) {
    _pointer = event.position;
    if (_dragging) _scrollToward(event.position);
  }

  /// The pointer at [global] while a row is dragged: near an edge, the tree
  /// scrolls toward it, faster the closer it is.
  void _scrollToward(Offset global) {
    final box = context.findRenderObject()! as RenderBox;
    final y = box.globalToLocal(global).dy;
    final bottom = box.size.height;
    final depth = y < _edge
        ? y - _edge
        : y > bottom - _edge
        ? y - (bottom - _edge)
        : 0.0;
    _step = (depth / _edge).clamp(-1.0, 1.0) * _speed;
    if (_step == 0) return _stop();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final scroll = widget.scroll;
      if (!scroll.hasClients) return;
      final position = scroll.position;
      position.jumpTo(
        (position.pixels + _step).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _end() {
    _stop();
    _dragging = false;
  }

  @override
  Widget build(BuildContext context) => NotificationListener<TreeDragStarted>(
    onNotification: (_) {
      _dragging = true;
      if (_pointer case final pointer?) _scrollToward(pointer);
      return true;
    },
    child: Listener(
      onPointerMove: _follow,
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) => _end(),
      child: DragTarget<TreeDrag>(
        onWillAcceptWithDetails: (details) =>
            treeDropMoves(details.data.path, ''),
        onAcceptWithDetails: (details) {
          final drag = details.data;
          if (drag.moved) widget.onMove(drag.path, '');
        },
        builder: (context, candidates, _) => widget.child,
      ),
    ),
  );
}
