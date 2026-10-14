/// The metrics of a pointer's menus, defined once (#296).
///
/// A phone's menu rows are 48 px tall and set in the label style, because
/// a thumb has to hit them; a mouse needs a third of that room, and a
/// menu of thirteen entries that runs most of a screen tall is the phone's
/// shape drawn for the wrong device. On a pointer-dense theme (see
/// `pointerDense`) every menu in the app is the tree's own: 32 px rows, an
/// 18 px icon, a 10 px gap, the label in body text, and 4 px of air at
/// the menu's ends.
///
/// Two things carry it, so that a menu added tomorrow is compact without
/// anyone remembering:
///
///  * [pointerMenuTheme], applied to the app's theme: what Flutter reads
///    from a theme — a popup menu's padding and label style, a
///    `MenuAnchor`'s panel and its `MenuItemButton`s. A menu built from
///    those needs nothing else.
///  * The helpers here ([menuItem], [menuDivider], `MenuRow`, the
///    [MenuMetrics] on a theme): what no theme can say, because Flutter
///    takes it as a constructor argument — a `PopupMenuItem`'s height, a
///    `PopupMenuDivider`'s. `test/unit/menu_sources_test.dart` keeps the
///    raw widgets out of everywhere else.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/pointer_density.dart';

/// The row height a pointer's menus use (#296): the phone's 48 px items
/// run thirteen entries most of a screen tall, for a cursor that needs a
/// third of the room.
const double pointerDenseItemHeight = 32;

/// The divider between two groups of a pointer's menu: the phone's 16 px
/// of air between two rows a mouse reads in one look.
const double pointerDenseDividerHeight = 9;

/// The room a pointer's menu keeps above its first row and below its last.
const EdgeInsets pointerDenseMenuPadding = EdgeInsets.symmetric(vertical: 4);

/// What a menu measures on [ThemeData]: the pointer's compact metrics where
/// the theme is pointer-dense, the thumb's where it is not.
extension MenuMetrics on ThemeData {
  /// The height of one menu row.
  double get menuItemHeight =>
      pointerDense(this) ? pointerDenseItemHeight : kMinInteractiveDimension;

  /// The height of the divider between two groups of rows.
  double get menuDividerHeight =>
      pointerDense(this) ? pointerDenseDividerHeight : 16;

  /// The size of a row's icon.
  double get menuIconSize => pointerDense(this) ? 18 : 20;

  /// The room between a row's icon and its label.
  double get menuIconGap => pointerDense(this) ? 10 : 12;

  /// The room above and below a row's text where the row is a plain
  /// padded box rather than a `PopupMenuItem`: what takes a one-line row
  /// to [menuItemHeight] (a body line is 20 px tall).
  double get menuRowPadding => pointerDense(this) ? 6 : 10;

  /// The theme of a `ListTile` drawn inside a menu's panel: the compact
  /// row, the label in body text. Null on a thumb's theme, whose tiles
  /// keep their own size.
  ListTileThemeData? get menuListTileTheme {
    if (!pointerDense(this)) return null;
    return ListTileThemeData(
      minTileHeight: pointerDenseItemHeight,
      minVerticalPadding: menuRowPadding,
      minLeadingWidth: menuIconSize,
      horizontalTitleGap: menuIconGap,
      titleTextStyle: textTheme.bodyMedium,
      subtitleTextStyle: textTheme.bodySmall,
    );
  }
}

/// [theme] with the pointer's menus in it: the popup menus' padding and
/// label, the `MenuAnchor` panels' padding, the `MenuItemButton`s' height,
/// icon and label. A thumb's theme is returned as it came.
///
/// What a theme cannot say — the height of a `PopupMenuItem`, the height
/// of a `PopupMenuDivider` — is [menuItem] and [menuDivider]'s.
ThemeData pointerMenuTheme(ThemeData theme) {
  if (!pointerDense(theme)) return theme;
  final scheme = theme.colorScheme;
  final body = theme.textTheme.bodyMedium;
  return theme.copyWith(
    popupMenuTheme: theme.popupMenuTheme.copyWith(
      menuPadding: pointerDenseMenuPadding,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => body?.copyWith(
          color: states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.38)
              : scheme.onSurface,
        ),
      ),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        padding: WidgetStatePropertyAll(pointerDenseMenuPadding),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        // The density already takes 8 px off a menu button's 48; the
        // height is asked for outright, not by what is left after it.
        visualDensity: VisualDensity(
          horizontal: theme.visualDensity.horizontal,
        ),
        minimumSize: const WidgetStatePropertyAll(
          Size(64, pointerDenseItemHeight),
        ),
        iconSize: const WidgetStatePropertyAll(18),
        textStyle: WidgetStatePropertyAll(body),
      ),
    ),
  );
}

/// A popup menu's row at the height [context]'s theme gives menus: the
/// tree's 32 px on a pointer, Material's 48 on a thumb — or [height], for
/// a row that is not an entry, such as a group's heading.
PopupMenuItem<T> menuItem<T>(
  BuildContext context, {
  required Widget child,
  Key? key,
  T? value,
  bool enabled = true,
  VoidCallback? onTap,
  double? height,
}) => PopupMenuItem<T>(
  key: key,
  value: value,
  enabled: enabled,
  onTap: onTap,
  height: height ?? Theme.of(context).menuItemHeight,
  child: child,
);

/// A popup menu's divider at the height [context]'s theme gives menus.
PopupMenuDivider menuDivider(BuildContext context) =>
    PopupMenuDivider(height: Theme.of(context).menuDividerHeight);
