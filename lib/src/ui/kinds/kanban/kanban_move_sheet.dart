import 'package:flutter/material.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_menu.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_places.dart';
import 'package:niman/src/ui/strings.dart';

/// What the card sheet of the phone's board was closed with (#1168).
sealed class KanbanSheetChoice {
  const new();
}

/// **Move to…** a column: the end of it.
final class KanbanMoveToColumn extends KanbanSheetChoice {
  /// A move to the end of column [column].
  const new(this.column);

  /// The destination column's index.
  final int column;
}

/// **Move up** or **Move down**: one place within the card's column.
final class KanbanMoveWithin extends KanbanSheetChoice {
  /// A move one step [direction] ([KanbanDirection.up] or `down`).
  const new(this.direction);

  /// Which way.
  final KanbanDirection direction;
}

/// **Edit card**.
final class KanbanEditChoice extends KanbanSheetChoice {
  /// The card's title is to be edited.
  const new();
}

/// **Delete**.
final class KanbanDeleteChoice extends KanbanSheetChoice {
  /// The card is to go.
  const new();
}

/// The bottom sheet a long press on a card of the phone's board opens
/// (#1168): titled with the card, **Move to…** every other column, **Move
/// up** and **Move down**, then **Edit card** and **Delete**.
///
/// A move with nowhere to go is disabled, not removed, so the entries keep
/// their places. There is no drag on a phone: this is how a card changes
/// column.
Future<KanbanSheetChoice?> showKanbanMoveSheet(
  BuildContext context, {
  required String cardTitle,
  required List<String> columnNames,
  required int column,
  required bool canMoveUp,
  required bool canMoveDown,
}) => showModalBottomSheet<KanbanSheetChoice>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _KanbanMoveSheet(
    cardTitle: cardTitle,
    columnNames: columnNames,
    column: column,
    canMoveUp: canMoveUp,
    canMoveDown: canMoveDown,
  ),
);

final class _KanbanMoveSheet extends StatelessWidget {
  const new({
    required this.cardTitle,
    required this.columnNames,
    required this.column,
    required this.canMoveUp,
    required this.canMoveDown,
  });

  final String cardTitle;
  final List<String> columnNames;
  final int column;
  final bool canMoveUp;
  final bool canMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void close(KanbanSheetChoice choice) => Navigator.pop(context, choice);
    final others = [
      for (var i = 0; i < columnNames.length; i++)
        if (i != column) i,
    ];
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                cardTitle,
                key: const Key('kanban-sheet-title'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (others.isEmpty)
              ListTile(
                key: const Key('kanban-move-to'),
                enabled: false,
                leading: const Icon(Icons.arrow_forward),
                title: Text(AppStrings.kanbanMoveTo),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  AppStrings.kanbanMoveTo,
                  key: const Key('kanban-move-to'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final i in others)
                ListTile(
                  key: Key('kanban-move-to-$i'),
                  leading: const Icon(Icons.arrow_forward),
                  title: Text(columnNames[i]),
                  onTap: () => close(KanbanMoveToColumn(i)),
                ),
            ],
            const Divider(height: 1),
            for (final direction in const [
              KanbanDirection.up,
              KanbanDirection.down,
            ])
              ListTile(
                key: Key('kanban-move-${direction.name}'),
                leading: Icon(
                  direction == KanbanDirection.up
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                title: Text(KanbanCardMenu.label(direction)),
                enabled: direction == KanbanDirection.up
                    ? canMoveUp
                    : canMoveDown,
                onTap: () => close(KanbanMoveWithin(direction)),
              ),
            const Divider(height: 1),
            ListTile(
              key: const Key('kanban-card-edit'),
              leading: const Icon(Icons.edit_outlined),
              title: Text(AppStrings.kanbanEditCard),
              onTap: () => close(const KanbanEditChoice()),
            ),
            ListTile(
              key: const Key('kanban-card-delete'),
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                AppStrings.actionDelete,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () => close(const KanbanDeleteChoice()),
            ),
          ],
        ),
      ),
    );
  }
}
