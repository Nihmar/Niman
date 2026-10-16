/// The sheet behind the todo list's Filter control (T-TDM-03, #1003): the
/// due range as a single choice, then one `FilterChip` per token found in
/// the due-range-narrowed pool (counts, AND semantics).
///
/// The sheet owns no state: the selection lives in the [TodoListView] the
/// shell shares with the list, so a chip tapped here is selected at once
/// here and narrows the list behind it, and the token counts follow a due
/// range picked above them. A phone shows it as a bottom sheet, a pointer
/// as a pop-up under the control (see `showTodoFilter`).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_filter_labels.dart';

/// The filter sheet's content: due range and token chips.
final class TodoFilterSheet extends StatelessWidget {
  /// Creates the sheet over [view], counting the tokens of the open tasks
  /// of [controller] as of [today].
  const new({
    required this.controller,
    required this.view,
    required this.today,
    super.key,
  });

  /// The todo state, whose open tasks the token chips count.
  final TodoController controller;

  /// The filter being edited.
  final TodoListView view;

  /// The day the due ranges are read on.
  final DateTime today;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ListenableBuilder(
          listenable: Listenable.merge([view, controller]),
          builder: (context, _) {
            final filter = view.filter;
            final counts = tokenCountsFor(
              controller.snapshot?.todo ?? const [],
              filter.dueRange,
              today,
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.todoFilter, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(AppStrings.todoSortDue, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final range in TodoDueRange.values)
                      ChoiceChip(
                        key: Key('todo-due-${range.name}'),
                        label: Text(todoDueRangeLabel(range)),
                        selected: filter.dueRange == range,
                        onSelected: (_) {
                          _log.debug('todo filter due: ${range.name}');
                          view.setDueRange(range);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.todoHelpTokensTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (counts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                            view.toggleToken(entry.token);
                          },
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
