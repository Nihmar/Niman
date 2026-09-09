import 'package:drift/drift.dart';

part 'index_database.g.dart';

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

/// One library's note index.
///
/// Every table here is derived: deleting the file and rescanning the
/// library reproduces it exactly. That is why it lives in the app's
/// private storage and not in `.copist/` — a cache must be deletable
/// without loss and must never sync (T-ML-03).
///
/// One file per library, named by a digest of the library path (see
/// `libraryIndexFile`), so opening a second library does not scan over
/// the first one's rows. The file is created at the current schema and
/// never migrated: a shape change means deleting it and rescanning,
/// which costs a walk and loses nothing.
@DriftDatabase(tables: [Notes, NoteStems, Tags, NoteTags, NoteLinks])
class IndexDatabase extends _$IndexDatabase {
  /// Creates the index on top of [e].
  new(super.e);

  @override
  int get schemaVersion => 1;

  /// The FTS5 index (design.md: no drift class — raw SQL, `rowid` =
  /// `notes.id`, one row per note, `title` weighted above `body` by the
  /// search ranking). `IF NOT EXISTS` keeps a re-open idempotent.
  static const String _createFts =
      'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING '
      "fts5(title, body, tokenize = 'unicode61 remove_diacritics 2')";

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await m.database.customStatement(_createFts);
    },
    beforeOpen: (details) async {
      // Belt and braces: an index file that predates the FTS table (or
      // lost it) rebuilds it here rather than failing every search.
      await customStatement(_createFts);
    },
  );
}
