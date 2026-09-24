import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/core/theme_generator.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/palettes.dart';
import 'package:niman/src/ui/theme/theme_dialogs.dart';
import 'package:niman/src/ui/theme/theme_editor_screen.dart';
import 'package:niman/src/ui/theme/theme_row.dart';

/// The Themes area of the settings home (issue #269): how bright the app
/// is, and the theme it wears — the palettes the app ships, and the themes
/// the user made.
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

  /// The New theme row's key.
  static const Key newTheme = Key('theme-new-action');

  /// What a shipped palette reads as, in the list, the search and the
  /// dialog that starts a new theme from it.
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
      SettingsThemesScreen.builtinName(palette).toLowerCase(),
  };

  /// Every theme the page lists: the palettes the app ships, in their own
  /// order, then the user's own, by name.
  List<AppTheme> get _themes => [
    for (final palette in AppPalette.values) BuiltinAppTheme(palette),
    for (final theme in _custom) CustomAppTheme(theme),
  ];

  /// Asks for a new theme and stores it, worn.
  Future<void> _newTheme() async {
    final request = await showNewThemeDialog(
      context,
      sources: [
        for (final theme in _themes)
          (theme: theme, label: SettingsThemesScreen.themeName(theme)),
      ],
      takenNames: _takenNames,
    );
    if (request == null || !mounted) return;
    final from = request.from;
    await _save(
      from == null
          ? randomCustomTheme(id: newCustomThemeId(), name: request.name)
          : customThemeCopyOf(from, id: newCustomThemeId(), name: request.name),
    );
  }

  /// Copies [theme] into a theme of the user's own, named after it.
  Future<void> _duplicate(AppTheme theme) async {
    await _save(
      customThemeCopyOf(
        theme,
        id: newCustomThemeId(),
        name: uniqueThemeName(
          SettingsThemesScreen.themeName(theme),
          _takenNames,
        ),
      ),
    );
  }

  /// Stores [theme] and wears it: making one and copying one both end with
  /// the new theme in front of the user, where it can be looked at.
  Future<void> _save(CustomTheme theme) async {
    await widget.controller.saveCustomTheme(theme);
    await _setTheme(CustomAppTheme(theme));
    await _reload();
  }

  /// Asks for another name and stores it.
  Future<void> _rename(AppTheme theme) async {
    if (theme is! CustomAppTheme) return;
    final taken = _takenNames..remove(theme.theme.name.toLowerCase());
    final name = await showThemeNameDialog(
      context,
      title: AppStrings.actionRename,
      initial: theme.theme.name,
      takenNames: taken,
    );
    if (name == null || !mounted) return;
    await widget.controller.renameCustomTheme(theme.theme.id, name);
    await _reload();
  }

  /// Asks first, then deletes [theme]; the theme in use falls back to the
  /// app's own colors when the deleted one was it.
  Future<void> _delete(AppTheme theme) async {
    if (theme is! CustomAppTheme) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.actionDelete),
        content: Text(AppStrings.themeDeleteBody(theme.theme.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppStrings.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.controller.deleteCustomTheme(theme.theme.id);
    await _reload();
  }

  /// Opens the editor on [theme]; the app wears the draft while it is
  /// open, and the rows come back re-read whatever came of it.
  Future<void> _edit(AppTheme theme) async {
    if (theme is! CustomAppTheme) return;
    await Navigator.of(context).push(
      MaterialPageRoute<CustomTheme>(
        builder: (context) => ThemeEditorScreen(
          controller: widget.controller,
          theme: theme.theme,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _act(ThemeRowAction action, AppTheme theme) async {
    switch (action) {
      case ThemeRowAction.edit:
        await _edit(theme);
      case ThemeRowAction.duplicate:
        await _duplicate(theme);
      case ThemeRowAction.rename:
        await _rename(theme);
      case ThemeRowAction.delete:
        await _delete(theme);
    }
  }

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
          // for the tests and for the actions at its trailing edge.
          HighlightRow(
            key: SettingsKeys.theme,
            child: Column(
              children: [
                for (final theme in _themes)
                  ThemeRow(
                    key: SettingsKeys.themeRow(theme.id),
                    theme: theme,
                    label: SettingsThemesScreen.themeName(theme),
                    selected: theme == _theme,
                    onTap: () => unawaited(_setTheme(theme)),
                    onAction: (action) => unawaited(_act(action, theme)),
                  ),
                SettingsActionRow(
                  key: SettingsThemesScreen.newTheme,
                  title: AppStrings.themeNewTitle,
                  onTap: () => unawaited(_newTheme()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
