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
/// The target is the 48 dp a thumb aims at (#719) while the grip drawn
/// stays the 20 px icon in its 36×40 slot at the row's left, left-aligned
/// in the target: the row looks as it did.
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

  /// The width the grip itself takes in the row: what was here before
  /// the target grew around it.
  static const double gripWidth = 36;

  /// The height the grip itself takes in the row.
  static const double gripHeight = 40;

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
        child: SizedBox.square(
          dimension: targetSize,
          child: Align(
            // Left-aligned: growing the target around the grip must not
            // move the grip, which is what the row's eye lands on.
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
