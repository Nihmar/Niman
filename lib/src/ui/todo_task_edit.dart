/// Editing one existing task in the task dialog and writing it back: the
/// flow the Todo tab's rows and a note's task list (#1152) share.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';
import 'package:niman/src/ui/todo_link_host.dart';

const AppLogger _log = AppLogger(name: 'todo');

/// Opens the task dialog on [entry] and writes the line it returns in place
/// of the task's, in the file the task was read from: `done.txt` when [done],
/// else `todo.txt`. The dialog can also delete the task.
///
/// Nothing is written when the dialog is cancelled or [context] is gone by
/// the time it closes. [links] completes a `[[` typed in the text, and
/// [reminders] tells the dialog whether reminders can fire.
Future<void> editTodoTask(
  BuildContext context, {
  required TodoController controller,
  required TodoEntry entry,
  required bool done,
  required DateTime today,
  TodoLinkHost? links,
  ReminderService? reminders,
}) async {
  final snapshot = controller.snapshot;
  final line = await showTodoTaskDialog(
    context,
    initial: entry.task,
    today: today,
    knownTokens: snapshot == null ? const <String>{} : snapshotTokens(snapshot),
    linkSuggester: links?.suggester,
    onDelete: () {
      _log.debug('todo delete: line ${entry.lineIndex} (done $done)');
      unawaited(
        done ? controller.deleteDone(entry) : controller.deleteTodo(entry),
      );
    },
    health: reminders?.health.value ?? ReminderHealth.ok,
    onOpenReminderSettings: reminders?.openHealthSettings,
  );
  if (line == null || !context.mounted) return;
  _log.debug('todo row rewritten: line ${entry.lineIndex} (done $done)');
  await (done
      ? controller.updateDone(entry, line)
      : controller.updateTodo(entry, line));
}
