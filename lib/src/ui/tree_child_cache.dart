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
/// A new revision or order [clear]s the cache; the epoch it bumps tells a read
/// still in flight that what it carries is stale.
final class TreeChildCache {
  /// A cache reading [pageSize] children at a time.
  new({required this.pageSize});

  /// How many children one read asks for.
  final int pageSize;

  final Map<int, LoadedChildren> _folders = <int, LoadedChildren>{};
  final Set<int> _paging = <int>{};

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
        if (!_folders.containsKey(id))
          // One row past the page says whether there is another.
          session.childrenPage(id, limit: pageSize + 1, sort: sort).then((
            rows,
          ) {
            if (epoch != _epoch) return;
            _folders[id] = LoadedChildren(
              rows.take(pageSize).toList(),
              more: rows.length > pageSize,
            );
          }),
    ]);
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
    try {
      final page = await session.childrenPage(
        parentId,
        limit: pageSize + 1,
        sort: sort,
        after: loaded.rows.last,
      );
      if (epoch != _epoch) return false;
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
