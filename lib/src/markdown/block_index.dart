/// An immutable snapshot of a note's blocks, stamped with the revision it was
/// computed from.
///
/// The scanner produces one of these per change, sharing the unchanged blocks
/// with the previous one, so the view can diff by identity instead of
/// re-deriving anything. `blockAt` is a binary search: the layout asks "which
/// block is this line in" on every scroll frame.
library;

import 'package:niman/src/markdown/block.dart';

/// The blocks of a note, in line order.
final class BlockIndex {
  /// Wraps [blocks], computed from buffer revision [revision].
  ///
  /// The defaults are the empty index, for a document that has not been
  /// scanned: no blocks, and a revision no buffer can have.
  const new({this.blocks = const <Block>[], this.revision = -1});

  /// The blocks, in line order and non-overlapping.
  final List<Block> blocks;

  /// The buffer revision the blocks were computed from.
  final int revision;

  /// How many blocks there are.
  int get length => blocks.length;

  /// Whether there are no blocks.
  bool get isEmpty => blocks.isEmpty;

  /// The block containing [line], or null when there is none.
  ///
  /// O(log blocks). The last block that starts at or before [line], which is
  /// exactly the one covering it because the blocks tile the document.
  Block? blockAt(int line) {
    var low = 0;
    var high = blocks.length - 1;
    Block? found;
    while (low <= high) {
      final middle = (low + high) >> 1;
      final block = blocks[middle];
      if (block.startLine <= line) {
        found = block;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return found;
  }

  @override
  String toString() => 'BlockIndex(${blocks.length} blocks @$revision)';
}
