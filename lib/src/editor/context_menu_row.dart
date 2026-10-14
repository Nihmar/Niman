/// A row of the editors' desktop context menu.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_menu.dart';

/// One row of the desktop menu: an icon, a name, pressed while [active]
/// (a format that is on at the caret).
final class ContextMenuRow extends StatelessWidget {
  /// Creates a row.
  const new({
    required this.rowKey,
    required this.label,
    required this.onPressed,
    this.icon,
    this.active = false,
    this.trailing,
    this.onHover,
    super.key,
  });

  /// Called as the pointer comes onto the row: a group's row opens its
  /// submenu, any other closes the one open.
  final VoidCallback? onHover;

  /// What tests find the row by.
  final Key rowKey;

  /// Its icon; none leaves its room, so a menu of some rows with icons
  /// and some without keeps its labels in one column.
  final IconData? icon;

  /// Its name.
  final String label;

  /// What the row does; null greys it out (an action that does not apply).
  final VoidCallback? onPressed;

  /// Whether its format is on at the caret.
  final bool active;

  /// An icon at the row's end: the arrow of an entry opening a submenu.
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null;
    final dim = scheme.onSurface.withValues(alpha: 0.38);
    final trailing = this.trailing;
    final hover = onHover;
    final row = Semantics(
      toggled: active,
      enabled: enabled,
      child: InkWell(
        key: rowKey,
        onTap: onPressed,
        canRequestFocus: false,
        child: Container(
          height: pointerDenseItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: active ? scheme.primaryContainer : null,
          child: Row(
            children: [
              if (icon case final icon?)
                Icon(
                  icon,
                  size: theme.menuIconSize,
                  color: !enabled
                      ? dim
                      : active
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                )
              else
                SizedBox.square(dimension: theme.menuIconSize),
              SizedBox(width: theme.menuIconGap),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: !enabled
                        ? dim
                        : active
                        ? scheme.onPrimaryContainer
                        : null,
                  ),
                ),
              ),
              if (trailing != null)
                Icon(
                  trailing,
                  size: theme.menuIconSize,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
    if (hover == null) return row;
    return MouseRegion(onEnter: (_) => hover(), child: row);
  }
}

/// The icon a clipboard button of the selection toolbar wears, or null for
/// a button that is not one of the four.
IconData? clipboardIconOf(ContextMenuButtonType type) => switch (type) {
  ContextMenuButtonType.cut => Icons.content_cut,
  ContextMenuButtonType.copy => Icons.content_copy,
  ContextMenuButtonType.paste => Icons.content_paste,
  ContextMenuButtonType.selectAll => Icons.select_all,
  _ => null,
};
