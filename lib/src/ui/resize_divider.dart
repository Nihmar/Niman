import 'package:flutter/material.dart';
import 'package:niman/src/ui/island.dart';

/// A draggable divider between two side-by-side islands: the strip of
/// base between them, with the resize cursor (T-PP-21, #297).
///
/// It draws nothing of its own: the two islands' edges are the line. It
/// only reports the drag; the owner decides what moves, clamps it, and
/// persists it on [onDragEnd]. The tree's edge and the right dock's edge
/// are the same control, so they grab, look and move alike.
///
/// The gap is [width], but the strip that takes the pointer is
/// [grabWidth], reaching [overhang] over each island's edge (#786): a
/// 4 px target is hard to find with a mouse. The owner lays it over the
/// row, not in it — a widget in the row is hit only inside its own gap.
final class ResizeDivider extends StatelessWidget {
  /// A divider reporting each horizontal move to [onDrag].
  const new({required this.onDrag, required this.onDragEnd, super.key});

  /// The gap the divider stands in: what the row leaves between the two
  /// islands, the same base as shows around them.
  static const double width = Island.gap;

  /// The strip that takes the pointer: the 8 px the divider had before the
  /// gaps narrowed to [Island.gap] (#749).
  static const double grabWidth = 8;

  /// How far the strip reaches over each island's edge.
  static const double overhang = (grabWidth - width) / 2;

  /// Called with each move's horizontal delta, rightwards positive.
  final ValueChanged<double> onDrag;

  /// Called when the drag lifts.
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
      onHorizontalDragEnd: (_) => onDragEnd(),
      child: const MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        // The row's full height: with nothing drawn inside, a strip left
        // to size itself would be zero tall, and nothing to grab.
        child: SizedBox(width: grabWidth, height: double.infinity),
      ),
    );
  }
}
