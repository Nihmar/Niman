import 'package:flutter/widgets.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/ui/feature_names.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/trash.dart';

/// The settings search's rows of the library's own areas (#104):
/// Folders, Navigation, Features, Journal, Trash and history and Study,
/// in the order the search lists them.
List<SettingsSearchEntry> librarySearchEntries(SettingsSearchScope scope) {
  final controller = scope.controller;
  void pushFolders(Key row) => scope.openArea(SettingsAreaId.folders, row);
  void pushJournal(Key row) => scope.openArea(SettingsAreaId.journal, row);
  void pushTrash(Key row) => scope.openArea(SettingsAreaId.trashHistory, row);
  void pushStudy(Key row) => scope.openArea(SettingsAreaId.study, row);
  void pushNavigation(Key row) =>
      scope.openArea(SettingsAreaId.navigation, row);
  final ops = controller.ops;
  final folders = scope.libraryArea(AppStrings.settingsAreaFolders);
  final journal = scope.libraryArea(AppStrings.paletteGroupJournal);
  final trashHistory = scope.libraryArea(AppStrings.settingsAreaTrashHistory);
  final study = scope.libraryArea(AppStrings.tabStudy);
  final navigation = scope.libraryArea(AppStrings.settingsAreaNavigation);
  final featuresArea = scope.libraryArea(AppStrings.featuresTitle);
  return [
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
      value: scope.noValue,
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
      value: () async => ops == null
          ? null
          : scope.onOff(on: (await ops.navigation).device != null),
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
        value: () async =>
            scope.onOff(on: controller.features.value.isOn(feature)),
        areaId: SettingsAreaId.features,
        open: () => scope.openArea(
          SettingsAreaId.features,
          SettingsKeys.featureRow(feature),
        ),
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
      value: scope.noValue,
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
      value: () async =>
          ops == null ? null : scope.onOff(on: await ops.trashEnabled),
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
      value: scope.noValue,
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
      value: scope.noValue,
      open: () => scope.push(TrashScreen(controller: controller)),
    ),
  ];
}
