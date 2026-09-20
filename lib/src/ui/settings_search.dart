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
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings_appearance.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
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
  void pushEditor(Key row) => openArea(SettingsAreaId.editor, row);
  void pushFolders(Key row) => openArea(SettingsAreaId.folders, row);
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
  final editor = AppStrings.settingsSectionEditor;
  final folders = libraryArea(AppStrings.settingsAreaFolders);
  final trashHistory = libraryArea(AppStrings.settingsAreaTrashHistory);
  final maintenance = AppStrings.settingsGroupMaintenance;
  final entries = <SettingsSearchEntry>[
    SettingsSearchEntry(
      title: AppStrings.languageTitle,
      area: appearance,
      rowKey: SettingsKeys.language,
      value: () async => AppStrings.languageName(await controller.language),
      open: () => pushAppearance(SettingsKeys.language),
    ),
    SettingsSearchEntry(
      title: AppStrings.themeBrightnessTitle,
      area: appearance,
      rowKey: SettingsKeys.brightness,
      value: () async => switch (await controller.themeBrightness) {
        AppBrightness.system => AppStrings.themeBrightnessSystem,
        AppBrightness.day => AppStrings.themeBrightnessDay,
        AppBrightness.night => AppStrings.themeBrightnessNight,
      },
      open: () => pushAppearance(SettingsKeys.brightness),
    ),
    SettingsSearchEntry(
      title: AppStrings.themePaletteTitle,
      area: appearance,
      rowKey: SettingsKeys.palette,
      value: () async =>
          SettingsAppearanceScreen.paletteName(await controller.themePalette),
      open: () => pushAppearance(SettingsKeys.palette),
    ),
    SettingsSearchEntry(
      title: AppStrings.uiTextScaleTitle,
      area: appearance,
      rowKey: SettingsKeys.uiTextScale,
      value: () async =>
          AppStrings.textScaleValue(await controller.uiTextScale),
      open: () => pushAppearance(SettingsKeys.uiTextScale),
    ),
    SettingsSearchEntry(
      title: AppStrings.splitRatioTitle,
      area: appearance,
      rowKey: SettingsKeys.splitRatio,
      value: () async =>
          AppStrings.splitRatioValue(await controller.splitRatio),
      open: () => pushAppearance(SettingsKeys.splitRatio),
    ),
    // The desktops only (#209): elsewhere there is no tray to close into.
    if (Platform.isLinux || Platform.isWindows)
      SettingsSearchEntry(
        title: AppStrings.closeToTrayTitle,
        area: appearance,
        rowKey: SettingsKeys.closeToTray,
        value: () async => onOff(on: await controller.closeToTray),
        open: () => pushAppearance(SettingsKeys.closeToTray),
      ),
    SettingsSearchEntry(
      title: AppStrings.toolbarSettingsTitle,
      area: editor,
      rowKey: SettingsKeys.toolbar,
      value: noValue,
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
      title: AppStrings.settingsPreviewEnabledTitle,
      area: editor,
      rowKey: SettingsKeys.previewEnabled,
      value: () async => onOff(on: await controller.previewEnabled),
      open: () => pushEditor(SettingsKeys.previewEnabled),
    ),
    SettingsSearchEntry(
      title: AppStrings.lineNumbersTitle,
      area: editor,
      rowKey: SettingsKeys.lineNumbers,
      value: () async => onOff(on: await controller.lineNumbersEnabled),
      open: () => pushEditor(SettingsKeys.lineNumbers),
    ),
    SettingsSearchEntry(
      title: AppStrings.readableLineLengthTitle,
      area: editor,
      rowKey: SettingsKeys.readableLineLength,
      value: () async => onOff(on: await controller.readableLineLength),
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
      open: () => pushEditor(SettingsKeys.missingNoteLocation),
    ),
    SettingsSearchEntry(
      title: AppStrings.noteTextScaleTitle,
      area: editor,
      rowKey: SettingsKeys.noteTextScale,
      value: () async =>
          AppStrings.textScaleValue(await controller.noteTextScale),
      open: () => pushEditor(SettingsKeys.noteTextScale),
    ),
    SettingsSearchEntry(
      title: AppStrings.indentWidthTitle,
      area: editor,
      rowKey: SettingsKeys.indentWidth,
      value: () async =>
          AppStrings.indentWidthValue(await controller.indentWidth),
      open: () => pushEditor(SettingsKeys.indentWidth),
    ),
    SettingsSearchEntry(
      title: AppStrings.listFolderTitle,
      area: folders,
      rowKey: SettingsKeys.listFolder,
      value: () async => ops == null ? null : await ops.listNoteFolder,
      open: () => pushFolders(SettingsKeys.listFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.templateFolderTitle,
      area: folders,
      rowKey: SettingsKeys.templateFolder,
      value: () async => ops == null ? null : await ops.templateFolder,
      open: () => pushFolders(SettingsKeys.templateFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.templateHelpTitle,
      area: folders,
      rowKey: SettingsKeys.templateHelp,
      value: noValue,
      open: () => pushFolders(SettingsKeys.templateHelp),
    ),
    SettingsSearchEntry(
      title: AppStrings.attachmentsFolderTitle,
      area: folders,
      rowKey: SettingsKeys.attachmentsFolder,
      value: () async => ops == null ? null : await ops.attachmentsFolder,
      open: () => pushFolders(SettingsKeys.attachmentsFolder),
    ),
    SettingsSearchEntry(
      title: AppStrings.quickNoteTitle,
      area: folders,
      rowKey: SettingsKeys.quickNote,
      value: () async => ops == null
          ? null
          : (await ops.quickNotePath) ?? AppStrings.quickNoteUnset,
      open: () => pushFolders(SettingsKeys.quickNote),
    ),
    SettingsSearchEntry(
      title: AppStrings.trashTitle,
      area: trashHistory,
      rowKey: SettingsKeys.trash,
      value: () async => ops == null ? null : onOff(on: await ops.trashEnabled),
      open: () => pushTrash(SettingsKeys.trash),
    ),
    SettingsSearchEntry(
      title: AppStrings.trashAutoEmptyTitle,
      area: trashHistory,
      rowKey: SettingsKeys.trashAutoEmpty,
      value: () async =>
          AppStrings.trashAutoEmptyValue(await controller.trashAutoEmptyDays),
      open: () => pushTrash(SettingsKeys.trashAutoEmpty),
    ),
    SettingsSearchEntry(
      title: AppStrings.historyVersionsTitle,
      area: trashHistory,
      rowKey: SettingsKeys.historyVersions,
      value: () async =>
          AppStrings.historyVersionsValue(await controller.historyVersions),
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
        open: () => pushUpdates(SettingsKeys.autoUpdate),
      ),
      SettingsSearchEntry(
        title: AppStrings.checkForUpdatesTitle,
        area: AppStrings.settingsSectionUpdates,
        rowKey: SettingsKeys.checkUpdates,
        value: noValue,
        open: () => pushUpdates(SettingsKeys.checkUpdates),
      ),
    ],
    SettingsSearchEntry(
      title: AppStrings.debugLogsTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.debugLogs,
      value: () async => onOff(on: await controller.debugLogsEnabled),
      open: () => pushDiagnostics(SettingsKeys.debugLogs),
    ),
    SettingsSearchEntry(
      title: AppStrings.exportLogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.exportLog,
      value: noValue,
      open: () => pushDiagnostics(SettingsKeys.exportLog),
    ),
    SettingsSearchEntry(
      title: AppStrings.changelogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: SettingsKeys.changelog,
      value: noValue,
      open: () => pushDiagnostics(SettingsKeys.changelog),
    ),
    SettingsSearchEntry(
      title: AppStrings.reminderShowTokensTitle,
      area: libraryArea(AppStrings.settingsSectionReminders),
      rowKey: SettingsKeys.reminderShowTokens,
      value: () async => onOff(on: await controller.reminderShowTokens),
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
