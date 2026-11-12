import 'package:flutter/widgets.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';

/// The settings search's rows of Updates — where the app updates itself
/// — and Diagnostics (#104), in the order the search lists them.
List<SettingsSearchEntry> diagnosticsSearchEntries(SettingsSearchScope scope) {
  final controller = scope.controller;
  void pushUpdates(Key row) => scope.openArea(SettingsAreaId.updates, row);
  void pushDiagnostics(Key row) =>
      scope.openArea(SettingsAreaId.diagnostics, row);
  return [
    if (appUpdatesItself) ...[
      SettingsSearchEntry(
        title: AppStrings.autoUpdateTitle,
        area: AppStrings.settingsSectionUpdates,
        rowKey: SettingsKeys.autoUpdate,
        value: () async => scope.onOff(on: await controller.autoUpdateEnabled),
        areaId: SettingsAreaId.updates,
        open: () => pushUpdates(SettingsKeys.autoUpdate),
      ),
      SettingsSearchEntry(
        title: AppStrings.checkForUpdatesTitle,
        area: AppStrings.settingsSectionUpdates,
        rowKey: SettingsKeys.checkUpdates,
        value: scope.noValue,
        areaId: SettingsAreaId.updates,
        open: () => pushUpdates(SettingsKeys.checkUpdates),
      ),
    ] else if (updatesFromReleasePage)
      SettingsSearchEntry(
        title: AppStrings.updateReleasePage,
        area: AppStrings.settingsSectionUpdates,
        rowKey: SettingsKeys.releasePage,
        value: scope.noValue,
        areaId: SettingsAreaId.updates,
        open: () => pushUpdates(SettingsKeys.releasePage),
      ),
    SettingsSearchEntry(
      title: AppStrings.debugLogsTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.debugLogs,
      value: () async => scope.onOff(on: await controller.debugLogsEnabled),
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.debugLogs),
    ),
    SettingsSearchEntry(
      title: AppStrings.exportLogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.exportLog,
      value: scope.noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.exportLog),
    ),
    SettingsSearchEntry(
      title: AppStrings.changelogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.changelog,
      value: scope.noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.changelog),
    ),
    SettingsSearchEntry(
      title: AppStrings.cheatsheetTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.cheatsheet,
      value: scope.noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.cheatsheet),
    ),
    SettingsSearchEntry(
      title: AppStrings.welcomeDeckCommand,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.welcomeDeck,
      value: scope.noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.welcomeDeck),
    ),
    SettingsSearchEntry(
      title: AppStrings.welcomeTourCommand,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.welcomeTour,
      value: scope.noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.welcomeTour),
    ),
  ];
}
