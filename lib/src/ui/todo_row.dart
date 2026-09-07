/// One todo row (plan/todo-mockup.md T-TDM-02): a checkbox, the
/// task's display text, a one-line due/reminder subtitle and — when
/// the task carries a `#tag` — a left accent bar in the tag's color.
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
  const TodoRow({
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
    final row = ListTile(
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
      subtitle: _DueLine(task: task, today: now),
      onTap: () {
        _log.debug('todo row tap (edit): line ${entry.lineIndex}');
        onEdit();
      },
      onLongPress: () {
        _log.debug('todo row menu: line ${entry.lineIndex}');
        onShowMenu();
      },
    );
    final accent = task.hashtags.isEmpty
        ? null
        : tagColorFor(task.hashtags.first);
    if (accent == null) {
      return row;
    }
    // The mockup's left accent bar: 3 dp, full row height, the color of
    // the first `#tag`. IntrinsicHeight bounds the stretch against the
    // list view's unbounded height.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 3,
            child: ColoredBox(key: const Key('todo-accent'), color: accent),
          ),
          Expanded(child: row),
        ],
      ),
    );
  }
}

/// The one-line subtitle (T-TDM-02): the due state + short date, then —
/// when the task has a reminder — the clock icon and its time (the
/// clock + time is the reminder marker; the old alarm icon is gone).
final class _DueLine extends StatelessWidget {
  const _DueLine({required this.task, required this.today});

  final TodoTask task;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final dueState = todoDueState(task.due, today);
    final date = task.due ?? task.reminder;
    final reminder = task.reminder;
    if (dueState == null && reminder == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final color = switch (dueState) {
      TodoDueState.overdue => scheme.error,
      TodoDueState.today => scheme.tertiary,
      _ => scheme.onSurfaceVariant,
    };
    final label = switch (dueState) {
      TodoDueState.overdue => task.due == null
          ? AppStrings.todoDueOverdue
          : '${AppStrings.todoDueOverdue} · ${_shortDate(task.due!, today)}',
      TodoDueState.today => AppStrings.todoDueToday,
      _ => date == null ? null : _shortDate(date, today),
    };
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) Text(label, style: style),
        if (reminder != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.access_time, size: 14, color: color),
          const SizedBox(width: 2),
          Text(_timeOf(reminder), style: style),
        ],
      ],
    );
  }
}

const List<String> _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// The display form of [date] (`7 Sep`), appending the year when it
/// differs from [today]'s — the row's display formatting (the parser's
/// `formatTodoDate` stays the machine form).
String _shortDate(DateTime date, DateTime today) {
  final base = '${date.day} ${_monthNames[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}

/// The `HH:MM` of [stamp] (the reminder time).
String _timeOf(DateTime stamp) {
  final h = stamp.hour.toString().padLeft(2, '0');
  final m = stamp.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
