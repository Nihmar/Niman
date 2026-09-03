import 'package:copist/src/db/database.dart';
import 'package:drift/drift.dart';

/// Query helpers over the materialized notes tree.
final class NoteDao {
  /// Creates the DAO backed by the given [CopistDatabase].
  NoteDao(this._db);

  final CopistDatabase _db;

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

  /// Children of the row with id [parentId], directories first, then by name.
  Future<List<Note>> children(int parentId) {
    return (_db.select(_db.notes)
          ..where((t) => t.parent.equals(parentId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDir),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// The row at library-relative `path`, or null when absent.
  Future<Note?> find(String path) async {
    final rows = await (
      _db.select(_db.notes)
        ..where((t) => t.path.equals(path))
    ).get();
    return rows.isEmpty ? null : rows.first;
  }

  /// All directory rows, path-ordered (for move-target pickers).
  Future<List<Note>> folders() {
    return (_db.select(_db.notes)
          ..where((t) => t.isDir)
          ..orderBy([(t) => OrderingTerm.asc(t.path)]))
        .get();
  }

  /// Every indexed row, for full-scan reconciliation.
  Future<List<Note>> allRows() {
    return _db.select(_db.notes).get();
  }

  /// Deletes the row at `path` and every descendant row, returning the
  /// number of rows deleted.
  Future<int> deleteSubtree(String path) {
    final t = _db.notes;
    return (_db.delete(t)
          ..where(
            (x) => x.path.equals(path) |
                x.path.like('${_sqlLikeEscape(path)}/%', escapeChar: r'\'),
          ))
      .go();
  }

  /// The row at `path` and every descendant row (the directory subtree),
  /// or every row when [path] is empty.
  Future<List<Note>> subtreeRows(String path) async {
    if (path.isEmpty) return allRows();
    return (
      _db.select(_db.notes)
        ..where(
          (t) => t.path.equals(path) |
              t.path.like('${_sqlLikeEscape(path)}/%', escapeChar: r'\'),
        )
    ).get();
  }
}

/// Escapes SQL `LIKE` wildcards in [s] so it can be used safely with an
/// `ESCAPE '\'` clause.
String _sqlLikeEscape(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}
