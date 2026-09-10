import 'package:copist/src/db/index_database.dart';
import 'package:drift/drift.dart';

/// Query helpers over the materialized notes tree.
final class NoteDao {
  /// Creates the DAO backed by the given [IndexDatabase].
  new(this._db);

  final IndexDatabase _db;

  /// Rows directly under the library root (parent id 0), directories first.
  Future<List<Note>> topLevel() {
    return (_db.select(_db.notes)
          ..where((t) => t.parent.equals(0))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDir),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// Children of the row with id [parentId], directories first, then by
  /// name (ascending, or descending with [nameDesc]).
  Future<List<Note>> children(int parentId, {bool nameDesc = false}) {
    return (_db.select(_db.notes)
          ..where((t) => t.parent.equals(parentId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDir),
            (t) =>
                nameDesc ? OrderingTerm.desc(t.name) : OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// Every note that belongs to the root or to one of the [expandedPaths],
  /// in tree order (directories first, then name).
  ///
  /// Used for single-query tree flattening: one round-trip to the database
  /// returns every potentially visible row.
  Future<List<Note>> tree(
    Iterable<String> expandedPaths, {
    bool nameDesc = false,
  }) {
    return (_db.select(_db.notes)
          ..where(
            (t) =>
                t.parent.equals(0) |
                t.parent.isInQuery(
                  _db.selectOnly(_db.notes)
                    ..addColumns([_db.notes.id])
                    ..where(_db.notes.path.isIn(expandedPaths)),
                ),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDir),
            (t) =>
                nameDesc ? OrderingTerm.desc(t.name) : OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// The row at library-relative `path`, or null when absent.
  Future<Note?> find(String path) async {
    final rows = await (_db.select(
      _db.notes,
    )..where((t) => t.path.equals(path))).get();
    return rows.isEmpty ? null : rows.first;
  }

  /// All directory rows, path-ordered (for move-target pickers).
  ///
  /// `is_dir = 1` rather than the bare column: SQLite matches an index on
  /// an equality, not on a truthiness test, and the difference at a
  /// million notes is a scan of every row against a walk of the folders
  /// (T-M6-01).
  Future<List<Note>> folders() {
    return (_db.select(_db.notes)
          ..where((t) => t.isDir.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.path)]))
        .get();
  }

  /// Every indexed row, for full-scan reconciliation.
  Future<List<Note>> allRows() {
    return _db.select(_db.notes).get();
  }

  /// Deletes the row at `path` and every descendant row, returning the
  /// number of rows deleted.
  ///
  /// The subtree's dependent rows (FTS by `rowid`, stems/tags/links by
  /// note id) are wiped in the same transaction, through subqueries over
  /// the still-present notes rows — so a subtree of any size costs a
  /// constant number of statements, never an argument-list per note.
  Future<int> deleteSubtree(String path) {
    // Every statement binds the same three arguments.
    const where = 'path = ? OR (path >= ? AND path < ?)';
    final range = subtreePathRange(path);
    final args = [path, range.from, range.to];
    return _db.transaction(() async {
      // Dependents first (they select the ids from notes), then the notes
      // rows themselves.
      await _db.customStatement(
        'DELETE FROM notes_fts WHERE rowid IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM note_stems WHERE note_id IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM note_tags WHERE note_id IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM frontmatter_fields WHERE note_id IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM note_links WHERE from_note IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM note_links WHERE to_note IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      return await _db.customUpdate(
        'DELETE FROM notes WHERE $where',
        variables: [for (final arg in args) Variable<String>(arg)],
        updates: {_db.notes},
      );
    });
  }

  /// The row at `path` and every descendant row (the directory subtree),
  /// or every row when [path] is empty.
  Future<List<Note>> subtreeRows(String path) async {
    if (path.isEmpty) return await allRows();
    final range = subtreePathRange(path);
    return await (_db.select(_db.notes)..where(
          (t) =>
              t.path.equals(path) |
              (t.path.isBiggerOrEqualValue(range.from) &
                  t.path.isSmallerThanValue(range.to)),
        ))
        .get();
  }
}

/// The half-open path range holding everything under [path].
///
/// A subtree used to be found with `LIKE 'path/%'`, which reads every row
/// in the table: SQLite's LIKE is case-insensitive by default, and an
/// index built on the default collation cannot answer it. A range on the
/// same prefix is an index seek instead — a second saved per deleted
/// folder at a million notes (T-M6-01).
///
/// `to` is the prefix with its trailing `/` replaced by the next
/// character in the alphabet, `0`, which is the first string that sorts
/// after every descendant.
({String from, String to}) subtreePathRange(String path) =>
    (from: '$path/', to: '${path}0');

/// Escapes SQL `LIKE` wildcards in [s] so it can be used safely with an
/// `ESCAPE '\'` clause. Public: the contains search (T-M3-08) builds its
/// pattern with it.
String sqlLikeEscape(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
