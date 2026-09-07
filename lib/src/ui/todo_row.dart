/// One todo row: checkbox, description, badges and token chips
/// (plan/todo-tab.md T-TD-04).
///
/// Dumb by design: the parent owns the controller, the edit dialog and
/// the long-press menu — the row only reports toggle, edit and menu
/// callbacks.
library;

import 'package:copist/src/core/logging.dart';
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';

/// The due-date state driving the badge styling (overdue and today
/// stand out; upcoming is plain).
enum TodoDueState {
  /// The due date is before today.
  overdue,

  /// The due date is today.
  today,

  /// The due date is in the future.
  upcoming,
}

/// The badge state of [due] relative to [today] (null when no due date).
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
  /// [today] is the wall-clock day for the due badge (injected in
  /// widget tests; defaults to now). [onToggle] flips the checkbox,
  /// [onEdit] opens the edit dialog, [onShowMenu] opens the long-press
  /// bottom sheet.
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

  /// The wall-clock day for the due badge (defaults to now).
  final DateTime? today;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final theme = Theme.of(context);
    final now = today ?? DateTime.now();
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
        task.description.isEmpty ? task.raw : task.description,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: _Badges(task: task, today: now, theme: theme),
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

/// Priority badge, due badge, token chips and the reminder icon.
final class _Badges extends StatelessWidget {
  const _Badges({
    required this.task,
    required this.today,
    required this.theme,
  });

  final TodoTask task;
  final DateTime today;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dueState = todoDueState(task.due, today);
    final chips = <Widget>[
      if (task.priority != null) _badge('(${task.priority})', theme),
      if (dueState != null)
        _badge(formatTodoDate(task.due!), theme, state: dueState),
      for (final project in task.projects) _chip('+$project', theme),
      for (final context in task.contexts) _chip('@$context', theme),
      for (final tag in task.hashtags) _chip('#$tag', theme),
      if (task.reminder != null)
        const Tooltip(
          message: AppStrings.todoHasReminder,
          child: Icon(Icons.alarm, size: 16),
        ),
    ];
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(spacing: 4, runSpacing: 4, children: chips);
  }

  /// A small outlined badge (priority, due date); the due badge takes
  /// the error/tertiary color when overdue/today.
  Widget _badge(String text, ThemeData theme, {TodoDueState? state}) {
    final color = switch (state) {
      TodoDueState.overdue => theme.colorScheme.error,
      TodoDueState.today => theme.colorScheme.tertiary,
      _ => theme.colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }

  /// A static token chip (filtering them is T-TD-05).
  Widget _chip(String text, ThemeData theme) {
    return Chip(
      label: Text(text),
      labelStyle: theme.textTheme.labelSmall,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
  }
}
