import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/library_tree.dart';

/// The [LibraryTree] read from the open library's index through [NoteDao].
final class IndexLibraryTree implements LibraryTree {
  /// Reads the index the callback answers: the open library's, or null
  /// while none is open.
  new(this._indexDb);

  final IndexDatabase? Function() _indexDb;

  /// The DAO over the open index, or null while no library is open.
  NoteDao? get _dao {
    final db = _indexDb();
    return db == null ? null : NoteDao(db);
  }

  @override
  Future<List<Note>> children(
    int parentId, {
    TreeSort sort = TreeSort.nameAsc,
  }) async => await _dao?.children(parentId, sort: sort) ?? const [];

  @override
  Future<List<Note>> childrenPage(
    int parentId, {
    required int limit,
    TreeSort sort = TreeSort.nameAsc,
    Note? after,
    Note? before,
  }) async =>
      await _dao?.childrenPage(
        parentId,
        limit: limit,
        sort: sort,
        after: after,
        before: before,
      ) ??
      const [];

  @override
  Future<int> childCount(int parentId) async =>
      await _dao?.childCount(parentId) ?? 0;

  @override
  Future<int> rankOf(Note note, {TreeSort sort = TreeSort.nameAsc}) async =>
      await _dao?.rankOf(note, sort: sort) ?? 0;

  @override
  Future<List<Note>> childrenAt(
    int parentId, {
    required int offset,
    required int limit,
    TreeSort sort = TreeSort.nameAsc,
  }) async =>
      await _dao?.childrenAt(
        parentId,
        offset: offset,
        limit: limit,
        sort: sort,
      ) ??
      const [];

  @override
  Future<Note?> firstChildStartingWith(
    int parentId,
    String foldedPrefix, {
    TreeSort sort = TreeSort.nameAsc,
    Note? after,
  }) async => await _dao?.firstChildStartingWith(
    parentId,
    foldedPrefix,
    sort: sort,
    after: after,
  );

  @override
  Future<List<Note>> rows(
    Iterable<String> expandedPaths, {
    TreeSort sort = TreeSort.nameAsc,
  }) async => await _dao?.tree(expandedPaths, sort: sort) ?? const [];

  @override
  Future<List<Note>> folders() async => await _dao?.folders() ?? const [];

  @override
  Future<Set<String>> missingPaths(Iterable<String> paths) async =>
      await _dao?.missingAmong(paths) ?? const <String>{};
}
