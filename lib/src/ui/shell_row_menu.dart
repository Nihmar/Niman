/// The tree row's context menu (issue #100, split out of `shell.dart`):
/// what a long press on a phone and a right click on the desktop offer
/// for one row, and nothing about what the choice then does.
///
/// The two presentations read one list of entries, which is the point:
/// the sheet and the cursor menu cannot drift apart. Each resolves to
/// the chosen action's name, or null — the shell runs it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/strings.dart';

/// One entry of the tree-row menu.
typedef RowMenuEntry = ({Key key, IconData icon, String label, String value});

/// The phone's long-press sheet (T-UI-05): the note actions, scoped to
/// the pressed row. Resolves to the chosen action, or null.
Future<String?> showRowMenuSheet(
  BuildContext context, {
  required Note note,
  required bool isQuickNote,
}) {
  return showActionSheet<String>(
    context,
    items: (context) => [
      for (final entry in rowMenuEntries(note, isQuickNote: isQuickNote))
        ListTile(
          key: entry.key,
          leading: Icon(entry.icon),
          title: Text(entry.label),
          onTap: () => Navigator.pop(context, entry.value),
        ),
    ],
  );
}

/// The desktop's right-click menu (T-PP-20): the same actions at the
/// cursor instead of in a sheet. Resolves to the chosen action, or null.
Future<String?> showRowMenuAt(
  BuildContext context, {
  required Note note,
  required bool isQuickNote,
  required Offset position,
}) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      for (final entry in rowMenuEntries(note, isQuickNote: isQuickNote))
        PopupMenuItem(
          key: entry.key,
          value: entry.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(entry.icon, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(entry.label, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
    ],
  );
}

/// The entries for [note], shared by both presentations.
List<RowMenuEntry> rowMenuEntries(Note note, {required bool isQuickNote}) {
  return [
    (
      key: const Key('menu-new-note'),
      icon: Icons.note_add_outlined,
      label: AppStrings.newNoteHere,
      value: 'note',
    ),
    (
      key: const Key('menu-new-from-template'),
      icon: Icons.file_copy_outlined,
      label: AppStrings.newFromTemplateHere,
      value: 'template',
    ),
    if (note.isDir)
      (
        key: const Key('menu-new-folder'),
        icon: Icons.create_new_folder_outlined,
        label: AppStrings.newFolderHere,
        value: 'folder',
      ),
    if (!note.isDir)
      (
        key: const Key('menu-quick-note'),
        icon: isQuickNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
        label: isQuickNote
            ? AppStrings.currentQuickNote
            : AppStrings.setAsQuickNote,
        value: 'quicknote',
      ),
    // Any note, folders excluded: the next placed note widget adopts
    // the pin (issue 6). Shown everywhere; off Android the pin just
    // reports itself unavailable.
    if (!note.isDir)
      (
        key: const Key('menu-pin-widget'),
        icon: Icons.widgets_outlined,
        label: AppStrings.pinToWidget,
        value: 'pinwidget',
      ),
    // Markdown only: the pin is a frontmatter key, and a
    // `todo.txt` has no frontmatter to put it in. An already
    // pinned row keeps the entry whatever it is, so a pin
    // written before this rule can still be taken back off.
    if (!note.isDir && (isMarkdownNote(note.name) || note.pinned))
      (
        key: const Key('menu-pin'),
        icon: note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
        label: note.pinned ? AppStrings.actionUnpin : AppStrings.actionPin,
        value: 'pin',
      ),
    if (!note.isDir)
      (
        key: const Key('menu-history'),
        icon: Icons.history,
        label: AppStrings.noteHistoryTitle,
        value: 'history',
      ),
    // A note is also a file (issue #76). Desktop only: Android has no
    // file manager to select a path in, so the entries stay off there
    // rather than being shown and then failing.
    if (!note.isDir && supportsTreeContextActions) ...[
      (
        key: const Key('menu-open-file-manager'),
        icon: Icons.folder_open_outlined,
        label: AppStrings.openInFileManager,
        value: 'reveal',
      ),
      (
        key: const Key('menu-open-default-app'),
        icon: Icons.open_in_new,
        label: AppStrings.openInDefaultApp,
        value: 'openexternal',
      ),
    ],
    (
      key: const Key('menu-rename'),
      icon: Icons.edit_outlined,
      label: AppStrings.actionRename,
      value: 'rename',
    ),
    (
      key: const Key('menu-move'),
      icon: Icons.drive_folder_upload_outlined,
      label: AppStrings.actionMove,
      value: 'move',
    ),
    (
      key: const Key('menu-delete'),
      icon: Icons.delete_outline,
      label: AppStrings.actionDelete,
      value: 'delete',
    ),
  ];
}
