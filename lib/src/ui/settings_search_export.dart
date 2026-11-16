import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';

/// The settings search's rows of Export (#1285), in the order the search
/// lists them.
List<SettingsSearchEntry> exportSearchEntries(SettingsSearchScope scope) {
  final controller = scope.controller;
  return [
    SettingsSearchEntry(
      title: AppStrings.pdfPaperTitle,
      area: AppStrings.settingsSectionExport,
      rowKey: SettingsKeys.pdfPaper,
      value: () async =>
          AppStrings.paperSizeName(await controller.appSettings.pdfPaper),
      areaId: SettingsAreaId.export,
      open: () => scope.openArea(SettingsAreaId.export, SettingsKeys.pdfPaper),
    ),
  ];
}
