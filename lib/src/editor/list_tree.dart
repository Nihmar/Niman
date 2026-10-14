import 'package:niman/src/editor/list_row.dart';

/// How the list items among `rows` nest, read the way CommonMark does: an
/// item is inside the nearest item above it whose content column it reaches,
/// and a sibling of whatever it sits next to on the way out.
///
/// One pass over the rows, which are the contiguous list block around the
/// caret and nothing more.
final class ListTree {
  /// Reads the structure of `rows`.
  new(List<ListRow> rows)
    : parent = List<int>.filled(rows.length, -1),
      previous = List<int>.filled(rows.length, -1),
      next = List<int>.filled(rows.length, -1),
      sublistEnd = List<int>.filled(rows.length, -1) {
    final open = <int>[];
    final children = List<int>.filled(rows.length, -1);
    for (var at = 0; at < rows.length; at++) {
      final row = rows[at];
      if (open.isNotEmpty && rows[open.first].depth != row.depth) open.clear();
      if (row.blank) continue;
      if (row.head == null) {
        // A line at the margin is not part of any item above it.
        if (row.indent == 0) open.clear();
        continue;
      }
      var left = -1;
      while (open.isNotEmpty && rows[open.last].contentColumn > row.indent) {
        left = open.removeLast();
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

  /// For each row, the item it is inside, or -1.
  final List<int> parent;

  /// For each row, the item before it at its level, or -1.
  final List<int> previous;

  /// For each row, the item after it at its level, or -1.
  final List<int> next;

  /// For each item, the last item of its previous sibling's own children at
  /// the moment it came (the sublist it would join), or -1.
  final List<int> sublistEnd;
}
