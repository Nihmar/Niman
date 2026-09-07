/// The todo filter chip bar: sort control, due-range chips and one
/// filter chip per project/context/tag (plan/todo-tab.md T-TD-05).
///
/// Dumb by design: the parent tab owns the filter state; the bar only
/// reports due-range, token and sort selections.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/todo_filter.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The horizontal chip bar over the todo list.
final class TodoFilterBar extends StatelessWidget {
  /// Creates the bar for [filter] with ranked [counts].
  const TodoFilterBar({
    required this.filter,
    required this.counts,
    required this.onDueRange,
    required this.onToggleToken,
    required this.onSort,
    super.key,
  });

  /// The current filter (selected states).
  final TodoFilter filter;

  /// Ranked `(token, task count)` chips.
  final List<({String token, int count})> counts;

  /// Selects a due range (single-select).
  final ValueChanged<TodoDueRange> onDueRange;

  /// Toggles a token chip (chips AND together).
  final ValueChanged<String> onToggleToken;

  /// Selects the sort key.
  final ValueChanged<TodoSort> onSort;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('todo-filter-scroll'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PopupMenuButton<TodoSort>(
            key: const Key('todo-sort-button'),
            icon: const Icon(Icons.sort),
            tooltip: AppStrings.todoSortTooltip,
            onSelected: (sort) {
              _log.debug('todo sort: ${sort.name}');
              onSort(sort);
            },
            itemBuilder: (context) => [
              for (final sort in TodoSort.values)
                CheckedPopupMenuItem<TodoSort>(
                  key: Key('todo-sort-${sort.name}'),
                  value: sort,
                  checked: sort == filter.sort,
                  child: Text(_sortLabel(sort)),
                ),
            ],
          ),
          for (final range in TodoDueRange.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: ChoiceChip(
                key: Key('todo-due-${range.name}'),
                label: Text(_dueLabel(range)),
                selected: filter.dueRange == range,
                onSelected: (_) {
                  _log.debug('todo due range: ${range.name}');
                  onDueRange(range);
                },
              ),
            ),
          const SizedBox(width: 4),
          for (final entry in counts)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FilterChip(
                key: Key('todo-token-${entry.token}'),
                label: Text('${entry.token} (${entry.count})'),
                selected: filter.tokens.contains(entry.token),
                onSelected: (_) {
                  _log.debug('todo token chip: ${entry.token}');
                  onToggleToken(entry.token);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// The chip label of [range].
  String _dueLabel(TodoDueRange range) {
    return switch (range) {
      TodoDueRange.all => AppStrings.todoDueAll,
      TodoDueRange.overdue => AppStrings.todoDueOverdue,
      TodoDueRange.today => AppStrings.todoDueToday,
      TodoDueRange.next7 => AppStrings.todoDueNext7,
      TodoDueRange.noDate => AppStrings.todoDueNoDate,
    };
  }

  /// The menu label of [sort].
  String _sortLabel(TodoSort sort) {
    return switch (sort) {
      TodoSort.due => AppStrings.todoSortDue,
      TodoSort.priority => AppStrings.todoSortPriority,
      TodoSort.creation => AppStrings.todoSortCreation,
    };
  }
}
