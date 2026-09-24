/// One todo row (T-TDM-02): a checkbox, the
/// task's display text, and a subtitle with the due/reminder line plus
/// a chip per `+project` / `@context` / `#tag` token the task carries
/// (2026-09-07 user feedback: the tokens were invisible in the row).
/// Each kind wears its own color ([tokenColor]).
///
/// Dumb by design: the parent owns the controller, the edit dialog and
/// the long-press menu — the row only reports toggle, edit and menu
/// callbacks. A right-click opens the menu too: a mouse has no long
/// press worth the name.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/tokens.dart';

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

  /// Opens the long-press (or right-click) bottom sheet.
  final VoidCallback onShowMenu;

  /// The wall-clock day for the due state (defaults to now).
  final DateTime? today;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final now = today ?? DateTime.now();
    final display = taskDisplayText(task.description);
    return GestureDetector(
      onSecondaryTap: () {
        _log.debug('todo row menu (right-click): line ${entry.lineIndex}');
        onShowMenu();
      },
      child: _tile(task, display, now),
    );
  }

  /// The tile itself: checkbox, text, subtitle, tap and long-press.
  Widget _tile(TodoTask task, String display, DateTime now) {
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

/// One token chip of the row subtitle: the token's kind color
/// (`+project` the accent, `@context` the syntax tag teal, `#tag` the
/// tertiary) behind the token text with its sigil, so what `todo.txt`
/// separates on purpose looks apart at a glance (issue #131).
final class _TokenChip extends StatelessWidget {
  const new({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tokenColor(context, token);
    return Container(
      key: Key('todo-row-token-$token'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        token,
        style: theme.textTheme.bodySmall?.copyWith(color: color),
      ),
    );
  }
}

/// The token's color by kind, not by name: projects wear the accent,
/// contexts the syntax tag teal, tags the tertiary.
Color tokenColor(BuildContext context, String token) {
  final scheme = Theme.of(context).colorScheme;
  if (token.startsWith('+')) return scheme.primary;
  if (token.startsWith('@')) return SyntaxColors.of(context).tag;
  return scheme.tertiary;
}

/// The display form of [date] (`7 Sep`), appending the year when it
/// differs from [today]'s — the row's display formatting (the parser's
/// `formatTodoDate` stays the machine form).
String _shortDate(DateTime date, DateTime today) {
  final base = '${date.day} ${AppStrings.monthNamesShort[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}

/// The `HH:MM` of [stamp] (the reminder time).
String _timeOf(DateTime stamp) {
  final h = stamp.hour.toString().padLeft(2, '0');
  final m = stamp.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
