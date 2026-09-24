import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/close_to_tray.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Appearance area of the settings home (issue #104): the app's own
/// look — language, brightness, palette, the interface text size, and
/// which engine draws a note.
final class SettingsAppearanceScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  /// What a palette reads as, in the dialog, on the row, and in the
  /// settings search.
  static String paletteName(AppPalette palette) => switch (palette) {
    AppPalette.system => AppStrings.themePaletteSystem,
    AppPalette.catppuccin => AppStrings.themePaletteCatppuccin,
    AppPalette.solarized => AppStrings.themePaletteSolarized,
    AppPalette.gruvbox => AppStrings.themePaletteGruvbox,
    AppPalette.niman => AppStrings.themePaletteNiman,
  };

  @override
  State<SettingsAppearanceScreen> createState() =>
      _SettingsAppearanceScreenState();
}

final class _SettingsAppearanceScreenState
    extends State<SettingsAppearanceScreen> {
  AppLanguage _language = AppLanguage.system;
  AppBrightness _themeBrightness = AppBrightness.system;
  AppPalette _themePalette = AppPalette.system;
  double _uiTextScale = defaultTextScale;
  bool _closeToTray = true;

  /// The tray is the desktops': elsewhere there is nothing to close into.
  static final bool _hasTray = Platform.isLinux || Platform.isWindows;

  /// Steps of 5% between [minTextScale] and [maxTextScale]: fine enough
  /// to land on a size that fits, coarse enough to be hit on a phone.
  static final int _textScaleSteps = ((maxTextScale - minTextScale) * 20)
      .round();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final controller = widget.controller;
    final language = await controller.language;
    final themeBrightness = await controller.themeBrightness;
    final themePalette = await controller.themePalette;
    final uiTextScale = await controller.uiTextScale;
    final closeToTray = await controller.closeToTray;
    if (!mounted) return;
    setState(() {
      _language = language;
      _themeBrightness = themeBrightness;
      _themePalette = themePalette;
      _uiTextScale = uiTextScale;
      _closeToTray = closeToTray;
    });
  }

  /// Persists the UI language and applies it immediately (T-L10N-04):
  /// the app root listens to [AppLanguages] and rebuilds every screen.
  Future<void> _setLanguage(AppLanguage language) async {
    await widget.controller.setLanguage(language);
    AppLanguages.choice = language;
    if (mounted) {
      setState(() => _language = language);
    }
  }

  /// Persists the brightness and applies it immediately (T-M6-05): the
  /// app root listens to [AppThemes] and rebuilds every screen.
  Future<void> _setThemeBrightness(AppBrightness brightness) async {
    await widget.controller.setThemeBrightness(brightness);
    AppThemes.brightness = brightness;
    if (mounted) {
      setState(() => _themeBrightness = brightness);
    }
  }

  /// Persists the palette and applies it immediately.
  Future<void> _setThemePalette(AppPalette palette) async {
    await widget.controller.setThemePalette(palette);
    AppThemes.palette = palette;
    if (mounted) {
      setState(() => _themePalette = palette);
    }
  }

  /// Asks which language the app speaks in.
  Future<void> _chooseLanguage() async {
    final language = await showSettingsChoice<AppLanguage>(
      context,
      dialogKey: const Key('language-dialog'),
      title: AppStrings.languageTitle,
      subtitle: AppStrings.languageSubtitle,
      current: _language,
      options: [
        SettingsOption(
          AppLanguage.system,
          AppStrings.languageName(AppLanguage.system),
        ),
        for (final language in AppLanguages.supported)
          SettingsOption(language, AppStrings.languageName(language)),
      ],
    );
    if (language != null) await _setLanguage(language);
  }

  /// Asks how bright the app should be.
  Future<void> _chooseThemeBrightness() async {
    final brightness = await showSettingsChoice<AppBrightness>(
      context,
      dialogKey: const Key('theme-brightness-dialog'),
      title: AppStrings.themeBrightnessTitle,
      subtitle: AppStrings.themeBrightnessSubtitle,
      current: _themeBrightness,
      options: [
        SettingsOption(AppBrightness.system, AppStrings.themeBrightnessSystem),
        SettingsOption(AppBrightness.day, AppStrings.themeBrightnessDay),
        SettingsOption(AppBrightness.night, AppStrings.themeBrightnessNight),
      ],
    );
    if (brightness != null) await _setThemeBrightness(brightness);
  }

  /// Asks which palette the app wears.
  Future<void> _chooseThemePalette() async {
    final palette = await showSettingsChoice<AppPalette>(
      context,
      dialogKey: const Key('theme-palette-dialog'),
      title: AppStrings.themePaletteTitle,
      subtitle: AppStrings.themePaletteSubtitle,
      current: _themePalette,
      options: [
        for (final palette in AppPalette.values)
          SettingsOption(
            palette,
            SettingsAppearanceScreen.paletteName(palette),
          ),
      ],
    );
    if (palette != null) await _setThemePalette(palette);
  }

  /// Asks how large the interface text should be.
  Future<void> _chooseUiTextScale() async {
    final scale = await showSettingsSlider(
      context,
      dialogKey: const Key('ui-text-scale-dialog'),
      sliderKey: const Key('ui-text-scale-slider'),
      title: AppStrings.uiTextScaleTitle,
      subtitle: AppStrings.uiTextScaleSubtitle,
      current: _uiTextScale,
      min: minTextScale,
      max: maxTextScale,
      divisions: _textScaleSteps,
      format: AppStrings.textScaleValue,
    );
    if (scale == null) return;
    await widget.controller.setUiTextScale(scale);
    if (mounted) setState(() => _uiTextScale = scale);
  }

  Future<void> _setCloseToTray({required bool enabled}) async {
    await widget.controller.setCloseToTray(enabled: enabled);
    CloseToTray.enabled.value = enabled;
    if (mounted) setState(() => _closeToTray = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsAreaShell(
      title: AppStrings.settingsSectionAppearance,
      controller: widget.controller,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          HighlightRow(
            key: SettingsKeys.language,
            child: SettingsValueRow(
              title: AppStrings.languageTitle,
              subtitle: AppStrings.languageSubtitle,
              value: AppStrings.languageName(_language),
              onTap: () => unawaited(_chooseLanguage()),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.brightness,
            child: SettingsValueRow(
              title: AppStrings.themeBrightnessTitle,
              subtitle: AppStrings.themeBrightnessSubtitle,
              value: switch (_themeBrightness) {
                AppBrightness.system => AppStrings.themeBrightnessSystem,
                AppBrightness.day => AppStrings.themeBrightnessDay,
                AppBrightness.night => AppStrings.themeBrightnessNight,
              },
              onTap: () => unawaited(_chooseThemeBrightness()),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.palette,
            child: SettingsValueRow(
              title: AppStrings.themePaletteTitle,
              subtitle: AppStrings.themePaletteSubtitle,
              value: SettingsAppearanceScreen.paletteName(_themePalette),
              onTap: () => unawaited(_chooseThemePalette()),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.uiTextScale,
            child: SettingsValueRow(
              title: AppStrings.uiTextScaleTitle,
              subtitle: AppStrings.uiTextScaleSubtitle,
              value: AppStrings.textScaleValue(_uiTextScale),
              onTap: () => unawaited(_chooseUiTextScale()),
            ),
          ),
          // The window's × (#209): the desktops only, where there is a
          // tray to hide into.
          if (_hasTray)
            HighlightRow(
              key: SettingsKeys.closeToTray,
              child: SettingsSwitchRow(
                title: AppStrings.closeToTrayTitle,
                description: AppStrings.closeToTraySubtitle,
                value: _closeToTray,
                onChanged: (value) =>
                    unawaited(_setCloseToTray(enabled: value)),
              ),
            ),
        ],
      ),
    );
  }
}
