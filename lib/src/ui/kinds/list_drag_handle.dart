import 'package:flutter/material.dart';
import 'package:niman/src/ui/strings.dart';

/// The grab handle of a list row (T-TK-09).
///
/// Dragging starts here and nowhere else: the rest of the row keeps its
/// tap-to-edit gesture, and a drag started anywhere else still scrolls
/// the list. The pan recognizer sits deeper than the list's scroll
/// recognizer, so it wins the gesture arena on the handle.
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
        onPanStart: (d) => onDragStart(d.globalPosition),
        onPanUpdate: (d) => onDragMove(d.globalPosition),
        onPanEnd: (_) => onDragEnd(),
        onPanCancel: onDragCancel,
        child: SizedBox(
          width: 36,
          height: 40,
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
    );
  }
}
