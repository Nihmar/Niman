/// The tree's and the grid's menus (issue #100): a row's, held or
/// right-clicked, the empty space's, and the tree footer's New menu. What
/// a choice does is [ShellRowActions]'s and the creation flows'; this asks
/// which choice it is and hands it on.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/create_kinds.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/shell_export_flow.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/shell_row_menu.dart';
import 'package:niman/src/ui/shell_tree_footer.dart';

/// The menus over the Files pane, run through the shell's row actions.
final class ShellTreeMenus {
  /// Menus whose choices [rows] carries out, [exports] writing a folder or
  /// the library out, [journal] and [capture] behind the New menu's
  /// entries of theirs. [features], [offersOcr] and [wide] are read when a
  /// menu opens: what it offers follows them.
  new({
    required this.rows,
    required this.exports,
    required this.journal,
    required this.capture,
    required this.features,
    required this.offersOcr,
    required this.wide,
  });

  /// The actions on one row, and the creation flows they hold.
  final ShellRowActions rows;

  /// The exports: a folder's, the library's.
  final ShellExportFlow exports;

  /// Today's journal entry, the New menu's first entry.
  final JournalFlow journal;

  /// A web page captured as a note.
  final CaptureFlow capture;

  /// The library's features: a menu offers what is on.
  final Features Function() features;

  /// Whether a row's menu offers Recognize text (#594).
  final bool Function() offersOcr;

  /// Whether the shell is the wide one: a row's menu offers a new tab.
  final bool Function() wide;

  /// The tree's right-click menus, which one opened and when: a row's and
  /// the background's were both seen on one click (0.0.9 test round).
  static const AppLogger _treeMenuLog = AppLogger(name: 'tree.menu');

  /// Long-press context menu on a tree row (T-UI-05): the note actions,
  /// scoped to the pressed row. New note/folder target the row's folder
  /// (issue #100 moved the menu itself into `shell_row_menu.dart`).
  /// A pointer's menu grows from [anchor], the row held.
  Future<void> rowMenu(BuildContext context, Note note, Rect? anchor) async {
    final here = note.isDir ? note.path : parentOf(note.path);
    final isQuickNote = await rows.controller.ops?.quickNotePath == note.path;
    if (!context.mounted) return;
    final action = await showRowMenuSheet(
      context,
      note: note,
      isQuickNote: isQuickNote,
      offersRecognize: offersOcr(),
      features: features(),
      anchor: anchor,
    );
    if (!context.mounted) return;
    await rows.run(context, action, note, here, anchor: anchor);
  }

  /// Right-click context menu on a tree row (T-PP-20): the same actions
  /// at the cursor instead of in the phone's bottom sheet.
  Future<void> rowMenuAt(
    BuildContext context,
    Note note,
    Offset position,
  ) async {
    _treeMenuLog.debug('row menu asked: "${note.path}"');
    final here = note.isDir ? note.path : parentOf(note.path);
    final isQuickNote = await rows.controller.ops?.quickNotePath == note.path;
    if (!context.mounted) return;
    final action = await showRowMenuAt(
      context,
      note: note,
      isQuickNote: isQuickNote,
      position: position,
      offersNewTab: wide(),
      offersRecognize: offersOcr(),
      features: features(),
    );
    _treeMenuLog.debug('row menu closed: "${note.path}" -> $action');
    if (!context.mounted) return;
    await rows.run(context, action, note, here, anchor: menuAnchorAt(position));
    _treeMenuLog.debug('row menu action done: "${note.path}" $action');
  }

  /// The right-click menu on the tree's empty space: a note, a note from a
  /// template or a folder, at the library's root.
  Future<void> treeBackgroundAt(BuildContext context, Offset position) async {
    _treeMenuLog.debug('background menu asked');
    final action = await showTreeBackgroundMenuAt(
      context,
      position: position,
      features: features(),
    );
    _treeMenuLog.debug('background menu closed -> $action');
    if (!context.mounted) return;
    await _runBackground(context, action, '', position);
  }

  /// The right-click menu on the grid's empty space: a note, a note from
  /// a template or a folder in the folder shown, and that folder's export
  /// (the library's at the root).
  Future<void> gridBackgroundAt(
    BuildContext context,
    String folder,
    Offset position,
  ) async {
    final here = folder.isEmpty ? null : folder;
    final action = await showTreeBackgroundMenuAt(
      context,
      position: position,
      here: here,
      features: features(),
    );
    if (!context.mounted) return;
    await _runBackground(context, action, folder, position);
  }

  /// Runs an empty space's menu [action] in [folder] (`''` the root): the
  /// export the menu offers there — a folder's, or the library's at the
  /// root — or what it makes.
  Future<void> _runBackground(
    BuildContext context,
    String? action,
    String folder,
    Offset position,
  ) async {
    switch (action) {
      case 'note':
        await rows.creates.createNote(context, parent: folder);
      case 'template':
        await rows.templates.createFromTemplate(context, parent: folder);
      case 'folder':
        await rows.creates.createFolder(context, parent: folder);
      case 'exportfolder':
        await exports.runFolderExport(
          context,
          folder,
          library: false,
          anchor: menuAnchorAt(position),
        );
      case 'exportlibrary':
        await exports.runFolderExport(
          context,
          '',
          library: true,
          anchor: menuAnchorAt(position),
        );
      default:
        // The kinds a folder creates in place: one table (#1013).
        await createKindFromMenu(action, rows.creates, context, parent: folder);
    }
  }

  /// Runs the create flow behind a tree-footer menu entry.
  void newItem(BuildContext context, NewShellItem item) {
    final creates = rows.creates;
    switch (item) {
      case NewShellItem.journal:
        unawaited(journal.openToday(context));
      case NewShellItem.note:
        unawaited(creates.createNote(context));
      case NewShellItem.listNote:
        unawaited(creates.createListNote(context));
      case NewShellItem.audioNote:
        unawaited(creates.createAudioNote(context));
      case NewShellItem.slides:
        unawaited(creates.createSlidesNote(context));
      case NewShellItem.flashcards:
        unawaited(creates.createFlashcards(context));
      case NewShellItem.kanban:
        unawaited(creates.createKanban(context));
      case NewShellItem.template:
        unawaited(rows.templates.createFromTemplate(context));
      case NewShellItem.captureWebPage:
        unawaited(capture.capture(context));
      case NewShellItem.folder:
        unawaited(creates.createFolder(context));
    }
  }
}
