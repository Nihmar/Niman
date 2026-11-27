import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';

/// The settings search's rows of Dictionaries (#1382): the area itself,
/// where a dictionary is downloaded, and the note on a PDF's language.
///
/// None shows a value: what is installed is read from the folder, which a
/// search result has no business listing.
List<SettingsSearchEntry> dictionarySearchEntries(SettingsSearchScope scope) {
  Future<String?> none() async => null;
  void open(Key row) => scope.openArea(SettingsAreaId.dictionaries, row);
  return [
    SettingsSearchEntry(
      title: AppStrings.settingsSectionDictionaries,
      area: AppStrings.settingsSectionDictionaries,
      rowKey: SettingsKeys.dictionaries,
      value: none,
      areaId: SettingsAreaId.dictionaries,
      open: () => open(SettingsKeys.dictionaries),
    ),
    SettingsSearchEntry(
      title: AppStrings.dictionariesDownload,
      area: AppStrings.settingsSectionDictionaries,
      rowKey: SettingsKeys.dictionaryDownload,
      value: none,
      areaId: SettingsAreaId.dictionaries,
      open: () => open(SettingsKeys.dictionaryDownload),
    ),
    SettingsSearchEntry(
      title: AppStrings.dictionaryPdfLanguageTitle,
      area: AppStrings.settingsSectionDictionaries,
      rowKey: SettingsKeys.dictionaryPdfLanguage,
      value: none,
      areaId: SettingsAreaId.dictionaries,
      open: () => open(SettingsKeys.dictionaryPdfLanguage),
    ),
  ];
}
