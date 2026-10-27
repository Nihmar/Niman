import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/tree_read_guard.dart';

/// What the model of the tree needs of one expanded folder (#1200): its row,
/// its place among its siblings and how many children it has.
typedef FolderFact = ({Note note, int rank, int count});

/// A folder's row with its rank among its siblings, as read.
typedef _Placed = ({Note note, int rank});

/// The small facts about the tree's folders, read once and held until a
/// revision moves them (#1200).
///
/// There is a handful of them per expanded folder, against the pages' two
/// thousand rows, so they stay held when a folder closes, and reopening one
/// costs no count. Each is dropped by [forget] when the rows it depends on
/// moved: a folder's child count with the folder's own forget, and its row
/// and its rank with its parent's, the rank being a count of its siblings.
final class TreeFolderFacts {
  /// The expanded folders' rows and ranks, by path: the widget knows a folder
  /// by its path, and the id is only known once the row is read.
  final Map<String, _Placed> _placed = <String, _Placed>{};

  /// The child counts, by folder id (0 = the root).
  final Map<int, int> _counts = <int, int>{};

  /// The held child count of folder [id], or null.
  int? count(int id) => _counts[id];

  /// Holds [count] as the child count of folder [id].
  void keepCount(int id, int count) => _counts[id] = count;

  /// The facts about the folder at [path] in [sort]'s order, reading the
  /// ones not held; null when no folder is there, or the library is closed.
  ///
  /// What a read brings is held only while [guard] says that it holds since
  /// [stamp]: a revision that moved the folder's parent, or the folder's own
  /// children, while it was out leaves it unheld, though it is still the
  /// answer for the model being built.
  Future<FolderFact?> read(
    LibrarySession session,
    String path,
    TreeSort sort,
    TreeReadGuard guard,
    ReadStamp stamp,
  ) async {
    final placed = _placed[path];
    final note = placed?.note ?? await session.ops?.find(path);
    if (note == null || !note.isDir) return null;
    final held = _counts[note.id];
    final (rank, count) = await (
      placed != null
          ? Future<int>.value(placed.rank)
          : session.rankOf(note, sort: sort),
      held != null ? Future<int>.value(held) : session.childCount(note.id),
    ).wait;
    if (guard.holds(stamp, note.parent)) {
      _placed[path] = (note: note, rank: rank);
    }
    if (guard.holds(stamp, note.id)) _counts[note.id] = count;
    return (note: note, rank: rank, count: count);
  }

  /// Forgets everything held.
  void clear() {
    _placed.clear();
    _counts.clear();
  }

  /// Forgets what the rows moved in the folders with ids [parents] change:
  /// their counts, and the rows and ranks of the folders in them.
  void forget(Set<int> parents) {
    _counts.removeWhere((id, _) => parents.contains(id));
    _placed.removeWhere((_, folder) => parents.contains(folder.note.parent));
  }
}
