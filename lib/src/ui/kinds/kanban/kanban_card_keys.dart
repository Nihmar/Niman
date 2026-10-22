import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';

/// What a key does to the focused card (#1167).
final class KanbanCardKeys {
  /// Handlers for the keys of one card.
  const new({
    required this.onMove,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  /// `Alt` and an arrow: a step for the card.
  final ValueChanged<KanbanDirection> onMove;

  /// `Enter`: edit the title.
  final VoidCallback onEdit;

  /// `Delete`: remove the card.
  final VoidCallback onDelete;

  /// `Space`: flip the box.
  final VoidCallback onToggle;

  /// The result of [event] on [node]: handled when it was one of the card's
  /// keys. A plain arrow moves the focus to the neighbouring card, as it
  /// does in a grid.
  KeyEventResult handle(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final direction = _direction(key);
    if (direction != null) {
      if (HardwareKeyboard.instance.isAltPressed) {
        onMove(direction);
      } else {
        node.focusInDirection(_traversal(direction));
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      onEdit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      onDelete();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      onToggle();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static KanbanDirection? _direction(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft) return KanbanDirection.left;
    if (key == LogicalKeyboardKey.arrowRight) return KanbanDirection.right;
    if (key == LogicalKeyboardKey.arrowUp) return KanbanDirection.up;
    if (key == LogicalKeyboardKey.arrowDown) return KanbanDirection.down;
    return null;
  }

  static TraversalDirection _traversal(KanbanDirection direction) =>
      switch (direction) {
        KanbanDirection.left => TraversalDirection.left,
        KanbanDirection.right => TraversalDirection.right,
        KanbanDirection.up => TraversalDirection.up,
        KanbanDirection.down => TraversalDirection.down,
      };
}
