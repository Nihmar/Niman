import 'package:flutter/material.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/feature_names.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/ocr/ocr_settings_section.dart';
import 'package:niman/src/ui/settings_area_features.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_appearance.dart';
import 'package:niman/src/ui/settings_search_editor.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/transcription/transcription_settings_section.dart';
import 'package:niman/src/ui/trash.dart';

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
  void pushFolders(Key row) => openArea(SettingsAreaId.folders, row);
  void pushJournal(Key row) => openArea(SettingsAreaId.journal, row);
  void pushTrash(Key row) => openArea(SettingsAreaId.trashHistory, row);
  void pushStudy(Key row) => openArea(SettingsAreaId.study, row);
  void pushNavigation(Key row) => openArea(SettingsAreaId.navigation, row);
  void pushUpdates(Key row) => openArea(SettingsAreaId.updates, row);
  void pushDiagnostics(Key row) => openArea(SettingsAreaId.diagnostics, row);

  String libraryArea(String area) =>
      '${AppStrings.settingsGroupLibrary(libraryName)} › $area';
  String onOff({required bool on}) =>
      on ? AppStrings.settingsToggleOn : AppStrings.settingsToggleOff;
  Future<String?> noValue() async => null;

  final ops = controller.ops;
  final folders = libraryArea(AppStrings.settingsAreaFolders);
  final journal = libraryArea(AppStrings.paletteGroupJournal);
  final trashHistory = libraryArea(AppStrings.settingsAreaTrashHistory);
  final study = libraryArea(AppStrings.tabStudy);
  final navigation = libraryArea(AppStrings.settingsAreaNavigation);
  final featuresArea = libraryArea(AppStrings.featuresTitle);
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
    SettingsSearchEntry(
      title: AppStrings.listFolderTitle,
      area: folders,
      rowKey: SettingsKeys.listFolder,
      value: () async => ops == null ? null : await ops.listNoteFolder,
      areaId: SettingsAreaId.folders,
      open: () => pushFolders(SettingsKeys.listFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.templateFolderTitle,
      area: folders,
      rowKey: SettingsKeys.templateFolder,
      value: () async => ops == null ? null : await ops.templateFolder,
      areaId: SettingsAreaId.folders,
      open: () => pushFolders(SettingsKeys.templateFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.templateHelpTitle,
      area: folders,
      rowKey: SettingsKeys.templateHelp,
      value: noValue,
      areaId: SettingsAreaId.folders,
      open: () => pushFolders(SettingsKeys.templateHelp),
    ),
    SettingsSearchEntry(
      title: AppStrings.attachmentsFolderTitle,
      area: folders,
      rowKey: SettingsKeys.attachmentsFolder,
      value: () async => ops == null ? null : await ops.attachmentsFolder,
      areaId: SettingsAreaId.folders,
      open: () => pushFolders(SettingsKeys.attachmentsFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.annotationsFolderTitle,
      area: folders,
      rowKey: SettingsKeys.annotationsFolder,
      value: () async => ops == null ? null : await ops.annotationsFolder,
      areaId: SettingsAreaId.folders,
      open: () => pushFolders(SettingsKeys.annotationsFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.captureFolderTitle,
      area: folders,
      rowKey: SettingsKeys.captureFolder,
      value: () async => ops == null ? null : await ops.captureFolder,
      areaId: SettingsAreaId.folders,
      open: () => pushFolders(SettingsKeys.captureFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.quickNoteTitle,
      area: folders,
      rowKey: SettingsKeys.quickNote,
      value: () async => ops == null
          ? null
          : (await ops.quickNotePath) ?? AppStrings.quickNoteUnset,
      areaId: SettingsAreaId.folders,
      open: () => pushFolders(SettingsKeys.quickNote),
    ),
    SettingsSearchEntry(
      title: AppStrings.navigationScopeDevice,
      area: navigation,
      rowKey: SettingsKeys.navigationScope,
      value: () async =>
          ops == null ? null : onOff(on: (await ops.navigation).device != null),
      areaId: SettingsAreaId.navigation,
      open: () => pushNavigation(SettingsKeys.navigationScope),
    ),
    SettingsSearchEntry(
      title: AppStrings.navigationStart,
      area: navigation,
      rowKey: SettingsKeys.navigationStart,
      value: () async {
        if (ops == null) return null;
        final navigation = await ops.navigation;
        return startLabel(
          navigation.device ?? navigation.library ?? const NavigationLayout(),
        );
      },
      areaId: SettingsAreaId.navigation,
      open: () => pushNavigation(SettingsKeys.navigationStart),
    ),
    // The switches of Features (#1109): found by their names, and opened
    // with their row flashed. The value is what the library does, so a
    // child whose parent is off reads Off.
    for (final feature in LibraryFeature.values)
      SettingsSearchEntry(
        title: featureName(feature),
        area: featuresArea,
        rowKey: SettingsKeys.featureRow(feature),
        value: () async => onOff(on: controller.features.value.isOn(feature)),
        areaId: SettingsAreaId.features,
        open: () =>
            openArea(SettingsAreaId.features, SettingsKeys.featureRow(feature)),
      ),
    SettingsSearchEntry(
      title: AppStrings.journalFolderTitle,
      area: journal,
      rowKey: SettingsKeys.journalFolder,
      value: () async => ops == null ? null : (await ops.journal).folder,
      areaId: SettingsAreaId.journal,
      open: () => pushJournal(SettingsKeys.journalFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.journalEntryNameTitle,
      area: journal,
      rowKey: SettingsKeys.journalEntryName,
      value: () async => ops == null ? null : (await ops.journal).entryName,
      areaId: SettingsAreaId.journal,
      open: () => pushJournal(SettingsKeys.journalEntryName),
    ),
    SettingsSearchEntry(
      title: AppStrings.journalTemplateTitle,
      area: journal,
      rowKey: SettingsKeys.journalTemplate,
      value: () async => ops == null
          ? null
          : (await ops.journal).template ?? AppStrings.journalTemplateNone,
      areaId: SettingsAreaId.journal,
      open: () => pushJournal(SettingsKeys.journalTemplate),
    ),
    SettingsSearchEntry(
      title: AppStrings.journalDayStartTitle,
      area: journal,
      rowKey: SettingsKeys.journalDayStart,
      value: noValue,
      areaId: SettingsAreaId.journal,
      open: () => pushJournal(SettingsKeys.journalDayStart),
    ),
    SettingsSearchEntry(
      title: AppStrings.journalEventTimesTitle,
      area: journal,
      rowKey: SettingsKeys.journalEventTimes,
      value: () async => ops == null
          ? null
          : (await ops.journal).clockTimes
          ? AppStrings.journalEventTimesClock
          : AppStrings.journalEventTimesWritten,
      areaId: SettingsAreaId.journal,
      open: () => pushJournal(SettingsKeys.journalEventTimes),
    ),
    SettingsSearchEntry(
      title: AppStrings.trashTitle,
      area: trashHistory,
      rowKey: SettingsKeys.trash,
      value: () async => ops == null ? null : onOff(on: await ops.trashEnabled),
      areaId: SettingsAreaId.trashHistory,
      open: () => pushTrash(SettingsKeys.trash),
    ),
    SettingsSearchEntry(
      title: AppStrings.trashAutoEmptyTitle,
      area: trashHistory,
      rowKey: SettingsKeys.trashAutoEmpty,
      value: () async =>
          AppStrings.trashAutoEmptyValue(await controller.trashAutoEmptyDays),
      areaId: SettingsAreaId.trashHistory,
      open: () => pushTrash(SettingsKeys.trashAutoEmpty),
    ),
    SettingsSearchEntry(
      title: AppStrings.settingsNewCardsPerDay,
      area: study,
      rowKey: SettingsKeys.newCardsPerDay,
      value: () async => '${await controller.newCardsPerDay}',
      areaId: SettingsAreaId.study,
      open: () => pushStudy(SettingsKeys.newCardsPerDay),
    ),
    SettingsSearchEntry(
      title: AppStrings.settingsResetAllReviews,
      area: study,
      rowKey: SettingsKeys.resetAllReviews,
      value: noValue,
      areaId: SettingsAreaId.study,
      open: () => pushStudy(SettingsKeys.resetAllReviews),
    ),
    SettingsSearchEntry(
      title: AppStrings.historyVersionsTitle,
      area: trashHistory,
      rowKey: SettingsKeys.historyVersions,
      value: () async =>
          AppStrings.historyVersionsValue(await controller.historyVersions),
      areaId: SettingsAreaId.trashHistory,
      open: () => pushTrash(SettingsKeys.historyVersions),
    ),
    SettingsSearchEntry(
      title: AppStrings.historyIntervalTitle,
      area: trashHistory,
      rowKey: SettingsKeys.historyInterval,
      value: () async => AppStrings.historyIntervalValue(
        await controller.historyIntervalMinutes,
      ),
      open: () => pushTrash(SettingsKeys.historyInterval),
    ),
    // What empties the trash for good lands on the screen that
    // holds it.
    SettingsSearchEntry(
      title: AppStrings.trashDeletePermanently,
      area: trashHistory,
      // Its own key: the trash toggle's would make two results in one
      // list share an identity, and this one opens a different screen.
      rowKey: SettingsKeys.trashEmptyAction,
      value: noValue,
      open: () => push(TrashScreen(controller: controller)),
    ),
    if (appUpdatesItself) ...[
      SettingsSearchEntry(
        title: AppStrings.autoUpdateTitle,
        area: AppStrings.settingsSectionUpdates,
        rowKey: SettingsKeys.autoUpdate,
        value: () async => onOff(on: await controller.autoUpdateEnabled),
        areaId: SettingsAreaId.updates,
        open: () => pushUpdates(SettingsKeys.autoUpdate),
      ),
      SettingsSearchEntry(
        title: AppStrings.checkForUpdatesTitle,
        area: AppStrings.settingsSectionUpdates,
        rowKey: SettingsKeys.checkUpdates,
        value: noValue,
        areaId: SettingsAreaId.updates,
        open: () => pushUpdates(SettingsKeys.checkUpdates),
      ),
    ],
    SettingsSearchEntry(
      title: AppStrings.debugLogsTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.debugLogs,
      value: () async => onOff(on: await controller.debugLogsEnabled),
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.debugLogs),
    ),
    SettingsSearchEntry(
      title: AppStrings.exportLogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.exportLog,
      value: noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.exportLog),
    ),
    SettingsSearchEntry(
      title: AppStrings.changelogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.changelog,
      value: noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.changelog),
    ),
    SettingsSearchEntry(
      title: AppStrings.cheatsheetTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.cheatsheet,
      value: noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.cheatsheet),
    ),
    SettingsSearchEntry(
      title: AppStrings.welcomeDeckCommand,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.welcomeDeck,
      value: noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.welcomeDeck),
    ),
    SettingsSearchEntry(
      title: AppStrings.welcomeTourCommand,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.welcomeTour,
      value: noValue,
      areaId: SettingsAreaId.diagnostics,
      open: () => pushDiagnostics(SettingsKeys.welcomeTour),
    ),
    SettingsSearchEntry(
      title: AppStrings.reminderShowTokensTitle,
      area: libraryArea(AppStrings.settingsSectionReminders),
      rowKey: SettingsKeys.reminderShowTokens,
      value: () async => onOff(on: await controller.reminderShowTokens),
      areaId: SettingsAreaId.reminders,
      open: () =>
          openArea(SettingsAreaId.reminders, SettingsKeys.reminderShowTokens),
    ),
    if (ocr case final ocr?) ...[
      SettingsSearchEntry(
        title: AppStrings.ocrQualityTitle,
        area: AppStrings.settingsSectionTextRecognition,
        rowKey: SettingsKeys.ocrQuality,
        value: () async => ocrQualityLabel(ocr.settings.quality),
        areaId: SettingsAreaId.textRecognition,
        open: () =>
            openArea(SettingsAreaId.textRecognition, SettingsKeys.ocrQuality),
      ),
      SettingsSearchEntry(
        title: AppStrings.ocrLanguageTitle,
        area: AppStrings.settingsSectionTextRecognition,
        rowKey: SettingsKeys.ocrLanguage,
        value: () async => ocr.defaultLanguage().native,
        areaId: SettingsAreaId.textRecognition,
        open: () =>
            openArea(SettingsAreaId.textRecognition, SettingsKeys.ocrLanguage),
      ),
      SettingsSearchEntry(
        title: AppStrings.ocrAlsoTitle,
        area: AppStrings.settingsSectionTextRecognition,
        rowKey: SettingsKeys.ocrAlso,
        value: () async => ocr.alsoLanguage()?.native ?? AppStrings.ocrAlsoNone,
        areaId: SettingsAreaId.textRecognition,
        open: () =>
            openArea(SettingsAreaId.textRecognition, SettingsKeys.ocrAlso),
      ),
    ],
    if (transcription case final models?) ...[
      SettingsSearchEntry(
        title: AppStrings.transcriptionModelTitle,
        area: libraryArea(AppStrings.settingsSectionTranscription),
        rowKey: SettingsKeys.transcriptionModel,
        value: () async {
          final model = models.defaultModel;
          return model == null
              ? AppStrings.transcriptionModelNone
              : AppStrings.transcriptionModelName(model);
        },
        areaId: SettingsAreaId.transcription,
        open: () => openArea(
          SettingsAreaId.transcription,
          SettingsKeys.transcriptionModel,
        ),
      ),
      SettingsSearchEntry(
        title: AppStrings.transcriptionLanguageTitle,
        area: libraryArea(AppStrings.settingsSectionTranscription),
        rowKey: SettingsKeys.transcriptionLanguage,
        value: () async => TranscriptionSettingsSection.languageLabel(
          models.settings.language,
        ),
        open: () => openArea(
          SettingsAreaId.transcription,
          SettingsKeys.transcriptionLanguage,
        ),
      ),
    ],
    if (controller.sync case final sync?)
      SettingsSearchEntry(
        title: AppStrings.settingsSectionSync,
        area: libraryArea(AppStrings.settingsSectionSync),
        rowKey: const Key('settings-area-sync'),
        value: () async => syncStatusLine(sync.status, DateTime.now()),
        areaId: SettingsAreaId.sync,
        open: () =>
            openArea(SettingsAreaId.sync, const Key('settings-area-sync')),
      ),
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
