import 'package:drift/drift.dart';
import 'package:niman/src/db/index_database.dart';

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

  /// Which of [paths] the index does not hold, in one query: the notes a
  /// caller keeps open that the tree no longer has (#289).
  Future<Set<String>> missingAmong(Iterable<String> paths) async {
    final wanted = paths.toSet();
    if (wanted.isEmpty) return const <String>{};
    final rows = await (_db.select(
      _db.notes,
    )..where((t) => t.path.isIn(wanted))).get();
    final found = <String>{for (final row in rows) row.path};
    return wanted.difference(found);
  }

  /// Notes (not folders) whose name holds [query], case-insensitively:
  /// the command palette's note half (#155). Names that start with it
  /// come first, then the shorter ones, then by path; at most [limit].
  ///
  /// A substring scan over the names — fine at a million rows on the
  /// database's own isolate, behind the palette's debounce; full text
  /// stays the search screen's.
  Future<List<Note>> named(String query, {int limit = 50}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final escaped = q
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final rows = await _db
        .customSelect(
          r"SELECT * FROM notes WHERE is_dir = 0 AND name LIKE ? ESCAPE '\' "
          r"ORDER BY (name LIKE ? ESCAPE '\') DESC, length(name), path "
          'LIMIT ?',
          variables: [
            Variable.withString('%$escaped%'),
            Variable.withString('$escaped%'),
            Variable.withInt(limit),
          ],
          readsFrom: {_db.notes},
        )
        .get();
    return [for (final row in rows) _db.notes.map(row.data)];
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

  /// The paths of the notes (files, not folders) under [folder], at any
  /// depth; every note's for the root (empty).
  ///
  /// A range on the path, like [subtreeRows], so a folder is an index
  /// seek however large the library: the journal's calendar reads a
  /// month's entries this way (#7).
  Future<List<String>> filePathsUnder(String folder) async {
    final query = _db.selectOnly(_db.notes)
      ..addColumns([_db.notes.path])
      ..where(_db.notes.isDir.equals(false));
    if (folder.isNotEmpty) {
      final range = subtreePathRange(folder);
      query.where(
        _db.notes.path.isBiggerOrEqualValue(range.from) &
            _db.notes.path.isSmallerThanValue(range.to),
      );
    }
    final rows = await query.get();
    return [for (final row in rows) row.read(_db.notes.path)!];
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
