import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/history/history_labels.dart';
import 'package:niman/src/ui/history/note_history_screen.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

const _log = AppLogger(name: 'history');

/// Opens the history of the note at library-relative [path] (mockups
/// H1–H6), from the tree menu or the note's own menu.
///
/// Open editors are saved first, so "Current version" is what is on
/// screen. After a restore, [onRestored] reloads the open note and a
/// snackbar offers Undo, which restores the text the restore replaced.
Future<void> openNoteHistory(
  BuildContext context, {
  required LibrarySession session,
  required UnsavedTracker unsaved,
  required String path,
  required VoidCallback onRestored,
}) async {
  final ops = session.ops;
  if (ops == null) return;
  _log.info('open history "$path"');
  try {
    await unsaved.saveAll();
  } on Object catch (e) {
    // The history still opens: "Current version" is then the disk's.
    _log.warning('open history "$path": saving open notes failed: $e');
  }
  final limit = await session.historyVersions;
  if (!context.mounted) return;
  final restored = await Navigator.push<HistoryVersion>(
    context,
    MaterialPageRoute(
      builder: (context) =>
          NoteHistoryScreen(ops: ops, path: path, limit: limit),
    ),
  );
  if (restored == null || !context.mounted) return;
  _log.info('restored "$path" v${restored.number}, offering undo');
  onRestored();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('history-restored-snack'),
      content: Text(
        AppStrings.historyRestored(
          historyWhen(restored.savedAt, DateTime.now()),
        ),
      ),
      action: SnackBarAction(
        label: AppStrings.actionUndo,
        onPressed: () async {
          await _undoRestore(ops, path);
          onRestored();
        },
      ),
    ),
  );
}

/// Puts back the text a restore replaced: the newest version kept for
/// [HistoryReason.restore].
Future<void> _undoRestore(NoteOperations ops, String path) async {
  try {
    final manifest = await ops.noteHistory(path);
    final before = manifest.versions.lastWhere(
      (v) => v.reason == HistoryReason.restore,
    );
    _log.info('undo restore "$path": back to v${before.number}');
    await ops.restoreNoteVersion(path, before.number);
  } on Object catch (e) {
    _log.error('undo restore "$path" failed: $e');
  }
}
