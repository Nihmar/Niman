/// The tree pane's footer bar (issue #100, split out of `shell.dart`):
/// the create menu on the left, and the tree's own actions on the right.
///
/// It is a widget rather than a method on the shell's `State` because it
/// reads none of that state: what it needs is the create choice to
/// report, the session the trash belongs to, and two buttons the shell
/// builds because they are the shell's — sync and sort.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/trash.dart';

/// What the tree footer's create menu offers.
enum NewShellItem {
  /// Today's journal entry, made first when there is none (#7).
  journal,

  /// A plain Markdown note.
  note,

  /// A list note (frontmatter type: list) in the list folder.
  listNote,

  /// A voice note (frontmatter type: audio) in the current folder.
  audioNote,

  /// A slides note (frontmatter type: slides) in the current folder.
  slides,

  /// A note copied from a template.
  template,

  /// A web page captured as a note (#531).
  captureWebPage,

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
    // A pointer's menu is the tree's own (#296, #747): the footer's menus
    // run the dense rows where the tree's do.
    final dense = pointerDense(theme);
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
              // The one thing done every day (#7), set apart like the FAB's.
              _item(
                NewShellItem.journal,
                Icons.today_outlined,
                AppStrings.journalFabToday,
                key: const Key('journal-today-action'),
                dense: dense,
              ),
              PopupMenuDivider(height: dense ? pointerDenseDividerHeight : 16),
              _item(
                NewShellItem.note,
                Icons.note_add_outlined,
                AppStrings.newNoteTitle,
                key: const Key('new-note-action'),
                dense: dense,
              ),
              _item(
                NewShellItem.listNote,
                Icons.checklist_outlined,
                AppStrings.newListNoteTitle,
                key: const Key('new-list-note-action'),
                dense: dense,
              ),
              _item(
                NewShellItem.audioNote,
                Icons.mic_outlined,
                AppStrings.newAudioNoteTitle,
                key: const Key('new-audio-note-action'),
                dense: dense,
              ),
              _item(
                NewShellItem.slides,
                Icons.slideshow_outlined,
                AppStrings.newSlidesTitle,
                key: const Key('new-slides-action'),
                dense: dense,
              ),
              _item(
                NewShellItem.template,
                Icons.file_copy_outlined,
                AppStrings.newFromTemplateTitle,
                key: const Key('new-from-template-action'),
                dense: dense,
              ),
              _item(
                NewShellItem.captureWebPage,
                Icons.language_outlined,
                AppStrings.captureWebPage,
                key: const Key('capture-web-page-action'),
                dense: dense,
              ),
              PopupMenuDivider(height: dense ? pointerDenseDividerHeight : 16),
              _item(
                NewShellItem.folder,
                Icons.create_new_folder_outlined,
                AppStrings.newFolderTitle,
                key: const Key('new-folder-action'),
                dense: dense,
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
            icon: const Icon(Icons.delete_outline),
            onPressed: () => unawaited(openTrash(context, controller)),
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
    required bool dense,
    Key? key,
  }) {
    return PopupMenuItem<NewShellItem>(
      key: key,
      value: item,
      height: dense ? pointerDenseItemHeight : kMinInteractiveDimension,
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

/// The tree's sort control: the orders in a menu, with the chevron turned
/// to say the direction (#726).
///
/// It sits in the footer and, on a phone, in the Files app bar; both show
/// the same control over the same setting. Choosing an order keeps the
/// direction that is on — the two menu entries under the divider are how
/// it turns over.
final class TreeSortToggle extends StatelessWidget {
  /// Creates the control; [sort] is the order in force.
  const new({required this.sort, required this.onSort, super.key});

  /// The order and direction in force.
  final TreeSort sort;

  /// Applies what the menu chose; the shell persists it.
  final ValueChanged<TreeSort> onSort;

  @override
  Widget build(BuildContext context) {
    final dense = pointerDense(Theme.of(context));
    return PopupMenuButton<TreeSort>(
      key: const Key('toggle-sort'),
      icon: AnimatedRotation(
        turns: sort.descending ? 0.5 : 0,
        duration: const Duration(milliseconds: 180),
        child: const Icon(Icons.unfold_more),
      ),
      onSelected: onSort,
      itemBuilder: (context) => [
        for (final order in TreeOrder.values)
          _sortItem(
            key: Key('sort-${order.name}'),
            value: TreeSort.of(order, descending: sort.descending),
            checked: order == sort.order,
            label: sortOrderLabel(order),
            dense: dense,
          ),
        PopupMenuDivider(height: dense ? pointerDenseDividerHeight : 16),
        _sortItem(
          key: const Key('sort-ascending'),
          value: TreeSort.of(sort.order, descending: false),
          checked: !sort.descending,
          label: AppStrings.sortAscending,
          dense: dense,
        ),
        _sortItem(
          key: const Key('sort-descending'),
          value: TreeSort.of(sort.order, descending: true),
          checked: sort.descending,
          label: AppStrings.sortDescending,
          dense: dense,
        ),
      ],
    );
  }

  /// One entry of the sort menu.
  ///
  /// A plain item with the check leading, not a `CheckedPopupMenuItem`: that
  /// one draws a [ListTile], and a tile keeps its own 48 px whatever height
  /// the item was given — the sort menu stood twice as tall as the create
  /// menu beside it because of it (#747).
  PopupMenuItem<TreeSort> _sortItem({
    required Key key,
    required TreeSort value,
    required bool checked,
    required String label,
    required bool dense,
  }) {
    return PopupMenuItem<TreeSort>(
      key: key,
      value: value,
      height: dense ? pointerDenseItemHeight : kMinInteractiveDimension,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The room of the check a chosen order wears, taken either way so
          // the labels line up.
          SizedBox(
            width: 18,
            child: checked
                ? const Icon(Icons.check, size: 18)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Text(label, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// What an order reads as in the sort menu.
String sortOrderLabel(TreeOrder order) => switch (order) {
  // The frames of the Home whose fields these names are (#535): one word
  // each, in every language the app already speaks.
  TreeOrder.name => AppStrings.homeSearchName,
  TreeOrder.modified => AppStrings.sortLastModified,
  TreeOrder.created => AppStrings.sortDateCreated,
  TreeOrder.size => AppStrings.sortSize,
};
