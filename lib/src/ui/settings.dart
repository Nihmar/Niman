import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings_appearance.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_diagnostics.dart';
import 'package:niman/src/ui/settings_editor.dart';
import 'package:niman/src/ui/settings_folders_paths.dart';
import 'package:niman/src/ui/settings_maintenance.dart';
import 'package:niman/src/ui/settings_reminders.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_search.dart';
import 'package:niman/src/ui/settings_transcription.dart';
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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _searchToken = 0;

  /// The live search results (issue #104): each entry with its current
  /// value, loaded for the matches only.
  List<(SettingsSearchEntry, String?)> _results = const [];

  /// The home row the search landed on (a maintenance action): flashed
  /// in place once the search clears.
  Key? _homeHighlight;

  bool get _searching => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _keyboard = KeyboardPresence();
    _keyboard.listen();
    unawaited(_load());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
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

  /// Re-runs the search 200 ms after the last keystroke: every keystroke
  /// fans out into session reads, so they wait for a pause.
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text;
    setState(() => _homeHighlight = null);
    if (query.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    final token = ++_searchToken;
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      unawaited(_runSearch(query, token));
    });
  }

  Future<void> _runSearch(String query, int token) async {
    final controller = widget.controller;
    final matches = matchSettingsEntries(
      settingsSearchEntries(
        controller: controller,
        transcription: widget.transcription,
        spellCheck: widget.spellCheck,
        libraryName: _libraryName ?? '',
        context: context,
        flashHome: _flashHome,
      ),
      query,
    );
    final loaded = await Future.wait([
      for (final entry in matches)
        () async {
          String? value;
          try {
            value = await entry.value();
          } on Object catch (_) {
            value = null;
          }
          return (entry, value);
        }(),
    ]);
    if (!mounted || token != _searchToken) return;
    setState(() => _results = loaded);
  }

  /// Clears the search and flashes the home [row] (a maintenance
  /// action): the row remounts under the highlight scope and lights up.
  void _flashHome(Key row) {
    _searchDebounce?.cancel();
    _searchToken++;
    _searchController.clear();
    setState(() {
      _results = const [];
      _homeHighlight = row;
    });
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
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                key: const Key('settings-search-field'),
                controller: _searchController,
                onChanged: (_) => _onSearchChanged(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: AppStrings.settingsSearchHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: _searching
                      ? IconButton(
                          key: const Key('settings-search-clear'),
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchDebounce?.cancel();
                            _searchToken++;
                            _searchController.clear();
                            setState(() {
                              _results = const [];
                              _homeHighlight = null;
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: _searching
                  ? _buildResults(context)
                  : SettingsHighlight(
                      target: _homeHighlight,
                      child: _buildAreas(
                        context,
                        controller: controller,
                        theme: theme,
                        libraryName: libraryName,
                        keyboardAttached: keyboardAttached,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// The results of the live search (issue #104): each with its current
  /// value and the area it came from, opening its screen highlighted.
  Widget _buildResults(BuildContext context) {
    final theme = Theme.of(context);
    final results = _results;
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            key: const Key('settings-search-count'),
            AppStrings.settingsSearchResults(results.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final (entry, value) in results)
          ListTile(
            key: Key(
              'settings-search-${(entry.rowKey as ValueKey<String>).value}',
            ),
            title: Text(entry.title),
            subtitle: Text(
              entry.area,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null)
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: entry.open,
          ),
      ],
    );
  }

  /// The settings home itself: the areas grouped by what they edit.
  Widget _buildAreas(
    BuildContext context, {
    required LibrarySession controller,
    required ThemeData theme,
    required String? libraryName,
    required bool keyboardAttached,
  }) {
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
        // The keyboard shortcut reference is useless without a
        // keyboard to press: with none seen the row says so instead
        // of opening a dead end.
        ListTile(
          key: const Key('keyboard-shortcuts'),
          leading: Icon(
            Icons.keyboard_alt_outlined,
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
        SettingsAreaRow(
          key: const Key('settings-area-diagnostics'),
          icon: Icons.health_and_safety,
          title: AppStrings.settingsAreaDiagnostics,
          onTap: () => _pushArea(
            context,
            SettingsDiagnosticsScreen(controller: controller),
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
            SettingsFoldersPathsScreen(controller: controller),
          ),
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
        // App-wide, like the models it points at, but under the
        // library group: that is where the voice notes it
        // transcribes live. The current model rides on the row.
        if (widget.transcription case final transcription?)
          ListenableBuilder(
            listenable: transcription,
            builder: (context, _) {
              final model = transcription.defaultModel;
              return SettingsAreaRow(
                key: const Key('settings-area-transcription'),
                icon: Icons.mic_outlined,
                title: AppStrings.settingsSectionTranscription,
                subtitle: model == null
                    ? AppStrings.transcriptionModelNone
                    : AppStrings.transcriptionModelName(model),
                onTap: () => _pushArea(
                  context,
                  SettingsTranscriptionScreen(
                    controller: controller,
                    models: transcription,
                  ),
                ),
              );
            },
          ),
        SettingsAreaRow(
          key: const Key('settings-area-reminders'),
          icon: Icons.notifications_outlined,
          title: AppStrings.settingsSectionReminders,
          onTap: () => _pushArea(
            context,
            SettingsRemindersScreen(controller: controller),
          ),
        ),
        SettingsMaintenanceGroup(
          controller: controller,
          onClosed: widget.onClosed,
        ),
      ],
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
