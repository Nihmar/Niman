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

  /// Whether the note editor shows the row-number column (default true).
  BoolColumn get lineNumbers =>
      boolean().named('line_numbers').withDefault(const Constant(true))();

  /// Whether the note editor focuses (shows the keyboard) when a note
  /// opens (default false — the keyboard appears on the first tap).
  BoolColumn get editorAutofocus =>
      boolean().named('editor_autofocus').withDefault(const Constant(false))();

  /// Whether a reminder's notification text keeps the `+project`,
  /// `@context` and `#tag` markers (default false).
  ///
  /// In the list they carry meaning next to the checkbox and the filter
  /// chips; on a lock screen there is nothing to explain them, so they
  /// are off by default — but someone who files by project may want them.
  BoolColumn get reminderShowTokens => boolean()
      .named('reminder_show_tokens')
      .withDefault(const Constant(false))();

  /// The preview layout mode: `auto` (width-based), `split` or `switch`
  /// (forced; default `auto`).
  TextColumn get previewMode =>
      text().named('preview_mode').withDefault(const Constant('auto'))();

  /// The editor|preview split fraction (0..1; default 0.55).
  RealColumn get splitRatio =>
      real().named('split_ratio').withDefault(const Constant(0.55))();

  /// The library tree sort order (T-UI-03): the sort enum `.name`
  /// value (`nameAsc` or `nameDesc`).
  TextColumn get treeSort =>
      text().named('tree_sort').withDefault(const Constant('nameAsc'))();

  /// The link format the editor's link button inserts: `wikilink`
  /// (`[[…]]`) or `markdown` (`[…](…)`; default `wikilink`).
  TextColumn get linkType =>
      text().named('link_type').withDefault(const Constant('wikilink'))();

  /// The editor's indent/outdent width in spaces (default 2).
  IntColumn get indentWidth =>
      integer().named('indent_width').withDefault(const Constant(2))();

  /// The editor toolbar the user arranged: every button id in their
  /// order, a `-` prefix marking a hidden one (see `ToolbarLayout`).
  /// Empty means the shipped toolbar.
  TextColumn get editorToolbar =>
      text().named('editor_toolbar').withDefault(const Constant(''))();

  /// The UI language: `system` (follow the OS, the default), `en` or
  /// `it`.
  TextColumn get language => text().withDefault(const Constant('system'))();

  /// The settings the dropped `library_settings` table held, waiting to
  /// reach the libraries they belong to (T-ML-02).
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

  @override
  Set<Column> get primaryKey => {id};
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

/// The app's own database: settings that belong to the installation, not
/// to any one library.
///
/// It is the file `copist.db` in the application-support directory, and
/// up to schema v14 it held the note index too. T-ML-03 moved the index
/// out, one database per library, and left this one with the settings —
/// which is why the migration chain below starts long before this class
/// existed. It carries the only rows in the app that are NOT rebuildable
/// from disk, so it is the one database worth backing up.
@DriftDatabase(tables: [AppSettings, KnownLibraries])
class AppDatabase extends _$AppDatabase {
  /// Creates the database on top of [e].
  new(super.e);

  @override
  int get schemaVersion => 16;

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
  /// library they were about to resume.
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
    },
  );

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
