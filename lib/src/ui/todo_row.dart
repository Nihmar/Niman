/// One todo row (plan/todo-mockup.md T-TDM-02): a checkbox, the
/// task's display text, and a subtitle with the due/reminder line plus
/// a chip per `+project` / `@context` / `#tag` token the task carries
/// (2026-09-07 user feedback: the tokens were invisible in the row; the
/// old left accent bar — the first `#tag`'s color — is gone, its color
/// now dots the chips).
///
/// Dumb by design: the parent owns the controller, the edit dialog and
/// the long-press menu — the row only reports toggle, edit and menu
/// callbacks.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/tag_color.dart';
import 'package:flutter/material.dart';

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

/// One row of the todo list.
final class TodoRow extends StatelessWidget {
  /// Creates a row for [entry].
  ///
  /// [today] is the wall-clock day for the due state and the short date
  /// (injected in widget tests; defaults to now). [onToggle] flips the
  /// checkbox, [onEdit] opens the edit dialog, [onShowMenu] opens the
  /// long-press bottom sheet.
  const new({
    required this.entry,
    required this.onToggle,
    required this.onEdit,
    required this.onShowMenu,
    this.today,
    super.key,
  });

  /// The task with its file line index.
  final TodoEntry entry;

  /// Flips the checkbox.
  final ValueChanged<bool> onToggle;

  /// Opens the edit dialog.
  final VoidCallback onEdit;

  /// Opens the long-press bottom sheet.
  final VoidCallback onShowMenu;

  /// The wall-clock day for the due state (defaults to now).
  final DateTime? today;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final now = today ?? DateTime.now();
    final display = taskDisplayText(task.description);
    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (value) {
          _log.debug(
            'todo row toggle: line ${entry.lineIndex} -> ${value == true}',
          );
          onToggle(value ?? false);
        },
      ),
      title: Text(
        display.isEmpty ? task.raw : display,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: _RowSubtitle(task: task, today: now),
      onTap: () {
        _log.debug('todo row tap (edit): line ${entry.lineIndex}');
        onEdit();
      },
      onLongPress: () {
        _log.debug('todo row menu: line ${entry.lineIndex}');
        onShowMenu();
      },
    );
  }
}

/// The row subtitle: the due/reminder line, then — when the task
/// carries `+project` / `@context` / `#tag` tokens — a chip per token,
/// so the row shows what it is filed under (2026-09-07 user feedback).
final class _RowSubtitle extends StatelessWidget {
  const new({required this.task, required this.today});

  final TodoTask task;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final tokens = <String>[
      for (final p in task.projects) '+$p',
      for (final c in task.contexts) '@$c',
      for (final h in task.hashtags) '#$h',
    ];
    if (task.due == null && task.reminder == null && tokens.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (task.due != null) _DueChip(due: task.due!, today: today),
        if (task.reminder != null)
          _ReminderChip(stamp: task.reminder!, today: today),
        for (final token in tokens) _TokenChip(token: token),
      ],
    );
  }
}

/// The due part of the row subtitle (T-TDM-02, split on 2026-09-07):
/// the due state + short date, prefixed ("Overdue · 1 Sep", "Due
/// today", "Due 7 Sep") so it can never be read as the reminder's date.
final class _DueChip extends StatelessWidget {
  const new({required this.due, required this.today});

  final DateTime due;
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
        '${AppStrings.todoDueOverdue} · ${_shortDate(due, today)}',
      TodoDueState.today => AppStrings.todoRowDueToday,
      TodoDueState.upcoming =>
        '${AppStrings.todoRowDue} ${_shortDate(due, today)}',
    };
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: color);
    return Text(label, style: style);
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
        Text('${_shortDate(stamp, today)} ${_timeOf(stamp)}', style: style),
      ],
    );
  }
}

/// One token chip of the row subtitle: a dot in the token's color (the
/// same `tagColorFor` the old accent bar used) plus the token text with
/// its sigil (`+p`, `@c`, `#t`), so the color still marks the token
/// without a bar nobody could name.
final class _TokenChip extends StatelessWidget {
  const new({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      key: Key('todo-row-token-$token'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tagColorFor(token),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            token,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The display form of [date] (`7 Sep`), appending the year when it
/// differs from [today]'s — the row's display formatting (the parser's
/// `formatTodoDate` stays the machine form).
String _shortDate(DateTime date, DateTime today) {
  final base = '${date.day} ${AppStrings.monthNames[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}

/// The `HH:MM` of [stamp] (the reminder time).
String _timeOf(DateTime stamp) {
  final h = stamp.hour.toString().padLeft(2, '0');
  final m = stamp.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
