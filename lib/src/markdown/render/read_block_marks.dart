/// The marks of the read view that fall in one of its blocks: a book's
/// annotated paragraphs (#285), or the part of one annotated (#283).
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';

/// The marks of [marks] — by line, ascending — falling in [block].
List<BlockMark> marksIn(List<BlockMark> marks, Block block) {
  if (marks.isEmpty) return const [];
  // The first mark at or after the block's start.
  var low = 0;
  var high = marks.length;
  while (low < high) {
    final middle = (low + high) >> 1;
    if (marks[middle].line < block.startLine) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  return [
    for (var i = low; i < marks.length && marks[i].line < block.endLine; i++)
      marks[i],
  ];
}
