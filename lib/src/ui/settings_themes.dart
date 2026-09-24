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
import 'package:niman/src/ui/theme/theme_actions.dart';
import 'package:niman/src/ui/theme/theme_files.dart';
import 'package:niman/src/ui/theme/theme_row.dart';

/// The Themes area of the settings home (issue #269): how bright the app
/// is, and the theme it wears — the palettes the app ships, and the themes
/// the user made.
///
/// One page owns the app's look, brightness included: the two choices
/// answer the same question, and splitting them across two screens made
/// the palette row the only way to see a theme's colors. What can be done
/// to a theme lives in [ThemeActions]; this is the list, the choice and
/// the marks.
final class SettingsThemesScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  ///
  /// The two file calls are the system's pickers, and a seam the tests
  /// hand their own through: importing and exporting are the one thing on
  /// this page that leaves the app.
  const new({
    required this.controller,
    this.highlight,
    this.saveThemeFile = saveThemeFileToDisk,
    this.pickThemeFile = pickThemeFileFromDisk,
    super.key,
  });

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  /// Writes an exported theme where the user says.
  final SaveThemeFile saveThemeFile;

  /// Reads an imported theme from where the user says.
  final PickThemeFile pickThemeFile;

  /// The New theme row's key.
  static const Key newTheme = Key('theme-new-action');

  /// The Import row's key.
  static const Key importTheme = Key('theme-import-action');

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

  /// Re-reads what an action may have changed: the themes themselves, and
  /// the one in use, which a rename or a delete changes with the rows.
  Future<void> _reload() async {
    final controller = widget.controller;
    final custom = await controller.customThemes();
    final theme = await controller.theme;
    if (!mounted) return;
    AppThemes.theme = theme;
    setState(() {
      _custom = custom;
      _theme = theme;
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

  /// The names the list already answers to, lowercased: the user's own,
  /// and the shipped ones, which read just as much like a theme's name.
  Set<String> get _takenNames => {
    for (final theme in _custom) theme.name.toLowerCase(),
    for (final palette in AppPalette.values)
      builtinThemeLabel(palette).toLowerCase(),
  };

  /// Every theme the page lists: the palettes the app ships, in their own
  /// order, then the user's own, by name.
  List<AppTheme> get _themes => [
    for (final palette in AppPalette.values) BuiltinAppTheme(palette),
    for (final theme in _custom) CustomAppTheme(theme),
  ];

  @override
  Widget build(BuildContext context) {
    // Built with the widget's own file calls on every build, so a caller
    // that hands in different ones gets them.
    final actions = ThemeActions(
      controller: widget.controller,
      reload: _reload,
      themes: () => _themes,
      takenNames: () => _takenNames,
      saveThemeFile: widget.saveThemeFile,
      pickThemeFile: widget.pickThemeFile,
    );
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
          // for the tests and for the actions at its trailing edge.
          HighlightRow(
            key: SettingsKeys.theme,
            child: Column(
              children: [
                for (final theme in _themes)
                  ThemeRow(
                    key: SettingsKeys.themeRow(theme.id),
                    theme: theme,
                    selected: theme == _theme,
                    onTap: () => unawaited(_setTheme(theme)),
                    onAction: (action) =>
                        unawaited(actions.act(context, action, theme)),
                  ),
                SettingsActionRow(
                  key: SettingsThemesScreen.newTheme,
                  title: AppStrings.themeNewTitle,
                  onTap: () => unawaited(actions.newTheme(context)),
                ),
                SettingsActionRow(
                  key: SettingsThemesScreen.importTheme,
                  title: AppStrings.themeImport,
                  onTap: () => unawaited(actions.import(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
