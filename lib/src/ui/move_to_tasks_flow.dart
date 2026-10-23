/// Move to tasks (#1152): the checkbox items under the selection become
/// tasks that link the note, and leave the note.
///
/// **The order is the promise.** The task files are written first, through the
/// controller's write chain, and the note's lines go only when both files took
/// the tasks: a failure in between leaves a task in both places, never in
/// neither. Undo goes the other way round for the same reason — the lines come
/// back into the note, then the tasks are taken out of the files.
///
/// One item opens the task dialog, so it can be given a date or a priority
/// before it is saved; several are moved at once, without one.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/task_items.dart';
import 'package:niman/src/editor/task_items_edit.dart';
import 'package:niman/src/todo/moved_task_lines.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';

/// Moves a note's checkbox items to the tasks.
final class MoveToTasksFlow {
  /// The flow over the shell's tasks [tasks].
  const new(this.tasks);

  /// The task files, the dialog's helpers and the day.
  final NoteTasksHost tasks;

  /// Moves the items under [note]'s selection. With none that can be moved it
  /// says why, as a command offered anywhere has to.
  Future<void> run(BuildContext context, NoteViewHandle note) async {
    if (!note.canInsert) return;
    final items = note.taskItems;
    final movable = [
      for (final item in items)
        if (item.movable) item,
    ];
    if (movable.isEmpty) {
      _say(
        context,
        MoveAvailability.of(items) == MoveAvailability.blocked
            ? AppStrings.moveToTasksHasSubItems
            : AppStrings.moveToTasksNeedsItem,
      );
      return;
    }
    final link = await tasks.linkTo(note.notePath);
    if (!context.mounted) return;
    final lines = await _lines(context, movable, link);
    if (lines == null || !context.mounted) return;
    final added = await tasks.controller.addMoved(
      todo: lines.todo,
      done: lines.done,
    );
    if (!added) {
      // Nothing was taken out of the note: the items are where they were.
      if (context.mounted) _say(context, AppStrings.shellActionFailed);
      return;
    }
    // The note is read again here: it may have changed under the dialog, and
    // an item that is no longer where it was stays, as a task as well.
    final taken = note.takeOutTaskItems(movable);
    if (taken == null || !context.mounted) return;
    _offerUndo(context, note, taken, lines);
  }

  /// The lines to write: the dialog's for one item, the plain ones for
  /// several; null when the dialog was cancelled.
  Future<MovedTaskLines?> _lines(
    BuildContext context,
    List<TaskItem> movable,
    String link,
  ) async {
    final today = tasks.today;
    if (movable.length > 1) {
      return movedTaskLines(
        items: [
          for (final item in movable) (text: item.text, checked: item.checked),
        ],
        link: link,
        today: today,
      );
    }
    final item = movable.single;
    final snapshot = tasks.controller.snapshot;
    final reminders = tasks.reminders;
    final line = await showTodoTaskDialog(
      context,
      today: today,
      // The caret starts before the words, as in every pre-filled dialog.
      text: '${item.text} $link',
      title: AppStrings.moveToTasks,
      confirmLabel: AppStrings.moveToTasksConfirm,
      knownTokens: snapshot == null
          ? const <String>{}
          : snapshotTokens(snapshot),
      linkSuggester: tasks.links.suggester,
      health: reminders?.health.value ?? ReminderHealth.ok,
      onOpenReminderSettings: reminders?.openHealthSettings,
    );
    if (line == null) return null;
    return item.checked
        ? MovedTaskLines(todo: const [], done: [completeTodoLine(line, today)])
        : MovedTaskLines(todo: [line], done: const []);
  }

  void _offerUndo(
    BuildContext context,
    NoteViewHandle note,
    TakenTaskItems taken,
    MovedTaskLines lines,
  ) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('moved-to-tasks-done'),
          // An action would keep it up until it is dismissed by hand (#508).
          persist: false,
          content: Text(
            taken.count == 1
                ? AppStrings.movedToTasksOne
                : AppStrings.movedToTasks(taken.count),
          ),
          action: SnackBarAction(
            label: AppStrings.actionUndo,
            onPressed: () => _undo(note, taken, lines),
          ),
        ),
      );
  }

  /// The lines back in the note first, the tasks out of the files after: a
  /// note that has gone away leaves the tasks where they are.
  Future<void> _undo(
    NoteViewHandle note,
    TakenTaskItems taken,
    MovedTaskLines lines,
  ) async {
    if (!note.putBackTaskItems(taken)) return;
    await tasks.controller.removeMoved(todo: lines.todo, done: lines.done);
  }

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
