/// The todo filter row (T-TDM-03): a due-range
/// dropdown pill ("All dates"), a `Filter` pill opening the token/sort
/// sheet, and the right-aligned "N open"/"N done" count.
///
/// Dumb by design: the parent tab owns the filter state; the row only
/// reports due-range selection and the sheet request.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/ui/strings.dart';

/// The compact filter row over the todo list.
final class TodoFilterBar extends StatelessWidget {
  /// Creates the row for [filter].
  const new({
    required this.filter,
    required this.showDone,
    required this.count,
    required this.onDueRange,
    required this.onOpenFilter,
    this.leading,
    this.trailing,
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

  /// Optional control before the due-range pill: the desktop folds its
  /// Open/Done switch in here (T-PP-22).
  final Widget? leading;

  /// Optional controls after the count: the desktop's Add task and help.
  final Widget? trailing;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final countText = showDone
        ? '$count ${AppStrings.todoCountDone}'
        : '$count ${AppStrings.todoCountOpen}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (leading case final lead?) ...[lead, const SizedBox(width: 12)],
          // Flexible with an ellipsized label: two icon-label-chevron
          // pills plus the count must fit a 360 dp row in every
          // language, so the pills shrink before anything clips.
          Flexible(
            child: _PillButton(
              key: const Key('todo-due-menu'),
              icon: Icons.calendar_today_outlined,
              label: _DueRangeMenu.label(filter.dueRange),
              onPressed: (buttonContext) => _DueRangeMenu.open(
                buttonContext,
                filter.dueRange,
                onDueRange,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _PillButton(
              key: const Key('todo-filter-button'),
              icon: Icons.filter_alt_outlined,
              label: AppStrings.todoFilter,
              onPressed: (_) {
                _log.debug('todo filter sheet: open');
                onOpenFilter();
              },
            ),
          ),
          const Spacer(),
          // On the pills' line: the same text style, centered in the
          // row, so the count shares the chips' baseline instead of
          // sitting on its own (issue #131).
          Text(
            key: const Key('todo-count'),
            countText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (trailing case final tail?) ...[const SizedBox(width: 8), tail],
        ],
      ),
    );
  }
}

/// One pill of the filter row (issue #131): a leading icon, a label
/// and a trailing chevron, in the same shape for the due range and the
/// filter — the row used to mix a chevron pill with an icon pill.
final class _PillButton extends StatelessWidget {
  /// Creates the pill with [icon], [label] and [onPressed].
  const new({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// The pill's leading icon.
  final IconData icon;

  /// The pill's label.
  final String label;

  /// Opens whatever the pill picks, with the pill's own context (the
  /// due-range menu positions itself under the pill).
  final void Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return OutlinedButton(
      onPressed: () => onPressed(context),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        foregroundColor: scheme.onSurface,
        textStyle: theme.textTheme.bodySmall,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, size: 16, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// The due-range popup behind the date pill: the five ranges, checked
/// at the current one, opening under the pill.
final class _DueRangeMenu {
  /// Opens the five-range menu under the pill.
  static Future<void> open(
    BuildContext context,
    TodoDueRange range,
    ValueChanged<TodoDueRange> onDueRange,
  ) async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
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
                Expanded(child: Text(label(r))),
                if (r == range) const Icon(Icons.check, size: 16),
              ],
            ),
          ),
      ],
    );
    if (selected != null) {
      onDueRange(selected);
    }
  }

  static String label(TodoDueRange range) {
    return switch (range) {
      TodoDueRange.all => AppStrings.todoAllDates,
      TodoDueRange.overdue => AppStrings.todoDueOverdue,
      TodoDueRange.today => AppStrings.todoDueToday,
      TodoDueRange.next7 => AppStrings.todoDueNext7,
      TodoDueRange.noDate => AppStrings.todoDueNoDate,
    };
  }
}
