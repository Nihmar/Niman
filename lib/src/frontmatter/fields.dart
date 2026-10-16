/// The read side of `frontmatter_fields` (design.md:
/// frontmatter/fields.dart).
///
/// Two questions are asked of it. The pinned section asks for the notes
/// whose frontmatter says `pinned: true` (T-M4-04), and the search screen
/// asks for the notes where some key holds some value (T-M4-03) — any
/// key, known or invented, which is the whole point of storing them all.
///
/// Pinned is answered from the `notes` row and not from the table: the
/// known fields are materialized there, and asking the column is one
/// index scan instead of a join.
library;

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/db/index_database.dart';

/// The frontmatter keys the app itself acts on.
///
/// Everything else is stored and filterable but drives nothing: it is the
/// user's vocabulary, not the app's.
const Set<String> knownFrontmatterKeys = {
  'title',
  'tags',
  'date',
  'pinned',
  'aliases',
};

/// A frontmatter key with the number of notes that declare it.
final class FieldKeyCount {
  /// Creates a key count.
  const new({required this.key, required this.count});

  /// The key, lowercased.
  final String key;

  /// How many notes carry it.
  final int count;
}

/// The frontmatter-field data source the UI talks to.
///
/// [FieldRepo] is the production implementation over drift; widget tests
/// inject a fake.
abstract interface class FieldSource {
  /// The notes whose frontmatter pins them, in path order.
  Future<List<Note>> pinnedNotes();

  /// The notes where [key] holds [value], in path order.
  ///
  /// Both are matched case-insensitively: the key is stored lowercased,
  /// and a person filtering by `status = Draft` means the note that says
  /// `status: draft`. An empty [value] matches every note that declares
  /// the key at all. [limit] keeps the first ones only, and [after] starts
  /// past that path: the cursor of a long list read a page at a time
  /// (#1037).
  Future<List<Note>> notesWithField(
    String key,
    String value, {
    int? limit,
    String? after,
  });

  /// How many notes [notesWithField] lists for [key] and [value] in all.
  Future<int> countWithField(String key, String value);

  /// Every key in use, most declared first (ties alphabetical).
  Future<List<FieldKeyCount>> fieldKeys();

  /// Every value of [key], with the note holding it, in path order: the
  /// notes that name the file they annotate (#284) ask it of `annotates`.
  Future<List<({Note note, String value})>> fieldValues(String key);

  /// The values [key] holds across the library, most used first (ties
  /// alphabetical), at most [limit]: the suggestions a Home action's form
  /// offers for a field it asks for (#535).
  Future<List<String>> topValues(String key, {int limit = 20});
}

/// Queries over the frontmatter fields of the open library's index.
final class FieldRepo implements FieldSource {
  /// Creates the repo over [IndexDatabase].
  new(this._db);

  final IndexDatabase _db;

  @override
  Future<List<Note>> pinnedNotes() => pinnedQuery().get();

  /// The pinned notes' statement. `pinned = 1` is a literal, not a bound
  /// variable, so SQLite proves the `notes_pinned` partial index covers it
  /// and reads the pinned rows alone, already in path order (#1065). The
  /// folder test stays `NOT is_dir`, which no index answers: written as
  /// `is_dir = 0` the planner would take `notes_dir_path` over the partial
  /// index and read every note.
  @visibleForTesting
  SimpleSelectStatement<$NotesTable, Note> pinnedQuery() {
    return _db.select(_db.notes)
      ..where(
        (n) => n.pinned.equalsExp(const Constant<bool>(true)) & n.isDir.not(),
      )
      ..orderBy([(n) => OrderingTerm.asc(n.path)]);
  }

  @override
  Future<List<Note>> notesWithField(
    String key,
    String value, {
    int? limit,
    String? after,
  }) {
    final fields = _db.frontmatterFields;
    final query = _db.select(_db.notes)
      ..where(
        (n) =>
            n.id.isInQuery(
              _db.selectOnly(fields)
                ..addColumns([fields.noteId])
                ..where(_matches(fields, key, value)),
            ) &
            (after == null
                ? const Constant(true)
                : n.path.isBiggerThanValue(after)),
      )
      ..orderBy([(n) => OrderingTerm.asc(n.path)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  @override
  Future<int> countWithField(String key, String value) async {
    final fields = _db.frontmatterFields;
    final count = value.trim().isEmpty
        ? fields.noteId.count(distinct: true)
        : fields.noteId.count();
    final query = _db.selectOnly(fields)
      ..addColumns([count])
      ..where(_matches(fields, key, value));
    final row = await query.getSingle();
    final total = row.read<int>(count);
    return total ?? 0;
  }

  /// The rows of [key] holding [value] (any value when it is empty): an
  /// equality on the `(key, value, note_id)` index. `value` is a
  /// `COLLATE NOCASE` column, so the seek is the index's and needs no
  /// `lower()` over every row of the key (#1037).
  Expression<bool> _matches(
    $FrontmatterFieldsTable fields,
    String key,
    String value,
  ) {
    final wanted = value.trim().toLowerCase();
    final named = fields.key.equals(key.trim().toLowerCase());
    return wanted.isEmpty ? named : named & fields.value.equals(wanted);
  }

  @override
  Future<List<({Note note, String value})>> fieldValues(String key) async {
    final fields = _db.frontmatterFields;
    final notes = _db.notes;
    final rows =
        await (_db.select(notes).join([
                innerJoin(fields, fields.noteId.equalsExp(notes.id)),
              ])
              ..where(fields.key.equals(key.trim().toLowerCase()))
              ..orderBy([OrderingTerm.asc(notes.path)]))
            .get();
    return [
      for (final row in rows)
        (note: row.readTable(notes), value: row.readTable(fields).value),
    ];
  }

  /// Grouped over the rows of one key, which the `fields_key_value` index
  /// hands over without a look at any other key's.
  @override
  Future<List<String>> topValues(String key, {int limit = 20}) async {
    final rows = await _db
        .customSelect(
          'SELECT value, count(*) AS c FROM frontmatter_fields '
          'WHERE key = ? GROUP BY value ORDER BY c DESC, value ASC LIMIT ?',
          variables: [
            Variable.withString(key.trim().toLowerCase()),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.frontmatterFields},
        )
        .get();
    return [for (final row in rows) row.read<String>('value')];
  }

  @override
  Future<List<FieldKeyCount>> fieldKeys() async {
    final rows = await _db
        .customSelect(
          'SELECT key, count(DISTINCT note_id) AS c FROM frontmatter_fields '
          'GROUP BY key ORDER BY c DESC, key ASC',
        )
        .get();
    return [
      for (final row in rows)
        FieldKeyCount(key: row.read<String>('key'), count: row.read<int>('c')),
    ];
  }
}
