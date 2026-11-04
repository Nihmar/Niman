import 'package:flutter/material.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings_area_features.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_appearance.dart';
import 'package:niman/src/ui/settings_search_diagnostics.dart';
import 'package:niman/src/ui/settings_search_editor.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_library.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/settings_search_services.dart';
import 'package:niman/src/ui/strings.dart';

export 'package:niman/src/ui/settings_search_entry.dart';
export 'package:niman/src/ui/settings_search_match.dart';

/// Every row the settings search can find (issue #104).
///
/// Titles and areas are localized at build time; values load on demand
/// for the matches only.
List<SettingsSearchEntry> settingsSearchEntries({
  required LibrarySession controller,
  required TranscriptionModels? transcription,
  required EditorSpellCheck? spellCheck,
  required String libraryName,
  required BuildContext context,
  required void Function(Key rowKey) flashHome,
  required void Function(SettingsAreaId area, Key rowKey) openArea,
  bool keyboardAttached = true,
  bool libraryRows = true,
  OcrInstallation? ocr,
}) {
  void push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (context) => screen));

  Future<String?> noValue() async => null;

  final maintenance = AppStrings.settingsGroupMaintenance;
  final scope = SettingsSearchScope(
    controller: controller,
    libraryName: libraryName,
    push: push,
    flashHome: flashHome,
    openArea: openArea,
  );
  final entries = <SettingsSearchEntry>[
    ...appearanceSearchEntries(scope),
    ...editorSearchEntries(scope),
    ...librarySearchEntries(scope),
    ...diagnosticsSearchEntries(scope),
    ...serviceSearchEntries(scope, ocr: ocr, transcription: transcription),
    // Maintenance lives on the home itself: opening one means clearing
    // the search and flashing the row in place.
    SettingsSearchEntry(
      title: AppStrings.reindexTitle,
      area: maintenance,
      rowKey: SettingsKeys.reindex,
      value: noValue,
      open: () => flashHome(SettingsKeys.reindex),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.rebuildIndexTitle,
      area: maintenance,
      rowKey: SettingsKeys.rebuildIndex,
      value: noValue,
      open: () => flashHome(SettingsKeys.rebuildIndex),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.notionImportTitle,
      area: maintenance,
      rowKey: SettingsKeys.notionImport,
      value: noValue,
      open: () => flashHome(SettingsKeys.notionImport),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.epubConvertSettingsTitle,
      area: maintenance,
      rowKey: SettingsKeys.epubConvert,
      value: noValue,
      open: () => flashHome(SettingsKeys.epubConvert),
      onHome: true,
    ),
    if (libraryRows) ...[
      SettingsSearchEntry(
        title: AppStrings.switchLibraryTitle,
        area: maintenance,
        rowKey: SettingsKeys.switchLibrary,
        value: noValue,
        open: () => flashHome(SettingsKeys.switchLibrary),
        onHome: true,
      ),
      SettingsSearchEntry(
        title: AppStrings.closeLibraryTitle,
        area: maintenance,
        rowKey: SettingsKeys.closeLibrary,
        value: noValue,
        open: () => flashHome(SettingsKeys.closeLibrary),
        onHome: true,
      ),
    ],
  ];
  // Every command's own row on the keyboard screen: searching "zen" lands
  // on Zen mode's keys, not only on the screen's title (0.0.8 test round).
  // Without a keyboard, where that screen does not open, on its row of
  // the Commands page instead (#207). None named like a row above
  // (Re-index now, Switch library): the setting itself is the better
  // answer, and the list shows no twins.
  final titles = {for (final entry in entries) entry.title};
  final all = <SettingsSearchEntry>[
    ...entries,
    for (final command in AppCommand.values)
      if (titles.contains(appCommandLabel(command)))
        ...const <SettingsSearchEntry>[]
      else if (keyboardAttached)
        SettingsSearchEntry(
          title: appCommandLabel(command),
          area: AppStrings.keyboardShortcutsTitle,
          rowKey: shortcutRowKey(command),
          areaId: SettingsAreaId.shortcuts,
          value: () async =>
              switch (AppKeyMap.current.value.bindingOf(command)) {
                final keys? => describeActivator(keys),
                null => AppStrings.shortcutNone,
              },
          open: () =>
              openArea(SettingsAreaId.shortcuts, shortcutRowKey(command)),
        )
      else
        SettingsSearchEntry(
          title: appCommandLabel(command),
          area: AppStrings.commandsTitle,
          rowKey: commandRowKey(command),
          areaId: SettingsAreaId.commands,
          value: noValue,
          open: () => openArea(SettingsAreaId.commands, commandRowKey(command)),
        ),
    // The formatting keys (#205), where there is a keyboard to press:
    // searching "bold" lands on its row rather than on nothing.
    if (keyboardAttached)
      for (final item in ToolbarItem.values)
        if (item != ToolbarItem.tools)
          SettingsSearchEntry(
            title: item.label,
            area: AppStrings.keyboardShortcutsTitle,
            rowKey: editorShortcutRowKey(item),
            areaId: SettingsAreaId.shortcuts,
            value: () async =>
                switch (AppKeyMap.current.value.editorBindingOf(item)) {
                  final keys? => describeActivator(keys),
                  null => AppStrings.shortcutNone,
                },
            open: () =>
                openArea(SettingsAreaId.shortcuts, editorShortcutRowKey(item)),
          ),
  ];
  // A row of an area whose feature is off is not found (#1109): the area is
  // not listed either.
  final features = controller.features.value;
  return [
    for (final entry in all)
      if (entry.areaId case final area? when !areaShown(area, features))
        ...const <SettingsSearchEntry>[]
      else
        entry,
  ];
}
