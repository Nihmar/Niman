import 'package:flutter/material.dart';
import 'package:niman/src/todo/task_link_label.dart';
import 'package:niman/src/todo/task_row_links.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/note_task_anchor_chip.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/todo_link_chip.dart';
import 'package:niman/src/ui/todo_link_host.dart';
import 'package:niman/src/ui/todo_priority_badge.dart';
import 'package:niman/src/ui/todo_row_timing.dart';
import 'package:niman/src/ui/todo_row_tokens.dart';

/// One task in a note's task list (#1152): a task as the Todo tab draws it —
/// checkbox, priority, description, due date, tokens, a chip per other link —
/// with the link to the note the list is for left out.
///
/// What that link named inside the note (a heading, a block) stays as a
/// `§ Boiler` chip. The checkbox ticks the task; a tap on the row opens it in
/// the task dialog. The room is a side panel's or a sheet's, so the
/// description takes the first line and the rest wraps under it.
final class NoteTaskRow extends StatelessWidget {
  /// The row of [entry] in the task list of the note at library-relative
  /// [notePath]; [done] says it is a line of `done.txt`.
  const new({
    required this.entry,
    required this.done,
    required this.notePath,
    required this.today,
    required this.onToggle,
    required this.onEdit,
    this.links,
    super.key,
  });

  /// The task with its file line.
  final TodoEntry entry;

  /// Whether the task is a line of `done.txt`.
  final bool done;

  /// The note the list is for, library-relative: the link to it is not drawn.
  /// Null for a list that is about no note (every task), which draws them
  /// all.
  final String? notePath;

  /// The wall-clock day for the due state.
  final DateTime today;

  /// Ticks the task, or reopens it.
  final ValueChanged<bool> onToggle;

  /// Opens the task in the task dialog.
  final VoidCallback onEdit;

  /// The links of the tasks and how to follow one; null draws them as chips
  /// that do nothing.
  final TodoLinkHost? links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = entry.task;
    final linked = taskRowLinksOf(task, map: links?.map, hiding: notePath);
    final timing = todoRowTiming(task, today, done: done);
    final tokens = todoRowTokenChips(task);
    final hasMore =
        timing.isNotEmpty ||
        tokens.isNotEmpty ||
        linked.anchors.isNotEmpty ||
        linked.chips.isNotEmpty;
    final id = '${done ? 'done' : 'open'}-${entry.lineIndex}';
    final priority = task.priority;
    final compact = pointerDense(theme);
    return InkWell(
      key: Key('note-task-row-$id'),
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 14, 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: Key('note-task-check-$id'),
              value: task.completed,
              visualDensity: compact ? VisualDensity.compact : null,
              onChanged: (value) => onToggle(value ?? false),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: compact ? 5 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (priority != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 6),
                            child: TodoPriorityBadge(priority: priority),
                          ),
                        Expanded(
                          child: Text(
                            // A task that is only the link to this note
                            // reads as the note's name.
                            linked.text.isEmpty && !hasMore
                                ? taskPlainText(task.description)
                                : linked.text,
                            key: Key('note-task-text-$id'),
                            style: task.completed
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...timing,
                            ...tokens,
                            for (final anchor in linked.anchors)
                              NoteTaskAnchorChip(anchor: anchor),
                            for (final link in linked.chips)
                              TodoLinkChip(
                                link: link,
                                host: links,
                                compact: compact,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
