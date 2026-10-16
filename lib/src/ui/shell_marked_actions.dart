/// What a desktop does to several tree rows marked together (#712): their
/// menu, a delete of them all with one Undo, and a move of them all into
/// one folder. One row at a time stays [ShellRowActions]'s.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tree_drag.dart';

/// The marked rows' actions, through the single row's own.
final class ShellMarkedActions {
  /// Acts through [rows], the shell's actions on one row.
  new(this.rows);

  /// The actions on one row: their guard, their callbacks, their moves.
  final ShellRowActions rows;

  /// The drop being carried out, or the last one: the next waits behind it.
  Future<void> _lastMove = Future<void>.value();

  /// The menu of [paths], at [anchor]: how many, then Move… and Delete.
  Future<void> menu(
    BuildContext context,
    List<String> paths,
    Rect anchor,
  ) async {
    final action = await showActionSheet<String>(
      context,
      anchor: anchor,
      title: AppStrings.treeMarkedCount(paths.length),
      items: (context) => [
        ListTile(
          key: const Key('marked-menu-move'),
          leading: const Icon(Icons.drive_folder_upload_outlined),
          title: Text('${AppStrings.actionMove}…'),
          onTap: () => Navigator.pop(context, 'move'),
        ),
        ListTile(
          key: const Key('marked-menu-delete'),
          leading: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(AppStrings.actionDelete),
          onTap: () => Navigator.pop(context, 'delete'),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (action) {
      case 'move':
        await move(context, paths);
      case 'delete':
        await delete(context, paths);
    }
  }

  /// Moves [paths] into one folder chosen from a dialog: no folder among
  /// them, nor one inside them, is offered.
  Future<void> move(BuildContext context, List<String> paths) async {
    final ops = rows.controller.ops;
    if (ops == null) return;
    final folders = await rows.controller.folders();
    if (!context.mounted) return;
    bool moving(String folder) =>
        paths.any((path) => folder == path || isUnder(path, folder));
    final target = await showFolderPicker(
      context,
      title: AppStrings.moveTitle(AppStrings.treeMarkedCount(paths.length)),
      subtitle: AppStrings.chooseDestination,
      confirmLabel: AppStrings.actionMove,
      allowRoot: true,
      folders: [
        for (final folder in folders)
          if (!moving(folder.path)) folder,
      ],
      ops: ops,
    );
    if (target == null || !context.mounted) return;
    await moveTo(context, paths, target);
  }

  /// Moves [paths] into [folder] — a drop's destination (#996), or the
  /// dialog's answer — each outermost path on its own: a row inside
  /// another marked folder goes with it.
  ///
  /// A drop made while another is still moving waits for it (#1012), so two
  /// never run over the same rows; the second then finds what the first
  /// took away and reports it as rows that did not move.
  Future<void> moveTo(
    BuildContext context,
    List<String> paths,
    String folder,
  ) async {
    final before = _lastMove;
    final done = Completer<void>();
    _lastMove = done.future;
    try {
      await before;
      if (!context.mounted) return;
      await _moveNow(context, paths, folder);
    } finally {
      done.complete();
    }
  }

  Future<void> _moveNow(
    BuildContext context,
    List<String> paths,
    String folder,
  ) async {
    final outermost = treeOutermost(paths);
    // One row is the row's own move, as ever: no report, and its guard's
    // message when it fails.
    if (outermost.length < 2) {
      for (final path in outermost) {
        await rows.moveTo(path, folder);
      }
      return;
    }
    var ran = false;
    var moved = 0;
    var failed = 0;
    await rows.guard(() async {
      ran = true;
      // Once for all of them: a move writes the links of other notes, on
      // disk, and an open note's buffer must be there first (#507).
      await rows.saveOpen();
      for (final path in outermost) {
        // A row that cannot move must not stop the others, nor be lost
        // among them: it is counted.
        try {
          await rows.moveSaved(path, folder);
          moved++;
        } on Object catch (error) {
          const AppLogger(name: 'shell')
              .error('could not move "$path": $error');
          failed++;
        }
      }
    });
    if (!context.mounted) return;
    // The guard was busy with another flow: nothing was tried.
    if (!ran) failed = outermost.length;
    final movedLine = AppStrings.treeMarkedCount(moved);
    final failedLine = AppStrings.treeMarkedCount(failed);
    final report = [
      if (moved > 0) '${AppStrings.actionMove} · $movedLine',
      if (failed > 0) '${AppStrings.shellActionFailed} · $failedLine',
    ];
    if (report.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(persist: false, content: Text(report.join('\n'))));
  }

  /// Deletes [paths]: into the trash at once, one Undo bringing them all
  /// back; for good only once asked. Their own notes (#717) stay: that
  /// question is one file's, not a selection's.
  Future<void> delete(BuildContext context, List<String> paths) async {
    final ops = rows.controller.ops;
    if (ops == null) return;
    final trash = await ops.trashEnabled;
    if (!context.mounted) return;
    if (!trash) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppStrings.actionDelete),
          content: Text(AppStrings.treeMarkedCount(paths.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.actionCancel),
            ),
            TextButton(
              key: const Key('marked-delete-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.actionDelete),
            ),
          ],
        ),
      );
      if (sure != true || !context.mounted) return;
    }
    final gone = <String>[];
    await rows.guard(() async {
      for (final path in treeOutermost(paths)) {
        await ops.delete(path);
        rows.onDeleted(path);
        gone.add(path);
      }
    });
    if (gone.isEmpty || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: false,
        content: Text(
          '${trash ? AppStrings.movedToTrash : AppStrings.deletedMessage}'
          ' · ${AppStrings.treeMarkedCount(gone.length)}',
        ),
        action: trash
            ? SnackBarAction(
                label: AppStrings.actionUndo,
                onPressed: () => unawaited(
                  rows.guard(() async {
                    for (final path in gone) {
                      final name = await rows.justDeleted(ops, path);
                      if (name == null) continue;
                      await ops.restoreTrash(name);
                      rows.onDeleted(path);
                    }
                  }),
                ),
              )
            : null,
      ),
    );
  }
}
