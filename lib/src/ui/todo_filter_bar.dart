/// The todo filter row (plan/todo-mockup.md T-TDM-03): a due-range
/// dropdown pill ("All dates"), a `Filter` pill opening the token/sort
/// sheet, and the right-aligned "N open"/"N done" count.
///
/// Dumb by design: the parent tab owns the filter state; the row only
/// reports due-range selection and the sheet request.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/todo_filter.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The compact filter row over the todo list.
final class TodoFilterBar extends StatelessWidget {
  /// Creates the row for [filter].
  const TodoFilterBar({
    required this.filter,
    required this.showDone,
    required this.count,
    required this.onDueRange,
    required this.onOpenFilter,
    super.key,
  });

  /// The current filter (the due range drives the pill's label).
  final TodoFilter filter;

  /// Whether the Done file is visible (the count's label).
  final bool showDone;

  /// The entries of the visible file, unfiltered (the count).
  final int count;

  /// Selects a due range (single-select).
  final ValueChanged<TodoDueRange> onDueRange;

  /// Opens the token + sort sheet.
  final VoidCallback onOpenFilter;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final countText = showDone
        ? '$count ${AppStrings.todoCountDone}'
        : '$count ${AppStrings.todoCountOpen}';
    final pill = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      foregroundColor: scheme.onSurface,
      textStyle: theme.textTheme.bodySmall,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _DueRangeMenu(range: filter.dueRange, onDueRange: onDueRange),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: const Key('todo-filter-button'),
            onPressed: () {
              _log.debug('todo filter sheet: open');
              onOpenFilter();
            },
            style: pill,
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text(AppStrings.todoFilter),
          ),
          const Spacer(),
          Text(
            key: const Key('todo-count'),
            countText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The due-range dropdown pill ("All dates ⌄"): an outlined button
/// opening the five-range popup menu (checked = the current range).
final class _DueRangeMenu extends StatelessWidget {
  const _DueRangeMenu({required this.range, required this.onDueRange});

  final TodoDueRange range;
  final ValueChanged<TodoDueRange> onDueRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return OutlinedButton(
      key: const Key('todo-due-menu'),
      onPressed: () => _openMenu(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: scheme.onSurface,
        textStyle: theme.textTheme.bodySmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_label(range)),
          const SizedBox(width: 4),
          Icon(
            Icons.expand_more,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Future<void> _openMenu(BuildContext context) async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(context).overlay!
        .context
        .findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final selected = await showMenu<TodoDueRange>(
      context: context,
      position: position,
      items: [
        for (final r in TodoDueRange.values)
          PopupMenuItem<TodoDueRange>(
            key: Key('todo-due-${r.name}'),
            value: r,
            child: Row(
              children: [
                Expanded(child: Text(_label(r))),
                if (r == range)
                  const Icon(
                    Icons.check,
                    size: 16,
                  ),
              ],
            ),
          ),
      ],
    );
    if (selected != null) {
      onDueRange(selected);
    }
  }

  String _label(TodoDueRange range) {
    return switch (range) {
      TodoDueRange.all => AppStrings.todoAllDates,
      TodoDueRange.overdue => AppStrings.todoDueOverdue,
      TodoDueRange.today => AppStrings.todoDueToday,
      TodoDueRange.next7 => AppStrings.todoDueNext7,
      TodoDueRange.noDate => AppStrings.todoDueNoDate,
    };
  }
}
