import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/epub/epub_look.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/close_to_tray.dart';
import 'package:niman/src/ui/epub_look_sheet.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Appearance area of the settings home (issue #104): the app's own
/// look — language, the interface text size, the books' own look (#280)
/// and, on the desktops, what the window's × does. The colors have their
/// own area (issue #269).
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
  EpubLook _epubLook = const EpubLook();
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
    final epubLook = await controller.epubLook;
    final closeToTray = await controller.closeToTray;
    if (!mounted) return;
    setState(() {
      _language = language;
      _uiTextScale = uiTextScale;
      _epubLook = epubLook;
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

  /// The sheet the book's Aa button opens, on the same values.
  Future<void> _editEpubLook() async {
    final controller = widget.controller;
    await showEpubLookSheet(context, session: controller);
    final look = await controller.epubLook;
    if (mounted) setState(() => _epubLook = look);
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
            key: SettingsKeys.uiTextScale,
            child: SettingsValueRow(
              title: AppStrings.uiTextScaleTitle,
              subtitle: AppStrings.uiTextScaleSubtitle,
              value: AppStrings.textScaleValue(_uiTextScale),
              onTap: () => unawaited(_chooseUiTextScale()),
            ),
          ),
          HighlightRow(
            key: SettingsKeys.epubLook,
            child: SettingsValueRow(
              title: AppStrings.epubLookTitle,
              subtitle: AppStrings.epubLookSubtitle,
              value: epubLookSummary(_epubLook),
              onTap: () => unawaited(_editEpubLook()),
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
