import 'package:niman/src/db/index_database.dart';

/// The keyboard's cursor in the walk: its place, and the row it is on.
typedef TreeWalkCursor = ({int at, TreeWalkRow row});

/// One row the tree's keyboard walks (#727): the note it draws, where the
/// list puts it, and what a key on it acts on.
final class TreeWalkRow {
  /// A row of the walk.
  const new({
    required this.note,
    required this.path,
    required this.pinned,
    required this.depth,
    required this.top,
    required this.height,
    required this.index,
    this.sidecar = false,
  });

  /// The note the row draws.
  final Note note;

  /// The note's library-relative path.
  final String path;

  /// The row's place in the walk: the pinned notes first, then the tree's
  /// own rows.
  final int index;

  /// The pinned block's copy of the note, rather than its own row in the
  /// tree: a pinned note is drawn twice, and the cursor is on one of them.
  final bool pinned;

  /// How deep the row sits, for the right arrow's step into the rows under
  /// it. A pinned row is drawn at the root: its depth means nothing there.
  final int depth;

  /// Whether the row is a text recognition sidecar, whose left arrow goes to
  /// the file it is drawn under.
  final bool sidecar;

  /// Where the list draws the row.
  final double top;

  /// How tall the row is.
  final double height;
}
