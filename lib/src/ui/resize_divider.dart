import 'package:flutter/material.dart';

/// A draggable divider between two side-by-side panes: a 1 px line in a
/// wider grab strip, with the resize cursor (T-PP-21, #297).
///
/// It only reports the drag; the owner decides what moves, clamps it, and
/// persists it on [onDragEnd]. The tree's edge and the right dock's edge
/// are the same control, so they grab, look and move alike.
final class ResizeDivider extends StatelessWidget {
  /// A divider reporting each horizontal move to [onDrag].
  const new({required this.onDrag, required this.onDragEnd, super.key});

  /// The grab strip's width: what the divider takes out of the row.
  static const double width = 13;

  /// Called with each move's horizontal delta, rightwards positive.
  final ValueChanged<double> onDrag;

  /// Called when the drag lifts.
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
      onHorizontalDragEnd: (_) => onDragEnd(),
      child: const MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: SizedBox(
          width: width,
          child: Center(child: VerticalDivider(width: 1)),
        ),
      ),
    );
  }
}
