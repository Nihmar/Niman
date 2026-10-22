import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// The ⋮ menu of a card (#1167): the moves a drag makes, without a drag, and
/// delete. A move with nowhere to go is disabled, not removed, so the entries
/// keep their places.
///
/// The card also opens it at the pointer, from a right click: [controller]
/// is the card's handle on it.
final class KanbanCardMenu extends StatelessWidget {
  /// A menu whose entries call [onMove] and [onDelete]; [canMove] says which
  /// moves have somewhere to go.
  const new({
    required this.controller,
    required this.canMove,
    required this.onMove,
    required this.onDelete,
    super.key,
  });

  /// Opens and closes the menu.
  final MenuController controller;

  /// Whether the card has a place one step in the given direction.
  final bool Function(KanbanDirection direction) canMove;

  /// Moves the card one step.
  final ValueChanged<KanbanDirection> onMove;

  /// Deletes the card.
  final VoidCallback onDelete;

  /// The label of a move.
  static String label(KanbanDirection direction) => switch (direction) {
    KanbanDirection.left => AppStrings.kanbanMoveLeft,
    KanbanDirection.right => AppStrings.kanbanMoveRight,
    KanbanDirection.up => AppStrings.kanbanMoveUp,
    KanbanDirection.down => AppStrings.kanbanMoveDown,
  };

  static IconData _icon(KanbanDirection direction) => switch (direction) {
    KanbanDirection.left => Icons.arrow_back,
    KanbanDirection.right => Icons.arrow_forward,
    KanbanDirection.up => Icons.arrow_upward,
    KanbanDirection.down => Icons.arrow_downward,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      controller: controller,
      menuChildren: [
        for (final direction in KanbanDirection.values)
          MenuItemButton(
            key: Key('kanban-move-${direction.name}'),
            leadingIcon: Icon(_icon(direction), size: 20),
            onPressed: canMove(direction) ? () => onMove(direction) : null,
            child: Text(label(direction)),
          ),
        const Divider(height: 1),
        MenuItemButton(
          key: const Key('kanban-card-delete'),
          leadingIcon: Icon(
            Icons.delete_outline,
            size: 20,
            color: scheme.error,
          ),
          onPressed: onDelete,
          child: Text(
            AppStrings.actionDelete,
            style: TextStyle(color: scheme.error),
          ),
        ),
      ],
      builder: (context, menu, _) => IconButton(
        key: const Key('kanban-card-menu'),
        tooltip: AppStrings.kanbanCardActions,
        icon: Icon(Icons.more_vert, size: 18, color: scheme.onSurfaceVariant),
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}
