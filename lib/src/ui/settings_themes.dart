import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/palettes.dart';

/// The Themes area of the settings home (issue #269): how bright the app
/// is, and the theme it wears — the palettes the app ships, and the
/// themes the user made.
///
/// One page owns the app's look, brightness included: the two choices
/// answer the same question, and splitting them across two screens made
/// the palette row the only way to see a theme's colors.
final class SettingsThemesScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  /// What a shipped palette reads as, in the list, the search and the
  /// dialog that explains it.
  static String builtinName(AppPalette palette) => switch (palette) {
    AppPalette.system => AppStrings.themePaletteSystem,
    AppPalette.catppuccin => AppStrings.themePaletteCatppuccin,
    AppPalette.solarized => AppStrings.themePaletteSolarized,
    AppPalette.gruvbox => AppStrings.themePaletteGruvbox,
    AppPalette.niman => AppStrings.themePaletteNiman,
  };

  /// What [theme] reads as: a shipped palette's name, or the theme's own.
  static String themeName(AppTheme theme) => switch (theme) {
    BuiltinAppTheme(:final palette) => builtinName(palette),
    CustomAppTheme(:final theme) => theme.name,
  };

  @override
  State<SettingsThemesScreen> createState() => _SettingsThemesScreenState();
}

final class _SettingsThemesScreenState extends State<SettingsThemesScreen> {
  AppBrightness _brightness = AppBrightness.system;
  AppTheme _theme = const BuiltinAppTheme(AppPalette.niman);
  List<CustomTheme> _custom = const <CustomTheme>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final brightness = await controller.themeBrightness;
    final theme = await controller.theme;
    final custom = await controller.customThemes();
    if (!mounted) return;
    setState(() {
      _brightness = brightness;
      _theme = theme;
      _custom = custom;
    });
  }

  /// Persists the brightness and applies it immediately (T-M6-05): the
  /// app root listens to [AppThemes] and rebuilds every screen.
  Future<void> _setBrightness(AppBrightness brightness) async {
    await widget.controller.setThemeBrightness(brightness);
    AppThemes.brightness = brightness;
    if (mounted) {
      setState(() => _brightness = brightness);
    }
  }

  /// Persists the theme and applies it immediately (issue #269).
  Future<void> _setTheme(AppTheme theme) async {
    await widget.controller.setTheme(theme);
    AppThemes.theme = theme;
    if (mounted) {
      setState(() => _theme = theme);
    }
  }

  /// Asks how bright the app should be.
  Future<void> _chooseBrightness() async {
    final brightness = await showSettingsChoice<AppBrightness>(
      context,
      dialogKey: const Key('theme-brightness-dialog'),
      title: AppStrings.themeBrightnessTitle,
      subtitle: AppStrings.themeBrightnessSubtitle,
      current: _brightness,
      options: [
        SettingsOption(AppBrightness.system, AppStrings.themeBrightnessSystem),
        SettingsOption(AppBrightness.day, AppStrings.themeBrightnessDay),
        SettingsOption(AppBrightness.night, AppStrings.themeBrightnessNight),
      ],
    );
    if (brightness != null) await _setBrightness(brightness);
  }

  /// Every theme the page lists: the palettes the app ships, in their own
  /// order, then the user's own, by name.
  List<AppTheme> get _themes => [
    for (final palette in AppPalette.values) BuiltinAppTheme(palette),
    for (final theme in _custom) CustomAppTheme(theme),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.settingsSectionThemes,
      controller: widget.controller,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          HighlightRow(
            key: SettingsKeys.brightness,
            child: SettingsValueRow(
              title: AppStrings.themeBrightnessTitle,
              subtitle: AppStrings.themeBrightnessSubtitle,
              value: switch (_brightness) {
                AppBrightness.system => AppStrings.themeBrightnessSystem,
                AppBrightness.day => AppStrings.themeBrightnessDay,
                AppBrightness.night => AppStrings.themeBrightnessNight,
              },
              onTap: () => unawaited(_chooseBrightness()),
            ),
          ),
          // The whole list is one searchable setting ("Theme"), so the
          // search lands on it and flashes it; each row keeps its own key
          // for the tests and, later, for the actions that grow from its
          // trailing edge (issue #269).
          HighlightRow(
            key: SettingsKeys.theme,
            child: Column(
              children: [
                for (final theme in _themes)
                  _ThemeRow(
                    key: SettingsKeys.themeRow(theme.id),
                    theme: theme,
                    selected: theme == _theme,
                    onTap: () => unawaited(_setTheme(theme)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One theme in the list: what it is called, its colors at a glance, and
/// the mark that says this is the one the app wears.
///
/// The mark keeps its place whether or not the theme is in use — outline
/// for the ones that are not, filled for the one that is — so nothing on
/// the row moves under a thumb already on it.
final class _ThemeRow extends StatelessWidget {
  /// Creates the row for [theme].
  const new({
    required this.theme,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// The theme this row is about.
  final AppTheme theme;

  /// Whether the app is wearing it.
  final bool selected;

  /// Selects it.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SettingsRowFrame(
      title: SettingsThemesScreen.themeName(theme),
      onTap: onTap,
      trailing: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
        semanticLabel: selected ? AppStrings.themesInUse : null,
      ),
      control: _ThemeSwatches(theme: theme),
    );
  }
}

/// A theme's colors at a glance: the ground, the rows raised above it,
/// the text on them, the accent that carries the interface and the error
/// color, resolved at the brightness on screen so the strip reads the way
/// choosing the theme would.
final class _ThemeSwatches extends StatelessWidget {
  /// Creates the strip for [theme].
  const new({required this.theme});

  /// The theme to show.
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
    return Row(
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
    );
  }
}
