/// How many notes carry each tag, kept as `note_tags` changes (#692): the
/// Home's top-tags tile and the Tags screen read the counts off an index
/// instead of grouping every tag row.
///
/// SQLite keeps the table, through triggers on `note_tags`, so every
/// writer of those rows — the indexer, a deleted note's cleanup — counts
/// without knowing it. A note that carries a tag both in its frontmatter
/// and inline counts once, as `count(DISTINCT note_id)` did.
///
/// Not a drift table: declaring one is a schema bump, and an upgrade of
/// the index file is a wipe and a full rescan. A new or upgraded file gets
/// the table as it is created, empty; an older one gets it, filled from
/// the rows on hand, behind the tree once the library is open.
library;

import 'package:drift/drift.dart';

/// The table's name.
const String tagCountsTable = 'tag_counts';

const String _createTable =
    'CREATE TABLE IF NOT EXISTS $tagCountsTable '
    '(tag TEXT NOT NULL PRIMARY KEY, c INTEGER NOT NULL) WITHOUT ROWID';

const String _createIndex =
    'CREATE INDEX IF NOT EXISTS tag_counts_c ON $tagCountsTable (c DESC, tag)';

/// A row that is the note's first for the tag adds the note.
const String _createAdd =
    'CREATE TRIGGER IF NOT EXISTS tag_counts_add AFTER INSERT ON note_tags '
    'WHEN (SELECT count(*) FROM note_tags '
    'WHERE tag = NEW.tag AND note_id = NEW.note_id) = 1 BEGIN '
    'INSERT INTO $tagCountsTable (tag, c) VALUES (NEW.tag, 1) '
    'ON CONFLICT (tag) DO UPDATE SET c = c + 1; END';

/// The note's last row for the tag gone takes the note off; a tag no note
/// carries leaves the table.
const String _createDrop =
    'CREATE TRIGGER IF NOT EXISTS tag_counts_drop AFTER DELETE ON note_tags '
    'WHEN NOT EXISTS (SELECT 1 FROM note_tags '
    'WHERE tag = OLD.tag AND note_id = OLD.note_id) BEGIN '
    'UPDATE $tagCountsTable SET c = c - 1 WHERE tag = OLD.tag; '
    'DELETE FROM $tagCountsTable WHERE tag = OLD.tag AND c <= 0; END';

/// The statements that make the table, its index and its triggers; each
/// one is a no-op where its object exists.
const List<String> _schema = [
  _createTable,
  _createIndex,
  _createAdd,
  _createDrop,
];

/// Makes the counts on a file whose `note_tags` is empty: a new one.
Future<void> createTagCounts(DatabaseConnectionUser db) async {
  for (final statement in _schema) {
    await db.customStatement(statement);
  }
}

/// Whether [db] keeps the counts.
Future<bool> hasTagCounts(DatabaseConnectionUser db) async =>
    (await db
            .customSelect(
              "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
              variables: [Variable.withString(tagCountsTable)],
            )
            .get())
        .isNotEmpty;

/// Makes the counts on a file from before them, filled from the rows on
/// hand in the same transaction as the triggers, so no write falls between
/// the fill and the counting; nothing where they exist.
Future<void> ensureTagCounts(GeneratedDatabase db) async {
  if (await hasTagCounts(db)) return;
  await db.transaction(() async {
    if (await hasTagCounts(db)) return;
    await createTagCounts(db);
    await db.customStatement(
      'INSERT INTO $tagCountsTable (tag, c) '
      'SELECT tag, count(DISTINCT note_id) FROM note_tags GROUP BY tag',
    );
  });
}
