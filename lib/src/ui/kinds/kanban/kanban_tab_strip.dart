import 'package:flutter/material.dart';
import 'package:niman/src/kanban/kanban_column.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_palette.dart';
import 'package:niman/src/ui/strings.dart';

/// The strip along the top of the phone's board (#1168): one tab per column
/// with its name and its card count, the selected one underlined; a ⋮ for
/// the selected column (rename, delete) and a + that adds a column.
///
/// The ⋮ stays in its place on a board with no column and is disabled
/// there; the + is always live, so an empty board is never a dead end.
final class KanbanTabStrip extends StatelessWidget {
  /// The strip over [columns], driven by [controller] (null without any).
  const new({
    required this.columns,
    required this.controller,
    required this.onRename,
    required this.onDeleteColumn,
    required this.onAddColumn,
    super.key,
  });

  /// The board's columns.
  final List<KanbanColumn> columns;

  /// Selects the column; null when the board has none.
  final TabController? controller;

  /// Renames the selected column.
  final VoidCallback onRename;

  /// Deletes the selected column.
  final VoidCallback onDeleteColumn;

  /// Asks for the name of a column to add.
  final VoidCallback onAddColumn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = KanbanPalette.of(context);
    final scheme = theme.colorScheme;
    final tabs = controller;
    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          Expanded(
            child: tabs == null
                ? const SizedBox(height: 48)
                : TabBar(
                    key: const Key('kanban-tabs'),
                    controller: tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      for (var i = 0; i < columns.length; i++)
                        Tab(
                          key: Key('kanban-tab-$i'),
                          height: 48,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    columns[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${columns[i].cards.length}',
                                  key: Key('kanban-tab-count-$i'),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          PopupMenuButton<VoidCallback>(
            key: const Key('kanban-column-menu'),
            enabled: tabs != null,
            tooltip: AppStrings.kanbanColumnActions,
            icon: const Icon(Icons.more_vert),
            onSelected: (run) => run(),
            itemBuilder: (context) => [
              PopupMenuItem<VoidCallback>(
                key: const Key('kanban-column-rename'),
                value: onRename,
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(AppStrings.actionRename),
                  ],
                ),
              ),
              PopupMenuItem<VoidCallback>(
                key: const Key('kanban-column-delete'),
                value: onDeleteColumn,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: scheme.error),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.kanbanDeleteColumn,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            key: const Key('kanban-add-column'),
            tooltip: AppStrings.kanbanAddColumn,
            icon: const Icon(Icons.add),
            onPressed: onAddColumn,
          ),
        ],
      ),
    );
  }
}
