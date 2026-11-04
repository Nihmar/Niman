import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/ui/epub_look_sheet.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/theme_row.dart';

/// The settings search's rows of Appearance and Themes (#104), in the
/// order the search lists them.
List<SettingsSearchEntry> appearanceSearchEntries(SettingsSearchScope scope) {
  final controller = scope.controller;
  void pushAppearance(Key row) =>
      scope.openArea(SettingsAreaId.appearance, row);
  void pushThemes(Key row) => scope.openArea(SettingsAreaId.themes, row);
  final appearance = AppStrings.settingsSectionAppearance;
  final themes = AppStrings.settingsSectionThemes;
  return [
    SettingsSearchEntry(
      title: AppStrings.languageTitle,
      area: appearance,
      rowKey: SettingsKeys.language,
      value: () async => AppStrings.languageName(await controller.language),
      areaId: SettingsAreaId.appearance,
      open: () => pushAppearance(SettingsKeys.language),
    ),
    SettingsSearchEntry(
      title: AppStrings.weekStartTitle,
      area: appearance,
      rowKey: SettingsKeys.weekStart,
      value: () async => AppStrings.weekStartName(await controller.weekStart),
      areaId: SettingsAreaId.appearance,
      open: () => pushAppearance(SettingsKeys.weekStart),
    ),
    SettingsSearchEntry(
      title: AppStrings.themeBrightnessTitle,
      area: themes,
      rowKey: SettingsKeys.brightness,
      value: () async => switch (await controller.themeBrightness) {
        AppBrightness.system => AppStrings.themeBrightnessSystem,
        AppBrightness.day => AppStrings.themeBrightnessDay,
        AppBrightness.night => AppStrings.themeBrightnessNight,
      },
      areaId: SettingsAreaId.themes,
      open: () => pushThemes(SettingsKeys.brightness),
    ),
    SettingsSearchEntry(
      title: AppStrings.themeTitle,
      area: themes,
      rowKey: SettingsKeys.theme,
      value: () async => themeLabel(await controller.theme),
      areaId: SettingsAreaId.themes,
      open: () => pushThemes(SettingsKeys.theme),
    ),
    SettingsSearchEntry(
      title: AppStrings.uiTextScaleTitle,
      area: appearance,
      rowKey: SettingsKeys.uiTextScale,
      value: () async =>
          AppStrings.textScaleValue(await controller.uiTextScale),
      areaId: SettingsAreaId.appearance,
      open: () => pushAppearance(SettingsKeys.uiTextScale),
    ),
    SettingsSearchEntry(
      title: AppStrings.epubLookTitle,
      area: appearance,
      rowKey: SettingsKeys.epubLook,
      value: () async => epubLookSummary(await controller.epubLook),
      areaId: SettingsAreaId.appearance,
      open: () => pushAppearance(SettingsKeys.epubLook),
    ),
    // The desktops only (#209): elsewhere there is no tray to close into.
    if (Platform.isLinux || Platform.isWindows)
      SettingsSearchEntry(
        title: AppStrings.closeToTrayTitle,
        area: appearance,
        rowKey: SettingsKeys.closeToTray,
        value: () async => scope.onOff(on: await controller.closeToTray),
        areaId: SettingsAreaId.appearance,
        open: () => pushAppearance(SettingsKeys.closeToTray),
      ),
  ];
}
