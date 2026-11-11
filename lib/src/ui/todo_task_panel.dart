/// The task beside a tablet's Todo list (#1266): the edit dialog's fields
/// in a panel that stays while the list does, and moves to another task
/// when that one is tapped.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';
import 'package:niman/src/ui/todo_link_host.dart';

const AppLogger _log = AppLogger(name: 'todo');

/// The editor of [entry], beside the list, writing to [controller].
final class TodoTaskPanel extends StatelessWidget {
  /// The panel over [entry], from `done.txt` when [done]; [onClose] takes
  /// it away after a Save, a Cancel or a Delete.
  const new({
    required this.controller,
    required this.entry,
    required this.done,
    required this.today,
    required this.onClose,
    this.links,
    this.reminders,
    super.key,
  });

  /// The width the panel takes beside the list.
  static const double width = 360;

  /// The tasks, and where the edit is written.
  final TodoController controller;

  /// The task, as it was when it was tapped.
  final TodoEntry entry;

  /// Whether the task is a done one.
  final bool done;

  /// The day the pickers start from.
  final DateTime today;

  /// Takes the panel away.
  final VoidCallback onClose;

  /// Completes a `[[` typed in the text.
  final TodoLinkHost? links;

  /// Whether reminders can fire.
  final ReminderService? reminders;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    return TodoTaskEditor(
      // A task tapped after this one starts over, with its own text.
      key: ValueKey(('todo-panel', done, entry.lineIndex, entry.task.raw)),
      panel: true,
      initial: entry.task,
      text: '',
      due: null,
      today: today,
      knownTokens: snapshot == null
          ? const <String>{}
          : snapshotTokens(snapshot),
      linkSuggester: links?.suggester,
      onDelete: () {
        final now = _current();
        if (now == null) return;
        _log.debug('todo panel delete: line ${now.lineIndex} (done $done)');
        unawaited(
          done ? controller.deleteDone(now) : controller.deleteTodo(now),
        );
      },
      health: reminders?.health.value ?? ReminderHealth.ok,
      onOpenReminderSettings: reminders?.openHealthSettings,
      title: null,
      confirmLabel: null,
      onClose: (line) {
        onClose();
        if (line == null) return;
        final now = _current();
        if (now == null) return;
        _log.debug('todo panel rewrote line ${now.lineIndex} (done $done)');
        unawaited(
          done
              ? controller.updateDone(now, line)
              : controller.updateTodo(now, line),
        );
      },
    );
  }

  /// The task as the list holds it now: the lines may have moved while the
  /// panel was open — another task checked off, a sync — so it is found by
  /// its text, at its old line first. Null when it is gone.
  TodoEntry? _current() {
    final snapshot = controller.snapshot;
    if (snapshot == null) return null;
    final entries = done ? snapshot.done : snapshot.todo;
    final raw = entry.task.raw;
    if (entry.lineIndex < entries.length &&
        entries[entry.lineIndex].task.raw == raw) {
      return entries[entry.lineIndex];
    }
    for (final candidate in entries) {
      if (candidate.task.raw == raw) return candidate;
    }
    return null;
  }
}
