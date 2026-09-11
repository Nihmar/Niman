import 'package:drift/drift.dart';

part 'index_database.g.dart';

/// One note file or folder in the library.
///
/// [path] is library-relative, slash-separated. Directory rows are
/// materialized (not derived on the fly) so tree queries stay cheap at
/// scale. [parent] is the parent row id; 0 means the library root.
///
/// Materialized rows are only half of cheap, though: without an index on
/// [parent] every "what is in this folder" is a scan of the whole table,
/// which is a millisecond at a thousand notes and a tenth of a second at
/// a million — per expanded folder, on the frame that opens it (T-M6-01).
/// The folder index covers the picker's "every directory, by path", which
/// otherwise reads a million rows to find a thousand.
@TableIndex(name: 'notes_parent', columns: {#parent})
@TableIndex(name: 'notes_dir_path', columns: {#isDir, #path})
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

  /// The frontmatter `title:`, or null when the note has none — then the
  /// filename is the display name.
  ///
  /// It lives on the row rather than only in [FrontmatterFields] because
  /// the tree reads it for every visible row on every paint, and a join
  /// per paint is a cost the tree does not have to pay (T-M4-02).
  TextColumn get title => text().nullable()();

  /// The frontmatter `date:` when it reads as a date, else null.
  DateTimeColumn get date => dateTime().nullable()();

  /// Whether the frontmatter says `pinned: true`.
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
}

/// Every frontmatter key of every note: `title`, `tags`, `date`, `pinned`
/// and `aliases` alongside whatever else the note declares.
///
/// One row per (note, key, value) — not per (note, key): a key whose value
/// is a list is one field with several values, and filtering by
/// `projects = alpha` has to match a note that lists alpha among others.
/// Nested maps arrive flattened onto dotted keys (`author.name`), so the
/// table stays two columns wide whatever the block's shape.
///
/// The known keys are also materialized on [Notes]; this table is what
/// makes *any* key filterable (T-M4-03). The primary key answers "the
/// fields of this note"; the index answers the other direction, "the
/// notes whose `status` is `draft`", which is what filtering asks.
@TableIndex(name: 'fields_key_value', columns: {#key, #value})
class FrontmatterFields extends Table {
  /// The id of the note the field belongs to.
  IntColumn get noteId => integer()();

  /// The key, lowercased; dotted for a nested map's leaf.
  TextColumn get key => text()();

  /// One of the key's values, as text.
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {noteId, key, value};
}

/// The link-resolution index: one row per note *stem* (filename without
/// `.md`, lowercased) and — from M4 on — per frontmatter alias, both
/// `COLLATE NOCASE` so `[[note]]` and `[[Note]]` share a candidate set.
///
/// Rows are maintained by the indexer on insert/rename/delete; the table is
/// rebuildable from disk by a full rescan. The primary key resolves a
/// link; the index is for the maintenance, which deletes a note's rows by
/// its id — once per re-indexed note, so a scan there is a scan per note.
@TableIndex(name: 'stems_note', columns: {#noteId})
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
@TableIndex(name: 'note_tags_note', columns: {#noteId})
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
///
/// The primary key reads a note's outgoing links; the index reads them the
/// way the backlinks panel will, which is the direction the key cannot
/// answer.
@TableIndex(name: 'links_to', columns: {#toNote})
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
/// private storage and not in `.niman/` — a cache must be deletable
/// without loss and must never sync (T-ML-03).
///
/// One file per library, named by a digest of the library path (see
/// `libraryIndexFile`), so opening a second library does not scan over
/// the first one's rows. The file is created at the current schema and
/// never migrated: a shape change means deleting it and rescanning,
/// which costs a walk and loses nothing.
@DriftDatabase(
  tables: [Notes, NoteStems, Tags, NoteTags, NoteLinks, FrontmatterFields],
)
class IndexDatabase extends _$IndexDatabase {
  /// Creates the index on top of [e].
  new(super.e);

  /// v1: M3's tree, stems, tags and links. v2: the frontmatter fields
  /// table and the three known-field columns on `notes` (T-M4-02). v3:
  /// the six indexes the million-note pass showed missing (T-M6-01).
  @override
  int get schemaVersion => 3;

  /// The FTS5 index (design.md: no drift class — raw SQL, `rowid` =
  /// `notes.id`, one row per note, `title` weighted above `body` by the
  /// search ranking). `IF NOT EXISTS` keeps a re-open idempotent.
  static const String _createFts =
      'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING '
      "fts5(title, body, tokenize = 'unicode61 remove_diacritics 2')";

  /// The tables an upgrade drops, dependents before the rows they key on.
  static const List<String> _allTables = [
    'notes_fts',
    'frontmatter_fields',
    'note_links',
    'note_tags',
    'tags',
    'note_stems',
    'notes',
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await m.database.customStatement(_createFts);
    },
    // Every row here is derived from the notes on disk, so an upgrade is a
    // wipe and a rescan: the file is emptied and recreated at the new
    // shape, and the next full scan — which runs on open anyway — fills
    // it. That costs a walk and loses nothing, and it saves the app a
    // migration chain for a cache. The library's own files are not
    // touched; only this index file is.
    onUpgrade: (m, from, to) async {
      for (final table in _allTables) {
        await m.database.customStatement('DROP TABLE IF EXISTS $table');
      }
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
