/// The phone's notes left open (#23, PR 4): the badge in the app bar, the
/// switcher it opens, and what a close from it leaves on screen. Out of
/// `shell.dart` (#1266).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/open_notes_sheet.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_tab_switch.dart';
import 'package:niman/src/ui/shell_workspace.dart';

/// The open-notes badge and its switcher.
final class ShellOpenNotes {
  /// The switcher over [workspace]'s notes.
  new({
    required this.workspace,
    required this.selection,
    required this.tabs,
    required this.createFlow,
    required this.changes,
    required this.unsaved,
    required this.open,
    required this.context,
  });

  /// The notes open, and their order.
  final ShellWorkspace workspace;

  /// Which note is on screen.
  final ShellSelection selection;

  /// Closes the note on screen.
  final ShellTabSwitch tabs;

  /// Makes the note the switcher's **New** asks for.
  final ShellCreateFlow createFlow;

  /// Tells the switcher the notes open changed.
  final Listenable changes;

  /// The open notes holding unsaved edits, library-relative.
  final Set<String> Function() unsaved;

  /// Shows a note, as a link does.
  final void Function(String path) open;

  /// The shell's context.
  final BuildContext Function() context;

  /// The phone's badge for the notes left open.
  Widget button() => OpenNotesButton(
    count: workspace.value.tabs.length,
    onPressed: () => unawaited(show()),
  );

  /// The phone's open-notes switcher: every note left open, the one on
  /// screen marked, each with its unsaved dot and a close.
  Future<void> show() => showOpenNotesSheet(
    context(),
    workspace: () => workspace.value,
    changes: changes,
    unsaved: unsaved,
    shown: () => selection.noteOnScreen,
    onOpen: open,
    onClose: close,
    onCloseAll: () {
      workspace.controller.update((w) => w.closeAll());
      if (selection.noteOnScreen != null) tabs.closeNote();
      selection.clear();
    },
    // A phone opens every note alongside the others: the new one joins
    // them once it is named, and a cancel leaves nothing behind (#1133).
    onNewNote: () => unawaited(createFlow.createNote(context())),
  );

  /// Closes [path] from the switcher. The note on screen gives way to the
  /// next one open, or to the tree when it was the last.
  void close(String path) {
    final wasShown = selection.noteOnScreen == path;
    workspace.controller.update((w) => w.closePath(path));
    final next = workspace.value.activePath;
    if (wasShown && next != null) {
      open(next);
      return;
    }
    if (wasShown) tabs.closeNote();
    selection.clearIf(path);
  }
}
