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
  const new({
    required this.onDrag,
    required this.onDragEnd,
    this.touch = false,
    super.key,
  });

  /// The gap the divider stands in: what the row leaves between the two
  /// islands, the same base as shows around them.
  static const double width = Island.gap;

  /// The strip that takes the pointer: the 8 px the divider had before the
  /// gaps narrowed to [Island.gap] (#749).
  static const double grabWidth = 8;

  /// How far the strip reaches over each island's edge.
  static const double overhang = (grabWidth - width) / 2;

  /// The strip for a thumb (#849): a finger does not find 8 px, so it is
  /// a thumb's target wide, still over the islands' edges either side.
  static const double touchGrabWidth = kMinInteractiveDimension;

  /// How far the thumb's strip reaches over each island's edge.
  static const double touchOverhang = (touchGrabWidth - width) / 2;

  /// The strip's width for a mouse or, with [touch], a thumb.
  static double grabFor({required bool touch}) =>
      touch ? touchGrabWidth : grabWidth;

  /// The strip's reach over each island's edge, likewise.
  static double overhangFor({required bool touch}) =>
      touch ? touchOverhang : overhang;

  /// Whether the strip is the thumb's (#849).
  final bool touch;

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
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        // The row's full height: with nothing drawn inside, a strip left
        // to size itself would be zero tall, and nothing to grab.
        child: SizedBox(
          width: grabFor(touch: touch),
          height: double.infinity,
        ),
      ),
    );
  }
}
