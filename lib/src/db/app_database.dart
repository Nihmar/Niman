import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Global app settings; a single row (id 1).
class AppSettings extends Table {
  /// Row id; always 1.
  IntColumn get id => integer()();

  /// Last opened library root, used to resume the library on startup;
  /// null until a library has been opened.
  TextColumn get libraryPath => text().named('library_path').nullable()();

  /// Whether the in-app debug log buffer records events (default true).
  BoolColumn get debugLogsEnabled =>
      boolean().named('debug_logs_enabled').withDefault(const Constant(true))();

  /// Whether the app checks GitHub Releases for updates (issue #81).
  ///
  /// Off by default: the user opts into the launch + six-hourly check.
  /// The manual "Check for updates" row in Settings works regardless.
  BoolColumn get autoUpdateEnabled => boolean()
      .named('auto_update_enabled')
      .withDefault(const Constant(false))();

  /// Whether the window's × hides Niman to the tray and leaves it
  /// running (#209), instead of quitting.
  ///
  /// On by default on the desktops: the desktop reminders need the
  /// process alive to fire, and the tray icon is how you get the window
  /// back. The tray's Quit, and the × with this off, quit for real.
  BoolColumn get closeToTray =>
      boolean().named('close_to_tray').withDefault(const Constant(true))();

  /// Last update-check time, milliseconds since epoch; null until the
  /// first check runs (issue #81).
  IntColumn get lastUpdateCheckMs =>
      integer().named('last_update_check_ms').nullable()();

  /// The preview layout mode: `auto` (width-based), `split` or `switch`
  /// (forced; default `auto`).
  ///
  /// App-wide, with the split ratio: unlike the editor settings T-ML-10
  /// moved into the library folder, these two follow the screen. Carrying
  /// them in the folder would move a tablet's layout onto a phone.
  TextColumn get previewMode =>
      text().named('preview_mode').withDefault(const Constant('auto'))();

  /// The editor|preview split fraction (0..1; default 0.55).
  RealColumn get splitRatio =>
      real().named('split_ratio').withDefault(const Constant(0.55))();

  /// The UI language: `system` (follow the OS, the default), `en` or
  /// `it`.
  TextColumn get language => text().withDefault(const Constant('system'))();

  /// How bright the app is: `system` (follow the device, the default),
  /// `day` or `night` (T-M6-05).
  ///
  /// App-wide, like the language and unlike the two text sizes: the
  /// screen is the screen whichever library is open on it.
  TextColumn get themeBrightness =>
      text().named('theme_brightness').withDefault(const Constant('system'))();

  /// The palette: `niman` (the app's own colors, and what a fresh install
  /// wears), `system` (the device's own colors), `catppuccin`,
  /// `solarized` or `gruvbox`.
  TextColumn get themePalette =>
      text().named('theme_palette').withDefault(const Constant('niman'))();

  /// The settings waiting to reach the libraries they belong to: the
  /// dropped `library_settings` rows (T-ML-02) and the editor settings
  /// that used to be one value for every library (T-ML-10).
  ///
  /// A JSON object keyed by absolute library path; empty (`''`) once
  /// every one of them has been opened at least once, and on any install
  /// that never had the table. It exists because the two events cannot be
  /// made to coincide: the table is dropped when the database migrates,
  /// which on Android happens at startup, while the library folder is
  /// only writable later, after the storage permission — and a library on
  /// a disconnected drive may not be writable for weeks.
  TextColumn get legacyLibrarySettings =>
      text().named('legacy_library_settings').withDefault(const Constant(''))();

  /// The app version whose changelog the user last saw (issue #80);
  /// null until the first launch has written it, which is what turns the
  /// update dialog off on a fresh install.
  TextColumn get changelogSeenVersion =>
      text().named('changelog_seen_version').nullable()();

  /// The keyboard shortcuts the user changed (#159), as `KeyMap.toJson`
  /// writes them; null while none was. The device's, never a library's:
  /// a shortcut belongs to the keyboard.
  TextColumn get keyMap => text().named('key_map').nullable()();

  /// The commands pinned in the palette (#208), as a JSON array of their
  /// names, in pinning order; null while none was. The device's, like the
  /// key map: a pin is about how this machine is used.
  TextColumn get pinnedCommands => text().named('pinned_commands').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One placed home-screen widget instance (issue 6).
///
/// App-side on purpose, like [KnownLibraries]: forgetting a library drops
/// the rows that pointed at it, and the folder itself never holds widget
/// state. Each Android `appWidgetId` gets its own row, so the same widget
/// can appear twice for two libraries (or two notes) — a widget never
/// assumes the last-opened library.
class WidgetConfigs extends Table {
  /// The Android widget instance id; the primary key.
  IntColumn get androidWidgetId => integer().named('android_widget_id')();

  /// Which widget this is: `todo` or `note`.
  TextColumn get provider => text()();

  /// Absolute, normalized path of the library root this instance reads.
  TextColumn get libraryPath => text().named('library_path')();

  /// Library-relative path of the pinned note (`note` widgets only).
  TextColumn get notePath => text().named('note_path').nullable()();

  /// When the instance was last (re)configured.
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {androidWidgetId};
}

/// The notes left open in a library on this device (issue #23): its
/// panes, tabs and where each note was left, as the workspace's own JSON.
///
/// App-side on purpose, like [KnownLibraries] — decision 1 of the plan on
/// #23. `.niman/settings.json` syncs, and a phone must not inherit the
/// desktop's tabs; how a device is laid out is not the library's data.
/// Forgetting the library drops its row.
@DataClassName('WorkspaceRow')
class Workspaces extends Table {
  /// Absolute, normalized path of the library root; the primary key.
  TextColumn get libraryPath => text().named('library_path')();

  /// The workspace, as `Workspace.toJson` writes it.
  TextColumn get state => text()();

  /// When it was last written.
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {libraryPath};
}

/// How a library is shown on this device: the settings of its
/// `LibraryConfig` that describe the screen and the person rather than
/// the library (`LibraryConfig.deviceKeys`) — the tree's width, the text
/// scale, the editor and its toggles.
///
/// Kept here rather than in `.niman/settings.json`, which travels with
/// the library: a width set on a desktop means nothing on a phone, and
/// every tweak of one rewrote the shared file and synced it everywhere.
/// Forgetting the library drops its row.
@DataClassName('LibraryDeviceSettingsRow')
class LibraryDeviceSettings extends Table {
  /// Absolute, normalized path of the library root; the primary key.
  TextColumn get libraryPath => text().named('library_path')();

  /// The device keys, as a JSON object in the `settings.json` format.
  TextColumn get settings => text()();

  /// When it was last written.
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {libraryPath};
}

/// A library the app knows about: one row per entry on the home screen
/// (T-ML-04).
///
/// App-side on purpose. Forgetting a library removes its row and touches
/// nothing inside the folder, and a folder is a library whether or not
/// this table has ever heard of it — the registry is the list, not the
/// definition.
class KnownLibraries extends Table {
  /// Absolute, normalized path of the library root; the primary key.
  TextColumn get path => text()();

  /// Display name; the folder's own name unless the user renames it.
  TextColumn get name => text()();

  /// When the library was last opened.
  DateTimeColumn get lastOpened => dateTime().named('last_opened')();

  @override
  Set<Column> get primaryKey => {path};
}

/// Where a library syncs to: one row per library (M5, docs/dev/sync.md,
/// "Configuration").
///
/// App-side on purpose, like [KnownLibraries]: the same server can have a
/// different URL on each device, and a copied library folder must not
/// start syncing into the original's remote. The password is never here —
/// it lives in the OS secure storage (`SyncSecretStore`).
class SyncDestinations extends Table {
  /// Absolute, normalized path of the library root; the primary key.
  TextColumn get libraryPath => text().named('library_path')();

  /// The remote folder the library maps to, always ending with `/`.
  TextColumn get url => text()();

  /// The WebDAV user; empty for no authentication.
  TextColumn get username => text().withDefault(const Constant(''))();

  /// Off stops every trigger; the state rows stay.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Whether the automatic triggers (after an edit, on resume, periodic)
  /// run; manual sync always works.
  BoolColumn get autoSync =>
      boolean().named('auto_sync').withDefault(const Constant(true))();

  /// The periodic trigger while the app is open, in seconds; 0 = off.
  IntColumn get intervalSeconds =>
      integer().named('interval_seconds').withDefault(const Constant(60))();

  /// Whether the automatic triggers skip mobile data.
  BoolColumn get wifiOnly =>
      boolean().named('wifi_only').withDefault(const Constant(false))();

  /// The capability probe's JSON (`WebDavCapabilities`); `{}` = never
  /// probed.
  TextColumn get capabilities => text().withDefault(const Constant('{}'))();

  /// The last full sync that ended without errors, ms since epoch.
  IntColumn get lastSyncAtMs => integer().named('last_sync_at_ms').nullable()();

  /// The last failure, short and user-readable; never a secret.
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  Set<Column> get primaryKey => {libraryPath};
}

/// What both sides agreed on at the last successful sync of one file
/// (docs/dev/sync.md, "State: `sync_items`").
///
/// This is what tells "deleted here" from "created there", so it cannot
/// be rebuilt from disk — which is why it lives here and not in the
/// per-library index, which is dropped on every schema bump.
class SyncItems extends Table {
  /// Absolute, normalized library root.
  TextColumn get libraryPath => text().named('library_path')();

  /// Library-relative, `/`-separated file path.
  TextColumn get path => text()();

  /// Hex sha256 of the agreed content.
  TextColumn get localSha256 => text().named('local_sha256')();

  /// Size of the agreed content in bytes.
  IntColumn get localSize => integer().named('local_size')();

  /// Disk mtime right after the sync wrote or read the file, ms.
  IntColumn get localMtimeMs => integer().named('local_mtime_ms')();

  /// The remote ETag as sent; null when the server has none.
  TextColumn get remoteEtag => text().named('remote_etag').nullable()();

  /// The remote size in bytes.
  IntColumn get remoteSize => integer().named('remote_size')();

  /// The remote `getlastmodified`, ms (one-second resolution).
  IntColumn get remoteMtimeMs => integer().named('remote_mtime_ms')();

  /// Whether the listing this row was recorded from could not rule out a
  /// second write within the same second: a server without ETags whose
  /// `getlastmodified` was the server's current second. The next
  /// reconcile hashes the remote instead of trusting size and mtime.
  BoolColumn get remoteUnverified =>
      boolean().named('remote_unverified').withDefault(const Constant(false))();

  /// The remote `oc:fileid`, when the server has one.
  TextColumn get remoteFileId => text().named('remote_file_id').nullable()();

  /// The `.history` version pinned as the merge base; null for
  /// attachments and when history is off.
  IntColumn get baseVersion => integer().named('base_version').nullable()();

  /// For the library state files (`.niman/settings.json`, `counters.json`),
  /// which keep no history: the agreed content itself, the base of their
  /// key-by-key merge. Null for every other file.
  TextColumn get baseText => text().named('base_text').nullable()();

  /// When this agreement was recorded, ms.
  IntColumn get syncedAtMs => integer().named('synced_at_ms')();

  @override
  Set<Column> get primaryKey => {libraryPath, path};
}

/// A hint that something happened to a path since the last sync
/// (docs/dev/sync.md, "Queue and triggers"): a persisted, coalescing
/// queue that survives restarts and carries the retry backoff.
class SyncOps extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// Absolute, normalized library root.
  TextColumn get libraryPath => text().named('library_path')();

  /// Library-relative, `/`-separated path (a file, or a folder for a
  /// folder move or delete).
  TextColumn get path => text()();

  /// `changed`, `deleted` or `moved` (`SyncOpKind`).
  TextColumn get kind => text()();

  /// Where a `moved` path came from.
  TextColumn get fromPath => text().named('from_path').nullable()();

  /// Failed runs so far.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Not retried before this time, ms; 0 = due now.
  IntColumn get nextAttemptAtMs =>
      integer().named('next_attempt_at_ms').withDefault(const Constant(0))();

  /// The last failure, short; never a secret.
  TextColumn get lastError => text().named('last_error').nullable()();

  /// When the hint was last written, ms. Strictly increases on every
  /// rewrite, so a sync that finishes an older hint can tell it was
  /// replaced meanwhile and leave the new one alone.
  IntColumn get createdAtMs => integer().named('created_at_ms')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {libraryPath, path},
  ];
}

/// The app's own database: settings that belong to the installation, not
/// to any one library.
///
/// It is the file `niman.db` in the application-support directory, and
/// up to schema v14 it held the note index too. T-ML-03 moved the index
/// out, one database per library, and left this one with the settings —
/// which is why the migration chain below starts long before this class
/// existed. It carries the only rows in the app that are NOT rebuildable
/// from disk, so it is the one database worth backing up.
@DriftDatabase(
  tables: [
    AppSettings,
    KnownLibraries,
    WidgetConfigs,
    SyncDestinations,
    SyncItems,
    SyncOps,
    Workspaces,
    LibraryDeviceSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates the database on top of [e].
  new(super.e);

  @override
  int get schemaVersion => 28;

  /// The index tables that lived here through v14, dropped by v15.
  static const _indexTables = [
    'notes_fts',
    'note_links',
    'note_tags',
    'note_stems',
    'tags',
    'notes',
  ];

  /// Fresh databases get `app_settings` alone; v1 databases gain the
  /// `debug_logs_enabled` column, pre-v3 databases `line_numbers`,
  /// pre-v4 databases `editor_autofocus`, pre-v5 databases
  /// `preview_mode` + `split_ratio`, pre-v6 databases the
  /// `quick_note_path` library setting, pre-v7 databases `tree_sort`,
  /// pre-v9 databases `reminder_show_tokens`, pre-v10 databases
  /// `link_type` + `indent_width`, pre-v11 databases the
  /// `list_note_folder` library setting, pre-v12 databases
  /// `editor_toolbar`, pre-v13 databases `language`, pre-v14 databases
  /// lose `library_settings` (T-ML-02) after its rows are parked in
  /// `legacy_library_settings`, pre-v15 databases lose the index
  /// tables (T-ML-03), which each library now keeps in its own file, and
  /// pre-v16 databases gain `known_libraries` (T-ML-04), seeded with the
  /// library they were about to resume, and pre-v17 databases lose the
  /// seven editor settings that were one value for every library
  /// (T-ML-10), after parking them for each known library to collect, and
  /// pre-v18 databases gain the theme: `theme_brightness` and
  /// `theme_palette` (T-M6-05), both starting at `system`, which is what
  /// the app looked like before the setting existed, and pre-v19
  /// databases gain `widget_configs` (issue 6), one row per placed
  /// home-screen widget instance, empty on upgrade, and pre-v20
  /// databases gain `changelog_seen_version` (issue #80), seeded with
  /// `0.0.3` — the last version before this feature shipped — so an
  /// upgrade into this build shows its own notes rather than nothing,
  /// while a fresh install's null stays what turns the dialog off, and
  /// pre-v21 databases gain the auto-update state (issue #81):
  /// `auto_update_enabled` (off, like a fresh install) and
  /// `last_update_check_ms` (null until the first check runs), and pre-v22
  /// databases gain the WebDAV sync state (M5): `sync_destinations`,
  /// `sync_items` and `sync_ops`, all empty — no library syncs until one
  /// is configured, and pre-v23 databases gain `workspaces` (issue #23),
  /// empty: every library starts with nothing open, and pre-v24 databases
  /// gain `key_map` (issue #159), null: every shortcut as shipped, and
  /// pre-v25 databases gain `pinned_commands` (issue #208), null: the
  /// palette opens on what was used lately, as it did, and pre-v26
  /// databases gain `close_to_tray` (issue #209), on: the window's × puts
  /// Niman in the tray, where the reminders keep firing, and pre-v27
  /// databases gain `library_device_settings`, empty: each library fills
  /// its row from its `settings.json` the first time it is opened, and
  /// pre-v28 databases gain `sync_items.base_text`, null: the settings
  /// files merge without a base until their next agreement records one.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN debug_logs_enabled '
          'BOOLEAN NOT NULL DEFAULT 1',
        );
      }
      if (from < 3) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN line_numbers '
          'BOOLEAN NOT NULL DEFAULT 1',
        );
      }
      if (from < 4) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN editor_autofocus '
          'BOOLEAN NOT NULL DEFAULT 0',
        );
      }
      if (from < 5) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN preview_mode '
          "TEXT NOT NULL DEFAULT 'auto'",
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN split_ratio '
          'REAL NOT NULL DEFAULT 0.55',
        );
      }
      if (from < 6) {
        await m.database.customStatement(
          'ALTER TABLE library_settings ADD COLUMN quick_note_path TEXT',
        );
      }
      if (from < 7) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN tree_sort '
          "TEXT NOT NULL DEFAULT 'nameAsc'",
        );
      }
      // v8 created the M3 index tables here. v15 drops them from this
      // database, so an old enough upgrade skips straight to that: the
      // library's own index file is built by the scan on its first open.
      if (from < 9) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN reminder_show_tokens '
          'BOOLEAN NOT NULL DEFAULT 0',
        );
      }
      if (from < 10) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN link_type '
          "TEXT NOT NULL DEFAULT 'wikilink'",
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN indent_width '
          'INTEGER NOT NULL DEFAULT 2',
        );
      }
      if (from < 11) {
        await m.database.customStatement(
          'ALTER TABLE library_settings ADD COLUMN list_note_folder '
          "TEXT NOT NULL DEFAULT 'Lists'",
        );
      }
      if (from < 12) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN editor_toolbar '
          "TEXT NOT NULL DEFAULT ''",
        );
      }
      if (from < 13) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN language '
          "TEXT NOT NULL DEFAULT 'system'",
        );
      }
      if (from < 14) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN legacy_library_settings '
          "TEXT NOT NULL DEFAULT ''",
        );
        await _parkLibrarySettings(m.database);
        await m.database.customStatement(
          'DROP TABLE IF EXISTS library_settings',
        );
      }
      if (from < 15) {
        for (final table in _indexTables) {
          await m.database.customStatement('DROP TABLE IF EXISTS $table');
        }
        await m.database.customStatement('VACUUM');
      }
      if (from < 16) {
        await m.createTable(knownLibraries);
        await _seedRegistry();
      }
      if (from < 17) {
        await _parkEditorSettings();
        for (final column in _librarySettingColumns) {
          await m.database.customStatement(
            'ALTER TABLE app_settings DROP COLUMN $column',
          );
        }
      }
      if (from < 18) {
        for (final column in ['theme_brightness', 'theme_palette']) {
          await m.database.customStatement(
            'ALTER TABLE app_settings ADD COLUMN $column '
            "TEXT NOT NULL DEFAULT 'system'",
          );
        }
      }
      if (from < 19) {
        await m.createTable(widgetConfigs);
      }
      if (from < 20) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN changelog_seen_version TEXT',
        );
        await m.database.customStatement(
          "UPDATE app_settings SET changelog_seen_version = '0.0.3' "
          'WHERE id = 1',
        );
      }
      if (from < 21) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN auto_update_enabled '
          'BOOLEAN NOT NULL DEFAULT 0',
        );
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN last_update_check_ms '
          'INTEGER',
        );
      }
      if (from < 22) {
        await m.createTable(syncDestinations);
        await m.createTable(syncItems);
        await m.createTable(syncOps);
      }
      if (from < 23) {
        await m.createTable(workspaces);
      }
      if (from < 24) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN key_map TEXT',
        );
      }
      if (from < 25) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN pinned_commands TEXT',
        );
      }
      if (from < 26) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN close_to_tray '
          'BOOLEAN NOT NULL DEFAULT 1',
        );
      }
      if (from < 27) {
        await m.createTable(libraryDeviceSettings);
      }
      // Only on a table that was already there: below v22 it was just
      // created, with the column.
      if (from >= 22 && from < 28) {
        await m.database.customStatement(
          'ALTER TABLE sync_items ADD COLUMN base_text TEXT',
        );
      }
    },
  );

  /// The columns v17 hands to the libraries (T-ML-10).
  ///
  /// They were one value for every library, which is wrong for settings
  /// that describe how you write in a particular one: a library of prose
  /// wants a toolbar without code blocks, the notes on programming next
  /// to it want exactly those.
  static const _librarySettingColumns = [
    'line_numbers',
    'editor_autofocus',
    'reminder_show_tokens',
    'tree_sort',
    'link_type',
    'indent_width',
    'editor_toolbar',
  ];

  /// Parks the app-wide editor settings for every library the app knows,
  /// so each collects the user's current configuration on its next open
  /// rather than dropping to the defaults.
  Future<void> _parkEditorSettings() async {
    final settings = await customSelect(
      'SELECT ${_librarySettingColumns.join(', ')} FROM app_settings',
    ).get();
    if (settings.isEmpty) return;
    final row = settings.first;
    final values = <String, Object?>{
      'lineNumbers': row.read<int>('line_numbers') != 0,
      'editorAutofocus': row.read<int>('editor_autofocus') != 0,
      'reminderShowTokens': row.read<int>('reminder_show_tokens') != 0,
      'treeSort': row.read<String>('tree_sort'),
      'linkType': row.read<String>('link_type'),
      'indentWidth': row.read<int>('indent_width'),
      'editorToolbar': row.read<String>('editor_toolbar'),
    };
    final libraries = await select(knownLibraries).get();
    if (libraries.isEmpty) return;
    final parked = await _parkedNow();
    for (final library in libraries) {
      parked[library.path] = {...?parked[library.path], ...values};
    }
    await (update(appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(legacyLibrarySettings: Value(jsonEncode(parked))),
    );
  }

  /// Whatever an earlier migration already parked, so v17 adds to it
  /// rather than replacing it.
  ///
  /// One column by name, not the table through its generated mapper: the
  /// row this reads is mid-migration and does not have the columns a
  /// later schema will add, and mapping it would fail on the one that is
  /// not there yet.
  Future<Map<String, Map<String, Object?>>> _parkedNow() async {
    final rows = await customSelect(
      'SELECT legacy_library_settings FROM app_settings',
    ).get();
    if (rows.isEmpty) return {};
    final parked = rows.first.read<String>('legacy_library_settings');
    if (parked.isEmpty) return {};
    final decoded = jsonDecode(parked);
    if (decoded is! Map) return {};
    return {
      for (final entry in decoded.entries)
        if (entry.value case final Map<Object?, Object?> value)
          entry.key.toString(): {
            for (final field in value.entries)
              field.key.toString(): field.value,
          },
    };
  }

  /// Puts the library the app was already resuming into the new registry,
  /// so an upgrade lands on a home screen that lists it rather than an
  /// empty one (T-ML-04).
  Future<void> _seedRegistry() async {
    final rows = await customSelect(
      'SELECT library_path FROM app_settings WHERE library_path IS NOT NULL',
    ).get();
    for (final row in rows) {
      final path = row.read<String>('library_path');
      await into(knownLibraries).insert(
        KnownLibrariesCompanion.insert(
          path: path,
          name: p.basename(path),
          lastOpened: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// Copies whatever `library_settings` holds into
  /// `app_settings.legacy_library_settings`, so dropping the table does
  /// not throw the settings away.
  ///
  /// They cannot be written to their libraries here: this runs on the
  /// first query after an upgrade, which is app startup, before the
  /// storage permission on Android and with no guarantee the folders are
  /// even reachable. `LegacyLibrarySettings` drains the parked values as
  /// each library is opened.
  static Future<void> _parkLibrarySettings(DatabaseConnectionUser db) async {
    final table = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'library_settings'",
        )
        .get();
    if (table.isEmpty) return;
    final rows = await db.customSelect('SELECT * FROM library_settings').get();
    if (rows.isEmpty) return;
    final parked = <String, Object?>{
      for (final row in rows)
        row.read<String>('path'): <String, Object?>{
          'trashEnabled': row.read<int>('trash_enabled') != 0,
          'historyVersions': row.read<int>('history_versions'),
          'quickNotePath': ?row.readNullable<String>('quick_note_path'),
          'listNoteFolder': row.read<String>('list_note_folder'),
        },
    };
    await db.customStatement(
      'INSERT INTO app_settings (id, legacy_library_settings) '
      'VALUES (1, ?1) ON CONFLICT(id) DO UPDATE SET '
      'legacy_library_settings = ?1',
      [jsonEncode(parked)],
    );
  }
}
