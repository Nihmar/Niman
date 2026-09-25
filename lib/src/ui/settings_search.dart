import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/epub_look_sheet.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/theme/theme_row.dart';
import 'package:niman/src/ui/transcription/transcription_settings_section.dart';
import 'package:niman/src/ui/trash.dart';

/// One searchable settings row (issue #104): its title, where it lives,
/// its current value, and how to open it.
final class SettingsSearchEntry {
  /// Describes the row titled [title] in [area].
  const new({
    required this.title,
    required this.area,
    required this.rowKey,
    required this.value,
    required this.open,
    this.areaId,
    this.onHome = false,
  });

  /// The row's title.
  final String title;

  /// Where the row lives ("Library X › Trash and history"), so nothing
  /// is changed by accident in the wrong place.
  final String area;

  /// The row's key: the highlight target on its screen.
  final Key rowKey;

  /// The row's current value for the result line; null shows none.
  final Future<String?> Function() value;

  /// Opens the row's screen with the row highlighted.
  final VoidCallback open;

  /// Which area the row lives in, for a caller that opens settings
  /// itself — the command palette (#229). Null for the rows that sit on
  /// the settings home.
  final SettingsAreaId? areaId;

  /// True for the maintenance actions: they sit on the home itself, so
  /// opening them means clearing the search and flashing in place.
  final bool onHome;
}

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
}) {
  void push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (context) => screen));
  void pushAppearance(Key row) => openArea(SettingsAreaId.appearance, row);
  void pushThemes(Key row) => openArea(SettingsAreaId.themes, row);
  void pushEditor(Key row) => openArea(SettingsAreaId.editor, row);
  void pushFolders(Key row) => openArea(SettingsAreaId.folders, row);
  void pushJournal(Key row) => openArea(SettingsAreaId.journal, row);
  void pushTrash(Key row) => openArea(SettingsAreaId.trashHistory, row);
  void pushUpdates(Key row) => openArea(SettingsAreaId.updates, row);
  void pushDiagnostics(Key row) => openArea(SettingsAreaId.diagnostics, row);

  String libraryArea(String area) =>
      '${AppStrings.settingsGroupLibrary(libraryName)} › $area';
  String onOff({required bool on}) =>
      on ? AppStrings.settingsToggleOn : AppStrings.settingsToggleOff;
  Future<String?> noValue() async => null;

  final ops = controller.ops;
  final appearance = AppStrings.settingsSectionAppearance;
  final themes = AppStrings.settingsSectionThemes;
  final editor = AppStrings.settingsSectionEditor;
  final folders = libraryArea(AppStrings.settingsAreaFolders);
  final journal = libraryArea(AppStrings.paletteGroupJournal);
  final trashHistory = libraryArea(AppStrings.settingsAreaTrashHistory);
  final maintenance = AppStrings.settingsGroupMaintenance;
  final entries = <SettingsSearchEntry>[
    SettingsSearchEntry(
      title: AppStrings.languageTitle,
      area: appearance,
      rowKey: SettingsKeys.language,
      value: () async => AppStrings.languageName(await controller.language),
      areaId: SettingsAreaId.appearance,
      open: () => pushAppearance(SettingsKeys.language),
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
        value: () async => onOff(on: await controller.closeToTray),
        areaId: SettingsAreaId.appearance,
        open: () => pushAppearance(SettingsKeys.closeToTray),
      ),
    SettingsSearchEntry(
      title: AppStrings.toolbarSettingsTitle,
      area: editor,
      rowKey: SettingsKeys.toolbar,
      value: noValue,
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.toolbar),
    ),
    SettingsSearchEntry(
      title: AppStrings.editorKindSource,
      area: editor,
      rowKey: SettingsKeys.editorSource,
      value: () async => onOff(
        on: (await controller.enabledEditors).contains(EditorKind.source),
      ),
      open: () => pushEditor(SettingsKeys.editorSource),
    ),
    SettingsSearchEntry(
      title: AppStrings.editorKindWysiwyg,
      area: editor,
      rowKey: SettingsKeys.editorWysiwyg,
      value: () async => onOff(
        on: (await controller.enabledEditors).contains(EditorKind.wysiwyg),
      ),
      open: () => pushEditor(SettingsKeys.editorWysiwyg),
    ),
    SettingsSearchEntry(
      title: AppStrings.lineNumbersTitle,
      area: editor,
      rowKey: SettingsKeys.lineNumbers,
      value: () async => onOff(on: await controller.lineNumbersEnabled),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.lineNumbers),
    ),
    SettingsSearchEntry(
      title: AppStrings.readableLineLengthTitle,
      area: editor,
      rowKey: SettingsKeys.readableLineLength,
      value: () async => onOff(on: await controller.readableLineLength),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.readableLineLength),
    ),
    SettingsSearchEntry(
      title: AppStrings.noteColumnWidthTitle,
      area: editor,
      rowKey: SettingsKeys.noteColumnWidth,
      value: () async => AppStrings.noteColumnWidthValue(
        (await controller.noteColumnWidth).round(),
      ),
      open: () => pushEditor(SettingsKeys.noteColumnWidth),
    ),
    SettingsSearchEntry(
      title: AppStrings.typewriterTitle,
      area: editor,
      rowKey: SettingsKeys.typewriter,
      value: () async => onOff(on: await controller.typewriter),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.typewriter),
    ),
    SettingsSearchEntry(
      title: AppStrings.linkTypeTitle,
      area: editor,
      rowKey: SettingsKeys.linkType,
      value: () async => switch (await controller.linkType) {
        LinkType.wikilink => AppStrings.linkTypeWikilink,
        LinkType.markdown => AppStrings.linkTypeMarkdown,
      },
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.linkType),
    ),
    SettingsSearchEntry(
      title: AppStrings.missingNoteLocationTitle,
      area: editor,
      rowKey: SettingsKeys.missingNoteLocation,
      value: () async => switch (await controller.missingNoteLocation) {
        MissingNoteLocation.libraryRoot => AppStrings.missingNoteLocationRoot,
        MissingNoteLocation.currentFolder =>
          AppStrings.missingNoteLocationCurrentFolder,
      },
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.missingNoteLocation),
    ),
    SettingsSearchEntry(
      title: AppStrings.noteTextScaleTitle,
      area: editor,
      rowKey: SettingsKeys.noteTextScale,
      value: () async =>
          AppStrings.textScaleValue(await controller.noteTextScale),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.noteTextScale),
    ),
    SettingsSearchEntry(
      title: AppStrings.indentWidthTitle,
      area: editor,
      rowKey: SettingsKeys.indentWidth,
      value: () async =>
          AppStrings.indentWidthValue(await controller.indentWidth),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.indentWidth),
    ),
    SettingsSearchEntry(
      title: AppStrings.tidyOnCloseTitle,
      area: editor,
      rowKey: SettingsKeys.tidyOnClose,
      value: () async => onOff(on: await controller.tidyOnClose),
      areaId: SettingsAreaId.editor,
      open: () => pushEditor(SettingsKeys.tidyOnClose),
    ),
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
    if (!isTestingBuild) ...[
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
      title: AppStrings.reminderShowTokensTitle,
      area: libraryArea(AppStrings.settingsSectionReminders),
      rowKey: SettingsKeys.reminderShowTokens,
      value: () async => onOff(on: await controller.reminderShowTokens),
      areaId: SettingsAreaId.reminders,
      open: () =>
          openArea(SettingsAreaId.reminders, SettingsKeys.reminderShowTokens),
    ),
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
  return [
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
}

/// Matches [entries] against [query]: every word lands in the title or
/// the area, case-insensitively.
List<SettingsSearchEntry> matchSettingsEntries(
  List<SettingsSearchEntry> entries,
  String query,
) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return const [];
  return [
    for (final entry in entries)
      if (words.every(
        (word) =>
            entry.title.toLowerCase().contains(word) ||
            entry.area.toLowerCase().contains(word),
      ))
        entry,
  ];
}
