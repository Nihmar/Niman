import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/tree_create_row.dart';
import 'package:niman/src/ui/tree_listing.dart';
import 'package:niman/src/ui/tree_walk.dart';

/// Where the row being made goes in the tree's listing (#712): one under
/// its folder's row, or at the top of the tree for the root.
final class TreeCreatePlacement {
  /// Places the row [creating] says is being made in the listings of
  /// [walk], redrawing through [update] when a place the index was asked
  /// for lands; nothing lands once [mounted] says the tree is gone.
  new({
    required this.walk,
    required this.creating,
    required this.mounted,
    required this.update,
  });

  /// The rows of the last build, whose listing a late answer must still be.
  final TreeWalk walk;

  /// The row being made as the tree has it now, or null.
  final TreeCreate? Function() creating;

  /// Whether the tree is still on screen.
  final bool Function() mounted;

  /// Makes a change and draws the tree again: the tree's `setState`.
  final void Function(VoidCallback change) update;

  /// The listing and the folder the row being made is being placed for, so
  /// that one lookup is asked for each.
  TreeListing? _placingListing;
  String? _placingFolder;

  /// Puts the row being made in [listing], one under its folder's row. The
  /// folder is usually on screen, its row in a loaded page; when it is not,
  /// its place is asked of the index and the row shows when it answers.
  void place(TreeListing listing) {
    final creating = this.creating();
    if (creating == null || creating.folder.isEmpty) {
      // At the root the row being made tops the tree, outside the list.
      listing.placeCreating(null);
      return;
    }
    final folder = creating.folder;
    void place(int at) => listing.placeCreating(
      at,
      // One in from the folder's row.
      depth: listing.model.slotAt(at).depth + 1,
    );
    final held = listing.modelIndexOfLoaded(folder);
    if (held != null) {
      place(held);
      return;
    }
    listing.placeCreating(null);
    if (listing.isFrozen ||
        (identical(_placingListing, listing) && _placingFolder == folder)) {
      return;
    }
    _placingListing = listing;
    _placingFolder = folder;
    unawaited(
      listing.modelIndexOfPath(folder).then((at) {
        if (at == null ||
            !mounted() ||
            !identical(walk.rows?.listing, listing) ||
            this.creating()?.folder != folder) {
          return;
        }
        update(() => place(at));
      }),
    );
  }
}
