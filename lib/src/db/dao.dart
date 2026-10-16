import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/referrer_dao.dart';

/// Paths per `WHERE path IN (…)` statement: SQLite binds 999 variables by
/// default (32766 since 3.32), so a whole candidate set is looked up in
/// statement-sized chunks rather than in one (#360).
const _pathChunk = 500;

/// Query helpers over the materialized notes tree.
final class NoteDao {
  /// Creates the DAO backed by the given [IndexDatabase].
  new(this._db);

  final IndexDatabase _db;

  /// Who links to a note: the reverse lookups over the link edges.
  late final ReferrerDao referrers = ReferrerDao(_db);

  /// Rows directly under the library root (parent id 0), directories first.
  Future<List<Note>> topLevel() {
    return (_db.select(_db.notes)
          ..where((t) => t.parent.equals(0))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isDir),
            (t) => OrderingTerm.asc(t.nameKey),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .get();
  }

  /// Children of the row with id [parentId], in [sort]'s order (#726):
  /// directories first whatever the field, then the field in its own
  /// direction, the name breaking ties.
  Future<List<Note>> children(
    int parentId, {
    TreeSort sort = TreeSort.nameAsc,
  }) {
    return (_db.select(_db.notes)
          ..where((t) => t.parent.equals(parentId))
          ..orderBy(_treeOrder(sort)))
        .get();
  }

  /// One page of the children of [parentId], in [sort]'s order: at most
  /// [limit] rows, the ones after [after] (a row of the previous page) — a
  /// keyset, not an offset, so the page after the hundred-thousandth row
  /// is as cheap as the first (#1064).
  ///
  /// The cursor compares the sort's terms one after the other, in their own
  /// directions: folders first, then the field, then the name key and the
  /// name — the terms of `notes_tree` for a name order, which then reads
  /// `limit` index entries and sorts nothing.
  Future<List<Note>> childrenPage(
    int parentId, {
    required int limit,
    TreeSort sort = TreeSort.nameAsc,
    Note? after,
  }) async {
    final keys = _keysetOf(sort);
    final variables = <Variable<Object>>[Variable<int>(parentId)];
    final where = StringBuffer('parent = ?');
    if (after != null) {
      final branches = <String>[];
      for (var i = 0; i < keys.length; i++) {
        final equal = [
          for (var j = 0; j < i; j++) '${keys[j].column} = ?',
          '${keys[i].column} ${keys[i].descending ? '<' : '>'} ?',
        ];
        branches.add('(${equal.join(' AND ')})');
        for (var j = 0; j <= i; j++) {
          variables.add(keys[j].value(after));
        }
      }
      where.write(' AND (${branches.join(' OR ')})');
    }
    final order = [
      for (final key in keys)
        '${key.column} ${key.descending ? 'DESC' : 'ASC'}',
    ].join(', ');
    variables.add(Variable<int>(limit));
    final rows = await _db
        .customSelect(
          'SELECT * FROM notes WHERE $where ORDER BY $order LIMIT ?',
          variables: variables,
          readsFrom: {_db.notes},
        )
        .get();
    return [for (final row in rows) _db.notes.map(row.data)];
  }

  /// The terms [sort] orders by, with the column each reads and the value
  /// of a row for it: what a keyset cursor compares.
  static List<
    ({String column, bool descending, Variable<Object> Function(Note) value})
  >
  _keysetOf(TreeSort sort) {
    final direction = sort.descending;
    final isDir = (
      column: 'is_dir',
      descending: true,
      value: (Note n) => Variable<bool>(n.isDir) as Variable<Object>,
    );
    final key = (
      column: 'name_key',
      descending: sort.order == TreeOrder.name && direction,
      value: (Note n) => Variable<String>(n.nameKey) as Variable<Object>,
    );
    final name = (
      column: 'name',
      descending: sort.order == TreeOrder.name && direction,
      value: (Note n) => Variable<String>(n.name) as Variable<Object>,
    );
    if (sort.order == TreeOrder.name) return [isDir, key, name];
    final field = switch (sort.order) {
      TreeOrder.modified => (
        column: 'modified',
        descending: direction,
        value: (Note n) => Variable<DateTime>(n.modified) as Variable<Object>,
      ),
      TreeOrder.created => (
        column: 'created',
        descending: direction,
        value: (Note n) => Variable<DateTime>(n.created) as Variable<Object>,
      ),
      _ => (
        column: 'size',
        descending: direction,
        value: (Note n) => Variable<int>(n.size) as Variable<Object>,
      ),
    };
    return [isDir, field, key, name];
  }

  /// Every note that belongs to the root or to one of the [expandedPaths],
  /// in tree order — [sort]'s order the same way [children] reads it.
  ///
  /// Used for single-query tree flattening: one round-trip to the database
  /// returns every potentially visible row.
  Future<List<Note>> tree(
    Iterable<String> expandedPaths, {
    TreeSort sort = TreeSort.nameAsc,
  }) async {
    final ids = await _expandedIds(expandedPaths);
    return await treeQuery(ids, sort: sort).get();
  }

  /// The ids of the folders at [paths]: a seek on the unique path each.
  Future<List<int>> _expandedIds(Iterable<String> paths) async {
    if (paths.isEmpty) return const [];
    final query = _db.selectOnly(_db.notes)
      ..addColumns([_db.notes.id])
      ..where(_db.notes.path.isIn(paths));
    return [for (final row in await query.get()) row.read(_db.notes.id)!];
  }

  /// The statement behind [tree]: the children of the root and of the folders
  /// with the ids [expandedIds], parent by parent.
  ///
  /// Ordered by `parent` first, then by the tree's terms, so a name order
  /// walks the `notes_tree` index one parent after the other and sorts
  /// nothing (#1064, #1070); the previous `parent = 0 OR parent IN (…)`
  /// could not use it and sorted every row of every open folder in a
  /// temporary b-tree. The rows of one parent come out in the same order as
  /// before, which is all the caller groups them by.
  @visibleForTesting
  SimpleSelectStatement<$NotesTable, Note> treeQuery(
    Iterable<int> expandedIds, {
    TreeSort sort = TreeSort.nameAsc,
  }) {
    return _db.select(_db.notes)
      ..where((t) => t.parent.isIn([0, ...expandedIds]))
      ..orderBy([(t) => OrderingTerm.asc(t.parent), ..._treeOrder(sort)]);
  }

  /// The tree's own order terms for [sort] (#726): folders first, then the
  /// field — the name breaking ties where the field cannot (a folder's
  /// size is 0, two files saved in the same second share a time).
  static OrderingTerm _nameTie(Expression<Object> column, TreeSort sort) =>
      sort.order == TreeOrder.name && sort.descending
      ? OrderingTerm.desc(column)
      : OrderingTerm.asc(column);

  static List<OrderingTerm Function($NotesTable)> _treeOrder(TreeSort sort) {
    OrderingTerm by(Expression<Object> column) =>
        sort.descending ? OrderingTerm.desc(column) : OrderingTerm.asc(column);
    return [
      (t) => OrderingTerm.desc(t.isDir),
      switch (sort.order) {
        TreeOrder.name => (t) => by(t.nameKey),
        TreeOrder.modified => (t) => by(t.modified),
        TreeOrder.created => (t) => by(t.created),
        TreeOrder.size => (t) => by(t.size),
      },
      // The name key breaks ties of another field, and the name itself the
      // ties of the key (names that differ in case only). In a name order
      // the field already is the key: the tie-break goes the same way, or a
      // second ascending term would undo a descending order.
      if (sort.order != TreeOrder.name) (t) => OrderingTerm.asc(t.nameKey),
      (t) => _nameTie(t.name, sort),
    ];
  }

  /// The row at library-relative `path`, or null when absent.
  Future<Note?> find(String path) async {
    final rows = await (_db.select(
      _db.notes,
    )..where((t) => t.path.equals(path))).get();
    return rows.isEmpty ? null : rows.first;
  }

  /// The directory row whose path spells [path], or null: the folder
  /// `NoteOps.ensureFolder` reuses rather than making a second one under a
  /// different spelling (#847).
  ///
  /// The exact spelling wins (#857: a library holding `Journal/` and
  /// `journal/` must not have one redirected into the other), and it is the
  /// only lookup the `notes_dir_path` index can serve (#858). Only a miss
  /// falls back to a case-insensitive scan, which walks every folder row;
  /// of several that differ only by case, the first by path is taken.
  Future<Note?> folderIgnoringCase(String path) async {
    final exact =
        await (_db.select(_db.notes)
              ..where((t) => t.path.equals(path) & t.isDir.equals(true)))
            .getSingleOrNull();
    if (exact != null) return exact;
    final rows = await _db
        .customSelect(
          'SELECT * FROM notes WHERE is_dir = 1 AND path = ? COLLATE NOCASE '
          'ORDER BY path LIMIT 1',
          variables: [Variable.withString(path)],
          readsFrom: {_db.notes},
        )
        .get();
    return rows.isEmpty ? null : _db.notes.map(rows.first.data);
  }

  /// The rows at [paths], keyed by path, one `WHERE path IN (…)` per
  /// [_pathChunk] paths (a path the index does not hold is absent from the
  /// map, which is what [missingAmong] reads backwards).
  ///
  /// A candidate set is looked up whole: pairing a batch's new paths
  /// against its vanished ones used to ask for one gone row at a time,
  /// `SELECT … WHERE path = ?` per (live × gone) pair — a 1000-note folder
  /// move ran in the order of 10⁶ statements inside one batch (#360).
  Future<Map<String, Note>> byPaths(Iterable<String> paths) async {
    final wanted = paths.toSet().toList(growable: false);
    if (wanted.isEmpty) return const {};
    final rows = <String, Note>{};
    for (var i = 0; i < wanted.length; i += _pathChunk) {
      final end = i + _pathChunk < wanted.length
          ? i + _pathChunk
          : wanted.length;
      final batch = wanted.sublist(i, end);
      final found = await (_db.select(
        _db.notes,
      )..where((t) => t.path.isIn(batch))).get();
      for (final row in found) {
        rows[row.path] = row;
      }
    }
    return rows;
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

  /// The [limit] notes modified last, newest first, leaving out the ones
  /// under [excludeFolder] (the templates): the Home's recently modified
  /// tile (#535).
  ///
  /// `is_dir = 0` and the order on `modified` are what the `notes_recent`
  /// index holds (`IndexDatabase`), so the query walks that index from its
  /// end and stops after [limit] rows, whatever the library's size.
  Future<List<Note>> recentlyModified({
    int limit = 8,
    String excludeFolder = '',
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT * FROM notes WHERE is_dir = 0${_outside(excludeFolder)} '
          'ORDER BY modified DESC LIMIT ?',
          variables: [..._outsideArgs(excludeFolder), Variable.withInt(limit)],
          readsFrom: {_db.notes},
        )
        .get();
    return [for (final row in rows) _db.notes.map(row.data)];
  }

  /// A note picked at random, outside [excludeFolder], or null when there
  /// is none: the Home's random note tile (#535).
  ///
  /// A random id and the first note at or after it: one seek on the
  /// primary key. `ORDER BY random()` would read every row to pick one.
  /// Notes after a gap of deleted ids come up more often, which a tile
  /// that only wants something to reread can live with. The sign bit is
  /// masked rather than `abs()`ed: `abs` of the smallest integer throws.
  ///
  /// The id is drawn once, in a scalar subquery, and `+is_dir` keeps the
  /// planner off `notes_recent`: with the index on hand it scanned it,
  /// drew a fresh threshold per row, and the lowest ids always won (#666).
  Future<Note?> randomNote({String excludeFolder = ''}) async {
    final where = '+is_dir = 0${_outside(excludeFolder)}';
    final args = _outsideArgs(excludeFolder);
    final picked = await _db
        .customSelect(
          'SELECT * FROM notes WHERE $where AND id >= '
          '(SELECT (random() & 9223372036854775807) % (max(id) + 1) '
          'FROM notes) ORDER BY id LIMIT 1',
          variables: args,
          readsFrom: {_db.notes},
        )
        .getSingleOrNull();
    final row =
        picked ??
        await _db
            .customSelect(
              'SELECT * FROM notes WHERE $where ORDER BY id LIMIT 1',
              variables: args,
              readsFrom: {_db.notes},
            )
            .getSingleOrNull();
    return row == null ? null : _db.notes.map(row.data);
  }

  /// The SQL that keeps a row out of [folder]'s subtree; empty for none.
  static String _outside(String folder) =>
      folder.isEmpty ? '' : ' AND NOT (path >= ? AND path < ?)';

  static List<Variable<Object>> _outsideArgs(String folder) {
    if (folder.isEmpty) return const [];
    final range = subtreePathRange(folder);
    return [Variable.withString(range.from), Variable.withString(range.to)];
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

  /// Whether any of [stems] (lowercased file stems, as `noteStem` writes
  /// them) is also a stem or an alias of a note other than the ones with ids
  /// [own]: the names a link to one of them could be mistaken for a link to
  /// the other (#919).
  ///
  /// Asked in statement-sized chunks of stems, each an index lookup on the
  /// stem, and stops at the first chunk that finds one: a folder of a
  /// hundred thousand files is hundreds of statements, not one per file.
  Future<bool> stemsHeldBeyond(Iterable<String> stems, Set<int> own) async {
    final wanted = stems.toSet().toList(growable: false);
    for (var i = 0; i < wanted.length; i += _pathChunk) {
      final end = i + _pathChunk < wanted.length
          ? i + _pathChunk
          : wanted.length;
      final query = _db.selectOnly(_db.noteStems, distinct: true)
        ..addColumns([_db.noteStems.noteId])
        ..where(_db.noteStems.stem.isIn(wanted.sublist(i, end)));
      for (final row in await query.get()) {
        if (!own.contains(row.read(_db.noteStems.noteId))) return true;
      }
    }
    return false;
  }

  /// Whether the index holds any row at all: the first index's own
  /// precondition, answered without loading a row (`Indexer.indexTreeFirst`).
  Future<bool> hasRows() async {
    final row = await _db
        .customSelect('SELECT 1 AS one FROM notes LIMIT 1')
        .getSingleOrNull();
    return row != null;
  }

  /// The highest row id, or 0 when the index is empty: rows above it were
  /// inserted since, which is how a scan finds the notes it just added.
  Future<int> maxId() async {
    final row = await _db
        .customSelect('SELECT max(id) AS m FROM notes')
        .getSingle();
    return row.read<int?>('m') ?? 0;
  }

  /// How many notes (files, not folders) the index holds — the
  /// denominator a scan's progress reports against.
  Future<int> noteCount() async {
    final row = await _db
        .customSelect('SELECT count(*) AS c FROM notes WHERE is_dir = 0')
        .getSingle();
    return row.read<int>('c');
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
        'DELETE FROM note_anchors_fts WHERE rowid IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM note_headings WHERE note_id IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM note_blocks WHERE note_id IN '
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
        'DELETE FROM pending_links WHERE note_id IN '
        '(SELECT id FROM notes WHERE $where)',
        args,
      );
      await _db.customStatement(
        'DELETE FROM dangling_links WHERE note_id IN '
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
