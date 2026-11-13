import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';

/// The open library's tree as the index holds it (#1258): the rows of a
/// folder, a page of them, where a row sorts, and the folders.
///
/// Reached through `LibrarySession.tree`. Every read answers empty — no
/// rows, a count of 0, no note — while no library is open: there is no
/// index to read, and the tree asks for the root's children before the
/// first open.
abstract interface class LibraryTree {
  /// Children of the row with id [parentId] (0 = library root), in
  /// [sort]'s order (#726): directories first whatever the field, then
  /// the field in its own direction, the name breaking ties.
  Future<List<Note>> children(int parentId, {TreeSort sort = TreeSort.nameAsc});

  /// One page of the children of [parentId] in [sort]'s order: at most
  /// [limit] rows, those after [after], a row of the previous page (#1064),
  /// or the [limit] rows immediately before [before], in the tree's order
  /// (#1200). Giving both is an error. A page after a row that is shorter
  /// than [limit] is the last one.
  Future<List<Note>> childrenPage(
    int parentId, {
    required int limit,
    TreeSort sort = TreeSort.nameAsc,
    Note? after,
    Note? before,
  });

  /// How many children the row with id [parentId] has (#1200).
  Future<int> childCount(int parentId);

  /// How many siblings of [note] sort before it in [sort]'s order: its
  /// position among its parent's children (#1200).
  Future<int> rankOf(Note note, {TreeSort sort = TreeSort.nameAsc});

  /// [limit] children of [parentId] from position [offset] on in [sort]'s
  /// order (#1200): a page with no loaded neighbour to read from.
  Future<List<Note>> childrenAt(
    int parentId, {
    required int offset,
    required int limit,
    TreeSort sort = TreeSort.nameAsc,
  });

  /// The first child of [parentId], in [sort]'s order and after [after] when
  /// given, whose name starts with [foldedPrefix] as `foldName` folds names
  /// (#1200); null when none does.
  Future<Note?> firstChildStartingWith(
    int parentId,
    String foldedPrefix, {
    TreeSort sort = TreeSort.nameAsc,
    Note? after,
  });

  /// Every note that belongs to the root or to one of the [expandedPaths],
  /// in [sort]'s order the same way [children] reads it.
  Future<List<Note>> rows(
    Iterable<String> expandedPaths, {
    TreeSort sort = TreeSort.nameAsc,
  });

  /// Every indexed folder, path-ordered (for move-target pickers).
  Future<List<Note>> folders();

  /// Which of [paths] the index does not hold — a note pruned before this
  /// session read the tree, so no `LibrarySession.removals` event carries
  /// it. What a tab holds open on one closes when the workspace loads
  /// (#289).
  Future<Set<String>> missingPaths(Iterable<String> paths);
}
