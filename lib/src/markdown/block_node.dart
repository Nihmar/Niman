/// A note's blocks as a tree: the containers the scanner reads — quotes,
/// lists, items — with the leaves inside them, each leaf's lines mapped
/// back to the note (`docs/dev/block-tree.md`). `BlockTree` builds it.
///
/// The node kinds are one family, read by exhaustive switches, so they
/// share this file.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/block.dart';

/// Where a piece of a line stands in the note: line `line`, from column
/// `start` to `end`.
typedef SourceSpan = ({int line, int start, int end});

/// One node of the tree.
@immutable
sealed class BlockNode {
  const new();

  /// The note's line the node starts on.
  int get line;
}

/// A block quote, one level: what is inside its marks.
final class QuoteNode extends BlockNode {
  /// A quote starting on [line].
  const new({required this.line, required this.children});

  @override
  final int line;

  /// The blocks inside it.
  final List<BlockNode> children;
}

/// A list: consecutive items with the same [ItemNode.delimiter].
final class ListNode extends BlockNode {
  /// A list of [items], which the builder adds to.
  const new({required this.items});

  /// The items, in order; never empty.
  final List<ItemNode> items;

  /// Whether its items are numbered.
  bool get ordered => items.first.ordered;

  /// The number its first item counts from, 0 for a bullet list.
  int get start => items.first.ordinal;

  @override
  int get line => items.first.line;
}

/// A list item: its marker, and the blocks it holds.
final class ItemNode extends BlockNode {
  /// An item whose marker stands on [line].
  const new({
    required this.line,
    required this.marker,
    required this.delimiter,
    required this.ordinal,
    required this.children,
  });

  @override
  final int line;

  /// Where its marker stands.
  final SourceSpan marker;

  /// What keeps items one list: the bullet (`-`, `+`, `*`) or, after a
  /// number, its delimiter (`.`, `)`).
  final String delimiter;

  /// Whether the item is numbered.
  bool get ordered => delimiter == '.' || delimiter == ')';

  /// Its number as the list counts it, or 0 in a bullet list.
  final int ordinal;

  /// The blocks inside it: the scan of its content, then the blocks the note
  /// has in it after its own.
  final List<BlockNode> children;
}

/// A block with no blocks inside it.
final class LeafNode extends BlockNode {
  /// A leaf of [kind] over [lines].
  const new({
    required this.kind,
    required this.lines,
    this.headingLevel = 0,
    this.fenceInfo,
  });

  /// What it is: never a quote or an item, which are containers.
  final BlockKind kind;

  /// Its lines as its container reads them, each mapped to the note.
  final List<SourceSpan> lines;

  /// The heading level, for a heading.
  final int headingLevel;

  /// The fence's info string, for fenced code.
  final String? fenceInfo;

  @override
  int get line => lines.first.line;
}
