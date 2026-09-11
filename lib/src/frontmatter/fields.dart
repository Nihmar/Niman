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
  /// the key at all.
  Future<List<Note>> notesWithField(String key, String value);

  /// Every key in use, most declared first (ties alphabetical).
  Future<List<FieldKeyCount>> fieldKeys();
}

/// Queries over the frontmatter fields of the open library's index.
final class FieldRepo implements FieldSource {
  /// Creates the repo over [IndexDatabase].
  new(this._db);

  final IndexDatabase _db;

  @override
  Future<List<Note>> pinnedNotes() {
    return (_db.select(_db.notes)
          ..where((n) => n.pinned & n.isDir.not())
          ..orderBy([(n) => OrderingTerm.asc(n.path)]))
        .get();
  }

  @override
  Future<List<Note>> notesWithField(String key, String value) {
    final wanted = value.trim().toLowerCase();
    final fields = _db.frontmatterFields;
    return (_db.select(_db.notes)
          ..where(
            (n) => n.id.isInQuery(
              _db.selectOnly(fields)
                ..addColumns([fields.noteId])
                ..where(
                  wanted.isEmpty
                      ? fields.key.equals(key.trim().toLowerCase())
                      : fields.key.equals(key.trim().toLowerCase()) &
                            fields.value.lower().equals(wanted),
                ),
            ),
          )
          ..orderBy([(n) => OrderingTerm.asc(n.path)]))
        .get();
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
