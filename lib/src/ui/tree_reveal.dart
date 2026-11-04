import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/tree_walk.dart';
import 'package:niman/src/ui/tree_walk_row.dart';

/// Brings the tree's rows into view: the row being renamed in place (#707),
/// once, and the keyboard's cursor as it moves (#727).
final class TreeReveal {
  /// Scrolls [scroll] to the rows of [walk]; nothing scrolls once [mounted]
  /// says the tree is gone.
  new({required this.walk, required this.scroll, required this.mounted});

  /// The rows, and where the list draws them.
  final TreeWalk walk;

  /// The tree's scroll.
  final ScrollController scroll;

  /// Whether the tree is still on screen.
  final bool Function() mounted;

  /// The row a rename has scrolled to, so it is scrolled to once.
  String? _revealed;

  /// Brings the row being renamed, at [path], into view: a row the list has
  /// not built has no field to show. The field puts itself fully in view
  /// once it is built. Null while no row is being renamed.
  void renamed(String? path) {
    if (path == _revealed) return;
    _revealed = path;
    if (path == null) return;
    unawaited(_revealPath(path));
  }

  /// Scrolls to the row at [path], wherever it is in the tree: its index is
  /// worked out from its rank, and the list builds the page it lands on.
  Future<void> _revealPath(String path) async {
    final listing = walk.rows?.listing;
    if (listing == null) return;
    final index = await listing.modelIndexOfPath(path);
    if (index == null ||
        !mounted() ||
        !scroll.hasClients ||
        _revealed != path) {
      return;
    }
    scrollTo(walk.treeTop(listing.listIndexOf(index)), walk.rowHeight);
  }

  /// Scrolls [row] into view after the frame, as the grid's walk does.
  void ensureVisible(TreeWalkRow row) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted() || !scroll.hasClients) return;
      scrollTo(row.top, row.height);
    });
  }

  /// Scrolls the item at [top], [height] tall, to the middle of the list,
  /// unless it is in view already.
  void scrollTo(double top, double height) {
    final position = scroll.position;
    if (top >= position.pixels &&
        top + height <= position.pixels + position.viewportDimension) {
      return;
    }
    scroll.jumpTo(
      (top - position.viewportDimension / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }
}
