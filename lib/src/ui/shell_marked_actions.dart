/// What a desktop does to several tree rows marked together (#712): their
/// menu, a delete of them all with one Undo, and a move of them all into
/// one folder. One row at a time stays [ShellRowActions]'s.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/folder_picker.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/strings.dart';

/// The marked rows' actions, through the single row's own.
final class ShellMarkedActions {
  /// Acts through [rows], the shell's actions on one row.
  const new(this.rows);

  /// The actions on one row: their guard, their callbacks, their moves.
  final ShellRowActions rows;

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
    if (target == null) return;
    // A row inside another marked folder goes with it.
    for (final path in _outermost(paths)) {
      await rows.moveTo(path, target);
    }
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
      for (final path in _outermost(paths)) {
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

  /// [paths] without the ones inside another of them: a folder takes what
  /// it holds along.
  static List<String> _outermost(List<String> paths) => [
    for (final path in paths)
      if (!paths.any((other) => other != path && isUnder(other, path))) path,
  ];
}
