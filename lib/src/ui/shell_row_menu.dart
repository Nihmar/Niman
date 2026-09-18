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
import 'package:niman/src/ui/file_icon.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/strings.dart';

/// One entry of the tree-row menu.
typedef RowMenuEntry = ({
  Key key,
  IconData icon,
  String label,
  String value,
  bool destructive,
});

/// The phone's long-press sheet (T-UI-05): the note actions, scoped to
/// the pressed row. Resolves to the chosen action, or null.
Future<String?> showRowMenuSheet(
  BuildContext context, {
  required Note note,
  required bool isQuickNote,
}) {
  return showActionSheet<String>(
    context,
    items: (context) {
      final theme = Theme.of(context);
      return [
        RowMenuHeader(note: note),
        for (final (index, group) in rowMenuGroups(
          note,
          isQuickNote: isQuickNote,
        ).indexed) ...[
          if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
          for (final entry in group)
            ListTile(
              key: entry.key,
              leading: Icon(entry.icon),
              title: Text(entry.label),
              iconColor: entry.destructive ? theme.colorScheme.error : null,
              textColor: entry.destructive ? theme.colorScheme.error : null,
              onTap: () => Navigator.pop(context, entry.value),
            ),
        ],
      ];
    },
  );
}

/// The desktop's right-click menu (T-PP-20): the same actions at the
/// cursor instead of in a sheet. Resolves to the chosen action, or null.
///
/// No header here: the menu opens on the row with the cursor still on
/// it, so there is nothing to say about which row it belongs to. The
/// sheet covers the tree, and has to say it.
Future<String?> showRowMenuAt(
  BuildContext context, {
  required Note note,
  required bool isQuickNote,
  required Offset position,
  bool offersNewTab = false,
}) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final theme = Theme.of(context);
  return showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: [
      for (final (index, group) in rowMenuGroups(
        note,
        isQuickNote: isQuickNote,
        offersNewTab: offersNewTab,
      ).indexed) ...[
        if (index > 0) const PopupMenuDivider(),
        for (final entry in group)
          PopupMenuItem(
            key: entry.key,
            value: entry.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  entry.icon,
                  size: 20,
                  color: entry.destructive ? theme.colorScheme.error : null,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    entry.label,
                    overflow: TextOverflow.ellipsis,
                    style: entry.destructive
                        ? TextStyle(color: theme.colorScheme.error)
                        : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
}

/// What the menu acts on: the row's icon, its name, and the folder it
/// sits in.
///
/// The sheet rises over the tree and the pressed row carries no mark, so
/// without this the menu is a list of verbs with no subject — and a long
/// press that landed one row off looks exactly like one that landed
/// right.
final class RowMenuHeader extends StatelessWidget {
  /// Creates the header for [note].
  const new({required this.note, super.key});

  /// The row the menu was opened from.
  final Note note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parent = parentOf(note.path);
    return Padding(
      key: const Key('row-menu-header'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Icon(
            note.isDir ? Icons.folder_outlined : fileIconFor(note.name),
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  parent.isEmpty ? AppStrings.libraryRoot : parent,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The entries for [note], in groups, shared by both presentations.
///
/// The groups say what the entries are *about* — what this note is, what
/// the file is, what to make near it — and leave the one that destroys
/// it alone at the bottom, where a thumb reaching for the row above it
/// does not land by accident.
///
/// Creating comes first on a folder and last on a note, because "here"
/// means two different things: inside the folder, which is most of why
/// its menu is opened at all, or merely beside the note, which is the
/// afterthought it looks like.
///
/// [offersNewTab] adds Open in new tab first, where tabs exist (#23).
List<List<RowMenuEntry>> rowMenuGroups(
  Note note, {
  required bool isQuickNote,
  bool offersNewTab = false,
}) {
  // "Here" is the folder the row is, or the folder the note sits in —
  // two different places, and on a note the word was doing the reader no
  // favours. The note's entries say which folder they mean.
  final create = <RowMenuEntry>[
    (
      key: const Key('menu-new-note'),
      icon: Icons.note_add_outlined,
      label: note.isDir ? AppStrings.newNoteHere : AppStrings.newNoteSameFolder,
      value: 'note',
      destructive: false,
    ),
    (
      key: const Key('menu-new-from-template'),
      icon: Icons.file_copy_outlined,
      label: note.isDir
          ? AppStrings.newFromTemplateHere
          : AppStrings.newFromTemplateSameFolder,
      value: 'template',
      destructive: false,
    ),
    if (note.isDir)
      (
        key: const Key('menu-new-folder'),
        icon: Icons.create_new_folder_outlined,
        label: AppStrings.newFolderHere,
        value: 'folder',
        destructive: false,
      ),
  ];

  // What this note is: the roles it can be given, and its own past.
  final roles = <RowMenuEntry>[
    if (!note.isDir)
      (
        key: const Key('menu-quick-note'),
        icon: isQuickNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
        label: isQuickNote
            ? AppStrings.currentQuickNote
            : AppStrings.setAsQuickNote,
        value: 'quicknote',
        destructive: false,
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
        destructive: false,
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
        destructive: false,
      ),
    if (!note.isDir)
      (
        key: const Key('menu-history'),
        icon: Icons.history,
        label: AppStrings.noteHistoryTitle,
        value: 'history',
        destructive: false,
      ),
  ];

  // What the file is: what it is called, where it lives, and — on the
  // desktop — the ways out of Niman, and a tab of its own.
  final file = <RowMenuEntry>[
    if (!note.isDir && offersNewTab)
      (
        key: const Key('menu-open-new-tab'),
        icon: Icons.tab_outlined,
        label: AppStrings.openInNewTab,
        value: 'newtab',
        destructive: false,
      ),
    if (!note.isDir && offersNewTab)
      (
        key: const Key('menu-open-beside'),
        icon: Icons.vertical_split_outlined,
        label: AppStrings.openBeside,
        value: 'beside',
        destructive: false,
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
        destructive: false,
      ),
      (
        key: const Key('menu-open-default-app'),
        icon: Icons.open_in_new,
        label: AppStrings.openInDefaultApp,
        value: 'openexternal',
        destructive: false,
      ),
    ],
    (
      key: const Key('menu-rename'),
      icon: Icons.edit_outlined,
      label: AppStrings.actionRename,
      value: 'rename',
      destructive: false,
    ),
    (
      key: const Key('menu-move'),
      icon: Icons.drive_folder_upload_outlined,
      label: AppStrings.actionMove,
      value: 'move',
      destructive: false,
    ),
  ];

  final destroy = <RowMenuEntry>[
    (
      key: const Key('menu-delete'),
      icon: Icons.delete_outline,
      label: AppStrings.actionDelete,
      value: 'delete',
      destructive: true,
    ),
  ];

  return [
    if (note.isDir) create,
    if (roles.isNotEmpty) roles,
    file,
    if (!note.isDir) create,
    destroy,
  ];
}
