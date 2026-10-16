/// One top-level block of a note: what it is, and which lines it covers.
///
/// A block is the unit the surface lays out and the unit the parse is cached
/// by (`docs/records/unified-surface.md` §8.5). It is deliberately *flat*: a
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

  /// One fence line of a fenced div (#729): what it does is the block's
  /// [Block.divRole].
  div,
}

/// What a fence line of a fenced div does ([BlockKind.div]).
enum DivRole {
  /// Opens a `columns` div.
  opensColumns,

  /// Opens a `column` div, directly inside a `columns` one.
  opensColumn,

  /// Opens another div inside a `columns` one: tracked for its closer, and
  /// drawn as text where it stands.
  opensOther,

  /// Closes a `columns` div.
  closesColumns,

  /// Closes a `column` div.
  closesColumn,

  /// Closes another div: text, as its opener is.
  closesOther;

  /// Whether the line opens a div.
  bool get opens =>
      this == opensColumns || this == opensColumn || this == opensOther;

  /// Whether the div is one Niman lays out: `columns` or `column`.
  bool get laysOut => this != opensOther && this != closesOther;
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
    this.footnote = 0,
    this.definition = 0,
    this.reach = 0,
    this.divRole,
    this.divDepth = 0,
    this.holdsFence = false,
  });

  /// [definition] for a link reference definition's block.
  static const int opensDefinition = 2;

  /// [footnote] for a block inside a footnote definition.
  static const int inFootnote = 1;

  /// [footnote] for the block a footnote definition's line starts: its
  /// first line holds the definition's label.
  static const int opensFootnote = 2;

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
  /// Null for a `Block` built by hand.
  final LineState? entering;

  /// Whether it stands in a footnote definition — [inFootnote], or
  /// [opensFootnote] when its first line opens the definition — or 0.
  final int footnote;

  /// [opensDefinition] when the block is a link reference definition, or 0.
  /// The read view draws nothing of it: the parser files it with the note's
  /// links.
  final int definition;

  /// How many lines, from its first, reading whether the block opens a
  /// link reference definition looked at — it may have, whether or not it
  /// does — or 0: an edit on one of them may change what the first line is,
  /// and a rescan reads the block again from its start.
  final int reach;

  /// What the block's fence line does, when [kind] is [BlockKind.div].
  final DivRole? divRole;

  /// How many fenced divs the block stands in: for a fence line, the ones
  /// around the div it opens or closes.
  final int divDepth;

  /// Whether a line of this quote block opens a fenced div (`:::`) behind
  /// its `>` (#1048): only such a quote can hold a `columns` block, so a
  /// reader after those (`BlockList.fenceQuoteBlocks`) walks them alone.
  ///
  /// Never false for a quote that has such a line, and not part of
  /// [sameShape]: a block cut or kept whole by a rescan keeps it though the
  /// line that held it may have gone, and the reader looks at the text.
  final bool holdsFence;

  /// The same block, marked as holding a fenced div's opener.
  Block withFence() => Block(
    kind: kind,
    startLine: startLine,
    endLine: endLine,
    quoteDepth: quoteDepth,
    listDepth: listDepth,
    listOrdinal: listOrdinal,
    headingLevel: headingLevel,
    fenceInfo: fenceInfo,
    entering: entering,
    footnote: footnote,
    definition: definition,
    reach: reach,
    divRole: divRole,
    divDepth: divDepth,
    holdsFence: true,
  );

  /// How many lines it covers.
  int get lineCount => endLine - startLine;

  /// Whether [line] is inside the block.
  bool contains(int line) => line >= startLine && line < endLine;

  /// Whether [other] is the same block as this one wherever either of them
  /// starts and ends: its kind and everything read off its first line.
  bool sameShape(Block other) =>
      kind == other.kind &&
      quoteDepth == other.quoteDepth &&
      listDepth == other.listDepth &&
      listOrdinal == other.listOrdinal &&
      headingLevel == other.headingLevel &&
      fenceInfo == other.fenceInfo &&
      footnote == other.footnote &&
      definition == other.definition &&
      reach == other.reach &&
      divRole == other.divRole &&
      divDepth == other.divDepth;

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
      footnote: footnote,
      definition: definition,
      reach: reach,
      divRole: divRole,
      divDepth: divDepth,
      holdsFence: holdsFence,
    );
  }

  /// The block as it was before [end]: the run it covered up to a line
  /// inside it, which is what an edit leaves of the block it landed in.
  Block cutAt(int end) => Block(
    kind: kind,
    startLine: startLine,
    endLine: end,
    quoteDepth: quoteDepth,
    listDepth: listDepth,
    listOrdinal: listOrdinal,
    headingLevel: headingLevel,
    fenceInfo: fenceInfo,
    entering: entering,
    footnote: footnote,
    definition: definition,
    reach: reach,
    divRole: divRole,
    divDepth: divDepth,
    holdsFence: holdsFence,
  );

  /// The block from [start] on, to [end]: what is left of a block a scan
  /// stopped inside. Without its entering state, which was its first line's,
  /// nor the footnote label its first line held.
  Block cutFrom(int start, int end) => Block(
    kind: kind,
    startLine: start,
    endLine: end,
    quoteDepth: quoteDepth,
    listDepth: listDepth,
    listOrdinal: listOrdinal,
    headingLevel: headingLevel,
    fenceInfo: fenceInfo,
    footnote: footnote == opensFootnote && start != startLine
        ? inFootnote
        : footnote,
    divRole: divRole,
    divDepth: divDepth,
    holdsFence: holdsFence,
  );

  /// The block, a paragraph or an item's first one, as the setext heading
  /// of [level] its underline makes it. An item stays an item, its text
  /// headed: the parse reads its block as the item, marker and all, and a
  /// heading block that held a marker was given to it as text — four spaces
  /// of a sublist's marker were indented code.
  Block headed(int level) => kind == BlockKind.listItem
      ? Block(
          kind: kind,
          startLine: startLine,
          endLine: endLine,
          quoteDepth: quoteDepth,
          listDepth: listDepth,
          listOrdinal: listOrdinal,
          headingLevel: level,
          entering: entering,
          footnote: footnote,
          divDepth: divDepth,
          holdsFence: holdsFence,
        )
      : Block(
          kind: BlockKind.heading,
          startLine: startLine,
          endLine: endLine,
          quoteDepth: quoteDepth,
          listDepth: listDepth,
          headingLevel: level,
          entering: entering,
          footnote: footnote,
          divDepth: divDepth,
          holdsFence: holdsFence,
        );

  @override
  String toString() =>
      'Block(${kind.name} $startLine..$endLine'
      '${quoteDepth > 0 ? ' quote:$quoteDepth' : ''}'
      '${listDepth >= 0 ? ' list:$listDepth' : ''}'
      '${footnote > 0 ? ' footnote:$footnote' : ''}'
      '${definition > 0 ? ' definition' : ''}'
      '${divRole != null ? ' ${divRole!.name}' : ''}'
      '${divDepth > 0 ? ' div:$divDepth' : ''})';
}
