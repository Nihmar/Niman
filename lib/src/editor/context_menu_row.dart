/// A row of the editors' desktop context menu.
library;

import 'package:flutter/material.dart';

/// One row of the desktop menu: an icon, a name, pressed while [active]
/// (a format that is on at the caret).
final class ContextMenuRow extends StatelessWidget {
  /// Creates a row.
  const new({
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.onPressed,
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

  /// Its icon.
  final IconData icon;

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
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: active ? scheme.primaryContainer : null,
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: !enabled
                    ? dim
                    : active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
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
                Icon(trailing, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
    if (hover == null) return row;
    return MouseRegion(onEnter: (_) => hover(), child: row);
  }
}
