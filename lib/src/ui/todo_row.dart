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
///
/// The links in the task's text are chips in the subtitle (#1152), and are
/// not in the title as well.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_row_links.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/todo_link_chip.dart';
import 'package:niman/src/ui/todo_link_host.dart';
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
    this.links,
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

  /// The links of the tasks and how to follow one; null draws the links
  /// as chips that do nothing.
  final TodoLinkHost? links;

  static const AppLogger _log = AppLogger(name: 'todo');

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final now = today ?? DateTime.now();
    final linked = taskRowLinksOf(task, map: links?.map);
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _log.debug('todo row menu (right-click): line ${entry.lineIndex}');
        onShowMenuAt(details.globalPosition);
      },
      child: _tile(task, linked, now),
    );
  }

  /// The tile itself: checkbox, text, subtitle, tap and long-press.
  Widget _tile(TodoTask task, TaskRowLinks linked, DateTime now) {
    final display = linked.text;
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
        // A task that is only links reads as its chips, not as its line.
        display.isEmpty && linked.chips.isEmpty ? task.raw : display,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: TodoRowSubtitle(
        task: task,
        today: now,
        done: done,
        links: linked.chips,
        host: links,
      ),
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
/// so the row shows what it is filed under (2026-09-07 user feedback), and
/// a chip per link to a note (#1152).
final class TodoRowSubtitle extends StatelessWidget {
  /// Creates the subtitle of [task] as of [today]. A [done] task says when
  /// it was completed in place of its due date and reminder.
  const new({
    required this.task,
    required this.today,
    this.done = false,
    this.links = const <TaskRowLink>[],
    this.host,
    super.key,
  });

  /// The task the row shows.
  final TodoTask task;

  /// Whether the task is a line of `done.txt`.
  final bool done;

  /// The wall-clock day for the due state.
  final DateTime today;

  /// The links of the task, drawn after its tokens.
  final List<TaskRowLink> links;

  /// Follows a link; null draws them as they are.
  final TodoLinkHost? host;

  @override
  Widget build(BuildContext context) {
    final timing = todoRowTiming(task, today, done: done);
    final tokens = todoRowTokenChips(task);
    if (timing.isEmpty && tokens.isEmpty && links.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...timing,
        ...tokens,
        for (final link in links) TodoLinkChip(link: link, host: host),
      ],
    );
  }
}
