import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Appearance area of the settings home (issue #104): the app's own
/// look — language, brightness, palette, the interface text size, and
/// the split width where the panes split.
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
  double _splitRatio = defaultSplitRatio;
  bool _splitLoaded = false;
  PreviewLayoutMode _previewMode = PreviewLayoutMode.auto;
  EditorKind _editorKind = EditorKind.source;
  bool _previewEnabled = true;

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
    final splitRatio = await controller.splitRatio;
    final previewMode = await controller.previewMode;
    final editorKind = await controller.editorKind;
    final previewEnabled = await controller.previewEnabled;
    if (!mounted) return;
    setState(() {
      _language = language;
      _themeBrightness = themeBrightness;
      _themePalette = themePalette;
      _uiTextScale = uiTextScale;
      _splitRatio = splitRatio;
      _splitLoaded = true;
      _previewMode = previewMode;
      _editorKind = editorKind;
      _previewEnabled = previewEnabled;
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

  Future<void> _setSplitRatio(double ratio) async {
    final controller = widget.controller;
    await controller.setSplitRatio(ratio);
    controller.notify();
    if (mounted) {
      setState(() => _splitRatio = ratio);
    }
  }

  Future<void> _chooseSplitRatio() async {
    final ratio = await showSettingsSlider(
      context,
      dialogKey: const Key('split-ratio-dialog'),
      title: AppStrings.splitRatioTitle,
      subtitle: AppStrings.splitRatioSubtitle,
      current: _splitRatio,
      min: minSplitRatio,
      max: maxSplitRatio,
      format: AppStrings.splitRatioValue,
    );
    if (ratio != null) await _setSplitRatio(ratio);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < splitBreakpoint;
    return SettingsAreaShell(
      title: AppStrings.settingsSectionAppearance,
      controller: widget.controller,
      highlight: widget.highlight,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          HighlightRow(
            key: const Key('language-choice'),
            child: SettingsValueRow(
              title: AppStrings.languageTitle,
              value: AppStrings.languageName(_language),
              onTap: () => unawaited(_chooseLanguage()),
            ),
          ),
          HighlightRow(
            key: const Key('theme-brightness-setting'),
            child: SettingsValueRow(
              title: AppStrings.themeBrightnessTitle,
              value: switch (_themeBrightness) {
                AppBrightness.system => AppStrings.themeBrightnessSystem,
                AppBrightness.day => AppStrings.themeBrightnessDay,
                AppBrightness.night => AppStrings.themeBrightnessNight,
              },
              onTap: () => unawaited(_chooseThemeBrightness()),
            ),
          ),
          HighlightRow(
            key: const Key('theme-palette-setting'),
            child: SettingsValueRow(
              title: AppStrings.themePaletteTitle,
              value: SettingsAppearanceScreen.paletteName(_themePalette),
              onTap: () => unawaited(_chooseThemePalette()),
            ),
          ),
          HighlightRow(
            key: const Key('ui-text-scale-setting'),
            child: SettingsValueRow(
              title: AppStrings.uiTextScaleTitle,
              value: AppStrings.textScaleValue(_uiTextScale),
              onTap: () => unawaited(_chooseUiTextScale()),
            ),
          ),
          // The split ratio stays here; the split/switch choice itself
          // lives in the editor's app bar (user, 2026-09-09): a layout a
          // narrow screen cannot have is not a global setting.
          if (_splitLoaded &&
              previewSplits(
                _previewMode,
                narrow: narrow,
                editor: _editorKind,
                previewEnabled: _previewEnabled,
              ))
            HighlightRow(
              key: const Key('split-ratio-setting'),
              child: SettingsValueRow(
                title: AppStrings.splitRatioTitle,
                value: AppStrings.splitRatioValue(_splitRatio),
                onTap: () => unawaited(_chooseSplitRatio()),
              ),
            ),
        ],
      ),
    );
  }
}
