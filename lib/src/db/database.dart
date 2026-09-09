import 'dart:convert';

import 'package:drift/drift.dart';

part 'database.g.dart';

/// One note file or folder in the library.
///
/// [path] is library-relative, slash-separated. Directory rows are
/// materialized (not derived on the fly) so tree queries stay cheap at
/// scale. [parent] is the parent row id; 0 means the library root.
class Notes extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Library-relative slash-separated path; unique.
  TextColumn get path => text().unique()();

  /// Parent row id; 0 = library root.
  IntColumn get parent => integer()();

  /// Display name (file or folder name).
  TextColumn get name => text()();

  /// Whether this row is a directory.
  BoolColumn get isDir => boolean()();

  /// Byte size; 0 for directories.
  IntColumn get size => integer()();

  /// Last modification time as seen on disk.
  DateTimeColumn get modified => dateTime()();

  /// Content sha256, hex; files only (directories are null).
  TextColumn get sha256 => text().nullable()();
}

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

/// The link-resolution index: one row per note *stem* (filename without
/// `.md`, lowercased) and — from M4 on — per frontmatter alias, both
/// `COLLATE NOCASE` so `[[note]]` and `[[Note]]` share a candidate set.
///
/// Rows are maintained by the indexer on insert/rename/delete; the table is
/// rebuildable from disk by a full rescan.
class NoteStems extends Table {
  /// The normalized (lowercased) stem or alias text.
  TextColumn get stem => text().customConstraint('COLLATE NOCASE')();

  /// The id of the note row the stem points at.
  IntColumn get noteId => integer()();

  /// Where the stem came from: `file` (the filename stem) or `alias`
  /// (a frontmatter alias).
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {stem, noteId, source};
}

/// A tag, normalized (lowercased, no leading `#`); the tag name is the key.
class Tags extends Table {
  /// The normalized tag name.
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {name};
}

/// Which note carries which tag, and from where: frontmatter `tags:` or an
/// inline `#tag`. One row per (tag, note, source) — a tag in both sources
/// has two rows, so the counts and the source survive.
class NoteTags extends Table {
  /// The normalized tag name (see [Tags]).
  TextColumn get tag => text()();

  /// The ids of the note row.
  IntColumn get noteId => integer()();

  /// Whether the tag came from frontmatter (true) or inline `#tag` (false).
  BoolColumn get isFrontmatter => boolean()();

  @override
  Set<Column> get primaryKey => {tag, noteId, isFrontmatter};
}

/// A resolved link edge between two notes; dead links are skipped, so every
/// row points at an existing note. References/backlinks UI is future work
/// (M3 stores the edges; it has no reader for them yet).
class NoteLinks extends Table {
  /// The id of the note containing the link.
  IntColumn get fromNote => integer()();

  /// The id of the linked note.
  IntColumn get toNote => integer()();

  /// The link form: `wiki` (`[[…]]`) or `md` (`[t](p)`).
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {fromNote, toNote, kind};
}

/// The Copist database.
///
/// Every table is rebuildable from disk: deleting the database file and
/// rescanning the library reproduces it exactly.
@DriftDatabase(
  tables: [Notes, AppSettings, NoteStems, Tags, NoteTags, NoteLinks],
)
class CopistDatabase extends _$CopistDatabase {
  /// Creates the database on top of [e].
  new(super.e);

  @override
  int get schemaVersion => 14;

  /// The FTS5 index (design.md: no drift class — raw SQL, `rowid` =
  /// `notes.id`, one row per note, `title` weighted above `body` by the
  /// search ranking). `IF NOT EXISTS` keeps re-open and both migration
  /// paths idempotent.
  static const String _createFts =
      'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING '
      "fts5(title, body, tokenize = 'unicode61 remove_diacritics 2')";

  /// Fresh databases get all tables; v1 databases gain the
  /// `debug_logs_enabled` column, pre-v3 databases `line_numbers`,
  /// pre-v4 databases `editor_autofocus`, pre-v5 databases
  /// `preview_mode` + `split_ratio`, pre-v6 databases the
  /// `quick_note_path` library setting, pre-v7 databases `tree_sort`,
  /// pre-v8 databases the M3 tables (`note_stems`, `tags`, `note_tags`,
  /// `note_links`) plus the `notes_fts` FTS5 index, pre-v9 databases
  /// `reminder_show_tokens`, pre-v10 databases `link_type` +
  /// `indent_width`, and pre-v11 databases the `list_note_folder`
  /// library setting, pre-v12 databases `editor_toolbar`, pre-v13
  /// databases `language`, and pre-v14 databases lose `library_settings`
  /// (T-ML-02) after its rows are parked in `legacy_library_settings`.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await m.database.customStatement(_createFts);
    },
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
      if (from < 8) {
        await m.createTable(noteStems);
        await m.createTable(tags);
        await m.createTable(noteTags);
        await m.createTable(noteLinks);
        await m.database.customStatement(_createFts);
      }
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
    },
  );

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
