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

  /// A flashcard deck (frontmatter type: flashcard) in the current folder.
  flashcards,

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
    this.viewToggle,
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

  /// The list/grid pair (#727), when the pane can switch views.
  final Widget? viewToggle;

  /// Below this width the New button drops its label, keeping the plus
  /// and the arrow, so the footer fits with the view pair in it (#727).
  static const double _newLabelMinWidth = 260;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A pointer's menu is the tree's own (#296, #747): the footer's menus
    // run the dense rows where the tree's do.
    final dense = pointerDense(theme);
    // On a touch device (an Android tablet's wide shell, #849) the footer
    // is a thumb's: 56 px tall, every button its 48.
    final touch = thumbDense(theme);
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelled = constraints.maxWidth >= _newLabelMinWidth;
        // A narrow pane keeps the same controls on 32 px buttons, as the
        // mockup draws them, so the whole footer still fits (#727).
        final compact = IconButtonThemeData(
          style: labelled || touch
              ? null
              : IconButton.styleFrom(
                  minimumSize: const Size(32, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
        );
        final tools = <Widget>[
          syncButton,
          IconButton(
            key: const Key('open-trash'),
            tooltip: AppStrings.trashTitle,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => unawaited(openTrash(context, controller)),
          ),
          ?viewToggle,
          sortToggle,
        ];
        return Container(
          key: const Key('tree-footer'),
          height: touch ? 56 : 44,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: IconButtonTheme(
            data: compact,
            child: Row(
              children: [
                const SizedBox(width: 4),
                PopupMenuButton<NewShellItem>(
                  key: const Key('new-item-menu'),
                  tooltip: AppStrings.actionNew,
                  onSelected: onNewItem,
                  position: PopupMenuPosition.over,
                  menuPadding: dense ? pointerDenseMenuPadding : null,
                  // A desktop menu should appear, not perform (T-PP-22): the
                  // default 300 ms scale reads as skipped frames on this
                  // compositor, and 120 ms is a menu that is simply there.
                  popUpAnimationStyle: const AnimationStyle(
                    duration: Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                  ),
                  itemBuilder: (context) => [
                    // The one thing done every day (#7), set apart like the
                    // FAB's.
                    _item(
                      NewShellItem.journal,
                      Icons.today_outlined,
                      AppStrings.journalFabToday,
                      key: const Key('journal-today-action'),
                      dense: dense,
                    ),
                    PopupMenuDivider(
                      height: dense ? pointerDenseDividerHeight : 16,
                    ),
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
                      NewShellItem.flashcards,
                      Icons.style_outlined,
                      AppStrings.newFlashcardsTitle,
                      key: const Key('new-flashcards-action'),
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
                    PopupMenuDivider(
                      height: dense ? pointerDenseDividerHeight : 16,
                    ),
                    _item(
                      NewShellItem.folder,
                      Icons.create_new_folder_outlined,
                      AppStrings.newFolderTitle,
                      key: const Key('new-folder-action'),
                      dense: dense,
                    ),
                  ],
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: touch ? 15 : 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 18),
                        if (labelled) ...[
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.actionNew,
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
                if (touch)
                  // Forty-eight px buttons do not all fit the tree's
                  // narrowest width: the row scrolls from its end rather
                  // than shrink them or overflow.
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: tools,
                      ),
                    ),
                  )
                else ...[
                  const Spacer(),
                  ...tools,
                ],
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
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
///
/// Where the app bar has no room for the `TreeViewToggle` pair, passing
/// [view] and [onView] puts the view at the top of this same menu: a
/// **View** heading and the two choices (#727).
final class TreeSortToggle extends StatelessWidget {
  /// Creates the control; [sort] is the order in force.
  const new({
    required this.sort,
    required this.onSort,
    this.view,
    this.onView,
    super.key,
  });

  /// The order and direction in force.
  final TreeSort sort;

  /// Applies what the menu chose; the shell persists it.
  final ValueChanged<TreeSort> onSort;

  /// The view in force, when the menu carries the switch (#727).
  final TreeView? view;

  /// Applies the view chosen from the menu; null hides the group.
  final ValueChanged<TreeView>? onView;

  @override
  Widget build(BuildContext context) {
    final dense = pointerDense(Theme.of(context));
    final view = this.view;
    final onView = this.onView;
    return PopupMenuButton<Object>(
      key: const Key('toggle-sort'),
      // Its name, as a tooltip and to a screen reader: without one both
      // fall back to Flutter's generic "Show menu" (#785). The to-do
      // list's sort button already says it, in every language — and where
      // the menu carries the view pair too (#727) the name says both,
      // from the two words every locale already has: a third label for
      // the one control would be a string nothing else reads.
      tooltip: view == null
          ? AppStrings.todoSortTooltip
          : '${AppStrings.todoSortTooltip} · ${AppStrings.viewGroup}',
      menuPadding: dense ? pointerDenseMenuPadding : null,
      icon: AnimatedRotation(
        turns: sort.descending ? 0.5 : 0,
        duration: const Duration(milliseconds: 180),
        child: const Icon(Icons.unfold_more),
      ),
      onSelected: (choice) {
        if (choice is TreeSort) {
          onSort(choice);
        } else if (choice is TreeView) {
          onView?.call(choice);
        }
      },
      itemBuilder: (context) => [
        if (view != null && onView != null) ...[
          _menuHeading(context, AppStrings.viewGroup, dense: dense),
          _viewItem(
            key: const Key('view-list'),
            value: TreeView.list,
            checked: view == TreeView.list,
            label: AppStrings.viewList,
            dense: dense,
          ),
          _viewItem(
            key: const Key('view-grid'),
            value: TreeView.grid,
            checked: view == TreeView.grid,
            label: AppStrings.viewGrid,
            dense: dense,
          ),
          PopupMenuDivider(height: dense ? pointerDenseDividerHeight : 16),
        ],
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

  /// The small heading over a group, as the mockup's **View** (#727).
  PopupMenuItem<Object> _menuHeading(
    BuildContext context,
    String label, {
    required bool dense,
  }) {
    return PopupMenuItem<Object>(
      enabled: false,
      height: dense ? 24 : 28,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// One entry of the sort menu.
  ///
  /// A plain item with the check leading, not a `CheckedPopupMenuItem`: that
  /// one draws a [ListTile], and a tile keeps its own 48 px whatever height
  /// the item was given — the sort menu stood twice as tall as the create
  /// menu beside it because of it (#747). The check is said to a screen
  /// reader as the checked state the old item carried (#785).
  PopupMenuItem<Object> _sortItem({
    required Key key,
    required TreeSort value,
    required bool checked,
    required String label,
    required bool dense,
  }) {
    return _choiceItem(
      key: key,
      value: value,
      checked: checked,
      label: label,
      dense: dense,
    );
  }

  /// One entry of the view group at the top of the menu (#727).
  PopupMenuItem<Object> _viewItem({
    required Key key,
    required TreeView value,
    required bool checked,
    required String label,
    required bool dense,
  }) {
    return _choiceItem(
      key: key,
      value: value,
      checked: checked,
      label: label,
      dense: dense,
    );
  }

  /// A menu entry with the check leading; [value] is either a [TreeSort]
  /// or a [TreeView], and the two are told apart by the selection.
  PopupMenuItem<Object> _choiceItem({
    required Key key,
    required Object value,
    required bool checked,
    required String label,
    required bool dense,
  }) {
    return PopupMenuItem<Object>(
      key: key,
      value: value,
      height: dense ? pointerDenseItemHeight : kMinInteractiveDimension,
      child: Semantics(
        checked: checked,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The room of the check a chosen entry wears, taken either way
            // so the labels line up.
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
