import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings_appearance.dart';
import 'package:niman/src/ui/settings_diagnostics.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_folders_paths.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_trash_history.dart';
import 'package:niman/src/ui/settings_updates.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/sync/sync_labels.dart';
import 'package:niman/src/ui/sync/sync_settings_screen.dart';
import 'package:path/path.dart' as p;

/// The settings home (issue #104): the areas a settings screen splits
/// into, grouped by what they edit — the app, the library, and the app's
/// own diagnostics — each opening its own screen.
///
/// The settings content, embedded as the Settings tab (bottom bar on
/// narrow, rail on wide).
final class SettingsBody extends StatefulWidget {
  /// Creates the settings body.
  const new({
    required this.controller,
    this.onClosed,
    this.spellCheck,
    this.transcription,
    super.key,
  });

  /// The session of the library whose settings this body edits.
  final LibrarySession controller;

  /// Called after "Close library" closes the session; the shell returns
  /// to the Files tab.
  final VoidCallback? onClosed;

  /// The editor's spelling state (T-PP-09), for the Editor area's toggle;
  /// null hides it.
  final EditorSpellCheck? spellCheck;

  /// The installation's transcription models; null hides their section.
  final TranscriptionModels? transcription;

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

final class _SettingsBodyState extends State<SettingsBody> {
  String? _libraryName;
  late final KeyboardPresence _keyboard;

  @override
  void initState() {
    super.initState();
    _keyboard = KeyboardPresence();
    _keyboard.listen();
    unawaited(_load());
  }

  @override
  void dispose() {
    _keyboard
      ..stopListening()
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final root = widget.controller.root;
    if (!mounted || root == null) return;
    setState(() => _libraryName = p.basename(root));
  }

  /// Pushes [screen], the area's own screen: the settings home stays on
  /// the route underneath, so back always lands back here.
  void _pushArea(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final libraryName = _libraryName;
    final keyboardAttached = _keyboard.attached;
    return ListenableBuilder(
      listenable: _keyboard,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            SettingsSection(AppStrings.settingsGroupApp),
            SettingsAreaRow(
              key: const Key('settings-area-appearance'),
              icon: Icons.palette_outlined,
              title: AppStrings.settingsSectionAppearance,
              onTap: () => _pushArea(
                context,
                SettingsAppearanceScreen(controller: controller),
              ),
            ),
            SettingsAreaRow(
              key: const Key('settings-area-editor'),
              icon: Icons.edit_outlined,
              title: AppStrings.settingsSectionEditor,
              onTap: () => _pushArea(
                context,
                SettingsEditorScreen(
                  controller: controller,
                  spellCheck: widget.spellCheck,
                ),
              ),
            ),
            // Update management exists only on the release channel
            // (issue #106): testing builds check no release channel, so
            // the whole area is out, not just its toggles.
            if (!isTestingBuild)
              SettingsAreaRow(
                key: const Key('settings-area-updates'),
                icon: Icons.system_update,
                title: AppStrings.settingsSectionUpdates,
                onTap: () => _pushArea(
                  context,
                  SettingsUpdatesScreen(controller: controller),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              // A Wrap, not a Row: a long library name next to its hint
              // must flow onto the next line on a phone, never past the
              // screen edge (the overflow the layout tests caught).
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  Text(
                    AppStrings.settingsGroupLibrary(libraryName ?? ''),
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    AppStrings.settingsGroupLibraryHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SettingsAreaRow(
              key: const Key('settings-area-folders'),
              icon: Icons.folder_outlined,
              title: AppStrings.settingsAreaFolders,
              onTap: () => _pushArea(
                context,
                SettingsFoldersPathsScreen(
                  controller: controller,
                  transcription: widget.transcription,
                  onClosed: widget.onClosed,
                ),
              ),
            ),
            // The status rides on the row, the way the mockup draws it
            // (issue #104): whether this library syncs, and when it last
            // did, is what the row is for — the screen behind it is the
            // configuration.
            if (controller.sync case final sync?)
              ListenableBuilder(
                listenable: sync,
                builder: (context, _) {
                  final status = sync.status;
                  return SettingsAreaRow(
                    key: const Key('settings-area-sync'),
                    icon: status.configured
                        ? syncStatusIcon(status)
                        : Icons.cloud_off_outlined,
                    title: AppStrings.settingsSectionSync,
                    subtitle: syncStatusLine(status, DateTime.now()),
                    onTap: () => _pushArea(
                      context,
                      SyncSettingsScreen(
                        sync: sync,
                        libraryName: p.basename(controller.root ?? ''),
                      ),
                    ),
                  );
                },
              ),
            SettingsAreaRow(
              key: const Key('settings-area-trash-history'),
              icon: Icons.restore,
              title: AppStrings.settingsAreaTrashHistory,
              onTap: () => _pushArea(
                context,
                SettingsTrashHistoryScreen(controller: controller),
              ),
            ),
            SettingsSection(AppStrings.settingsGroupApp),
            SettingsAreaRow(
              key: const Key('settings-area-diagnostics'),
              icon: Icons.health_and_safety,
              title: AppStrings.settingsAreaDiagnostics,
              onTap: () => _pushArea(
                context,
                SettingsDiagnosticsScreen(controller: controller),
              ),
            ),
            // The keyboard shortcut reference is useless without a
            // keyboard to press: with none seen the row says so instead
            // of opening a dead end.
            ListTile(
              key: const Key('keyboard-shortcuts'),
              leading: Icon(
                Icons.keyboard_alt,
                color: keyboardAttached
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                AppStrings.keyboardShortcutsTitle,
                style: keyboardAttached
                    ? null
                    : theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
              ),
              trailing: keyboardAttached
                  ? const Icon(Icons.chevron_right)
                  : Text(
                      AppStrings.settingsAreaKeyboardDisabled,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
              onTap: keyboardAttached
                  ? () => _pushArea(context, const KeyboardShortcutsScreen())
                  : null,
            ),
          ],
        );
      },
    );
  }
}

/// One area of the settings home (issue #104): the area's name with an
/// icon and a chevron, pushing the area's own screen. The icon is an
/// outline one — an area is a place, not a state.
final class SettingsAreaRow extends StatelessWidget {
  /// Creates the row for [title]'s area.
  const new({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  /// The area's icon, an outline one.
  final IconData icon;

  /// The area's name.
  final String title;

  /// What the row is about right now — the sync status, a version —
  /// shown under the title the way the mockup draws it.
  final String? subtitle;

  /// Opens the area's screen.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

// The sync area pushes [SyncSettingsScreen] straight from the home: it
// carries its own app bar (the WebDAV title over the library's name), so
// no wrapper screen is needed.
