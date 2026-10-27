import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/tree_listing.dart';

/// The first row of the tree, in the order it is drawn, whose name starts
/// with what has been typed (#1200).
///
/// It is asked of the index, not walked through the rows: the list is cut
/// into runs, the children of one folder that follow one another with
/// nothing opened between them, and each run is one question to the index —
/// the first child of the folder after the run's start whose folded name
/// starts with the prefix. The answer is the run's if it lies within it; else
/// the search goes on after the expanded folder that ends the run, into its
/// rows. A tree with a handful of open folders is a handful of questions
/// however many rows it has.
///
/// A text recognition sidecar is drawn under its file but sorts by its name:
/// the index answers in the order of the names, so a sidecar can be found
/// before the file it is drawn under.
final class TreeNameSearch {
  /// Searches the rows of [listing].
  const new(this.listing);

  /// The rows searched.
  final TreeListing listing;

  /// The first note, at a model index from [start] up to but not including
  /// [end], whose name starts with [foldedPrefix] (see `foldName`); null when
  /// none does.
  Future<Note?> firstIn(String foldedPrefix, int start, int end) async {
    final model = listing.model;
    var index = start;
    while (index < end) {
      final slot = model.slotAt(index);
      final last = model.runEnd(slot.parent, slot.position)!;
      Note? before;
      if (slot.position > 0) {
        before = await listing.plainNoteAt(slot.parent, slot.position - 1);
        // Without the row before the run there is no telling where the
        // answer lies in it.
        if (before == null) return null;
      }
      final found = await listing.session.firstChildStartingWith(
        slot.parent,
        foldedPrefix,
        sort: listing.sort,
        after: before,
      );
      if (found != null) {
        final rank = await listing.session.rankOf(found, sort: listing.sort);
        if (rank <= last) {
          // The first match of the folder after the run's start is the first
          // of the run if it lies in it; before [end] or not at all, since
          // every row before it has been looked at.
          final at = model.indexOf(slot.parent, rank);
          return at != null && at < end ? found : null;
        }
      }
      // The run has none: on to the rows after its last, which are the ones
      // the expanded folder that ends it opens.
      index = model.indexOf(slot.parent, last)! + 1;
    }
    return null;
  }
}
