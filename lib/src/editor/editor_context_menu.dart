/// The editors' context menu (issue #174): the clipboard, then the same
/// formatting actions the toolbar has, then the extras (the spelling's
/// Add to dictionary) — three groups, set apart.
///
/// Both editors build it, so a selection can do the same things on both
/// surfaces and on both platforms. The toolbar stays; this is the second
/// way in, where the mouse already is.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/editor/context_menu_pages.dart';
import 'package:niman/src/editor/context_menu_row.dart';
import 'package:niman/src/editor/table_menu.dart';
import 'package:niman/src/editor/table_menu_sheet.dart';
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
/// On the desktop a vertical menu, each formatting entry with the
/// toolbar's icon and a divider between groups; on a phone the platform's
/// selection bar, whose overflow holds the formatting entries. Every
/// entry closes the menu through [onDismiss] before it runs, so a dialog
/// it opens (the heading level, the link) is not drawn under the menu.
final class EditorContextMenu extends StatelessWidget {
  /// Creates the menu.
  const new({
    required this.anchors,
    required this.clipboard,
    required this.onDismiss,
    this.formats = const [],
    this.extras = const [],
    this.table,
    super.key,
  });

  /// Where it opens.
  final TextSelectionToolbarAnchors anchors;

  /// Cut, copy, paste, select all — whichever apply.
  final List<ContextMenuButtonItem> clipboard;

  /// The formatting actions, in the toolbar's order.
  final List<FormatMenuEntry> formats;

  /// What follows the formatting (Add to dictionary).
  final List<ContextMenuButtonItem> extras;

  /// A table's rows and columns, when the menu opened on one of its cells
  /// (#261): after the clipboard, before the formatting.
  final TableMenu? table;

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
              group: (group, back) => _groupChildren(context, group, back),
            ),
          ),
        ),
      ],
    );
  }

  /// A table's submenu, in the menu's place: the way back, then its
  /// sections (#261). A flyout beside a menu that is itself a selection
  /// toolbar has nowhere steady to stand; the menu turning into its
  /// submenu does.
  List<Widget> _groupChildren(
    BuildContext context,
    TableMenuGroup group,
    VoidCallback back,
  ) {
    const divider = Divider(height: 9, indent: 8, endIndent: 8);
    return [
      ContextMenuRow(
        rowKey: Key('table-${group.id}-back'),
        icon: Icons.chevron_left,
        label: group.label,
        onPressed: back,
      ),
      for (final section in group.sections) ...[
        divider,
        for (final action in section) _tableRow(action),
      ],
    ];
  }

  Widget _tableRow(TableMenuAction action) {
    final pressed = action.onPressed;
    return ContextMenuRow(
      rowKey: Key('table-${action.id}'),
      icon: action.icon,
      label: action.label,
      onPressed: pressed == null ? null : () => _run(pressed),
    );
  }

  /// What the menu leaves free above and below it.
  static const double _screenMargin = 16;

  List<Widget> _desktopChildren(
    BuildContext context,
    void Function(TableMenuGroup group) open,
  ) {
    const divider = Divider(height: 9, indent: 8, endIndent: 8);
    final table = this.table;
    // Every row with its icon, the clipboard's too (0.0.8 test round):
    // one column of icons down the menu, the way the formatting reads.
    Widget plain(ContextMenuButtonItem item) => ContextMenuRow(
      rowKey: Key('context-${item.type.name}'),
      icon: _iconOf(item),
      label:
          item.label ??
          AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
      onPressed: item.onPressed ?? () {},
    );
    return [
      for (final item in clipboard) plain(item),
      if (table != null) ...[
        divider,
        for (final group in table.groups)
          ContextMenuRow(
            rowKey: Key('table-${group.id}'),
            icon: group.icon,
            label: group.label,
            trailing: Icons.chevron_right,
            onPressed: () => open(group),
          ),
        for (final action in table.actions) _tableRow(action),
      ],
      if (formats.isNotEmpty) divider,
      for (final (i, entry) in formats.indexed) ...[
        if (i > 0 && entry.item.group != formats[i - 1].item.group) divider,
        ContextMenuRow(
          rowKey: Key('context-${entry.item.id}'),
          icon: entry.item.icon,
          label: entry.item.label,
          active: entry.active,
          onPressed: () => _run(entry.onPressed),
        ),
      ],
      if (extras.isNotEmpty) ...[
        divider,
        for (final item in extras) plain(item),
      ],
    ];
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
    final table = this.table;
    final total =
        clipboard.length +
        (table == null ? 0 : table.groups.length + table.actions.length) +
        formats.length +
        extras.length;
    var index = 0;
    Widget button(Widget child, VoidCallback onPressed) =>
        TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(index++, total),
          onPressed: onPressed,
          child: child,
        );
    String label(ContextMenuButtonItem item) =>
        item.label ??
        AdaptiveTextSelectionToolbar.getButtonLabel(context, item);
    return [
      for (final item in clipboard) button(Text(label(item)), item.onPressed!),
      // A table's row and column open a sheet of their actions: the bar's
      // overflow is a list of words, with no room for a submenu.
      if (table != null) ...[
        for (final group in table.groups)
          button(
            Text('${group.label}…', key: Key('table-${group.id}')),
            () => showTableMenuSheet(context, group, onDismiss: onDismiss),
          ),
        for (final action in table.actions)
          if (action.onPressed case final pressed?)
            button(
              Text(action.label, key: Key('table-${action.id}')),
              () => _run(pressed),
            ),
      ],
      // The active state reads the way the toolbar's does: the format
      // that is on stands out.
      for (final entry in formats)
        button(
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
      for (final item in extras) button(Text(label(item)), item.onPressed!),
    ];
  }
}
