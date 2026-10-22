import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';

/// Makes a card draggable (#1167): picked up at once with a mouse, a
/// trackpad or a pen, and with a long press on a touch platform, where an
/// immediate drag would take the press a scroll needs.
///
/// It only carries the gesture and the lifted copy under the pointer. Where
/// the card lands is read by the board from the pointer's position
/// ([onUpdate]), not from drop targets: the columns scroll under a held
/// pointer, which targets never followed.
final class KanbanCardDraggable extends StatelessWidget {
  /// Wraps [child], the card [data], dragged as [feedback].
  const new({
    required this.data,
    required this.child,
    required this.feedback,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    super.key,
  });

  /// The card.
  final CardPos data;

  /// The card at rest.
  final Widget child;

  /// The lifted copy that follows the pointer, as wide as the card.
  final Widget Function(double width) feedback;

  /// The drag began.
  final VoidCallback onStart;

  /// The pointer moved to the given global position.
  final ValueChanged<Offset> onUpdate;

  /// The drag ended, dropped or not.
  final VoidCallback onEnd;

  /// Whether the platform's pointer is a finger.
  static bool get _touch => switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final lifted = feedback(constraints.maxWidth);
        final rest = Opacity(opacity: 0.35, child: child);
        void started() => onStart();
        void update(DragUpdateDetails details) =>
            onUpdate(details.globalPosition);
        void ended(DraggableDetails _) => onEnd();
        if (_touch) {
          return LongPressDraggable<CardPos>(
            data: data,
            feedback: lifted,
            childWhenDragging: rest,
            onDragStarted: started,
            onDragUpdate: update,
            onDragEnd: ended,
            child: child,
          );
        }
        return _PointerDraggable(
          data: data,
          feedback: lifted,
          childWhenDragging: rest,
          onDragStarted: started,
          onDragUpdate: update,
          onDragEnd: ended,
          child: child,
        );
      },
    );
  }
}

/// A [Draggable] that a finger does not start: on a desktop a touch screen
/// scrolls the column, and the move menu and the keys are its way to move a
/// card.
final class _PointerDraggable extends Draggable<CardPos> {
  const new({
    required super.data,
    required super.feedback,
    required super.childWhenDragging,
    required super.onDragStarted,
    required super.onDragUpdate,
    required super.onDragEnd,
    required super.child,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) {
    return ImmediateMultiDragGestureRecognizer(
      supportedDevices: const {
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      },
      allowedButtonsFilter: allowedButtonsFilter,
    )..onStart = onStart;
  }
}
