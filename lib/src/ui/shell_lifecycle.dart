/// What the shell does as the app comes and goes from the foreground
/// (issue #100 moved it out of the shell): the library walked only while
/// it is seen (#1067), the log and the workspace on disk before a possible
/// end, the reminders, the files and the decks read again on return.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/calendar/calendar_controller.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/ui/shell_home_widgets.dart';
import 'package:niman/src/ui/shell_study.dart';
import 'package:niman/src/ui/shell_workspace.dart';

/// The shell's answer to a change of the app's lifecycle state.
final class ShellLifecycle {
  /// The answer for [controller]'s library: [workspace] is flushed on the
  /// way out; [todo], [calendar], [study] (when made) and [homeWidgets]
  /// follow on the way back, and [reloadOpenNote] has the note on screen
  /// re-read.
  new({
    required this.controller,
    required this.workspace,
    required this.todo,
    required this.calendar,
    required this.study,
    required this.homeWidgets,
    required this.reloadOpenNote,
  });

  /// The open library.
  final LibrarySession controller;

  /// The notes open in the library, whose places are kept.
  final ShellWorkspace workspace;

  /// The tasks, their reminders resynced on return.
  final TodoController todo;

  /// The calendar file, read again on return.
  final CalendarController calendar;

  /// The decks, when they have been made: their counts follow the day.
  final ShellStudy? Function() study;

  /// The home-screen widgets, pushed on return.
  final ShellHomeWidgets homeWidgets;

  /// Has the note on screen re-read its file, when it is clean.
  final VoidCallback reloadOpenNote;

  /// Re-reconciles reminders on return to the app: the exact-alarm and
  /// notification grants live in system settings, so coming back from
  /// there must reschedule without waiting for the next file change.
  void changed(AppLifecycleState state) {
    // Unfocused is still on screen (a desktop window beside another, a
    // phone's shade pulled down); paused and hidden are not, and a library
    // nobody sees is not walked on a timer (#1067).
    controller.appVisibilityChanged(
      visible:
          state == AppLifecycleState.resumed ||
          state == AppLifecycleState.inactive,
    );
    if (state == AppLifecycleState.paused) {
      // The queued changes go now: the process may not come back.
      controller.sync?.appBackgrounded();
    }
    if (state != AppLifecycleState.resumed) {
      // Leaving the foreground may be the last thing this process does
      // (a swipe away, an OEM battery kill): get the buffered log on
      // disk while there is still a chance to — and where each note was
      // left, once the editors have handed it in (their mementos land
      // in microtasks; this runs after them).
      unawaited(AppLog.flush());
      unawaited(Future(workspace.controller.flush));
      return;
    }
    unawaited(todo.resyncReminders());
    // Changes made on other devices while the app was away.
    controller.sync?.appResumed();
    // A home-screen widget toggle edits todo.txt / the note file in a
    // background isolate while the app is away (the Android watcher is
    // unreliable, so no session event may arrive): re-read both surfaces
    // when clean instead of showing the pre-toggle state.
    unawaited(todo.open());
    unawaited(calendar.open());
    // The day may have turned while the app was away: the decks are
    // counted for the study day it is now, and Study and its widgets
    // follow (#533).
    study()?.refreshStates();
    reloadOpenNote();
    // Pushes the home-screen widgets: the todo resync above skips its
    // notification when the files did not move, and a widget placed
    // while the app was away has no trigger of its own at all.
    homeWidgets.pushAll();
  }
}
