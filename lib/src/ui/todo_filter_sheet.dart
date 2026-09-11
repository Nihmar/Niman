/// The token + sort sheet behind the filter row's `Filter` pill
/// (T-TDM-03): one `FilterChip` per token found in
/// the due-range-narrowed pool (counts, AND semantics) and the sort
/// choice chips.
///
/// The selection is live: the sheet keeps its own copy of the token/sort
/// state (seeded from [TodoFilterSheet.filter]) and flips it on every
/// tap, so a picked chip is visibly selected without closing and
/// reopening the sheet (2026-09-07 user feedback). The parent tab owns
/// the filter; the sheet mirrors it and reports token toggles and sort
/// selections.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/ui/strings.dart';

/// The bottom sheet: token chips with counts + the sort choice chips.
final class TodoFilterSheet extends StatefulWidget {
  /// Creates the sheet for [filter] with ranked [counts].
  const new({
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

  @override
  State<TodoFilterSheet> createState() => _TodoFilterSheetState();
}

final class _TodoFilterSheetState extends State<TodoFilterSheet> {
  static const AppLogger _log = AppLogger(name: 'todo');

  /// The live selection: seeded from the filter the sheet opened with,
  /// flipped per chip tap — the list behind updates through the
  /// callbacks, the chips update through this state.
  late final Set<String> _tokens = {...widget.filter.tokens};
  late TodoSort _sort = widget.filter.sort;

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
            if (widget.counts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(AppStrings.todoNoTokens),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in widget.counts)
                    FilterChip(
                      key: Key('todo-token-${entry.token}'),
                      label: Text('${entry.token} (${entry.count})'),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      selected: _tokens.contains(entry.token),
                      onSelected: (_) {
                        _log.debug('todo token chip: ${entry.token}');
                        setState(() {
                          if (!_tokens.remove(entry.token)) {
                            _tokens.add(entry.token);
                          }
                        });
                        widget.onToggleToken(entry.token);
                      },
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text(AppStrings.todoSortTooltip, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sort in TodoSort.values)
                  ChoiceChip(
                    key: Key('todo-sort-${sort.name}'),
                    label: Text(_sortLabel(sort)),
                    selected: _sort == sort,
                    onSelected: (_) {
                      _log.debug('todo sort: ${sort.name}');
                      setState(() => _sort = sort);
                      widget.onSort(sort);
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
