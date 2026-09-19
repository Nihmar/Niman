import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/changelog.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_area_rows.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_maintenance.dart';
import 'package:niman/src/ui/settings_navigation.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/settings_search.dart';
import 'package:niman/src/ui/settings_section_pane.dart';
import 'package:niman/src/ui/strings.dart';
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
    this.navigation,
    this.libraryRows = true,
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

  /// The desktop's two columns (issue #172): when given, this body is the
  /// left column — the areas select rather than open, and the search
  /// shows its row in the right column — and [SettingsSectionPane] draws
  /// the selection. Null on the phone, where each area is a screen.
  final SettingsNavigation? navigation;

  /// Whether Maintenance offers Switch library and Close library. Not in
  /// the settings window (#203): the rail's library window does both.
  final bool libraryRows;

  @override
  State<SettingsBody> createState() => _SettingsBodyState();
}

final class _SettingsBodyState extends State<SettingsBody> {
  String? _libraryName;
  String? _version;
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
    // Kept out of the load above: the platform channel behind
    // [appVersion] has no answer in the test environment and would hold
    // the home's first build hostage.
    unawaited(_loadVersion());
  }

  /// Loads the installed version for the Updates row (issue #104).
  Future<void> _loadVersion() async {
    String? version;
    try {
      version = await appVersion();
    } on Exception catch (_) {
      // Display-only: no answer just leaves the row bare.
    }
    if (mounted && version != null) {
      setState(() => _version = version);
    }
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
        openArea: _openArea,
        keyboardAttached: _keyboard.attached,
        libraryRows: widget.libraryRows,
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

  /// The areas, as this body lists them.
  List<SettingsArea> _areas() => settingsAreas(
    controller: widget.controller,
    spellCheck: widget.spellCheck,
    transcription: widget.transcription,
    keyboardAttached: _keyboard.attached,
    version: _version,
  );

  /// Opens [area] with [row] flashed: in the right column on the desktop,
  /// as its own screen on the phone.
  void _openArea(SettingsAreaId area, Key? row) {
    final navigation = widget.navigation;
    if (navigation != null) {
      navigation.select(area, highlight: row);
      return;
    }
    for (final candidate in _areas()) {
      if (candidate.id == area) {
        _pushArea(context, candidate.build(row));
        return;
      }
    }
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
    final areas = _areas();
    final navigation = widget.navigation;
    Widget row(SettingsArea area) {
      Widget build() => navigation == null
          ? SettingsAreaRow.of(area, onTap: () => _openArea(area.id, null))
          : SettingsNavItem(
              area: area,
              selected: navigation.selected == area.id,
              onTap: () => navigation.select(area.id),
            );
      final listenable = area.listenable;
      return listenable == null
          ? build()
          : ListenableBuilder(
              listenable: listenable,
              builder: (context, _) => build(),
            );
    }

    Widget list() => ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        SettingsSection(AppStrings.settingsGroupApp),
        for (final area in areas)
          if (area.group == SettingsGroup.app) row(area),
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
        for (final area in areas)
          if (area.group == SettingsGroup.library) row(area),
        SettingsMaintenanceGroup(
          controller: controller,
          onClosed: widget.onClosed,
          compact: navigation != null,
          libraryRows: widget.libraryRows,
        ),
      ],
    );
    return navigation == null
        ? list()
        : ListenableBuilder(
            listenable: navigation,
            builder: (context, _) => list(),
          );
  }
}
