import 'package:flutter/material.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/settings_appearance.dart';
import 'package:niman/src/ui/settings_diagnostics.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_folders_paths.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_reminders.dart';
import 'package:niman/src/ui/settings_transcription.dart';
import 'package:niman/src/ui/settings_trash_history.dart';
import 'package:niman/src/ui/settings_updates.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/sync/sync_settings_screen.dart';
import 'package:niman/src/ui/transcription/transcription_settings_section.dart';
import 'package:niman/src/ui/trash.dart';
import 'package:path/path.dart' as p;

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
}) {
  void push(Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (context) => screen));
  void pushAppearance(Key row) =>
      push(SettingsAppearanceScreen(controller: controller, highlight: row));
  void pushEditor(Key row) => push(
    SettingsEditorScreen(
      controller: controller,
      spellCheck: spellCheck,
      highlight: row,
    ),
  );
  void pushFolders(Key row) =>
      push(SettingsFoldersPathsScreen(controller: controller, highlight: row));
  void pushTrash(Key row) =>
      push(SettingsTrashHistoryScreen(controller: controller, highlight: row));
  void pushUpdates(Key row) =>
      push(SettingsUpdatesScreen(controller: controller, highlight: row));
  void pushDiagnostics(Key row) =>
      push(SettingsDiagnosticsScreen(controller: controller, highlight: row));

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
  return [
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
      open: () => push(
        SettingsRemindersScreen(
          controller: controller,
          highlight: SettingsKeys.reminderShowTokens,
        ),
      ),
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
        open: () => push(
          SettingsTranscriptionScreen(
            controller: controller,
            models: models,
            highlight: SettingsKeys.transcriptionModel,
          ),
        ),
      ),
      SettingsSearchEntry(
        title: AppStrings.transcriptionLanguageTitle,
        area: libraryArea(AppStrings.settingsSectionTranscription),
        rowKey: SettingsKeys.transcriptionLanguage,
        value: () async => TranscriptionSettingsSection.languageLabel(
          models.settings.language,
        ),
        open: () => push(
          SettingsTranscriptionScreen(
            controller: controller,
            models: models,
            highlight: SettingsKeys.transcriptionLanguage,
          ),
        ),
      ),
    ],
    if (controller.sync case final sync?)
      SettingsSearchEntry(
        title: AppStrings.settingsSectionSync,
        area: libraryArea(AppStrings.settingsSectionSync),
        rowKey: const Key('settings-area-sync'),
        value: () async => syncStatusLine(sync.status, DateTime.now()),
        open: () => push(
          SyncSettingsScreen(
            sync: sync,
            libraryName: p.basename(controller.root ?? ''),
          ),
        ),
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
