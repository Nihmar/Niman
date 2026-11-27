import 'package:niman/src/editor/list_row.dart';

/// How the list items among `rows` nest, read the way CommonMark does: an
/// item is inside the nearest item above it whose content column it reaches,
/// and a sibling of whatever it sits next to on the way out.
///
/// One pass over the rows, which are the contiguous list block around the
/// caret and nothing more — or the part of it above some line: what the tree
/// says about an item depends only on the rows above it, but for its next
/// sibling, which [closed] says whether the rows hold the answer to.
final class ListTree {
  /// Reads the structure of `rows`.
  new(this._rows)
    : parent = List<int>.filled(_rows.length, -1),
      previous = List<int>.filled(_rows.length, -1),
      next = List<int>.filled(_rows.length, -1),
      sublistEnd = List<int>.filled(_rows.length, -1),
      closed = List<bool>.filled(_rows.length, false) {
    final rows = _rows;
    final open = <int>[];
    final children = List<int>.filled(rows.length, -1);
    void closeAll() {
      for (final at in open) {
        closed[at] = true;
      }
      open.clear();
    }

    for (var at = 0; at < rows.length; at++) {
      final row = rows[at];
      if (open.isNotEmpty && rows[open.first].depth != row.depth) closeAll();
      if (row.blank) continue;
      if (row.head == null) {
        // A line at the margin is not part of any item above it.
        if (row.indent == 0) closeAll();
        continue;
      }
      var left = -1;
      while (open.isNotEmpty && rows[open.last].contentColumn > row.indent) {
        left = open.removeLast();
        closed[left] = true;
      }
      parent[at] = open.isEmpty ? -1 : open.last;
      previous[at] = left;
      if (left >= 0) {
        next[left] = at;
        sublistEnd[at] = children[left];
      }
      if (parent[at] >= 0) children[parent[at]] = at;
      open.add(at);
    }
  }

  final List<ListRow> _rows;

  /// For each row, the item it is inside, or -1.
  final List<int> parent;

  /// For each row, the item before it at its level, or -1.
  final List<int> previous;

  /// For each row, the item after it at its level, or -1.
  ///
  /// -1 is the answer for an item with no next sibling *in the rows*: the
  /// item is [closed] when that is the whole truth, and still open — more
  /// rows below could hold one — when it is not.
  final List<int> next;

  /// For each item, the last item of its previous sibling's own children at
  /// the moment it came (the sublist it would join), or -1.
  final List<int> sublistEnd;

  /// For each row, whether a row below it ended the item (or the list): then
  /// [next] is final. An item that is not closed was still open at the last
  /// row, and a sibling may be below it.
  final List<bool> closed;

  /// The siblings after the item [at] that count on from its number one by
  /// one with the same delimiter — `at` is 3, then 4, 5 — in order, up to
  /// the first that does not. A list numbered any other way is left as
  /// written.
  ///
  /// `open` is true when the run ran out of rows while it still held and the
  /// rows do not say where it ends: a sibling below them may count on too.
  ({List<int> run, bool open}) countingAfter(int at) {
    final head = _rows[at].head!;
    final number = head.number;
    if (number == null) return (run: const <int>[], open: false);
    final run = <int>[];
    var last = at;
    var expected = number;
    for (var sibling = next[at]; sibling >= 0; sibling = next[sibling]) {
      final row = _rows[sibling];
      expected += 1;
      if (row.head!.number != expected ||
          row.delimiter != _rows[at].delimiter) {
        return (run: run, open: false);
      }
      run.add(sibling);
      last = sibling;
    }
    return (run: run, open: !closed[last]);
  }
}
