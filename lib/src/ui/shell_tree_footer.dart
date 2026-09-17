/// The tree pane's footer bar (issue #100, split out of `shell.dart`):
/// the create menu on the left, and the tree's own actions on the right.
///
/// It is a widget rather than a method on the shell's `State` because it
/// reads none of that state: what it needs is the create choice to
/// report, the session the trash belongs to, and two buttons the shell
/// builds because they are the shell's — sync and sort.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/trash.dart';

/// What the tree footer's create menu offers.
enum NewShellItem {
  /// A plain Markdown note.
  note,

  /// A list note (frontmatter type: list) in the list folder.
  listNote,

  /// A voice note (frontmatter type: audio) in the current folder.
  audioNote,

  /// A note copied from a template.
  template,

  /// A folder.
  folder,
}

/// The bar under the note tree: **New**, then sync, trash and sort.
final class TreeFooterBar extends StatelessWidget {
  /// Creates the footer for [controller]'s tree.
  const new({
    required this.controller,
    required this.onNewItem,
    required this.syncButton,
    required this.sortToggle,
    super.key,
  });

  /// The open library, whose trash the bin button opens.
  final LibrarySession controller;

  /// Reports the chosen create action; the shell runs the flow.
  final void Function(NewShellItem item) onNewItem;

  /// The sync status button, hidden by itself while no destination is
  /// configured.
  final Widget syncButton;

  /// The tree's sort chevron.
  final Widget sortToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('tree-footer'),
      height: 44,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          PopupMenuButton<NewShellItem>(
            key: const Key('new-item-menu'),
            tooltip: AppStrings.actionNew,
            onSelected: onNewItem,
            position: PopupMenuPosition.over,
            // A desktop menu should appear, not perform (T-PP-22): the
            // default 300 ms scale reads as skipped frames on this
            // compositor, and 120 ms is a menu that is simply there.
            popUpAnimationStyle: const AnimationStyle(
              duration: Duration(milliseconds: 120),
              curve: Curves.easeOut,
            ),
            itemBuilder: (context) => [
              _item(
                NewShellItem.note,
                Icons.note_add_outlined,
                AppStrings.newNoteTitle,
                key: const Key('new-note-action'),
              ),
              _item(
                NewShellItem.listNote,
                Icons.checklist_outlined,
                AppStrings.newListNoteTitle,
                key: const Key('new-list-note-action'),
              ),
              _item(
                NewShellItem.audioNote,
                Icons.mic_outlined,
                AppStrings.newAudioNoteTitle,
                key: const Key('new-audio-note-action'),
              ),
              _item(
                NewShellItem.template,
                Icons.file_copy_outlined,
                AppStrings.newFromTemplateTitle,
                key: const Key('new-from-template-action'),
              ),
              const PopupMenuDivider(),
              _item(
                NewShellItem.folder,
                Icons.create_new_folder_outlined,
                AppStrings.newFolderTitle,
                key: const Key('new-folder-action'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 4),
                  Text(AppStrings.actionNew, style: theme.textTheme.labelLarge),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const Spacer(),
          syncButton,
          IconButton(
            key: const Key('open-trash'),
            tooltip: AppStrings.trashTitle,
            icon: const Icon(Icons.delete),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => TrashScreen(controller: controller),
              ),
            ),
          ),
          sortToggle,
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// One entry of the create menu.
  PopupMenuItem<NewShellItem> _item(
    NewShellItem item,
    IconData icon,
    String label, {
    Key? key,
  }) {
    return PopupMenuItem<NewShellItem>(
      key: key,
      value: item,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// The tree's sort chevron: name ascending, or name descending, with the
/// arrow turning to say which.
///
/// It sits in the footer and, on a phone, in the Files app bar; both show
/// the same control over the same setting.
final class TreeSortToggle extends StatelessWidget {
  /// Creates the toggle; [ascending] is the order in force.
  const new({required this.ascending, required this.onToggle, super.key});

  /// Whether the tree is sorted by name ascending.
  final bool ascending;

  /// Flips the order; the shell persists it.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('toggle-sort'),
      tooltip: ascending
          ? AppStrings.sortDescTooltip
          : AppStrings.sortAscTooltip,
      icon: AnimatedRotation(
        turns: ascending ? 0 : 0.5,
        duration: const Duration(milliseconds: 180),
        child: const Icon(Icons.unfold_more),
      ),
      onPressed: onToggle,
    );
  }
}
