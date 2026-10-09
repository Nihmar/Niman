/// Runs a Home action (#535): each kind handed to the flow the app already
/// has for it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/ui/strings.dart';

/// What the runner hands each kind of action to: the shell's own flows.
final class HomeActionRunner {
  /// A runner over the shell's flows.
  const new({
    required this.newNote,
    required this.addTask,
    required this.openNote,
    required this.openJournal,
    required this.capture,
    required this.missing,
    required this.tell,
  });

  /// Which of the paths given the library no longer holds.
  final Future<Set<String>> Function(Iterable<String> paths) missing;

  /// Says something to the user (a snackbar).
  final void Function(String message) tell;

  /// Makes a note for an action (its folder, template and fields).
  final Future<void> Function(BuildContext context, HomeAction action) newNote;

  /// Adds a task, an action's project and context written in.
  final Future<void> Function(HomeAction action) addTask;

  /// Opens a note by library-relative path.
  final void Function(String path) openNote;

  /// Opens today's journal entry.
  final Future<void> Function(BuildContext context) openJournal;

  /// Captures a web page into an action's folder.
  final Future<void> Function(BuildContext context, HomeAction action) capture;

  /// Runs [action]; a kind this build does not know does nothing, and one
  /// whose template or note is gone says so instead of half running.
  Future<void> run(BuildContext context, HomeAction action) async {
    final gone = await missing(action.requiredPaths);
    if (gone.isNotEmpty) {
      tell(AppStrings.homeActionMissing(gone.first));
      return;
    }
    if (!context.mounted) return;
    switch (action.kind) {
      case HomeActionKind.newNote:
        await newNote(context, action);
      case HomeActionKind.addTask:
        await addTask(action);
      case HomeActionKind.openNote:
        if (action.path case final path?) openNote(path);
      case HomeActionKind.journal:
        await openJournal(context);
      case HomeActionKind.capture:
        await capture(context, action);
      case null:
        return;
    }
  }
}
