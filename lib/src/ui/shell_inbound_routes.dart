import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/share_in.dart';
import 'package:niman/src/core/shortcuts.dart';
import 'package:niman/src/core/tray.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/todo/reminders.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/close_to_tray.dart';
import 'package:niman/src/ui/shell_home_widgets.dart';
import 'package:niman/src/ui/shell_import_flow.dart';
import 'package:niman/src/ui/shell_inbound.dart';
import 'package:niman/src/ui/shell_ocr_flow.dart';
import 'package:niman/src/ui/shell_outside_routes.dart';
import 'package:niman/src/ui/shell_personal_dictionary.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';

/// What the shell does with what reaches it from outside while it is up
/// (#1256): a notification tapped, a recognition finished, the library's
/// own events and changes on disk, a sync, a shortcut, a share, the tray,
/// a file, a folder or a link a launch or a drop brings. Each is listened
/// to in [listen], and all of them cancelled at once in [cancel].
final class ShellInboundRoutes {
  /// The routes of what reaches the shell.
  new({
    required this.controller,
    required this.workspace,
    required this.selection,
    required this.unsaved,
    required this.personalDictionary,
    required this.homeWidgets,
    required this.reminders,
    required this.ocrQueue,
    required this.ocrFlow,
    required this.shortcuts,
    required this.shareIn,
    required this.tray,
    required this.window,
    required this.launchRequests,
    required this.outside,
    required this.imports,
    required this.captureFlow,
    required this.openPath,
    required this.onRequest,
    required this.context,
    required this.mounted,
  });

  /// The open library: its events, its removals, the changes on disk.
  final LibrarySession controller;

  /// The panes, whose tabs follow the files.
  final ShellWorkspace workspace;

  /// What is selected, whose note a sync re-reads.
  final ShellSelection selection;

  /// The open notes, told of a change on disk.
  final UnsavedTracker unsaved;

  /// The personal dictionary, which a sync brings words to.
  final ShellPersonalDictionary personalDictionary;

  /// The home-screen widgets, which follow the library's notes.
  final ShellHomeWidgets homeWidgets;

  /// The reminders, whose notifications are tapped.
  final ReminderService reminders;

  /// The recognitions, where there is OCR.
  final OcrQueue? ocrQueue;

  /// What a finished recognition says.
  final ShellOcrFlow? Function() ocrFlow;

  /// The launcher's shortcuts.
  final ShortcutService shortcuts;

  /// What other apps share in.
  final ShareInService shareIn;

  /// The tray's menu.
  final TrayService tray;

  /// The window the tray brings back.
  final WindowController window;

  /// What a launch or a drop asks to open.
  final LaunchRequests launchRequests;

  /// Where a notification or a shortcut leads.
  final ShellOutsideRoutes outside;

  /// Shares and folders brought in.
  final ShellImportFlow imports;

  /// Web pages captured as notes.
  final CaptureFlow captureFlow;

  /// Opens a file by absolute path.
  final Future<void> Function(String path) openPath;

  /// Called before the handler of a request from outside (#1109).
  final VoidCallback onRequest;

  /// Where what a request opens opens.
  final BuildContext Function() context;

  /// Whether the shell is still up.
  final bool Function() mounted;

  late final ShellInbound _inbound = ShellInbound(onRequest: onRequest);

  /// Starts listening to all of it.
  void listen() {
    // Notification taps while running: a todo tap opens the Todo tab, a
    // recognition's opens its text.
    _inbound.listen(
      reminders.taps,
      (payload) =>
          unawaited(outside.notification(context(), payload, tap: true)),
      request: true,
    );
    // Recognitions as they finish (#594).
    _inbound.listen(ocrQueue?.finished, (job) {
      if (!mounted()) return;
      ocrFlow()?.finished(
        context(),
        job,
        inFront:
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
    });
    // Library session events (every note op bumps the revision): the
    // pinned notes follow the files, so each one refreshes the note
    // widgets (issue 6).
    _inbound.listen(controller.events, (_) {
      homeWidgets.pushNotes();
      unawaited(workspace.indexChanged());
    });
    // Paths a re-index pruned from the tree: the tabs they hold stay, and
    // are flagged missing (issues #289, #372).
    _inbound.listen(controller.removals, workspace.missing);
    // Notes rewritten on disk behind the editors' backs (a sync client,
    // another program): every open note whose buffer is clean adopts the
    // change, the tabs behind the one on screen included (#1055).
    _inbound.listen(controller.externalChanges, unsaved.notifyDiskChanged);
    // Paths a sync just changed on disk: the open note among them is
    // re-read (its buffer was saved before the sync started).
    _inbound.listen(controller.sync?.localChanges, (paths) {
      // Words added on another device count as soon as they arrive.
      personalDictionary.synced(paths);
      if (mounted()) selection.reloadOpen(paths);
    });
    _inbound.listen(
      shortcuts.actions,
      (action) => unawaited(outside.runShortcut(context(), action)),
      request: true,
    );
    // What other apps share in while the shell is up (#40).
    _inbound.listen(
      shareIn.requests,
      (request) => unawaited(imports.share(context(), request)),
      request: true,
    );
    _inbound.listen(
      tray.actions,
      (action) => unawaited(outside.runShortcut(context(), action)),
      request: true,
    );
    _inbound.listen(tray.activated, (_) => unawaited(window.show()));
    // The tray menu's own entries (#209): the way back to a hidden
    // window, and the way out.
    _inbound.listen(tray.commands, (command) {
      switch (command) {
        case TrayCommand.open:
          unawaited(window.show());
        case TrayCommand.quit:
          CloseToTray.quit();
      }
    });
    // Files a launch asked for (#41): the one the app started with, once
    // the shell can open it, and every later one.
    _inbound.listen(
      launchRequests.files,
      (path) => unawaited(openPath(path)),
      request: true,
    );
    // Folders dropped on the window (#75).
    _inbound.listen(
      launchRequests.folders,
      (path) => unawaited(imports.openFolder(context(), path)),
      request: true,
    );
    // Links dropped on the window (#531).
    _inbound.listen(launchRequests.pages, (url) {
      if (mounted()) unawaited(captureFlow.capture(context(), url: url));
    }, request: true);
  }

  /// Ends every subscription.
  Future<void> cancel() => _inbound.cancel();
}
