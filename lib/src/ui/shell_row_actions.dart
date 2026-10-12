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
import 'package:niman/src/ui/carried_notes.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/name_dialog.dart';
import 'package:niman/src/ui/rename_check.dart';
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
    required this.saveOpen,
    required this.creates,
    required this.templates,
    required this.selectedPath,
    required this.onMoved,
    required this.onDeleted,
    required this.onHistory,
    required this.onOpenInNewTab,
    required this.onOpenBeside,
    required this.onExport,
    required this.onExportFolder,
    this.onRecognize,
    this.renameInPlace,
  });

  /// Starts a rename in place in the tree (#707): true when it did — a
  /// desktop with the tree on screen — false to ask in a dialog.
  final bool Function(String path)? renameInPlace;

  /// The open library's session.
  final LibrarySession controller;

  /// Serializes mutating flows, reporting errors.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Writes every open note's unsaved edits to disk (#507). A rename or a
  /// move rewrites the links other notes hold, on disk: an open note's
  /// buffer must be there first, or its next save would put the old links
  /// back. A note that will not save stops the rename with it.
  final Future<void> Function() saveOpen;

  /// Creating a note or a folder in the pressed row's folder.
  final ShellCreateFlow creates;

  /// Creating a note from a template there.
  final ShellTemplateFlow templates;

  /// The selected row, for the actions invoked without one (the note
  /// menu's rename/move/delete).
  final String? Function() selectedPath;

  /// A rename or a move took the row at `from` to `to` — a note, or a
  /// folder with everything under it.
  final void Function(String from, String to) onMoved;

  /// The row at `path` is gone; the shell drops the selection and closes
  /// the note, and the workspace every tab under it.
  final void Function(String path) onDeleted;

  /// Opens the note's history; the shell owns that screen.
  final Future<void> Function(String path) onHistory;

  /// Opens the note in a tab of its own (#23).
  final void Function(String path) onOpenInNewTab;

  /// Opens the note in the other pane, splitting first if need be.
  final void Function(String path) onOpenBeside;

  /// Writes the note at `path` out as a file (#24); a pointer's format
  /// menu grows from `anchor`, where the row's menu was.
  final Future<void> Function(String path, Rect? anchor) onExport;

  /// Writes the folder at `path` out as one zip (#24); a pointer's format
  /// menu grows from `anchor`, where the row's menu was.
  final Future<void> Function(String path, Rect? anchor) onExportFolder;

  /// Recognizes the text of the file at `path` (#594); null offers none.
  final void Function(String path)? onRecognize;

  /// Runs [action] for [note], creating in [here] where the action makes
  /// something new. A null action (the menu was dismissed) does nothing.
  /// [anchor] is where the row's menu opened, for a choice that asks more.
  Future<void> run(
    BuildContext context,
    String? action,
    Note note,
    String here, {
    Rect? anchor,
  }) async {
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
      case 'export':
        await onExport(note.path, anchor);
      case 'exportfolder':
        await onExportFolder(note.path, anchor);
      case 'recognize':
        onRecognize?.call(note.path);
      case 'newtab':
        onOpenInNewTab(note.path);
      case 'beside':
        onOpenBeside(note.path);
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
        // An action would keep it up until it is dismissed by hand.
        persist: false,
        content: Text(
          pinned ? AppStrings.pinnedForWidget : AppStrings.pinWidgetUnavailable,
        ),
      ),
    );
  }

  /// Renames [path], or the selected row when none is given: in place in
  /// the tree when [renameInPlace] takes it, in a dialog otherwise.
  Future<void> rename(BuildContext context, [String? path]) async {
    final sel = path ?? selectedPath();
    if (sel == null) return;
    if (renameInPlace?.call(sel) ?? false) return;
    final name = await showNameDialog(
      context,
      title: AppStrings.actionRename,
      initial: p.basename(sel),
    );
    if (name == null) return;
    await guard(() async {
      await saveOpen();
      final row = await controller.ops!.rename(sel, name);
      onMoved(sel, row.path);
    });
  }

  /// Renames [path] to [name] from the tree's field (#707): null once
  /// done, or why the name cannot be, the field left open to fix it.
  Future<String?> renameTo(String path, String name) async {
    final ops = controller.ops;
    if (ops == null) return null;
    final row = await ops.find(path);
    if (row == null) return null;
    final problem = await renameProblem(ops, path, name, isDir: row.isDir);
    if (problem != null) return problem;
    await guard(() async {
      await saveOpen();
      final renamed = await ops.rename(path, name);
      onMoved(path, renamed.path);
    });
    return null;
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
    await moveTo(sel, target);
  }

  /// Moves [path] into [target] — a folder's path, `''` for the root — as
  /// [move] does once its dialog answers: what a drop in the tree runs
  /// (#567).
  Future<void> moveTo(String path, String target) => guard(() async {
    await saveOpen();
    final row = await controller.ops!.move(path, target);
    onMoved(path, row.path);
  });

  /// Deletes [path], into the trash or for good depending on the
  /// library's trash setting. A move to the trash needs no question —
  /// the snackbar's Undo takes it back — while a permanent delete still
  /// asks (#712).
  ///
  /// Notes of its own — companions, an OCR sidecar — are the exception
  /// (#717): the question appears to offer taking them along, with the
  /// answer given last time as the emphasised action, and one Undo brings
  /// the file and its notes back together. The question appears only when
  /// there is something to carry, so a plain note still deletes without
  /// one.
  Future<void> delete(BuildContext context, [String? path]) async {
    final sel = path ?? selectedPath();
    if (sel == null) return;
    final ops = controller.ops;
    if (ops == null) return;
    final trash = await ops.trashEnabled;
    if (!context.mounted) return;
    final name = p.basename(sel);
    final isDir = (await ops.find(sel))?.isDir ?? false;
    var carry = await _notesAbout(sel, isDir: isDir);
    if (!context.mounted) return;
    // The last answer is the emphasised one, so the usual choice is one
    // Enter away (#717).
    final takeNotesDefault = await ops.deleteCarriesNotes;
    if (!context.mounted) return;
    if (carry.isNotEmpty || !trash) {
      final takeNotes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.actionDelete),
          content: Text(trash ? name : AppStrings.deleteForeverConfirm(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.actionCancel),
            ),
            if (carry.isEmpty)
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppStrings.actionDelete),
              )
            else ...[
              _deleteChoice(
                context,
                key: const Key('delete-carry-no'),
                // "Only the file" is not what a folder is (#775).
                label: isDir
                    ? AppStrings.actionDelete
                    : AppStrings.deleteFileOnly,
                primary: !takeNotesDefault,
                choice: false,
              ),
              _deleteChoice(
                context,
                key: const Key('delete-carry-yes'),
                label: AppStrings.deleteNotesToo(carry.length),
                primary: takeNotesDefault,
                choice: true,
              ),
            ],
          ],
        ),
      );
      if (takeNotes == null) return;
      if (carry.isNotEmpty && takeNotes != takeNotesDefault) {
        await ops.setDeleteCarriesNotes(enabled: takeNotes);
      }
      if (!takeNotes) carry = const [];
    }
    await guard(() async {
      await ops.delete(sel);
      onDeleted(sel);
      // Each note on its own (#775): one that will not go must not leave
      // the file and the notes before it in the trash with no Undo — the
      // notice comes first, and the failure is reported after it.
      final taken = <String>[];
      (Object, StackTrace)? failure;
      for (final note in carry) {
        try {
          await ops.delete(note);
          onDeleted(note);
          taken.add(note);
        } on Object catch (error, stack) {
          failure ??= (error, stack);
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // An action would keep it up until it is dismissed by hand.
            persist: false,
            content: Text(
              trash ? AppStrings.movedToTrash : AppStrings.deletedMessage,
            ),
            // The file sits in the trash: the notice offers the way
            // back (issue #131). A hard delete has nothing to restore.
            action: trash
                ? SnackBarAction(
                    label: AppStrings.actionUndo,
                    onPressed: () async {
                      await guard(() async {
                        for (final restore in [sel, ...taken]) {
                          final name = await _justDeleted(ops, restore);
                          if (name == null) continue;
                          await ops.restoreTrash(name);
                          onDeleted(restore);
                        }
                      });
                    },
                  )
                : null,
          ),
        );
      }
      if (failure case (final error, final stack)?) {
        Error.throwWithStackTrace(error, stack);
      }
    });
  }

  /// One of the delete question's two actions (#717): the remembered one
  /// is the filled button, waiting for Enter.
  Widget _deleteChoice(
    BuildContext context, {
    required Key key,
    required String label,
    required bool primary,
    required bool choice,
  }) {
    void pick() => Navigator.pop(context, choice);
    return primary
        ? FilledButton(
            key: key,
            autofocus: true,
            onPressed: pick,
            child: Text(label),
          )
        : TextButton(key: key, onPressed: pick, child: Text(label));
  }

  /// The notes about [sel] (#717), from the library's own sources.
  Future<List<String>> _notesAbout(String sel, {required bool isDir}) async {
    final ops = controller.ops;
    if (ops == null) return const [];
    final fields = await controller.fieldSource;
    final links = await controller.linkSource;
    if (fields == null || links == null) return const [];
    final carried = await CarriedNotes(
      ops: ops,
      fields: fields,
      links: links,
      root: controller.root,
      annotationsFolder: await ops.annotationsFolder,
    ).of(sel, isDir: isDir);
    return carried;
  }

  /// The trash name of [sel]'s freshest deletion: what Undo restores.
  ///
  /// Deleting twice in a row stacks two entries for the same original
  /// path, so the newest deletion wins.
  Future<String?> _justDeleted(NoteOperations ops, String sel) async {
    final matches = [
      for (final item in await ops.trashItems())
        if (item.originalPath == sel) item,
    ];
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return matches.first.name;
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
