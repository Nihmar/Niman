/// The trigram index of the names a note answers to (#1043, #1036): what a
/// "contains" lookup of a note name or alias reads instead of a `%q%` scan.
///
/// One FTS5 row per note — `rowid` is `notes.id` — holding every stem the
/// note has in `note_stems` (its file name and its aliases), indexed with
/// the `trigram` tokenizer. A `MATCH` of three or more characters then
/// names the notes holding that string anywhere in a name, from the
/// index's posting lists, and stops at its `LIMIT`; the `LIKE '%q%'` it
/// replaces read every stem of the library on every keystroke.
///
/// SQLite keeps the table, through triggers on `note_stems`, so every
/// writer of those rows — the indexer, a rename, a deleted note's
/// cleanup — feeds it without knowing it. The row of a note is rewritten
/// from its stems on hand, so the table cannot drift from them.
///
/// Not a drift table: declaring one is a schema bump, and an upgrade of
/// the index file is a wipe and a full rescan. A new or upgraded file gets
/// the table as it is created, empty; an older one gets it, filled from
/// the rows on hand, behind the tree once the library is open. Until
/// then a reader finds the table missing, and answers without its tier.
library;

import 'package:drift/drift.dart';

/// The table's name.
const String stemTrigramsTable = 'stem_trigrams';

/// Contentless, deletable by rowid (the way `notes_fts` is): the table
/// holds the trigrams and not a copy of the names, which `note_stems`
/// already keeps.
const String _createTable =
    'CREATE VIRTUAL TABLE IF NOT EXISTS $stemTrigramsTable USING '
    "fts5(stem, content = '', contentless_delete = 1, tokenize = 'trigram')";

/// Rewrites the row of note `$id`: dropped, then made again from the
/// stems the note has now (none leaves it dropped). A newline between
/// stems keeps one name from running into the next.
String _rewrite(String id) =>
    'DELETE FROM $stemTrigramsTable WHERE rowid = $id; '
    'INSERT INTO $stemTrigramsTable (rowid, stem) '
    'SELECT note_id, group_concat(stem, char(10)) FROM note_stems '
    'WHERE note_id = $id GROUP BY note_id; ';

/// A stem added to a note: the note's row is made again.
final String _createAdd =
    'CREATE TRIGGER IF NOT EXISTS stem_trigrams_add AFTER INSERT ON '
    'note_stems BEGIN ${_rewrite('NEW.note_id')}END';

/// A stem gone from a note: the note's row is made again.
final String _createDrop =
    'CREATE TRIGGER IF NOT EXISTS stem_trigrams_drop AFTER DELETE ON '
    'note_stems BEGIN ${_rewrite('OLD.note_id')}END';

/// A stem changed: the note's row is made again (a note moved from one id
/// to another has its old row made again too).
final String _createChange =
    'CREATE TRIGGER IF NOT EXISTS stem_trigrams_change AFTER UPDATE ON '
    'note_stems BEGIN ${_rewrite('OLD.note_id')}${_rewrite('NEW.note_id')}END';

/// The statements that make the table and its triggers; each one is a
/// no-op where its object exists.
final List<String> _schema = [
  _createTable,
  _createAdd,
  _createDrop,
  _createChange,
];

/// Makes the index on a file whose `note_stems` is empty: a new one.
Future<void> createStemTrigrams(DatabaseConnectionUser db) async {
  for (final statement in _schema) {
    await db.customStatement(statement);
  }
}

/// Whether [db] keeps the index.
Future<bool> hasStemTrigrams(DatabaseConnectionUser db) async =>
    (await db
            .customSelect(
              "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
              variables: [Variable.withString(stemTrigramsTable)],
            )
            .get())
        .isNotEmpty;

/// Makes the index on a file from before it, filled from the stems on hand
/// in the same transaction as the triggers, so no write falls between the
/// fill and the keeping; nothing where it exists.
Future<void> ensureStemTrigrams(GeneratedDatabase db) async {
  if (await hasStemTrigrams(db)) return;
  await db.transaction(() async {
    if (await hasStemTrigrams(db)) return;
    await createStemTrigrams(db);
    await db.customStatement(
      'INSERT INTO $stemTrigramsTable (rowid, stem) '
      'SELECT note_id, group_concat(stem, char(10)) FROM note_stems '
      'GROUP BY note_id',
    );
  });
}

/// The FTS5 expression that finds [text] as a substring of a stem: the
/// whole string as one quoted phrase, which the trigram tokenizer turns
/// into the run of its trigrams. Null for text shorter than a trigram,
/// which the tokenizer cannot match.
String? stemTrigramQuery(String text) {
  if (text.runes.length < 3) return null;
  return '"${text.replaceAll('"', '""')}"';
}
