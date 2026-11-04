import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';

/// The settings search's rows of Maintenance (#104), in the order the
/// search lists them: switching and closing the library only with
/// [libraryRows].
List<SettingsSearchEntry> maintenanceSearchEntries(
  SettingsSearchScope scope, {
  required bool libraryRows,
}) {
  final maintenance = AppStrings.settingsGroupMaintenance;
  return [
    // Maintenance lives on the home itself: opening one means clearing
    // the search and flashing the row in place.
    SettingsSearchEntry(
      title: AppStrings.reindexTitle,
      area: maintenance,
      rowKey: SettingsKeys.reindex,
      value: scope.noValue,
      open: () => scope.flashHome(SettingsKeys.reindex),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.rebuildIndexTitle,
      area: maintenance,
      rowKey: SettingsKeys.rebuildIndex,
      value: scope.noValue,
      open: () => scope.flashHome(SettingsKeys.rebuildIndex),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.notionImportTitle,
      area: maintenance,
      rowKey: SettingsKeys.notionImport,
      value: scope.noValue,
      open: () => scope.flashHome(SettingsKeys.notionImport),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.epubConvertSettingsTitle,
      area: maintenance,
      rowKey: SettingsKeys.epubConvert,
      value: scope.noValue,
      open: () => scope.flashHome(SettingsKeys.epubConvert),
      onHome: true,
    ),
    if (libraryRows) ...[
      SettingsSearchEntry(
        title: AppStrings.switchLibraryTitle,
        area: maintenance,
        rowKey: SettingsKeys.switchLibrary,
        value: scope.noValue,
        open: () => scope.flashHome(SettingsKeys.switchLibrary),
        onHome: true,
      ),
      SettingsSearchEntry(
        title: AppStrings.closeLibraryTitle,
        area: maintenance,
        rowKey: SettingsKeys.closeLibrary,
        value: scope.noValue,
        open: () => scope.flashHome(SettingsKeys.closeLibrary),
        onHome: true,
      ),
    ],
  ];
}
