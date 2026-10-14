/// A menu row's content: an icon, a label, and the line under it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_menu.dart';

/// What a menu entry shows: an icon, then the label, with an optional
/// [subtitle] under it.
///
/// The icon's size and its gap to the label come from the theme's menu
/// metrics (`MenuMetrics`), and the label takes the menu's own text style,
/// so a row is compact on a pointer and thumb-sized on a phone without its
/// caller saying which. [color] colours both the icon and the label: the
/// error colour of a destructive entry.
final class MenuRow extends StatelessWidget {
  /// Creates a row reading [label].
  const new({
    required this.label,
    this.icon,
    this.subtitle,
    this.color,
    this.trailing,
    super.key,
  });

  /// The entry's name.
  final String label;

  /// The icon before the label, or none.
  final IconData? icon;

  /// A smaller line under the label.
  final String? subtitle;

  /// The colour of the icon and the label; null keeps the menu's own.
  final Color? color;

  /// A widget at the row's end: a check.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    final name = Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: color == null ? null : TextStyle(color: color),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final icon?) ...[
          Icon(icon, size: theme.menuIconSize, color: color),
          SizedBox(width: theme.menuIconGap),
        ],
        Flexible(
          child: subtitle == null
              ? name
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    name,
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
        ?trailing,
      ],
    );
  }
}
