/// A desktop's text-selection menu, drawn as the app's other menus are.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/context_menu_flyout.dart';
import 'package:niman/src/editor/context_menu_row.dart';

/// The buttons of a selection toolbar — Copy, Select all, and what a view
/// adds — as a pointer's menu at [anchor].
///
/// Flutter's desktop toolbar sets its own button size and cannot be
/// themed, so the read view and the PDF viewer, whose selection menus come
/// from `AdaptiveTextSelectionToolbar`, would stand taller than every other
/// menu on a desktop. This draws the same buttons in the editors' context
/// menu panel: the compact rows of `pointer_menu.dart`, the clipboard ones
/// with their icons.
final class SelectionButtonsMenu extends StatelessWidget {
  /// Creates the menu for [items].
  const new({required this.anchor, required this.items, super.key});

  /// Where the menu opens, in the coordinates of the box it fills.
  final Offset anchor;

  /// The buttons, in order; one with no action is greyed out.
  final List<ContextMenuButtonItem> items;

  @override
  Widget build(BuildContext context) {
    return ContextMenuFlyout(
      anchor: anchor,
      main: (context, rows) => [
        for (final (i, item) in items.indexed)
          ContextMenuRow(
            rowKey: Key('selection-menu-$i'),
            icon: clipboardIconOf(item.type),
            label:
                item.label ??
                AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
            onPressed: item.onPressed,
            onHover: () => rows.open(null),
          ),
      ],
      group: (_) => const <Widget>[],
    );
  }
}
