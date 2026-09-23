/// The settings areas, listed once (issue #172).
///
/// The phone shows them as a list whose rows open each area's screen; the
/// desktop shows the same list as the left column, with the selected
/// area on the right. Both read [settingsAreas], so an area added here
/// shows up in both shapes, with the same icon, name and group.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/journal/settings_journal.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings_appearance.dart';
import 'package:niman/src/ui/settings_commands.dart';
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
import 'package:path/path.dart' as p;

/// Which area a settings row lives in.
enum SettingsAreaId {
  /// Language, theme, text sizes.
  appearance,

  /// The editors and how they behave.
  editor,

  /// The keyboard shortcuts.
  shortcuts,

  /// What the command palette can run, and when (#207).
  commands,

  /// The release channel.
  updates,

  /// Logs, version, changelog.
  diagnostics,

  /// The library's folders.
  folders,

  /// The journal (#7).
  journal,

  /// Trash and note history.
  trashHistory,

  /// The library's server.
  sync,

  /// The voice-note models.
  transcription,

  /// Reminder notifications.
  reminders,
}

/// A place in the settings: an area, and a row in it to flash (#229).
///
/// The command palette answers with settings rows as well as commands
/// and notes, and a pick has to open the settings *there* — the area and
/// the row — rather than on the home with a search to redo.
typedef SettingsTarget = ({SettingsAreaId area, Key? row});

/// What an area edits: the app, or the open library.
enum SettingsGroup {
  /// The installation: the same for every library.
  app,

  /// The open library, whose name the group carries.
  library,
}

/// One area of the settings: how it is listed and how it is built.
final class SettingsArea {
  /// Describes the area [id].
  const new({
    required this.id,
    required this.group,
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.build,
    this.subtitle,
    this.listenable,
    this.enabled = true,
    this.disabledNote,
  });

  /// Which area this is.
  final SettingsAreaId id;

  /// Where it is listed.
  final SettingsGroup group;

  /// The key its row in the list carries.
  final Key rowKey;

  /// Its outline icon, read at build (sync's follows its status).
  final IconData Function() icon;

  /// Its name.
  final String title;

  /// What it is about right now (the sync status, the version), read at
  /// build; null shows nothing.
  final String? Function()? subtitle;

  /// What [icon] and [subtitle] follow, rebuilt when it changes.
  final Listenable? listenable;

  /// Whether it can be opened here: the shortcut reference needs a
  /// keyboard to press.
  final bool enabled;

  /// Why it cannot, shown in place of the way in.
  final String? disabledNote;

  /// Builds its screen, with the highlight as the row the search landed on.
  final Widget Function(Key? highlight) build;
}

/// Every area the settings show, in their order.
///
/// Some exist only where they can work: Updates on the release channel
/// (issue #106), Sync when the session has a sync engine, Transcription
/// when the installation has models. [version] rides on the Updates row.
List<SettingsArea> settingsAreas({
  required LibrarySession controller,
  required EditorSpellCheck? spellCheck,
  required TranscriptionModels? transcription,
  required bool keyboardAttached,
  String? version,
}) {
  final sync = controller.sync;
  return [
    SettingsArea(
      id: SettingsAreaId.appearance,
      group: SettingsGroup.app,
      rowKey: const Key('settings-area-appearance'),
      icon: () => Icons.palette_outlined,
      title: AppStrings.settingsSectionAppearance,
      build: (highlight) => SettingsAppearanceScreen(
        controller: controller,
        highlight: highlight,
      ),
    ),
    SettingsArea(
      id: SettingsAreaId.editor,
      group: SettingsGroup.app,
      rowKey: const Key('settings-area-editor'),
      icon: () => Icons.edit_outlined,
      title: AppStrings.settingsSectionEditor,
      build: (highlight) => SettingsEditorScreen(
        controller: controller,
        spellCheck: spellCheck,
        highlight: highlight,
      ),
    ),
    // The reference is useless without a keyboard to press: with none
    // seen, the row says so instead of opening a dead end.
    SettingsArea(
      id: SettingsAreaId.shortcuts,
      group: SettingsGroup.app,
      rowKey: const Key('keyboard-shortcuts'),
      icon: () => Icons.keyboard_alt_outlined,
      title: AppStrings.keyboardShortcutsTitle,
      enabled: keyboardAttached,
      disabledNote: AppStrings.settingsAreaKeyboardDisabled,
      build: (highlight) =>
          KeyboardShortcutsScreen(controller: controller, highlight: highlight),
    ),
    // Without a keyboard too: the phone reaches the palette's commands
    // as well, and they show there on the same conditions.
    SettingsArea(
      id: SettingsAreaId.commands,
      group: SettingsGroup.app,
      rowKey: const Key('settings-area-commands'),
      icon: () => Icons.bolt_outlined,
      title: AppStrings.commandsTitle,
      build: (highlight) => SettingsCommandsScreen(highlight: highlight),
    ),
    if (!isTestingBuild)
      SettingsArea(
        id: SettingsAreaId.updates,
        group: SettingsGroup.app,
        rowKey: const Key('settings-area-updates'),
        icon: () => Icons.system_update,
        title: AppStrings.settingsSectionUpdates,
        subtitle: () => version,
        build: (highlight) =>
            SettingsUpdatesScreen(controller: controller, highlight: highlight),
      ),
    SettingsArea(
      id: SettingsAreaId.diagnostics,
      group: SettingsGroup.app,
      rowKey: const Key('settings-area-diagnostics'),
      icon: () => Icons.health_and_safety,
      title: AppStrings.settingsAreaDiagnostics,
      build: (highlight) => SettingsDiagnosticsScreen(
        controller: controller,
        highlight: highlight,
      ),
    ),
    SettingsArea(
      id: SettingsAreaId.folders,
      group: SettingsGroup.library,
      rowKey: const Key('settings-area-folders'),
      icon: () => Icons.folder_outlined,
      title: AppStrings.settingsAreaFolders,
      build: (highlight) => SettingsFoldersPathsScreen(
        controller: controller,
        highlight: highlight,
      ),
    ),
    SettingsArea(
      id: SettingsAreaId.journal,
      group: SettingsGroup.library,
      rowKey: const Key('settings-area-journal'),
      icon: () => Icons.calendar_today_outlined,
      title: AppStrings.paletteGroupJournal,
      build: (highlight) =>
          SettingsJournalScreen(controller: controller, highlight: highlight),
    ),
    SettingsArea(
      id: SettingsAreaId.trashHistory,
      group: SettingsGroup.library,
      rowKey: const Key('settings-area-trash-history'),
      icon: () => Icons.restore,
      title: AppStrings.settingsAreaTrashHistory,
      build: (highlight) => SettingsTrashHistoryScreen(
        controller: controller,
        highlight: highlight,
      ),
    ),
    // The status rides on the row (issue #104): whether this library
    // syncs, and when it last did, is what the row is for.
    if (sync != null)
      SettingsArea(
        id: SettingsAreaId.sync,
        group: SettingsGroup.library,
        rowKey: const Key('settings-area-sync'),
        listenable: sync,
        icon: () => sync.status.configured
            ? syncStatusIcon(sync.status)
            : Icons.cloud_off_outlined,
        title: AppStrings.settingsSectionSync,
        subtitle: () => syncStatusLine(sync.status, DateTime.now()),
        build: (_) => SyncSettingsScreen(
          sync: sync,
          libraryName: p.basename(controller.root ?? ''),
        ),
      ),
    // App-wide, like the models it points at, but under the library:
    // that is where the voice notes it transcribes live.
    if (transcription != null)
      SettingsArea(
        id: SettingsAreaId.transcription,
        group: SettingsGroup.library,
        rowKey: const Key('settings-area-transcription'),
        listenable: transcription,
        icon: () => Icons.mic_outlined,
        title: AppStrings.settingsSectionTranscription,
        subtitle: () {
          final model = transcription.defaultModel;
          return model == null
              ? AppStrings.transcriptionModelNone
              : AppStrings.transcriptionModelName(model);
        },
        build: (highlight) => SettingsTranscriptionScreen(
          controller: controller,
          models: transcription,
          highlight: highlight,
        ),
      ),
    SettingsArea(
      id: SettingsAreaId.reminders,
      group: SettingsGroup.library,
      rowKey: const Key('settings-area-reminders'),
      icon: () => Icons.notifications_outlined,
      title: AppStrings.settingsSectionReminders,
      build: (highlight) =>
          SettingsRemindersScreen(controller: controller, highlight: highlight),
    ),
  ];
}
