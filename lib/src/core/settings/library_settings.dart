import 'package:drift/drift.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/db/app_database.dart';

/// Which editor a library writes in (T-WYS-03, default source).
enum EditorKind {
  /// The Markdown source editor (re_editor).
  source,

  /// The WYSIWYG surface (flutter_quill).
  wysiwyg,
}

/// Which engine draws a note's Markdown.
///
/// The switch exists because the two are meant to be compared. `legacy` is what
/// the app ships today: the source editor, the WYSIWYG editor and the preview,
/// each with its own parser, its own styling and its own idea of where a note
/// begins. `unified` is the one engine of
/// `docs/dev/unified-surface.md` — one parse, one theme, three modes over the
/// same pipeline — and it is opt-in until its render agrees with the preview
/// it is meant to replace.
enum MarkdownEngine {
  /// The three surfaces of today.
  legacy,

  /// The unified surface.
  unified,
}

/// The library tree sort order (T-UI-03).
enum TreeSort {
  /// Name ascending (default).
  nameAsc,

  /// Name descending.
  nameDesc,
}

/// The link format the editor's link button inserts.
enum LinkType {
  /// A wikilink `[[…]]` (the default).
  wikilink,

  /// A markdown link `[…](…)`.
  markdown,
}

/// At and above this width the shell is wide: the rail, the tree and the
/// note share the screen (spec: at 600 dp and up). Below it the phone
/// layout, where the tree and the note are two full-screen panes.
///
/// It used to be named for the editor|preview split, which landed here
/// and is gone: the width still decides the shell's shape, which is what
/// every reader of it was actually asking.
const double wideBreakpoint = 600;

/// The default folder (library-relative) of the list notes (T-TK-06).
const String defaultListFolder = 'Lists';

/// The default folder (library-relative) holding the note templates
/// (T-M4-05).
const String defaultTemplateFolder = 'Templates';

/// The default folder (library-relative) holding the attachments: images
/// copied in by the editor and voice-note clips alike (issue #56).
const String defaultAttachmentsFolder = 'assets';

/// Global app settings, a single row (id 1).
final class AppSettingsRepo {
  /// Creates the repo over the given [AppDatabase].
  new(this._db);

  final AppDatabase _db;

  /// The last opened library root, or null.
  Future<String?> lastLibraryPath() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? null : rows.first.libraryPath;
  }

  /// Persists `path` as the last opened library root.
  Future<void> setLastLibraryPath(String? path) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(libraryPath: Value(path)),
    );
  }

  /// Whether the debug log buffer records events (default true).
  Future<bool> debugLogsEnabled() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty || rows.first.debugLogsEnabled;
  }

  /// Persists the debug log recording toggle.
  Future<void> setDebugLogsEnabled({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(debugLogsEnabled: Value(enabled)),
    );
  }

  /// Whether the app checks GitHub Releases for updates (issue #81,
  /// default false). The manual check in Settings works regardless.
  Future<bool> autoUpdateEnabled() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isNotEmpty && rows.first.autoUpdateEnabled;
  }

  /// Persists the auto-update toggle.
  Future<void> setAutoUpdateEnabled({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(autoUpdateEnabled: Value(enabled)),
    );
  }

  /// Whether the window's × hides Niman to the tray (#209, default on).
  Future<bool> closeToTray() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty || rows.first.closeToTray;
  }

  /// Persists the close-to-tray choice.
  Future<void> setCloseToTray({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(closeToTray: Value(enabled)),
    );
  }

  /// The last update-check time, or null before the first check (issue
  /// #81).
  Future<DateTime?> lastUpdateCheck() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isEmpty) return null;
    final ms = rows.first.lastUpdateCheckMs;
    return ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  /// Persists the last update-check time.
  Future<void> setLastUpdateCheck(DateTime time) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(
        lastUpdateCheckMs: Value(time.millisecondsSinceEpoch),
      ),
    );
  }

  /// The stored UI language id (`system`, `en` or `it`).
  Future<AppLanguage> language() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty
        ? AppLanguage.system
        : AppLanguage.fromId(rows.first.language);
  }

  /// Persists the UI language.
  Future<void> setLanguage(AppLanguage language) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(language: Value(language.id)),
    );
  }

  /// The stored brightness choice (T-M6-05).
  Future<AppBrightness> themeBrightness() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty
        ? AppBrightness.system
        : AppBrightness.fromId(rows.first.themeBrightness);
  }

  /// Persists the brightness choice.
  Future<void> setThemeBrightness(AppBrightness brightness) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(themeBrightness: Value(brightness.id)),
    );
  }

  /// The stored palette (T-M6-05); a fresh install wears [AppPalette.niman].
  Future<AppPalette> themePalette() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty
        ? AppPalette.niman
        : AppPalette.fromId(rows.first.themePalette);
  }

  /// Persists the palette.
  Future<void> setThemePalette(AppPalette palette) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(themePalette: Value(palette.id)),
    );
  }

  /// The app version whose changelog was last seen (issue #80), or null
  /// on a fresh install — which is what keeps the update dialog off on
  /// the first launch.
  Future<String?> changelogSeenVersion() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? null : rows.first.changelogSeenVersion;
  }

  /// Persists [version] as the one the user has now seen.
  Future<void> setChangelogSeenVersion(String version) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(changelogSeenVersion: Value(version)),
    );
  }

  /// The keyboard shortcuts the user changed (#159), or null for none.
  Future<String?> keyMap() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? null : rows.first.keyMap;
  }

  /// Keeps [json] as the changed shortcuts.
  Future<void> setKeyMap(String json) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(keyMap: Value(json)),
    );
  }

  /// The commands pinned in the palette (#208), or null for none.
  Future<String?> pinnedCommands() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? null : rows.first.pinnedCommands;
  }

  /// Keeps [json] as the pinned commands.
  Future<void> setPinnedCommands(String json) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(pinnedCommands: Value(json)),
    );
  }

  Future<void> _ensureRow() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isNotEmpty) {
      return;
    }
    await _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            libraryPath: const Value(null),
          ),
        );
  }
}
