import 'package:drift/drift.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';

/// How many rows [TreePager.firstChildStartingWith] reads to check against
/// the tree's fold before it asks for the next ones.
const _foldBatch = 64;

/// The reads of one folder's children by position in the tree's order
/// (#1064, #1200): a page after a row, a page before it, a page at an
/// offset, a row's rank, the count, and the first name that starts with
/// something.
///
/// All of them share one description of the order, [_keysetOf], and one
/// cursor predicate, [_cursor]: "after a row" and "before a row" are the
/// same comparison turned round, and a rank is the rows "before" counted, so
/// the three cannot drift apart.
final class TreePager {
  /// Creates the reads over [_db].
  new(this._db);

  final IndexDatabase _db;

  /// How many children the row with id [parentId] has: a count over the
  /// `notes_tree` index, whose first column is `parent`.
  Future<int> childCount(int parentId) async {
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM notes WHERE parent = ?',
          variables: [Variable<int>(parentId)],
          readsFrom: {_db.notes},
        )
        .get();
    return rows.first.read<int>('c');
  }

  /// How many siblings of [note] sort before it in [sort]'s order: its
  /// position among its parent's children.
  ///
  /// The count of the rows the cursor [_cursor] finds before [note], so it is
  /// consistent with [page] by construction. [note] needs only the fields
  /// the order reads, not to be in the index still.
  Future<int> rankOf(Note note, {TreeSort sort = TreeSort.nameAsc}) async {
    if (sort.order == TreeOrder.name) return await _nameRank(note, sort);
    final variables = <Variable<Object>>[Variable<int>(note.parent)];
    final where = StringBuffer('parent = ?');
    _cursor(_keysetOf(sort), note, before: true, into: where, bind: variables);
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM notes WHERE $where',
          variables: variables,
          readsFrom: {_db.notes},
        )
        .get();
    return rows.first.read<int>('c');
  }

  /// One page of the children of [parentId] in [sort]'s order: at most
  /// [limit] rows, the ones after [after] or, when [before] is given, the
  /// [limit] ones immediately before it (still returned in the tree's
  /// order). With neither, the first rows.
  ///
  /// A keyset, not an offset, so a page far down a folder is as cheap as the
  /// first.
  Future<List<Note>> page(
    int parentId, {
    required int limit,
    required TreeSort sort,
    Note? after,
    Note? before,
  }) {
    assert(after == null || before == null, 'a page is after or before a row');
    return _select(
      parentId,
      sort: sort,
      limit: limit,
      cursor: after ?? before,
      before: before != null,
    );
  }

  /// [limit] children of [parentId] from position [offset] on in [sort]'s
  /// order: for a page with no loaded neighbour to start a keyset from.
  /// SQLite walks [offset] index entries to get there.
  Future<List<Note>> at(
    int parentId, {
    required int offset,
    required int limit,
    required TreeSort sort,
  }) {
    return _select(parentId, sort: sort, limit: limit, offset: offset);
  }

  /// The first child of [parentId], in [sort]'s order and after [after] when
  /// given, whose name starts with [foldedPrefix] — a name as `foldName`
  /// folds it, which is what the tree's type-ahead compares (#1070).
  ///
  /// `name_key` is not that fold: it is `foldName` with each run of digits
  /// rewritten as its length and then its digits (`alpha10` is `alpha0210`),
  /// so it reads a prefix right only up to the first digit, and `alpha1`
  /// would match nothing in it though `alpha10` starts with it. The query
  /// therefore bounds `name_key` by the part of the prefix before its first
  /// digit — a range, and in a name order a seek on `notes_tree` — which
  /// every name that matches satisfies, and checks the candidates against
  /// `foldName` itself. With a prefix that has no digit the first candidate
  /// always matches, so it is one row read.
  Future<Note?> firstChildStartingWith(
    int parentId,
    String foldedPrefix, {
    required TreeSort sort,
    Note? after,
  }) async {
    final head = foldedPrefix.split(RegExp('[0-9]')).first;
    final upper = _prefixUpperBound(head);
    final extra = <String>[];
    final extraVariables = <Variable<Object>>[];
    if (head.isNotEmpty) {
      extra.add('name_key >= ?');
      extraVariables.add(Variable<String>(head));
      if (upper != null) {
        extra.add('name_key < ?');
        extraVariables.add(Variable<String>(upper));
      }
    }
    // Folders come first in every order, so the walk is the folders and then
    // the files. Pinning `is_dir` lets SQLite seek `notes_tree` inside each
    // group, where a range on `name_key` alone would have to cross both.
    for (final dirs in [true, false]) {
      if (dirs && after != null && !after.isDir) continue;
      var cursor = after != null && after.isDir == dirs ? after : null;
      while (true) {
        final rows = await _select(
          parentId,
          sort: sort,
          limit: _foldBatch,
          cursor: cursor,
          extra: ['is_dir = ?', ...extra],
          extraVariables: [Variable<bool>(dirs), ...extraVariables],
        );
        for (final row in rows) {
          if (foldName(row.name).startsWith(foldedPrefix)) return row;
        }
        if (rows.length < _foldBatch) break;
        cursor = rows.last;
      }
    }
    return null;
  }

  /// The one read behind [page], [at] and [firstChildStartingWith]: the
  /// children of [parentId] satisfying [extra] (conditions, bound to
  /// [extraVariables] in order), after [cursor] — or before it when [before]
  /// — at most [limit] of them, from [offset].
  ///
  /// A read before the cursor goes through the order turned round and is
  /// turned back, so it is the [limit] rows nearest the cursor, in the
  /// tree's order.
  Future<List<Note>> _select(
    int parentId, {
    required TreeSort sort,
    required int limit,
    int? offset,
    Note? cursor,
    bool before = false,
    List<String> extra = const [],
    List<Variable<Object>> extraVariables = const [],
  }) async {
    if (cursor != null && offset == null && sort.order == TreeOrder.name) {
      return await _namePage(
        parentId,
        sort: sort,
        limit: limit,
        cursor: cursor,
        before: before,
        extra: extra,
        extraVariables: extraVariables,
      );
    }
    if (cursor == null && extra.isEmpty && sort.order == TreeOrder.name) {
      return await _nameWindow(
        parentId,
        sort: sort,
        limit: limit,
        offset: offset ?? 0,
      );
    }
    final keys = _keysetOf(sort);
    final variables = <Variable<Object>>[Variable<int>(parentId)];
    final where = StringBuffer('parent = ?');
    for (final condition in extra) {
      where.write(' AND $condition');
    }
    variables.addAll(extraVariables);
    if (cursor != null) {
      _cursor(keys, cursor, before: before, into: where, bind: variables);
    }
    final order = [
      for (final key in keys)
        '${key.column} ${key.descending != before ? 'DESC' : 'ASC'}',
    ].join(', ');
    variables.add(Variable<int>(limit));
    final paging = StringBuffer('LIMIT ?');
    if (offset != null) {
      paging.write(' OFFSET ?');
      variables.add(Variable<int>(offset));
    }
    final rows = await _db
        .customSelect(
          'SELECT * FROM notes WHERE $where ORDER BY $order $paging',
          variables: variables,
          readsFrom: {_db.notes},
        )
        .get();
    final notes = [for (final row in rows) _db.notes.map(row.data)];
    return before ? notes.reversed.toList() : notes;
  }

  /// [_select] after or before [cursor] in a name order, as seeks on
  /// `notes_tree` (#1200).
  ///
  /// The cursor of [_cursor] is a chain of `OR`s, which SQLite cannot turn
  /// into a range of the index: it walked the folder from its first entry,
  /// and a page a million rows down cost 98 ms where the first cost 28
  /// (`docs/records/tree-window.md`, "Measured"). So the read is split where
  /// the order splits, at `is_dir`. In the cursor's own group the rest of
  /// the order is one row value, `(name_key, name)`, compared in one
  /// direction — a range of `notes_tree (parent, is_dir DESC, name_key,
  /// name)`, read from the cursor on. When that group runs out before the
  /// page is full, the read goes on into the next group from its own end:
  /// the files after the last folder, or the folders before the first file.
  Future<List<Note>> _namePage(
    int parentId, {
    required TreeSort sort,
    required int limit,
    required Note cursor,
    required bool before,
    required List<String> extra,
    required List<Variable<Object>> extraVariables,
  }) async {
    // The name terms run in the sort's direction; reading before the cursor
    // runs them the other way, and the answer is turned back below.
    final descending = sort.descending != before;
    final direction = descending ? 'DESC' : 'ASC';
    final rows = await _nameRead(
      parentId,
      isDir: cursor.isDir,
      bound: '(name_key, name) ${descending ? '<' : '>'} (?, ?)',
      boundVariables: [
        Variable<String>(cursor.nameKey),
        Variable<String>(cursor.name),
      ],
      direction: direction,
      limit: limit,
      extra: extra,
      extraVariables: extraVariables,
    );
    // Folders come first: after a folder come the files, before a file the
    // folders; after a file, or before a folder, there is no other group.
    final otherGroup = before ? !cursor.isDir : cursor.isDir;
    if (rows.length < limit && otherGroup) {
      rows.addAll(
        await _nameRead(
          parentId,
          isDir: !cursor.isDir,
          direction: direction,
          limit: limit - rows.length,
          extra: extra,
          extraVariables: extraVariables,
        ),
      );
    }
    return before ? rows.reversed.toList() : rows;
  }

  /// [_select] with no cursor in a name order: the first rows, or those from
  /// [offset] on, as seeks on `notes_tree` (#1229).
  ///
  /// The index is `(parent, is_dir DESC, name_key, name)`. Read in a
  /// descending order, `is_dir DESC, name_key DESC, name DESC` is not a scan
  /// of it in either direction (the first term runs one way, the other two
  /// the other), so SQLite sorted the whole folder for a first page and for
  /// every jump by offset. The order splits at `is_dir` as [_namePage]'s
  /// does: each group is read alone, in the index's own order or backwards.
  /// The folders come first; the files are read when the folders run out, from
  /// the offset that is left once the folders are counted.
  Future<List<Note>> _nameWindow(
    int parentId, {
    required TreeSort sort,
    required int limit,
    required int offset,
  }) async {
    final direction = sort.descending ? 'DESC' : 'ASC';
    final rows = await _nameRead(
      parentId,
      isDir: true,
      direction: direction,
      limit: limit,
      offset: offset,
      extra: const [],
      extraVariables: const [],
    );
    if (rows.length >= limit) return rows;
    // The folders ran out. How many offset rows they absorbed: all the
    // offset when it was past the end (the read above is then empty), so
    // the files start `folders` rows less in. A short page that started
    // inside the folders absorbed no more than it returned.
    var filesOffset = 0;
    if (rows.isEmpty && offset > 0) {
      final folders = await _db
          .customSelect(
            'SELECT COUNT(*) AS c FROM notes WHERE parent = ? AND is_dir = 1',
            variables: [Variable<int>(parentId)],
            readsFrom: {_db.notes},
          )
          .get();
      filesOffset = offset - folders.first.read<int>('c');
    }
    rows.addAll(
      await _nameRead(
        parentId,
        isDir: false,
        direction: direction,
        limit: limit - rows.length,
        offset: filesOffset > 0 ? filesOffset : 0,
        extra: const [],
        extraVariables: const [],
      ),
    );
    return rows;
  }

  /// The children of [parentId] in one `is_dir` group, by `(name_key,
  /// name)` in [direction], from [bound] on when given: one range of
  /// `notes_tree`.
  Future<List<Note>> _nameRead(
    int parentId, {
    required bool isDir,
    required String direction,
    required int limit,
    required List<String> extra,
    required List<Variable<Object>> extraVariables,
    int offset = 0,
    String? bound,
    List<Variable<Object>> boundVariables = const [],
  }) async {
    final where = StringBuffer('parent = ? AND is_dir = ?');
    final variables = <Variable<Object>>[
      Variable<int>(parentId),
      Variable<bool>(isDir),
    ];
    if (bound != null) {
      where.write(' AND $bound');
      variables.addAll(boundVariables);
    }
    for (final condition in extra) {
      where.write(' AND $condition');
    }
    variables
      ..addAll(extraVariables)
      ..add(Variable<int>(limit));
    if (offset > 0) variables.add(Variable<int>(offset));
    final rows = await _db
        .customSelect(
          'SELECT * FROM notes WHERE $where '
          'ORDER BY name_key $direction, name $direction LIMIT ?'
          '${offset > 0 ? ' OFFSET ?' : ''}',
          variables: variables,
          readsFrom: {_db.notes},
        )
        .get();
    return [for (final row in rows) _db.notes.map(row.data)];
  }

  /// [rankOf] in a name order: the rows before [note] in its own `is_dir`
  /// group, one range of `notes_tree` counted, and for a file every folder
  /// as well, since the folders come first. The same split as [_namePage].
  Future<int> _nameRank(Note note, TreeSort sort) async {
    final before = sort.descending ? '>' : '<';
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM notes WHERE parent = ? AND is_dir = ? '
          'AND (name_key, name) $before (?, ?)',
          variables: [
            Variable<int>(note.parent),
            Variable<bool>(note.isDir),
            Variable<String>(note.nameKey),
            Variable<String>(note.name),
          ],
          readsFrom: {_db.notes},
        )
        .get();
    var rank = rows.first.read<int>('c');
    if (!note.isDir) {
      final folders = await _db
          .customSelect(
            'SELECT COUNT(*) AS c FROM notes WHERE parent = ? AND is_dir = 1',
            variables: [Variable<int>(note.parent)],
            readsFrom: {_db.notes},
          )
          .get();
      rank += folders.first.read<int>('c');
    }
    return rank;
  }

  /// Writes onto [into] the condition "strictly after [row]" in [keys]'s
  /// order — or, with [before], "strictly before" — and its values onto
  /// [bind].
  ///
  /// The terms are compared one after the other, each in its own direction:
  /// the first term differs, or it ties and the second differs, and so on.
  /// For the name orders those are the terms of `notes_tree`, so a page
  /// reads that many index entries and sorts nothing.
  static void _cursor(
    List<_Key> keys,
    Note row, {
    required bool before,
    required StringBuffer into,
    required List<Variable<Object>> bind,
  }) {
    final branches = <String>[];
    for (var i = 0; i < keys.length; i++) {
      final equal = [
        for (var j = 0; j < i; j++) '${keys[j].column} = ?',
        '${keys[i].column} ${keys[i].descending != before ? '<' : '>'} ?',
      ];
      branches.add('(${equal.join(' AND ')})');
      for (var j = 0; j <= i; j++) {
        bind.add(keys[j].value(row));
      }
    }
    into.write(' AND (${branches.join(' OR ')})');
  }

  /// The smallest string that sorts after every string starting with
  /// [prefix], or null when there is none (empty, or all of the last code
  /// point). SQLite compares text by its UTF-8 bytes, which is code point
  /// order, so the last code point is stepped up (past the surrogates, which
  /// no text holds).
  static String? _prefixUpperBound(String prefix) {
    final runes = prefix.runes.toList();
    while (runes.isNotEmpty) {
      final last = runes.removeLast();
      if (last < 0x10FFFF) {
        runes.add(last == 0xD7FF ? 0xE000 : last + 1);
        return String.fromCharCodes(runes);
      }
    }
    return null;
  }

  /// The terms [sort] orders by, with the column each reads and the value
  /// of a row for it: what a keyset cursor compares.
  static List<_Key> _keysetOf(TreeSort sort) {
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
}

/// One term of the tree's order: the column, its direction, and the value a
/// row has for it.
typedef _Key = ({
  String column,
  bool descending,
  Variable<Object> Function(Note) value,
});
