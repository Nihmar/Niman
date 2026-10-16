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
import 'package:niman/src/ui/todo_priority_badge.dart';
import 'package:niman/src/ui/todo_row_timing.dart';
import 'package:niman/src/ui/todo_row_tokens.dart';

/// One row of the todo list.
final class TodoRow extends StatelessWidget {
  /// Creates a row for [entry].
  ///
  /// [today] is the wall-clock day for the due state and the short date
  /// (injected in widget tests; defaults to now). [onToggle] flips the
  /// checkbox, [onEdit] opens the edit dialog, [onShowMenu] opens the
  /// long-press bottom sheet.
  ///
  /// A [done] row (a line of `done.txt`) says when it was completed where an
  /// open one says when it is due. The priority shows as a badge unless
  /// [showPriority] is off: a list sorted by priority has it in its
  /// section headings.
  const new({
    required this.entry,
    required this.onToggle,
    required this.onEdit,
    required this.onShowMenu,
    required this.onShowMenuAt,
    this.today,
    this.done = false,
    this.showPriority = true,
    super.key,
  });

  /// The task with its file line index.
  final TodoEntry entry;

  /// Whether the entry is a line of `done.txt`.
  final bool done;

  /// Whether the priority shows as a badge.
  final bool showPriority;

  /// Flips the checkbox.
  final ValueChanged<bool> onToggle;

  /// Opens the edit dialog.
  final VoidCallback onEdit;

  /// Opens the long-press bottom sheet.
  final VoidCallback onShowMenu;

  /// Opens the cursor menu at the pressed point (right-click).
  final ValueChanged<Offset> onShowMenuAt;

  /// The wall-clock day for the due state (defaults to now).
  final DateTime? today;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final now = today ?? DateTime.now();
    final display = taskDisplayText(task.description);
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _log.debug('todo row menu (right-click): line ${entry.lineIndex}');
        onShowMenuAt(details.globalPosition);
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
      subtitle: TodoRowSubtitle(task: task, today: now, done: done),
      trailing: showPriority && task.priority != null
          ? TodoPriorityBadge(priority: task.priority!)
          : null,
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
final class TodoRowSubtitle extends StatelessWidget {
  /// Creates the subtitle of [task] as of [today]. A [done] task says when
  /// it was completed in place of its due date and reminder.
  const new({
    required this.task,
    required this.today,
    this.done = false,
    super.key,
  });

  /// The task the row shows.
  final TodoTask task;

  /// Whether the task is a line of `done.txt`.
  final bool done;

  /// The wall-clock day for the due state.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final timing = todoRowTiming(task, today, done: done);
    final tokens = todoRowTokenChips(task);
    if (timing.isEmpty && tokens.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(spacing: 6, runSpacing: 2, children: [...timing, ...tokens]);
  }
}
