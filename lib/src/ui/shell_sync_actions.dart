/// The sync controls of the shell (issue #100, split out of
/// `shell.dart`; mockups S6–S11): the status button and the four screens
/// behind it — run, panel, settings, conflict.
///
/// Every one of them starts the same way, by asking the session for a
/// sync service and doing nothing without one, which is why they belong
/// together and why none of them belongs in the shell's `State`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/sync/sync_conflict_screen.dart';
import 'package:niman/src/ui/sync/sync_flow.dart';
import 'package:niman/src/ui/sync/sync_settings_screen.dart';
import 'package:niman/src/ui/sync/sync_status.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

/// Runs the shell's sync surfaces over the open library's sync service.
final class ShellSyncActions {
  /// Creates the actions; [onShowTrash] is the shell's own trash screen,
  /// which a sync that moved deletions there offers to open.
  new({required this.unsaved, required this.onShowTrash});

  /// The open notes with unsaved edits: a sync saves them first.
  final UnsavedTracker unsaved;

  /// Opens the trash screen of the session it is handed.
  final void Function(LibrarySession controller) onShowTrash;

  /// The sync icon for the tree's bar; nothing without a sync service
  /// (the button itself hides while no destination is configured).
  Widget button(BuildContext context, LibrarySession controller) {
    final sync = controller.sync;
    if (sync == null) return const SizedBox.shrink();
    return SyncStatusButton(
      sync: sync,
      onSync: () => unawaited(run(context, controller)),
      onOpenPanel: () => unawaited(openPanel(context, controller)),
    );
  }

  /// Syncs now, reporting through the shell's messenger.
  Future<void> run(BuildContext context, LibrarySession controller) async {
    final sync = controller.sync;
    if (sync == null) return;
    await runSyncFromUi(
      context,
      sync,
      unsaved: unsaved,
      onShowTrash: () => onShowTrash(controller),
      onShowPanel: () => unawaited(openPanel(context, controller)),
    );
  }

  /// Opens the status panel: what the last run could not settle.
  Future<void> openPanel(
    BuildContext context,
    LibrarySession controller,
  ) async {
    final sync = controller.sync;
    if (sync == null) return;
    await showSyncPanel(
      context,
      sync: sync,
      onSyncNow: () => unawaited(run(context, controller)),
      onOpenSettings: () => unawaited(openSettings(context, controller)),
      onResolve: (path) =>
          unawaited(resolveConflict(context, controller, path)),
    );
  }

  /// Opens the library's sync settings (destination, credentials, rules).
  Future<void> openSettings(
    BuildContext context,
    LibrarySession controller,
  ) async {
    final sync = controller.sync;
    if (sync == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SyncSettingsScreen(
          sync: sync,
          libraryName: p.basename(controller.root ?? ''),
          unsaved: unsaved,
          onShowTrash: () => onShowTrash(controller),
        ),
      ),
    );
  }

  /// Opens the conflict screen for [path].
  ///
  /// The open notes are saved first, and a failure to save is logged
  /// rather than raised: the conflict is the more urgent thing on screen,
  /// and the screen reads the file itself.
  Future<void> resolveConflict(
    BuildContext context,
    LibrarySession controller,
    String path,
  ) async {
    final sync = controller.sync;
    if (sync == null) return;
    try {
      await unsaved.saveAll();
    } on Object catch (e) {
      const AppLogger(name: 'sync').warning('resolve: saving failed: $e');
    }
    if (!context.mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SyncConflictScreen(sync: sync, path: path),
      ),
    );
  }
}
