/// The token + sort sheet behind the filter row's `Filter` pill
/// (plan/todo-mockup.md T-TDM-03): one `FilterChip` per token found in
/// the due-range-narrowed pool (counts, AND semantics) and the sort
/// choice chips.
///
/// Dumb by design: the parent tab owns the filter state; the sheet only
/// reports token toggles and sort selections.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/todo_filter.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The bottom sheet: token chips with counts + the sort choice chips.
final class TodoFilterSheet extends StatelessWidget {
  /// Creates the sheet for [filter] with ranked [counts].
  const TodoFilterSheet({
    required this.filter,
    required this.counts,
    required this.onToggleToken,
    required this.onSort,
    super.key,
  });

  /// The current filter (the selected token/sort states).
  final TodoFilter filter;

  /// Ranked `(token, task count)` chips.
  final List<({String token, int count})> counts;

  /// Toggles a token chip (chips AND together).
  final ValueChanged<String> onToggleToken;

  /// Selects the sort key.
  final ValueChanged<TodoSort> onSort;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.todoFilter, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (counts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(AppStrings.todoNoTokens),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in counts)
                    FilterChip(
                      key: Key('todo-token-${entry.token}'),
                      label: Text('${entry.token} (${entry.count})'),
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      selected: filter.tokens.contains(entry.token),
                      onSelected: (_) {
                        _log.debug('todo token chip: ${entry.token}');
                        onToggleToken(entry.token);
                      },
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              AppStrings.todoSortTooltip,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sort in TodoSort.values)
                  ChoiceChip(
                    key: Key('todo-sort-${sort.name}'),
                    label: Text(_sortLabel(sort)),
                    selected: filter.sort == sort,
                    onSelected: (_) {
                      _log.debug('todo sort: ${sort.name}');
                      onSort(sort);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The chip label of [sort].
  String _sortLabel(TodoSort sort) {
    return switch (sort) {
      TodoSort.due => AppStrings.todoSortDue,
      TodoSort.priority => AppStrings.todoSortPriority,
      TodoSort.creation => AppStrings.todoSortCreation,
    };
  }
}
