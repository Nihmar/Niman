/// A list that scrolls itself while a row is dragged near its top or bottom
/// edge (#1071), so a target that is off screen can be reached without
/// letting go.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/tree_drag.dart';

/// [child], a scrollable list moved by [controller], that scrolls while a
/// [TreeRowDrag] is held within [edge] of its top or bottom, faster the
/// closer to the edge; and that tells [onEnd] when the drag is over.
final class TreeDragScroll extends StatefulWidget {
  /// Makes [child] scroll [controller] under a drag.
  const new({
    required this.controller,
    required this.child,
    this.onEnd,
    super.key,
  });

  /// The list's scroll position.
  final ScrollController controller;

  /// Runs when a drag has ended, wherever it was let go.
  final VoidCallback? onEnd;

  /// The list.
  final Widget child;

  /// How close to an edge, in logical pixels, the scrolling begins.
  static const double edge = 48;

  /// The speed at the edge zone's inner border, in logical pixels per
  /// second.
  static const double slowest = 120;

  /// The speed at the list's very edge, in logical pixels per second.
  static const double fastest = 900;

  /// How often the list moves while a drag is held in the edge zone.
  static const Duration tick = Duration(milliseconds: 16);

  @override
  State<TreeDragScroll> createState() => _TreeDragScrollState();
}

final class _TreeDragScrollState extends State<TreeDragScroll> {
  Offset? _pointer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    TreeRowDrag.active.addListener(_onActive);
  }

  @override
  void dispose() {
    TreeRowDrag.active.removeListener(_onActive);
    _timer?.cancel();
    super.dispose();
  }

  void _onActive() {
    if (TreeRowDrag.active.value) return;
    _timer?.cancel();
    _timer = null;
    _pointer = null;
    widget.onEnd?.call();
  }

  /// The pointer moved: while a row is dragged, its place says whether the
  /// list scrolls.
  void _moved(PointerMoveEvent event) {
    if (!TreeRowDrag.active.value) return;
    _pointer = event.position;
    if (_velocity() == 0) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(TreeDragScroll.tick, (_) => _scrollStep());
  }

  /// Pixels per second, negative upwards, for the pointer's place: zero
  /// outside the edge zones, and outside the list's width — a drag headed
  /// for the editor is not asking for the list to move.
  double _velocity() {
    final at = _pointer;
    final box = context.findRenderObject();
    if (at == null || box is! RenderBox || !box.attached || !box.hasSize) {
      return 0;
    }
    final local = box.globalToLocal(at);
    if (local.dx < 0 || local.dx > box.size.width) return 0;
    const edge = TreeDragScroll.edge;
    final depth = local.dy < edge
        ? (edge - local.dy) / edge
        : local.dy > box.size.height - edge
        ? (box.size.height - edge - local.dy) / edge
        : 0.0;
    if (depth == 0) return 0;
    final speed =
        TreeDragScroll.slowest +
        (TreeDragScroll.fastest - TreeDragScroll.slowest) *
            depth.abs().clamp(0.0, 1.0);
    return depth > 0 ? -speed : speed;
  }

  void _scrollStep() {
    final controller = widget.controller;
    final velocity = _velocity();
    if (velocity == 0 || !controller.hasClients) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    final position = controller.position;
    final to =
        (position.pixels + velocity * TreeDragScroll.tick.inMilliseconds / 1000)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (to != position.pixels) controller.jumpTo(to);
  }

  @override
  Widget build(BuildContext context) =>
      Listener(onPointerMove: _moved, child: widget.child);
}
