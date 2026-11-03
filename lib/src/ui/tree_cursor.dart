import 'package:niman/src/ui/tree_walk.dart';
import 'package:niman/src/ui/tree_walk_row.dart';

/// The tree keyboard's cursor (#727): the row it is on, and whether its ring
/// shows, found in [walk] by path.
final class TreeCursor {
  /// A cursor over [walk]; until it is put on a row, it starts from the row
  /// at [selectedPath].
  new({required this.walk, required this.selectedPath});

  /// The rows the cursor walks.
  final TreeWalk walk;

  /// The selected row's path as the tree has it now, or null.
  final String? Function() selectedPath;

  /// The row the keyboard's cursor is on, by path, and whether that is the
  /// pinned block's copy of the note. Held by path rather than by place:
  /// the walk follows the row while the tree grows and shrinks around it.
  String? path;

  /// Whether the cursor is on the pinned block's copy of the note at [path].
  bool pinned = false;

  /// Whether the ring is on the cursor — the keyboard put it there, a
  /// pointer takes it away — as on a grid tile (#727).
  bool ring = false;

  /// Puts the cursor on the row at [path], the pinned block's copy when
  /// [pinned]; with [ring], shows or hides the ring too.
  void moveTo(String path, {required bool pinned, bool? ring}) {
    this.path = path;
    this.pinned = pinned;
    if (ring != null) this.ring = ring;
  }

  /// The cursor's place in the walk from the rows loaded: the row it is on,
  /// or the selected row — a walk begun with the keyboard starts where the
  /// tree already is — or the first row. Null when the row it is on is not
  /// in a page that is loaded: see [atAsync].
  int? at() {
    final path = this.path;
    if (path != null) return walk.find(path, inPinned: pinned);
    final selected = selectedPath();
    return selected == null ? 0 : walk.find(selected);
  }

  /// The cursor's place in the walk, asking the index for a row whose page
  /// is not loaded.
  Future<int> atAsync() async {
    final held = at();
    if (held != null) return held;
    final path = this.path;
    final selected = selectedPath();
    final cursor = path == null
        ? null
        : await walk.findAsync(path, inPinned: pinned);
    if (cursor != null) return cursor;
    final chosen = selected == null ? null : await walk.findAsync(selected);
    return chosen ?? 0;
  }

  /// The cursor and the row it is on, when both are loaded.
  TreeWalkCursor? here() {
    final at = this.at();
    final row = at == null ? null : walk.rowAt(at);
    return at == null || row == null ? null : (at: at, row: row);
  }

  /// The cursor and the row it is on, loading the page it is in.
  Future<TreeWalkCursor?> resolved() async {
    final at = await atAsync();
    final row = await walk.rowAtAsync(at);
    return row == null ? null : (at: at, row: row);
  }

  /// Whether the keyboard's ring is on [row] (#727), the tree holding the
  /// keyboard when [focused]: the cursor's own look, apart from the
  /// selection's fill, so the two are told apart and can be worn together.
  bool isOn(TreeWalkRow? row, {required bool focused}) =>
      row != null &&
      ring &&
      focused &&
      row.path == path &&
      row.pinned == pinned;
}
