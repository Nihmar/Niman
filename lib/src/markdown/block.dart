/// One top-level block of a note: what it is, and which lines it covers.
///
/// A block is the unit the surface lays out and the unit the parse is cached
/// by (`docs/dev/unified-surface.md` §8.5). It is deliberately *flat*: a
/// blockquote or a list item records its depth instead of owning nested
/// blocks, because the layout and the inline phase both work a block at a time
/// and neither needs the nesting to be a tree.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/line_state.dart';

/// What a block is.
enum BlockKind {
  /// A run of non-blank lines that is not another construct.
  paragraph,

  /// An ATX heading line.
  heading,

  /// A thematic break.
  thematicBreak,

  /// A fenced code block, fence lines included.
  fencedCode,

  /// An indented code block.
  indentedCode,

  /// A `$$…$$` block.
  math,

  /// The leading frontmatter block.
  frontmatter,

  /// An HTML block.
  html,

  /// One or more lines at a blockquote level.
  quote,

  /// One list item, with its continuation lines.
  listItem,

  /// A GFM table, header and delimiter rows included.
  table,

  /// One or more blank lines, which take space and separate what is around
  /// them.
  blank,
}

/// One block: a kind, a line range, and the container depths it sits at.
@immutable
final class Block {
  /// Creates a block covering `[startLine, endLine)`.
  const new({
    required this.kind,
    required this.startLine,
    required this.endLine,
    this.quoteDepth = 0,
    this.listDepth = -1,
    this.listOrdinal = 0,
    this.headingLevel = 0,
    this.fenceInfo,
    this.entering,
  });

  /// What the block is.
  final BlockKind kind;

  /// Its first line.
  final int startLine;

  /// One past its last line.
  final int endLine;

  /// How many blockquote levels it sits in.
  final int quoteDepth;

  /// How many list levels deep the item sits (0 at the top level), or -1 when
  /// it is not a list item.
  final int listDepth;

  /// Where this item sits in its list, counting from one, for an ordered list.
  ///
  /// CommonMark ignores the numbers a note writes except the first: a list
  /// written `1. 1. 1.` renders 1, 2, 3. That makes the number a property of
  /// the *list* rather than of the item, and the item is all a block knows — so
  /// the scanner counts it while it walks, where the list is still visible.
  final int listOrdinal;

  /// The heading level, when [kind] is [BlockKind.heading].
  final int headingLevel;

  /// The fence's info string (its language), when the block is fenced code.
  final String? fenceInfo;

  /// The state entering the block's first line, when the scanner kept it.
  ///
  /// What a rebuild that starts inside the block works from: the lines before
  /// the edit are the same lines, entered in this state, so their states are
  /// recomputed rather than walked (`BlockScanner._rescanFrom`, and
  /// `docs/dev/huge-notes.md` item 3). Null for a `Block` built by hand.
  final LineState? entering;

  /// How many lines it covers.
  int get lineCount => endLine - startLine;

  /// Whether [line] is inside the block.
  bool contains(int line) => line >= startLine && line < endLine;

  /// The same block, [delta] lines further down.
  ///
  /// An edit that adds or removes lines moves every block after it, and those
  /// blocks are kept rather than rebuilt — so their line numbers have to be
  /// brought into the new coordinates before anything compares them.
  Block shifted(int delta) {
    if (delta == 0) return this;
    return Block(
      kind: kind,
      startLine: startLine + delta,
      endLine: endLine + delta,
      quoteDepth: quoteDepth,
      listDepth: listDepth,
      listOrdinal: listOrdinal,
      headingLevel: headingLevel,
      fenceInfo: fenceInfo,
      entering: entering,
    );
  }

  @override
  String toString() =>
      'Block(${kind.name} $startLine..$endLine'
      '${quoteDepth > 0 ? ' quote:$quoteDepth' : ''}'
      '${listDepth >= 0 ? ' list:$listDepth' : ''})';
}
