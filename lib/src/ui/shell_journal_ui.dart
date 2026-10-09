/// The journal as the shell shows it (#7; split out of `shell.dart` for
/// #710): the calendar — the dock's pane where the window has room, the
/// Journal screen elsewhere — the strip over an entry, and what the
/// calendar reads: an entry's text, the tasks due on a day, an entry's
/// right-click menu.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/journal/journal_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/journal/journal_screen.dart';
import 'package:niman/src/ui/journal/journal_strip.dart';

/// Builds and opens the shell's journal views.
final class ShellJournalUi {
  /// Creates the views over [controller]'s library.
  new({
    required this.controller,
    required this.journal,
    required this.flow,
    required this.tasks,
    required this.dockRoom,
    required this.openDockJournal,
    required this.openTasks,
    required this.showRowMenuAt,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// The journal's settings as they stand.
  final JournalSettings Function() journal;

  /// Opens and makes entries.
  final JournalFlow flow;

  /// The task list, whose due tasks the calendar shows under a day.
  final TodoController tasks;

  /// Whether the window has room for the dock.
  final bool Function() dockRoom;

  /// Shows the dock on its journal pane.
  final VoidCallback openDockJournal;

  /// Opens the task list.
  final VoidCallback openTasks;

  /// Opens the tree's menu for a note at a position.
  final Future<void> Function(Note note, Offset position) showRowMenuAt;

  /// The dock's journal pane, on [focusDay] when an entry is on screen.
  Widget browser(BuildContext context, {DateTime? focusDay}) => JournalBrowser(
    today: journal().today(DateTime.now()),
    entryDays: flow.entryDays,
    readEntry: _readEntry,
    revision: controller.revision,
    onOpenDay: (day, {confirmed = false}) =>
        unawaited(flow.openDay(context, day, confirmed: confirmed)),
    dueOn: _tasksDueOn,
    tasksChanged: tasks,
    onOpenTasks: openTasks,
    focusDay: focusDay,
    onEntryMenu: (day, position) => unawaited(_entryMenuAt(day, position)),
  );

  /// A recent journal entry's right-click menu (#619): the tree's own,
  /// for the entry's note — a new tab and beside among its actions.
  Future<void> _entryMenuAt(DateTime day, Offset position) async {
    final note = await controller.ops?.find(journal().entryPath(day));
    if (note == null) return;
    await showRowMenuAt(note, position);
  }

  /// The open tasks due on [day], as the task list reads them: what the
  /// journal's calendar shows under the day (#7).
  List<String> _tasksDueOn(DateTime day) => [
    for (final entry in tasks.snapshot?.todo ?? const <TodoEntry>[])
      if (!entry.task.completed && entry.task.due == day)
        taskDisplayText(entry.task.description),
  ];

  /// The text of [day]'s journal entry, for the calendar's recent list.
  Future<String> _readEntry(DateTime day) async {
    final ops = controller.ops;
    if (ops == null) return '';
    return await ops.readNote(journal().entryPath(day));
  }

  /// The journal's calendar (#7): the dock's pane where the window has
  /// room for the dock, the Journal screen everywhere else.
  void showCalendar(BuildContext context) {
    if (dockRoom()) {
      openDockJournal();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (screen) => JournalScreen(
          today: journal().today(DateTime.now()),
          entryDays: flow.entryDays,
          readEntry: _readEntry,
          revision: controller.revision,
          dueOn: _tasksDueOn,
          tasksChanged: tasks,
          onOpenTasks: () {
            Navigator.of(screen).pop();
            openTasks();
          },
          onOpenDay: (day, {confirmed = false}) {
            // The screen goes first: the entry opens in the shell.
            Navigator.of(screen).pop();
            unawaited(flow.openDay(context, day, confirmed: confirmed));
          },
        ),
      ),
    );
  }

  /// The journal's strip over [path] when it is an entry (#7), else null.
  Widget? header(BuildContext context, String path, {bool compact = false}) {
    final settings = journal();
    final day = settings.dayOfPath(path);
    if (day == null) return null;
    return JournalStrip(
      day: day,
      today: settings.today(DateTime.now()),
      entryDays: flow.entryDays,
      onPrevious: () => unawaited(flow.openPrevious(context, day)),
      onNext: () => unawaited(flow.openNext(context, day)),
      onDay: () => showCalendar(context),
      revision: controller.revision,
      compact: compact,
    );
  }
}
