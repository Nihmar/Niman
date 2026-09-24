// One theme in the Themes list (issue #269).
//
// A row is a choice and a place for the actions that grow out of it: the
// colors sit under the name so a theme reads as what it looks like, the
// mark on the left says which one is on, and the menu keeps its place on
// every row — a shipped theme simply offers less (it can be copied, not
// renamed away).

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/palettes.dart';

/// What a shipped palette reads as, in the list, the search and the dialog
/// that starts a new theme from it.
String builtinThemeLabel(AppPalette palette) => switch (palette) {
  AppPalette.system => AppStrings.themePaletteSystem,
  AppPalette.catppuccin => AppStrings.themePaletteCatppuccin,
  AppPalette.solarized => AppStrings.themePaletteSolarized,
  AppPalette.gruvbox => AppStrings.themePaletteGruvbox,
  AppPalette.niman => AppStrings.themePaletteNiman,
};

/// What [theme] reads as: a shipped palette's name, or the theme's own.
String themeLabel(AppTheme theme) => switch (theme) {
  BuiltinAppTheme(:final palette) => builtinThemeLabel(palette),
  CustomAppTheme(:final theme) => theme.name,
};

/// What a theme row's menu can do.
enum ThemeRowAction {
  /// Change the colors of a theme of the user's own.
  edit,

  /// Make a theme of the user's own out of this one.
  duplicate,

  /// Give a theme of the user's own another name.
  rename,

  /// Write a theme of the user's own out into a file.
  export,

  /// Take a theme of the user's own away.
  delete,
}

/// One theme the Themes page lists.
final class ThemeRow extends StatelessWidget {
  /// Creates the row for [theme].
  const new({
    required this.theme,
    required this.selected,
    required this.onTap,
    required this.onAction,
    super.key,
  });

  /// The theme itself.
  final AppTheme theme;

  /// Whether the app is wearing it.
  final bool selected;

  /// Wears it.
  final VoidCallback onTap;

  /// Runs one of the actions its menu offers.
  final ValueChanged<ThemeRowAction> onAction;

  /// Whether this is a theme the user made: the shipped palettes can be
  /// copied, and nothing else.
  bool get _mine => theme is CustomAppTheme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        // The same measure the settings rows keep, padding included.
        constraints: const BoxConstraints(maxWidth: settingsRowMaxWidth + 32),
        child: ListTile(
          onTap: onTap,
          selected: selected,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            semanticLabel: selected ? AppStrings.themesInUse : null,
          ),
          title: Text(themeLabel(theme)),
          subtitle: _ThemeSwatches(theme: theme),
          trailing: PopupMenuButton<ThemeRowAction>(
            key: Key('theme-menu-${theme.id}'),
            tooltip: AppStrings.themeMenuTooltip,
            icon: const Icon(Icons.more_vert),
            onSelected: onAction,
            itemBuilder: (context) => [
              if (_mine) ...[
                _item(
                  ThemeRowAction.edit,
                  Icons.palette_outlined,
                  AppStrings.themeEdit,
                ),
                _item(
                  ThemeRowAction.duplicate,
                  Icons.copy_all_outlined,
                  AppStrings.themeDuplicate,
                ),
                _item(
                  ThemeRowAction.rename,
                  Icons.edit_outlined,
                  AppStrings.actionRename,
                ),
                _item(
                  ThemeRowAction.export,
                  Icons.file_upload_outlined,
                  AppStrings.themeExport,
                ),
                _item(
                  ThemeRowAction.delete,
                  Icons.delete_outline,
                  AppStrings.actionDelete,
                ),
              ] else
                _item(
                  ThemeRowAction.duplicate,
                  Icons.copy_all_outlined,
                  AppStrings.themeDuplicate,
                ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<ThemeRowAction> _item(
    ThemeRowAction action,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      key: Key('theme-menu-${action.name}'),
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// A theme's colors at a glance: the ground, the rows raised above it, the
/// text on them, the accent that carries the interface and the error
/// color, resolved at the brightness on screen so the strip reads the way
/// choosing the theme would.
final class _ThemeSwatches extends StatelessWidget {
  const new({required this.theme});

  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final scheme = themeColors(theme, Theme.of(context).brightness).scheme;
    final colors = [
      scheme.surface,
      scheme.surfaceContainerHigh,
      scheme.onSurface,
      scheme.primary,
      scheme.error,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          for (final color in colors)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Container(
                width: 28,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
