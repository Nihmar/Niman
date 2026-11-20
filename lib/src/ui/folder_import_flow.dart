/// Importing a folder from outside the library (#75, #1295), from wherever
/// it is asked: a folder dropped on the window and Settings → Maintenance.
/// One flow for both: the walk that counts what the folder holds, the offer
/// that says what will be made, the import on its isolate with its progress
/// and a cancel, and afterwards the tree showing the new folder.
///
/// What comes in: the folder's Markdown files, copied, and its web pages,
/// each converted into a note as a page converted on its own is (#1293), the
/// links between them rewritten (`import/folder/`).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart' show relPath;
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/import/folder/folder_import.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/convert_progress_dialog.dart';
import 'package:niman/src/ui/library_picker.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// The import of folders into notes, for one library session.
final class FolderImportFlow {
  /// Imports into [session]'s library; [reveal] shows a folder in the tree,
  /// by library-relative path.
  const new({
    required this.session,
    required this.reveal,
    this.limits = folderImportLimits,
  });

  /// The library.
  final LibrarySession session;

  /// Shows a folder in the tree.
  final void Function(String folder) reveal;

  /// What a folder may hold to be imported; a test hands in smaller ones.
  final FolderLimits limits;

  static const AppLogger _log = AppLogger(name: 'folder-import');

  /// Asks for a folder and imports it. Where the system's picker hands over
  /// no path an app may read — an iPhone's gives no grant outside the app's
  /// own folder — it lists the folders in Niman's own, as opening a library
  /// there does.
  Future<void> pickAndRun(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final pick = await pickLibraryFolder(
      context,
      AppStrings.importFolderSettingsTitle,
    );
    if (!context.mounted) return;
    switch (pick) {
      case LibraryPicked(:final path):
        await run(context, path);
      case LibraryPickCancelled():
        break;
      case LibraryPickNeedsAccess():
        messenger?.showSnackBar(
          SnackBar(content: Text(AppStrings.storageAccessNeeded)),
        );
      case LibraryPickFailed(:final message):
        messenger?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Imports the folder at [path], an absolute path outside the library:
  /// counts what it holds, offers it, and imports it once it is accepted.
  Future<void> run(BuildContext context, String path) async {
    final root = session.root;
    final ops = session.ops;
    if (root == null || ops == null || !context.mounted) return;
    // One of this library's own folders is not imported into itself.
    if (p.equals(root, path) || p.isWithin(root, path)) {
      reveal(p.equals(root, path) ? '' : relPath(path, root));
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final name = p.basename(p.normalize(path));
    // The walk is a FUSE round trip per folder on Android: it runs off the
    // UI isolate, so the count is awaited rather than read inline (#382).
    final FolderScan scan;
    try {
      scan = await scanFolder(path, limits: limits);
    } on FolderImportRefused catch (refused) {
      _log.warning('import "$name" refused: $refused');
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderTooLarge)),
      );
      return;
    } on Object catch (error) {
      _log.warning('import "$name" failed: $error');
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderFailed)),
      );
      return;
    }
    if (!context.mounted) return;
    if (scan.markdown.isEmpty && scan.pages.isEmpty) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderEmpty(name))),
      );
      return;
    }
    if (!await _offer(context, name, scan) || !context.mounted) return;
    final attachments = await ops.attachmentsFolder;
    final linkType = await session.librarySettings.linkType;
    if (!context.mounted) return;
    final FolderImport import;
    try {
      import = await FolderImport.start(
        source: path,
        scan: scan,
        libraryRoot: root,
        attachments: attachments,
        linkType: linkType,
      );
    } on Object catch (error) {
      _log.warning('import "$name" failed to start: $error');
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderFailed)),
      );
      return;
    }
    if (!context.mounted) {
      await import.cancel();
      return;
    }
    ConvertProgressDialog.show(
      context,
      progress: import.progress,
      done: import.done,
      cancel: import.cancel,
      reading: AppStrings.importFolderReading,
      title: AppStrings.importFolderAction,
      key: const Key('import-folder-progress'),
      cancelKey: const Key('import-folder-cancel-progress'),
    );
    await settle(
      context,
      done: import.done,
      name: name,
      root: root,
      messenger: messenger,
    );
  }

  /// Tells, on [messenger], how the import that [done] answers for ended,
  /// and — when it wrote — shows the folder it made, if the library it wrote
  /// into ([root]) is still the one open and the screen still there: an
  /// import takes a while, and the user may have switched library meanwhile.
  Future<void> settle(
    BuildContext context, {
    required Future<FolderImported?> done,
    required String name,
    required String root,
    required ScaffoldMessengerState? messenger,
  }) async {
    final FolderImported? imported;
    try {
      imported = await done;
    } on HtmlConvertCancelled {
      _log.info('import "$name": cancelled');
      return;
    } on Object catch (error) {
      _log.warning('import "$name" failed: $error');
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderFailed)),
      );
      return;
    }
    if (imported == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(AppStrings.importFolderEmpty(name))),
      );
      return;
    }
    _log.info(
      'import "$name" -> "${imported.folder}": ${imported.notes} note(s), '
      '${imported.pages} page(s), ${imported.pictures} picture(s), '
      '${imported.skipped} left out',
    );
    // The watcher finds what landed on its own: a rescan here would only
    // block the frame the reveal is drawn in (#382).
    if (session.root == root) reveal(imported.folder);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          imported.skipped == 0
              ? AppStrings.importFolderDone(imported.folder)
              : AppStrings.importFolderSkipped(
                  imported.folder,
                  imported.skipped,
                ),
        ),
      ),
    );
  }

  /// Asks whether to import [name], saying what it will make: its Markdown
  /// files copied and, when it has web pages, those converted into notes.
  Future<bool> _offer(
    BuildContext context,
    String name,
    FolderScan scan,
  ) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('import-folder'),
        title: Text(AppStrings.importFolderTitle(name)),
        content: Text(
          scan.pages.isEmpty
              ? AppStrings.importFolderBody(scan.markdown.length)
              : AppStrings.importFolderBodyPages(
                  scan.markdown.length,
                  scan.pages.length,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('import-folder-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.importFolderAction),
          ),
        ],
      ),
    );
    return go ?? false;
  }
}
