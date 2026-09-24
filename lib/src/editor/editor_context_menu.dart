/// The editors' context menu (issue #174): the clipboard, then the same
/// formatting actions the toolbar has, then the extras (the spelling's
/// Add to dictionary) — three groups, set apart.
///
/// The unified surface groups it by what the writer is doing instead
/// (#260), as Obsidian does: the word's spelling, the table's cell, the
/// links, Format ›, Paragraph › and Insert › as submenus, and the
/// clipboard last.
///
/// Both editors build it, so a selection can do the same things on both
/// surfaces and on both platforms. The toolbar stays; this is the second
/// way in, where the mouse already is.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/context_menu_pages.dart';
import 'package:niman/src/editor/context_menu_row.dart';
import 'package:niman/src/editor/menu_group_sheet.dart';
import 'package:niman/src/editor/toolbar_item.dart';

/// One formatting action for the menu: the toolbar's [item], what it
/// does, and whether its format is on at the caret.
@immutable
final class FormatMenuEntry {
  /// The entry for [item].
  const new({required this.item, required this.onPressed, this.active = false});

  /// The toolbar button it mirrors: its icon, its name, its group.
  final ToolbarItem item;

  /// The toolbar's own action.
  final VoidCallback onPressed;

  /// Whether the format is on at the caret, as the toolbar shows it.
  final bool active;
}

/// Builds an editor's [FormatMenuEntry]s at the moment the menu opens.
typedef FormatMenuBuilder = List<FormatMenuEntry> Function();

/// The context menu at [anchors].
///
/// On the desktop a vertical menu, each entry with its icon and a divider
/// between groups, a submenu opening in the menu's place; on a phone the
/// platform's selection bar, whose overflow holds the entries and whose
/// submenus open as sheets. Every entry closes the menu through
/// [onDismiss] before it runs, so a dialog it opens (the heading level,
/// the link) is not drawn under the menu.
final class EditorContextMenu extends StatelessWidget {
  /// Creates the menu.
  const new({
    required this.anchors,
    required this.clipboard,
    required this.onDismiss,
    this.formats = const [],
    this.extras = const [],
    this.table,
    this.structure,
    super.key,
  });

  /// Where it opens.
  final TextSelectionToolbarAnchors anchors;

  /// Cut, copy, paste, select all. One with no action is greyed out,
  /// kept in its place so nothing moves under the pointer.
  final List<ContextMenuButtonItem> clipboard;

  /// The formatting actions, in the toolbar's order — the flat menu's.
  final List<FormatMenuEntry> formats;

  /// The spelling's entries (suggestions, Add to dictionary).
  final List<ContextMenuButtonItem> extras;

  /// A table's rows and columns, when the menu opened on one of its cells
  /// (#261).
  final ContextMenuPart? table;

  /// The menu grouped by what the writer is doing (#260): the links, then
  /// Format, Paragraph and Insert. With it the spelling and the table come
  /// first and the clipboard last, and [formats] is not shown.
  final ContextMenuPart? structure;

  /// Closes the menu.
  final VoidCallback onDismiss;

  /// Whether this platform's menu is the phone's selection bar.
  static bool get _mobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void _run(VoidCallback action) {
    onDismiss();
    action();
  }

  @override
  Widget build(BuildContext context) {
    if (_mobile) {
      return AdaptiveTextSelectionToolbar(
        anchors: anchors,
        children: _mobileChildren(context),
      );
    }
    // All of the toolbar's buttons make a tall menu: on a short window it
    // keeps to the window and scrolls, rather than running off its foot.
    final room = MediaQuery.sizeOf(context).height - 2 * _screenMargin;
    return AdaptiveTextSelectionToolbar(
      anchors: anchors,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: room < 0 ? 0 : room),
          child: SingleChildScrollView(
            child: ContextMenuPages(
              main: _desktopChildren,
              group: _groupChildren,
            ),
          ),
        ),
      ],
    );
  }

  static const Divider _divider = Divider(height: 9, indent: 8, endIndent: 8);

  /// A submenu, in the menu's place: the way back, then its sections. A
  /// flyout beside a menu that is itself a selection toolbar has nowhere
  /// steady to stand; the menu turning into its submenu does.
  List<Widget> _groupChildren(ContextMenuGroup group, VoidCallback back) => [
    ContextMenuRow(
      rowKey: Key('${group.id}-back'),
      icon: Icons.chevron_left,
      label: group.label,
      onPressed: back,
    ),
    for (final section in group.sections) ...[
      _divider,
      for (final action in section) _actionRow(action),
    ],
  ];

  Widget _actionRow(ContextMenuAction action) {
    final pressed = action.onPressed;
    return ContextMenuRow(
      rowKey: Key(action.id),
      icon: action.icon,
      label: action.label,
      active: action.active,
      onPressed: pressed == null ? null : () => _run(pressed),
    );
  }

  /// What the menu leaves free above and below it.
  static const double _screenMargin = 16;

  List<Widget> _desktopChildren(
    BuildContext context,
    void Function(ContextMenuGroup group) open,
  ) {
    // Every row with its icon, the clipboard's too (0.0.8 test round):
    // one column of icons down the menu, the way the formatting reads.
    Widget plain(ContextMenuButtonItem item) => ContextMenuRow(
      rowKey: Key('context-${item.type.name}'),
      icon: _iconOf(item),
      label:
          item.label ??
          AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
      onPressed: item.onPressed,
    );
    Widget row(ContextMenuItem item) => switch (item) {
      ContextMenuAction() => _actionRow(item),
      ContextMenuGroup() => ContextMenuRow(
        rowKey: Key(item.id),
        icon: item.icon,
        label: item.label,
        trailing: Icons.chevron_right,
        onPressed: () => open(item),
      ),
    };
    List<List<Widget>> sections(ContextMenuPart? part) => [
      for (final section in part ?? const <List<ContextMenuItem>>[])
        if (section.isNotEmpty) [for (final item in section) row(item)],
    ];
    final formatRows = <List<Widget>>[];
    for (final (i, entry) in formats.indexed) {
      if (i == 0 || entry.item.group != formats[i - 1].item.group) {
        formatRows.add(<Widget>[]);
      }
      formatRows.last.add(
        ContextMenuRow(
          rowKey: Key('context-${entry.item.id}'),
          icon: entry.item.icon,
          label: entry.item.label,
          active: entry.active,
          onPressed: () => _run(entry.onPressed),
        ),
      );
    }
    final clipboardRows = [for (final item in clipboard) plain(item)];
    final extraRows = [for (final item in extras) plain(item)];
    final blocks = structure == null
        ? <List<Widget>>[
            clipboardRows,
            ...sections(table),
            ...formatRows,
            extraRows,
          ]
        : <List<Widget>>[
            extraRows,
            ...sections(table),
            ...sections(structure),
            clipboardRows,
          ];
    final children = <Widget>[];
    for (final block in blocks) {
      if (block.isEmpty) continue;
      if (children.isNotEmpty) children.add(_divider);
      children.addAll(block);
    }
    return children;
  }

  /// The clipboard's icons; anything else (Add to dictionary) is a word
  /// to keep.
  static IconData _iconOf(ContextMenuButtonItem item) => switch (item.type) {
    ContextMenuButtonType.cut => Icons.content_cut,
    ContextMenuButtonType.copy => Icons.content_copy,
    ContextMenuButtonType.paste => Icons.content_paste,
    ContextMenuButtonType.selectAll => Icons.select_all,
    _ => Icons.spellcheck,
  };

  List<Widget> _mobileChildren(BuildContext context) {
    final theme = Theme.of(context);
    String label(ContextMenuButtonItem item) =>
        item.label ??
        AdaptiveTextSelectionToolbar.getButtonLabel(context, item);
    // The bar has no room for a greyed-out word: what cannot run is left
    // out on a phone.
    final entries = <(Widget, VoidCallback)>[
      for (final item in clipboard)
        if (item.onPressed case final pressed?) (Text(label(item)), pressed),
      if (structure == null) ...[
        for (final part in [table])
          for (final section in part ?? const <List<ContextMenuItem>>[])
            for (final item in section) ?_mobileEntry(context, item),
        // The active state reads the way the toolbar's does: the format
        // that is on stands out.
        for (final entry in formats)
          (
            Text(
              entry.item.label,
              style: entry.active
                  ? TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            () => _run(entry.onPressed),
          ),
        for (final item in extras)
          if (item.onPressed case final pressed?) (Text(label(item)), pressed),
      ] else ...[
        for (final item in extras)
          if (item.onPressed case final pressed?) (Text(label(item)), pressed),
        for (final part in [table, structure])
          for (final section in part ?? const <List<ContextMenuItem>>[])
            for (final item in section) ?_mobileEntry(context, item),
      ],
    ];
    return [
      for (final (i, (child, onPressed)) in entries.indexed)
        TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(i, entries.length),
          onPressed: onPressed,
          child: child,
        ),
    ];
  }

  /// [item] on the phone's bar: an action as its word, a group as its word
  /// and an ellipsis, opening a sheet of its actions — the bar's overflow
  /// is a list of words, with no room for a submenu. Null for an action
  /// that cannot run.
  (Widget, VoidCallback)? _mobileEntry(
    BuildContext context,
    ContextMenuItem item,
  ) => switch (item) {
    ContextMenuAction(:final onPressed?) => (
      Text(item.label, key: Key(item.id)),
      () => _run(onPressed),
    ),
    ContextMenuAction() => null,
    ContextMenuGroup() => (
      Text('${item.label}…', key: Key(item.id)),
      () => showMenuGroupSheet(context, item, onDismiss: onDismiss),
    ),
  };
}
