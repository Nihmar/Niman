import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The grab handle of a list row (T-TK-09, #719).
///
/// A drag with a pointer starts here: the pan recognizer sits deeper than
/// the list's scroll recognizer, so it wins the gesture arena on the
/// handle, and the rest of the row keeps its tap-to-edit gesture. A touch
/// picks the row up with a long press anywhere on it instead, which
/// `ListItemRow` wires; the handle stays the discoverable grip.
///
/// The row lays out a [gripWidth]×[gripHeight] slot for the grip, as it
/// always did, and lays this handle over its left end (`ListItemRow`
/// stacks it there): the grip is drawn in that slot, while the area that
/// takes the press is [targetWidth] wide and as tall as the row (#778). A
/// thumb gets the 48 dp it aims at without the checkbox and text moving
/// over for it.
class ListDragHandle extends StatelessWidget {
  /// Creates the handle.
  const new({
    required this.active,
    required this.onDragStart,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onDragCancel,
    super.key,
  });

  /// The side of the square a thumb aims at (#719): the smallest target
  /// a finger can be asked to hit, whatever the grip drawn in it is.
  static const double targetSize = 48;

  /// The width the grip takes in the row's layout.
  static const double gripWidth = 36;

  /// The height the grip takes in the row's layout.
  static const double gripHeight = 40;

  /// The width of the area that takes the press, in [context]'s theme.
  ///
  /// Where the theme pads tap targets (a touch platform) it is
  /// [targetSize], reaching over the left of the checkbox's own padded
  /// target — the 15 dp of it beside the box drawn, never the box. Where
  /// it shrink-wraps them (a desktop, a precise pointer) it is the grip's
  /// own slot, as the checkbox beside it is.
  static double targetWidth(BuildContext context) =>
      Theme.of(context).materialTapTargetSize == MaterialTapTargetSize.padded
      ? targetSize
      : gripWidth;

  /// Whether this row is the one being dragged (the handle is
  /// highlighted).
  final bool active;

  /// The drag started at the given global position.
  final ValueChanged<Offset> onDragStart;

  /// The drag moved to the given global position.
  final ValueChanged<Offset> onDragMove;

  /// The drag ended (drop).
  final VoidCallback onDragEnd;

  /// The drag was cancelled (no drop).
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppStrings.listDragHandleLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Swallows the tap so grabbing the handle never opens the row's
        // in-place edit.
        onTap: () {},
        // The drag starts where the pointer went down, and the slop it
        // crossed arrives as the first move: the list reads the pickup
        // where the press was, and the way to the edge as a move (#777).
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (d) => onDragStart(d.globalPosition),
        onPanUpdate: (d) => onDragMove(d.globalPosition),
        onPanEnd: (_) => onDragEnd(),
        onPanCancel: onDragCancel,
        child: SizedBox(
          width: targetWidth(context),
          child: Align(
            // Left-aligned: the grip sits in the slot the row laid out for
            // it, whatever the target reaches over.
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: gripWidth,
              height: gripHeight,
              child: Center(
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: active
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
