import 'dart:async';

import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';

/// The loaded part of one folder's children.
final class LoadedChildren {
  /// The first [rows] of a folder, [more] when the folder has others.
  const new(this.rows, {required this.more});

  /// The children loaded so far, in the tree's order.
  final List<Note> rows;

  /// Whether the folder has children after [rows].
  final bool more;
}

/// What the tree has read of each folder (#1064).
///
/// The tree used to read every open folder's rows again, whole, for every
/// toggle, create or sync batch. Here a folder is read once per index
/// revision and in pages: opening a folder asks for that folder alone,
/// closing one asks for nothing, and a folder of a hundred thousand notes is
/// a page until the list scrolls to the end of it.
///
/// A new order, or a revision that may have moved any row, [clear]s the
/// cache; one that names the folders it moved rows in [forget]s those alone
/// (#1132). Either tells a read still in flight of a folder it dropped that
/// what it carries is stale.
final class TreeChildCache {
  /// A cache reading [pageSize] children at a time.
  new({required this.pageSize});

  /// How many children one read asks for.
  final int pageSize;

  final Map<int, LoadedChildren> _folders = <int, LoadedChildren>{};
  final Set<int> _paging = <int>{};

  /// How many times each folder was [forget]-ten: a read of it that started
  /// before the last time lands on nothing.
  final Map<int, int> _forgotten = <int, int>{};

  /// Counts the times the cache was emptied.
  int get epoch => _epoch;
  int _epoch = 0;

  /// The pinned notes of this revision, once read.
  List<Note>? pinned;

  /// What is loaded of the folder with id [parentId], or null.
  LoadedChildren? operator [](int parentId) => _folders[parentId];

  /// Forgets everything: the index moved, or the order changed.
  void clear() {
    _folders.clear();
    _paging.clear();
    pinned = null;
    _epoch++;
  }

  /// Forgets the folders with ids [parents], whose rows moved, and the
  /// pinned notes, whose titles and pins may have: every other folder's
  /// rows stand.
  void forget(Iterable<int> parents) {
    for (final id in parents) {
      _folders.remove(id);
      _forgotten[id] = (_forgotten[id] ?? 0) + 1;
    }
    pinned = null;
  }

  /// Whether a read of [parentId] begun at [epoch], with the folder
  /// forgotten [forgotten] times then, still holds.
  bool _current(int parentId, int epoch, int forgotten) =>
      epoch == _epoch && forgotten == (_forgotten[parentId] ?? 0);

  /// Reads the first page of each of [parents] that is not loaded yet, all
  /// at once.
  Future<void> ensure(
    LibrarySession session,
    Iterable<int> parents,
    TreeSort sort,
  ) {
    final epoch = _epoch;
    return Future.wait([
      for (final id in parents.toSet())
        if (!_folders.containsKey(id)) _read(session, id, sort, epoch),
    ]);
  }

  /// Reads the first page of [parentId], for [ensure].
  Future<void> _read(
    LibrarySession session,
    int parentId,
    TreeSort sort,
    int epoch,
  ) async {
    final forgotten = _forgotten[parentId] ?? 0;
    // One row past the page says whether there is another.
    final rows = await session.childrenPage(
      parentId,
      limit: pageSize + 1,
      sort: sort,
    );
    if (!_current(parentId, epoch, forgotten)) return;
    _folders[parentId] = LoadedChildren(
      rows.take(pageSize).toList(),
      more: rows.length > pageSize,
    );
  }

  /// Reads the page after what is loaded of [parentId] and appends it.
  /// Answers whether rows were added; a folder already being read, or with
  /// nothing more, answers false.
  Future<bool> loadMore(
    LibrarySession session,
    int parentId,
    TreeSort sort,
  ) async {
    final loaded = _folders[parentId];
    if (loaded == null || !loaded.more || !_paging.add(parentId)) return false;
    final epoch = _epoch;
    final forgotten = _forgotten[parentId] ?? 0;
    try {
      final page = await session.childrenPage(
        parentId,
        limit: pageSize + 1,
        sort: sort,
        after: loaded.rows.last,
      );
      if (!_current(parentId, epoch, forgotten)) return false;
      _folders[parentId] = LoadedChildren([
        ...loaded.rows,
        ...page.take(pageSize),
      ], more: page.length > pageSize);
      return page.isNotEmpty;
    } finally {
      _paging.remove(parentId);
    }
  }
}
