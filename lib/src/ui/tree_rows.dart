import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/tree_listing.dart';

/// What the tree renders: the pinned notes, then the folder tree.
final class TreeRows {
  /// The rows of one read: [pinned] above, [listing] below.
  const new({required this.pinned, required this.listing});

  /// The pinned notes, in the order the pinned block draws them.
  final List<Note> pinned;

  /// The folder tree's rows, by index (#1200).
  final TreeListing listing;

  /// Whether there is nothing to draw: no pinned note and no row.
  bool get isEmpty => pinned.isEmpty && listing.modelLength == 0;
}
