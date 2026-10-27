import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/ocr/ocr_tree_order.dart';
import 'package:niman/src/ui/tree_listing.dart';

/// What was last read of one folder while walking a range: its page number,
/// the rows as the index has them and as the tree draws them.
typedef _Read = ({int page, List<Note> plain, List<(Note, bool)> drawn});

/// The paths of a range of the tree's rows (#1200), for `Shift`+click and
/// `Shift`+arrows to mark.
///
/// A range can be longer than the pages held, so the rows of a page not held
/// are read and let go of as the walk moves on, one page of each folder at a
/// time and the next by keyset from the last, instead of being kept in the
/// tree's pages, which hold the screen's alone.
final class TreeRangeReader {
  /// Reads ranges of [listing]'s rows.
  const new(this.listing);

  /// The rows read.
  final TreeListing listing;

  /// The paths of the rows from model index [first] to [last], both included,
  /// when every one is held; null when a page is missing. Reads nothing.
  List<String>? heldPaths(int first, int last) {
    final paths = <String>[];
    for (var index = first; index <= last; index++) {
      final note = listing.modelEntryAt(index).note;
      if (note == null) return null;
      paths.add(note.path);
    }
    return paths;
  }

  /// The paths of the rows from model index [first] to [last], both
  /// included, reading the pages that are not held.
  Future<List<String>> paths(int first, int last) async {
    final size = listing.pages.pageSize;
    final model = listing.model;
    final paths = <String>[];
    final reading = <int, _Read>{};
    for (var index = first; index <= last; index++) {
      final slot = model.slotAt(index);
      final page = slot.position ~/ size;
      var read = reading[slot.parent];
      if (read == null || read.page != page) {
        read = await _read(slot.parent, page, read);
        reading[slot.parent] = read;
      }
      final at = slot.position % size;
      if (at < read.drawn.length) paths.add(read.drawn[at].$1.path);
    }
    return paths;
  }

  Future<_Read> _read(int parent, int page, _Read? previous) async {
    final held = listing.nestedRows(parent, page);
    if (held != null) {
      return (
        page: page,
        plain: listing.pages.pageRows(parent, page) ?? const <Note>[],
        drawn: held,
      );
    }
    final size = listing.pages.pageSize;
    final session = listing.session;
    final List<Note> plain;
    if (previous != null &&
        previous.page == page - 1 &&
        previous.plain.isNotEmpty) {
      // The next page of the same folder: from the last row of this one.
      plain = await session.childrenPage(
        parent,
        limit: size,
        sort: listing.sort,
        after: previous.plain.last,
      );
    } else {
      plain = await session.childrenAt(
        parent,
        offset: page * size,
        limit: size,
        sort: listing.sort,
      );
    }
    return (
      page: page,
      plain: plain,
      drawn: nestOcrSidecars(plain, (note) => note.name),
    );
  }
}
