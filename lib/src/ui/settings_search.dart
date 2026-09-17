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

  const languageKey = Key('language-choice');
  const brightnessKey = Key('theme-brightness-setting');
  const paletteKey = Key('theme-palette-setting');
  const uiScaleKey = Key('ui-text-scale-setting');
  const splitKey = Key('split-ratio-setting');
  const toolbarKey = Key('toolbar-setting');
  const sourceKey = Key('editor-source-setting');
  const wysiwygKey = Key('editor-wysiwyg-setting');
  const previewKey = Key('preview-enabled-setting');
  const lineNumbersKey = Key('line-numbers-setting');
  const linkTypeKey = Key('link-type');
  const missingNoteKey = Key('missing-note-location');
  const noteScaleKey = Key('note-text-scale-setting');
  const indentKey = Key('indent-width');
  const listFolderKey = Key('list-folder-setting');
  const templateFolderKey = Key('template-folder-setting');
  const templateHelpKey = Key('template-help-setting');
  const attachmentsKey = Key('attachments-folder-setting');
  const quickNoteKey = Key('quick-note-setting');
  const trashKey = Key('trash-setting');
  const autoEmptyKey = Key('trash-auto-empty-setting');
  const historyVersionsKey = Key('history-versions-setting');
  const historyIntervalKey = Key('history-interval-setting');
  const autoUpdateKey = Key('auto-update-setting');
  const checkUpdatesKey = Key('check-updates-setting');
  const debugLogsKey = Key('debug-logs-setting');
  const exportLogKey = Key('export-log-setting');
  const changelogKey = Key('changelog-setting');
  const remindersKey = Key('reminder-show-tokens');
  const modelKey = Key('transcription-model-setting');
  const transcriptionLanguageKey = Key('transcription-language-setting');
  const reindexKey = Key('reindex-setting');
  const switchKey = Key('switch-library-setting');
  const closeKey = Key('close-library-setting');

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
      rowKey: languageKey,
      value: () async => AppStrings.languageName(await controller.language),
      open: () => pushAppearance(languageKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.themeBrightnessTitle,
      area: appearance,
      rowKey: brightnessKey,
      value: () async => switch (await controller.themeBrightness) {
        AppBrightness.system => AppStrings.themeBrightnessSystem,
        AppBrightness.day => AppStrings.themeBrightnessDay,
        AppBrightness.night => AppStrings.themeBrightnessNight,
      },
      open: () => pushAppearance(brightnessKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.themePaletteTitle,
      area: appearance,
      rowKey: paletteKey,
      value: () async =>
          SettingsAppearanceScreen.paletteName(await controller.themePalette),
      open: () => pushAppearance(paletteKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.uiTextScaleTitle,
      area: appearance,
      rowKey: uiScaleKey,
      value: () async =>
          AppStrings.textScaleValue(await controller.uiTextScale),
      open: () => pushAppearance(uiScaleKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.splitRatioTitle,
      area: appearance,
      rowKey: splitKey,
      value: () async =>
          AppStrings.splitRatioValue(await controller.splitRatio),
      open: () => pushAppearance(splitKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.toolbarSettingsTitle,
      area: editor,
      rowKey: toolbarKey,
      value: noValue,
      open: () => pushEditor(toolbarKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.editorKindSource,
      area: editor,
      rowKey: sourceKey,
      value: () async => onOff(
        on: (await controller.enabledEditors).contains(EditorKind.source),
      ),
      open: () => pushEditor(sourceKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.editorKindWysiwyg,
      area: editor,
      rowKey: wysiwygKey,
      value: () async => onOff(
        on: (await controller.enabledEditors).contains(EditorKind.wysiwyg),
      ),
      open: () => pushEditor(wysiwygKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.settingsPreviewEnabledTitle,
      area: editor,
      rowKey: previewKey,
      value: () async => onOff(on: await controller.previewEnabled),
      open: () => pushEditor(previewKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.lineNumbersTitle,
      area: editor,
      rowKey: lineNumbersKey,
      value: () async => onOff(on: await controller.lineNumbersEnabled),
      open: () => pushEditor(lineNumbersKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.linkTypeTitle,
      area: editor,
      rowKey: linkTypeKey,
      value: () async => switch (await controller.linkType) {
        LinkType.wikilink => AppStrings.linkTypeWikilink,
        LinkType.markdown => AppStrings.linkTypeMarkdown,
      },
      open: () => pushEditor(linkTypeKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.missingNoteLocationTitle,
      area: editor,
      rowKey: missingNoteKey,
      value: () async => switch (await controller.missingNoteLocation) {
        MissingNoteLocation.libraryRoot => AppStrings.missingNoteLocationRoot,
        MissingNoteLocation.currentFolder =>
          AppStrings.missingNoteLocationCurrentFolder,
      },
      open: () => pushEditor(missingNoteKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.noteTextScaleTitle,
      area: editor,
      rowKey: noteScaleKey,
      value: () async =>
          AppStrings.textScaleValue(await controller.noteTextScale),
      open: () => pushEditor(noteScaleKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.indentWidthTitle,
      area: editor,
      rowKey: indentKey,
      value: () async =>
          AppStrings.indentWidthValue(await controller.indentWidth),
      open: () => pushEditor(indentKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.listFolderTitle,
      area: folders,
      rowKey: listFolderKey,
      value: () async => ops == null ? null : await ops.listNoteFolder,
      open: () => pushFolders(listFolderKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.templateFolderTitle,
      area: folders,
      rowKey: templateFolderKey,
      value: () async => ops == null ? null : await ops.templateFolder,
      open: () => pushFolders(templateFolderKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.templateHelpTitle,
      area: folders,
      rowKey: templateHelpKey,
      value: noValue,
      open: () => pushFolders(templateHelpKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.attachmentsFolderTitle,
      area: folders,
      rowKey: attachmentsKey,
      value: () async => ops == null ? null : await ops.attachmentsFolder,
      open: () => pushFolders(attachmentsKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.quickNoteTitle,
      area: folders,
      rowKey: quickNoteKey,
      value: () async => ops == null
          ? null
          : (await ops.quickNotePath) ?? AppStrings.quickNoteUnset,
      open: () => pushFolders(quickNoteKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.trashTitle,
      area: trashHistory,
      rowKey: trashKey,
      value: () async => ops == null ? null : onOff(on: await ops.trashEnabled),
      open: () => pushTrash(trashKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.trashAutoEmptyTitle,
      area: trashHistory,
      rowKey: autoEmptyKey,
      value: () async =>
          AppStrings.trashAutoEmptyValue(await controller.trashAutoEmptyDays),
      open: () => pushTrash(autoEmptyKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.historyVersionsTitle,
      area: trashHistory,
      rowKey: historyVersionsKey,
      value: () async =>
          AppStrings.historyVersionsValue(await controller.historyVersions),
      open: () => pushTrash(historyVersionsKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.historyIntervalTitle,
      area: trashHistory,
      rowKey: historyIntervalKey,
      value: () async => AppStrings.historyIntervalValue(
        await controller.historyIntervalMinutes,
      ),
      open: () => pushTrash(historyIntervalKey),
    ),
    // What empties the trash for good lands on the screen that
    // holds it.
    SettingsSearchEntry(
      title: AppStrings.trashDeletePermanently,
      area: trashHistory,
      rowKey: trashKey,
      value: noValue,
      open: () => push(TrashScreen(controller: controller)),
    ),
    if (!isTestingBuild) ...[
      SettingsSearchEntry(
        title: AppStrings.autoUpdateTitle,
        area: AppStrings.settingsSectionUpdates,
        rowKey: autoUpdateKey,
        value: () async => onOff(on: await controller.autoUpdateEnabled),
        open: () => pushUpdates(autoUpdateKey),
      ),
      SettingsSearchEntry(
        title: AppStrings.checkForUpdatesTitle,
        area: AppStrings.settingsSectionUpdates,
        rowKey: checkUpdatesKey,
        value: noValue,
        open: () => pushUpdates(checkUpdatesKey),
      ),
    ],
    SettingsSearchEntry(
      title: AppStrings.debugLogsTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: debugLogsKey,
      value: () async => onOff(on: await controller.debugLogsEnabled),
      open: () => pushDiagnostics(debugLogsKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.exportLogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: exportLogKey,
      value: noValue,
      open: () => pushDiagnostics(exportLogKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.changelogTitle,
      area: AppStrings.settingsAreaDiagnostics,
      rowKey: changelogKey,
      value: noValue,
      open: () => pushDiagnostics(changelogKey),
    ),
    SettingsSearchEntry(
      title: AppStrings.reminderShowTokensTitle,
      area: libraryArea(AppStrings.settingsSectionReminders),
      rowKey: remindersKey,
      value: () async => onOff(on: await controller.reminderShowTokens),
      open: () => push(
        SettingsRemindersScreen(
          controller: controller,
          highlight: remindersKey,
        ),
      ),
    ),
    if (transcription case final models?) ...[
      SettingsSearchEntry(
        title: AppStrings.transcriptionModelTitle,
        area: libraryArea(AppStrings.settingsSectionTranscription),
        rowKey: modelKey,
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
            highlight: modelKey,
          ),
        ),
      ),
      SettingsSearchEntry(
        title: AppStrings.transcriptionLanguageTitle,
        area: libraryArea(AppStrings.settingsSectionTranscription),
        rowKey: transcriptionLanguageKey,
        value: () async => TranscriptionSettingsSection.languageLabel(
          models.settings.language,
        ),
        open: () => push(
          SettingsTranscriptionScreen(
            controller: controller,
            models: models,
            highlight: transcriptionLanguageKey,
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
      rowKey: reindexKey,
      value: noValue,
      open: () => flashHome(reindexKey),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.switchLibraryTitle,
      area: maintenance,
      rowKey: switchKey,
      value: noValue,
      open: () => flashHome(switchKey),
      onHome: true,
    ),
    SettingsSearchEntry(
      title: AppStrings.closeLibraryTitle,
      area: maintenance,
      rowKey: closeKey,
      value: noValue,
      open: () => flashHome(closeKey),
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
