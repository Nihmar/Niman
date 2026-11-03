import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/toolbar.dart';
import 'package:niman/src/ui/tree_listing.dart';
import 'package:niman/src/ui/tree_rows.dart';
import 'package:niman/src/ui/tree_walk_row.dart';

/// The rows the tree's keyboard walks (#727), as the last build laid them
/// out: the pinned notes first, then the tree's own rows, each where the list
/// draws it.
///
/// The rows of the last build, the height each pinned item takes and the
/// height of a row are what the keyboard walks. The walk itself is built when
/// a key is pressed, not on every frame: only the rows a key reaches are made.
final class TreeWalk {
  /// The room the divider that closes the pinned block takes: its hairline
  /// and the breathing space under it.
  static const double pinnedDividerHeight = 9;

  /// The heights of the pinned block's items, in the order the list draws
  /// them: the heading, the notes (none when it is rolled up) and the
  /// divider that closes it off. Empty when nothing is pinned.
  static List<double> pinnedHeightsOf(
    List<Note> pinned,
    double rowHeight, {
    required bool collapsed,
  }) {
    if (pinned.isEmpty) return const <double>[];
    return [
      editorToolbarHeight,
      if (!collapsed)
        for (final _ in pinned) rowHeight,
      pinnedDividerHeight,
    ];
  }

  TreeRows? _rows;
  List<double> _pinnedHeights = const <double>[];
  double _pinnedTotal = 0;
  double _rowHeight = 0;

  /// The rows of the last build; null before the first and while the tree
  /// is empty.
  TreeRows? get rows => _rows;

  /// The heights of the pinned block's items the last build laid out.
  List<double> get pinnedHeights => _pinnedHeights;

  /// The height of a tree row the last build laid out.
  double get rowHeight => _rowHeight;

  /// Takes [rows] as the build lays them out: [rowHeight] a row, and the
  /// pinned block rolled up when [collapsed].
  void layout(
    TreeRows rows, {
    required double rowHeight,
    required bool collapsed,
  }) {
    _rows = rows;
    _pinnedHeights = pinnedHeightsOf(
      rows.pinned,
      rowHeight,
      collapsed: collapsed,
    );
    _pinnedTotal = _pinnedHeights.fold<double>(
      0,
      (total, height) => total + height,
    );
    _rowHeight = rowHeight;
  }

  /// Lets go of the rows: there are none to walk until the next build.
  void clear() => _rows = null;

  /// Where the list draws the tree's row at list index [listIndex]: below
  /// the pinned block, a row's height each.
  double treeTop(int listIndex) => _pinnedTotal + listIndex * _rowHeight;

  /// What the keyboard walks at the pinned block's [index] item (#727): the
  /// item's place and height, and the row it draws — null for the pinned
  /// heading and its divider, which are not rows. Reads the rows of the last
  /// build.
  TreeWalkRow? pinnedAt(int index) {
    final rows = _rows;
    final header = _pinnedHeights.length;
    if (rows == null || index <= 0 || index >= header - 1) return null;
    var top = 0.0;
    for (var at = 0; at < index; at++) {
      top += _pinnedHeights[at];
    }
    final note = rows.pinned[index - 1];
    return TreeWalkRow(
      note: note,
      path: note.path,
      pinned: true,
      // The pinned block draws every note at the root: its own depth
      // would say nothing there.
      depth: 0,
      top: top,
      height: _pinnedHeights[index],
      index: index - 1,
    );
  }

  /// The tree's own row at model index [modelIndex] as the walk sees it, from
  /// what the listing draws there; null while its page is not loaded.
  TreeWalkRow? treeRow(int modelIndex, TreeEntry entry) {
    final note = entry.note;
    final rows = _rows;
    if (note == null || rows == null) return null;
    return TreeWalkRow(
      note: note,
      path: note.path,
      pinned: false,
      depth: entry.depth,
      sidecar: entry.sidecar,
      top: treeTop(rows.listing.listIndexOf(modelIndex)),
      height: _rowHeight,
      index: pinnedWalked + modelIndex,
    );
  }

  /// How many of the pinned block's items are rows the keyboard walks: its
  /// notes, without the heading and the divider — none while rolled up.
  int get pinnedWalked =>
      _pinnedHeights.isEmpty ? 0 : _pinnedHeights.length - 2;

  /// How many rows the keyboard walks, in the order the list draws them:
  /// the pinned notes first, then the tree's own rows (#727). The row being
  /// made is not among them.
  int get length {
    final rows = _rows;
    return rows == null ? 0 : pinnedWalked + rows.listing.modelLength;
  }

  /// The walk's row at [index]: the list's item it is. Only the rows a key
  /// reaches are made — a tree of a million rows is not copied for each key
  /// press. Null while the row's page is not loaded; see [rowAtAsync].
  TreeWalkRow? rowAt(int index) {
    final pinned = pinnedWalked;
    if (index < pinned) return pinnedAt(index + 1);
    final rows = _rows;
    final at = index - pinned;
    if (rows == null || at >= rows.listing.modelLength) return null;
    return treeRow(at, rows.listing.modelEntryAt(at));
  }

  /// The walk's row at [index], its page read first when it is not loaded.
  /// Null when the rows were replaced meanwhile.
  Future<TreeWalkRow?> rowAtAsync(int index) async {
    final held = rowAt(index);
    if (held != null) return held;
    final listing = _rows?.listing;
    final at = index - pinnedWalked;
    if (listing == null || at < 0 || at >= listing.modelLength) return null;
    await listing.ensureRow(at);
    return identical(_rows?.listing, listing) ? rowAt(index) : null;
  }

  /// The walk index of the row at [path], from the rows loaded: the pinned
  /// copy, the tree's row, or both searched. Null when none of them is.
  int? find(String path, {bool? inPinned}) {
    final rows = _rows!;
    final pinned = pinnedWalked;
    if (inPinned != false) {
      for (var at = 0; at < pinned; at++) {
        if (rows.pinned[at].path == path) return at;
      }
    }
    if (inPinned != true) {
      final at = rows.listing.modelIndexOfLoaded(path);
      if (at != null) return pinned + at;
    }
    return null;
  }

  /// As [find], asking the index for a tree row whose page is not loaded.
  Future<int?> findAsync(String path, {bool? inPinned}) async {
    final held = find(path, inPinned: inPinned);
    if (held != null || inPinned == true) return held;
    final listing = _rows?.listing;
    if (listing == null) return null;
    final at = await listing.modelIndexOfPath(path);
    return at == null ? null : pinnedWalked + at;
  }

  /// The name of the walk's row at [index], or null while its page is not
  /// loaded.
  String? nameAt(int index) {
    final rows = _rows!;
    final pinned = pinnedWalked;
    if (index < pinned) return rows.pinned[index].name;
    return rows.listing.modelEntryAt(index - pinned).note?.name;
  }
}
