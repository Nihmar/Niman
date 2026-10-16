import 'package:flutter/material.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_filter_labels.dart';

/// The active filters, as a strip under the phone's app bar or the
/// desktop's toolbar (#1003): one removable chip per filter (the due range
/// when it is not All, each token), how many of the open tasks the filter
/// leaves (`N of M`), and `Clear`.
///
/// With no filter active it is not there at all: the list starts right
/// under the bar.
final class TodoFilterStrip extends StatelessWidget {
  /// Creates the strip of [view]'s filter; [shown] of [total] open tasks
  /// are left.
  const new({
    required this.view,
    required this.shown,
    required this.total,
    super.key,
  });

  /// The filter shown and edited.
  final TodoListView view;

  /// How many open tasks the filter leaves.
  final int shown;

  /// How many open tasks there are.
  final int total;

  @override
  Widget build(BuildContext context) {
    if (!view.hasActiveFilters) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final filter = view.filter;
    return Padding(
      key: const Key('todo-filter-strip'),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (filter.dueRange != TodoDueRange.all)
                  InputChip(
                    key: const Key('todo-strip-due'),
                    label: Text(todoDueRangeLabel(filter.dueRange)),
                    onDeleted: () => view.setDueRange(TodoDueRange.all),
                  ),
                for (final token in filter.tokens)
                  InputChip(
                    key: Key('todo-strip-token-$token'),
                    label: Text(token),
                    onDeleted: () => view.toggleToken(token),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.todoFilteredCount(shown, total),
            key: const Key('todo-filtered-count'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            key: const Key('todo-clear-filters'),
            onPressed: view.clearFilters,
            child: Text(AppStrings.todoClearFilters),
          ),
        ],
      ),
    );
  }
}
