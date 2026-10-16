/// What a todo row says about when: the due label, the reminder chip and,
/// for a done row, the day it was completed (T-TDM-02). Shared by the phone
/// row's subtitle, the desktop row, the Home's tasks tile (#535) and the
/// search list.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/ui/strings.dart';

/// The due-date state driving the subtitle styling (overdue and today
/// stand out; upcoming is plain).
enum TodoDueState {
  /// The due date is before today.
  overdue,

  /// The due date is today.
  today,

  /// The due date is in the future.
  upcoming,
}

/// The due state of [due] relative to [today] (null when no due date).
TodoDueState? todoDueState(DateTime? due, DateTime today) {
  if (due == null) {
    return null;
  }
  final day = DateTime(due.year, due.month, due.day);
  final now = DateTime(today.year, today.month, today.day);
  if (day.isBefore(now)) {
    return TodoDueState.overdue;
  }
  return day == now ? TodoDueState.today : TodoDueState.upcoming;
}

/// What a row says about when: the due label and the reminder, or for a
/// [done] row when it was completed. Empty when the task has none.
List<Widget> todoRowTiming(
  TodoTask task,
  DateTime today, {
  required bool done,
}) {
  if (done) {
    final completed = task.completionDate;
    return [
      if (completed != null) TodoDoneLabel(date: completed, today: today),
    ];
  }
  return [
    if (task.due != null) TodoDueLabel(due: task.due!, today: today),
    if (task.reminder != null)
      _ReminderChip(stamp: task.reminder!, today: today),
  ];
}

/// The due part of the row subtitle (T-TDM-02, split on 2026-09-07):
/// the due state + short date, prefixed ("Overdue · 1 Sep", "Due
/// today", "Due 7 Sep") so it can never be read as the reminder's date.
/// The Home's tasks tile (#535) wears it too.
final class TodoDueLabel extends StatelessWidget {
  /// The label of a task due on [due], read on [today].
  const new({required this.due, required this.today, super.key});

  /// The task's due date.
  final DateTime due;

  /// The day it is read on.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final dueState = todoDueState(due, today)!;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (dueState) {
      TodoDueState.overdue => scheme.error,
      TodoDueState.today => scheme.tertiary,
      TodoDueState.upcoming => scheme.onSurfaceVariant,
    };
    final label = switch (dueState) {
      TodoDueState.overdue =>
        '${AppStrings.todoDueOverdue} · ${todoShortDate(due, today)}',
      TodoDueState.today => AppStrings.todoRowDueToday,
      TodoDueState.upcoming =>
        '${AppStrings.todoRowDue} ${todoShortDate(due, today)}',
    };
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: color);
    return Text(label, style: style);
  }
}

/// The completion part of a done row: `Done 7 Sep`, where an open row has
/// its due date.
final class TodoDoneLabel extends StatelessWidget {
  /// The label of a task completed on [date], read on [today].
  const new({required this.date, required this.today, super.key});

  /// The day the task was completed.
  final DateTime date;

  /// The day it is read on.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      key: const Key('todo-row-done-on'),
      AppStrings.todoDoneOn(todoShortDate(date, today)),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The reminder part of the row subtitle: the clock icon plus the
/// reminder's *own* date + time (2026-09-07 user feedback: the old
/// "due date + reminder time" mix read as one pair, and the borrowed
/// date survived "No date" filters unexplained). The clock + time is
/// the reminder marker; the old alarm icon is still gone.
final class _ReminderChip extends StatelessWidget {
  const new({required this.stamp, required this.today});

  final DateTime stamp;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text('${todoShortDate(stamp, today)} ${_timeOf(stamp)}', style: style),
      ],
    );
  }
}

/// The display form of [date] (`7 Sep`), appending the year when it
/// differs from [today]'s — the row's display formatting (the parser's
/// `formatTodoDate` stays the machine form).
String todoShortDate(DateTime date, DateTime today) {
  final base = '${date.day} ${AppStrings.monthNamesShort[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}

/// The `HH:MM` of [stamp] (the reminder time).
String _timeOf(DateTime stamp) {
  final h = stamp.hour.toString().padLeft(2, '0');
  final m = stamp.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
