import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/close_to_tray.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Appearance area of the settings home (issue #104): the app's own
/// look — language, the interface text size, and the split width where
/// the panes split. The colors have their own area (issue #269).
final class SettingsAppearanceScreen extends StatefulWidget {
  /// Creates the screen for [controller]'s library session.
  const new({required this.controller, this.highlight, super.key});

  /// The session holding the settings.
  final LibrarySession controller;

  /// The row the settings search landed on, flashed once.
  final Key? highlight;

  @override
  State<SettingsAppearanceScreen> createState() =>
      _SettingsAppearanceScreenState();
}

final class _SettingsAppearanceScreenState
    extends State<SettingsAppearanceScreen> {
  AppLanguage _language = AppLanguage.system;
  double _uiTextScale = defaultTextScale;
  double _splitRatio = defaultSplitRatio;
  bool _splitLoaded = false;
  PreviewLayoutMode _previewMode = PreviewLayoutMode.auto;
  EditorKind _editorKind = EditorKind.source;
  bool _previewEnabled = true;
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
    final uiTextScale = await controller.uiTextScale;
    final splitRatio = await controller.splitRatio;
    final previewMode = await controller.previewMode;
    final editorKind = await controller.editorKind;
    final previewEnabled = await controller.previewEnabled;
    final closeToTray = await controller.closeToTray;
    if (!mounted) return;
    setState(() {
      _language = language;
      _uiTextScale = uiTextScale;
      _splitRatio = splitRatio;
      _splitLoaded = true;
      _closeToTray = closeToTray;
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
            key: SettingsKeys.language,
            child: SettingsValueRow(
              title: AppStrings.languageTitle,
              subtitle: AppStrings.languageSubtitle,
              value: AppStrings.languageName(_language),
              onTap: () => unawaited(_chooseLanguage()),
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
              key: SettingsKeys.splitRatio,
              child: SettingsValueRow(
                title: AppStrings.splitRatioTitle,
                subtitle: AppStrings.splitRatioSubtitle,
                value: AppStrings.splitRatioValue(_splitRatio),
                onTap: () => unawaited(_chooseSplitRatio()),
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
