/// What a tree-row menu choice does (issue #100, split out of
/// `shell.dart`): rename, move, delete, pin, open outside the app, and
/// the dispatch that turns a chosen action's name into one of them.
///
/// The menu that offers them is `shell_row_menu.dart`, which knows
/// nothing about this file; this file knows nothing about how the menu
/// was presented. Between them sits the action's name.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/name_dialog.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/widget/widget_pin.dart';
import 'package:path/path.dart' as p;

/// Runs the tree row's actions against the open library.
final class ShellRowActions {
  /// Creates the actions; the flows are the shell's own, so a row menu
  /// and the FAB create a note exactly the same way.
  new({
    required this.controller,
    required this.guard,
    required this.creates,
    required this.templates,
    required this.selectedPath,
    required this.onMoved,
    required this.onDeleted,
    required this.onHistory,
  });

  /// The open library's session.
  final LibrarySession controller;

  /// Serializes mutating flows, reporting errors.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Creating a note or a folder in the pressed row's folder.
  final ShellCreateFlow creates;

  /// Creating a note from a template there.
  final ShellTemplateFlow templates;

  /// The selected row, for the actions invoked without one (the note
  /// menu's rename/move/delete).
  final String? Function() selectedPath;

  /// A rename or a move landed the row at a new path.
  final void Function(String path) onMoved;

  /// The row is gone; the shell drops the selection and closes the note.
  final VoidCallback onDeleted;

  /// Opens the note's history; the shell owns that screen.
  final Future<void> Function(String path) onHistory;

  /// Runs [action] for [note], creating in [here] where the action makes
  /// something new. A null action (the menu was dismissed) does nothing.
  Future<void> run(
    BuildContext context,
    String? action,
    Note note,
    String here,
  ) async {
    if (action == null) return;
    switch (action) {
      case 'note':
        await creates.createNote(context, parent: here);
      case 'template':
        await templates.createFromTemplate(context, parent: here);
      case 'folder':
        await creates.createFolder(context, parent: here);
      case 'quicknote':
        await guard(() async {
          await controller.ops!.setQuickNotePath(path: note.path);
          controller.notify();
        });
      case 'pin':
        await guard(() async {
          await controller.ops!.setPinned(note.path, pinned: !note.pinned);
        });
      case 'pinwidget':
        await pinToWidget(context, note);
      case 'history':
        await onHistory(note.path);
      case 'reveal':
        await openOutside(context, note, TreeContextAction.openInFileManager);
      case 'openexternal':
        await openOutside(context, note, TreeContextAction.openInDefaultApp);
      case 'rename':
        await rename(context, note.path);
      case 'move':
        await move(context, note.path);
      case 'delete':
        await delete(context, note.path);
    }
  }

  /// Hands the next placed note widget this note (issue 6).
  Future<void> pinToWidget(BuildContext context, Note note) async {
    final root = controller.root;
    if (root == null) return;
    final pinned = await saveWidgetPin(libraryPath: root, notePath: note.path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pinned ? AppStrings.pinnedForWidget : AppStrings.pinWidgetUnavailable,
        ),
      ),
    );
  }

  /// Renames [path], or the selected row when none is given.
  Future<void> rename(BuildContext context, [String? path]) async {
    final sel = path ?? selectedPath();
    if (sel == null) return;
    final name = await showNameDialog(
      context,
      title: AppStrings.actionRename,
      initial: p.basename(sel),
    );
    if (name == null) return;
    await guard(() async {
      final row = await controller.ops!.rename(sel, name);
      onMoved(row.path);
    });
  }

  /// Moves [path] into a folder chosen from a dialog.
  Future<void> move(BuildContext context, [String? path]) async {
    final sel = path ?? selectedPath();
    if (sel == null) return;
    final folders = await controller.folders();
    if (!context.mounted) return;
    // A folder cannot move into itself or its own subtree, so those
    // targets are not offered.
    final candidates = [
      for (final folder in folders)
        if (folder.path != sel && !isUnder(sel, folder.path)) folder,
    ];
    final target = await showFolderPicker(
      context,
      title: AppStrings.moveTitle(p.basename(sel)),
      subtitle: AppStrings.chooseDestination,
      confirmLabel: AppStrings.actionMove,
      allowRoot: true,
      folders: candidates,
      ops: controller.ops!,
    );
    if (target == null) return;
    await guard(() async {
      final row = await controller.ops!.move(sel, target);
      onMoved(row.path);
    });
  }

  /// Deletes [path] after asking, into the trash or for good depending on
  /// the library's trash setting — which is also what the question says.
  Future<void> delete(BuildContext context, [String? path]) async {
    final sel = path ?? selectedPath();
    if (sel == null) return;
    final ops = controller.ops;
    if (ops == null) return;
    final trash = await ops.trashEnabled;
    if (!context.mounted) return;
    final name = p.basename(sel);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.actionDelete),
        content: Text(
          trash
              ? AppStrings.deleteToTrashConfirm(name)
              : AppStrings.deleteForeverConfirm(name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await guard(() async {
      await ops.delete(sel);
      onDeleted();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              trash ? AppStrings.movedToTrash : AppStrings.deletedMessage,
            ),
          ),
        );
      }
    });
  }

  /// Shows the note in the file manager, or opens it in its default app
  /// (issue #76). A failure is reported where it happened.
  Future<void> openOutside(
    BuildContext context,
    Note note,
    TreeContextAction action,
  ) async {
    final root = controller.root;
    if (root == null) return;
    final outcome = await runTreeContextAction(p.join(root, note.path), action);
    if (!context.mounted || outcome == TreeContextOutcome.opened) return;
    final message = switch (outcome) {
      TreeContextOutcome.missing => AppStrings.openFileMissing,
      _ => AppStrings.openFileFailed,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
