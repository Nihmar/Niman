/// What block a line starts, and whether it goes on with the block the scan
/// has open: the block-level half of the scan's rules, over what
/// `line_rules.dart` reads each line as.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/line_rules.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/table_line_syntax.dart';

/// The blocks the scan makes of the lines [LineRules] reads.
final class BlockRules {
  /// Block rules over what [_lines] says each line is.
  new(this._lines);

  final LineRules _lines;

  /// The block that starts on [line], one line long: the builder extends it.
  ///
  /// [previous] is the last non-blank block before it, which an ordered item
  /// counts on from.
  Block blockStarting(int line, Block? previous) {
    final read = _lines.read(line);
    final kind = read.kind;
    final text = _lines.lineText(line);
    // The depths *on* the line, not the ones entering it: a quote's first
    // line has no quote before its own `>`, and the state entering a marker
    // line describes the item before it — a block that took its depth from
    // there was drawn at the previous item's indent (device report,
    // 2026-09-21).
    final listDepth = read.items.length - 1;
    return Block(
      kind: kind,
      startLine: line,
      endLine: line + 1,
      quoteDepth: read.quoteDepth,
      listDepth: listDepth,
      // An ordered list counts from its first item on, wherever the list
      // starts; a list written `1. 1. 1.` renders 1, 2, 3, which is CommonMark
      // and what the preview draws. The count lives here because this is where
      // the *list* is still visible: a block knows only its own item.
      listOrdinal: kind == BlockKind.listItem
          ? ordinalOf(line, listDepth, read.quoteDepth, previous)
          : 0,
      // An ATX heading's: a setext one starts as its paragraph, and is
      // made a heading when its underline goes on with it. Read past the
      // indent the kind was already decided with: a heading in an item
      // stands up to three spaces past the item's content, more than three
      // from the margin.
      headingLevel: kind == BlockKind.heading
          ? LineSyntax.headingMarkerOf(text)?.$2 ?? 0
          : 0,
      fenceInfo: kind == BlockKind.fencedCode ? _fenceInfo(read.text) : null,
      entering: _lines.entering(line),
    );
  }

  /// Whether line [end] belongs to [open], the block the scan has open.
  ///
  /// A block goes on only in the container it is in: a line read with what
  /// was open there before it (`LineRead.carried`) — a fence in an item ends
  /// when its list does, and the fence the next line opens is another.
  bool mergesInto(Block open, int end) {
    final read = _lines.read(end);
    final entering = _lines.entering(end);
    switch (open.kind) {
      case BlockKind.heading:
      case BlockKind.thematicBreak:
        // An ATX heading is its own line, and a setext one ends with its
        // underline: nothing goes on with either.
        return false;
      case BlockKind.listItem:
        // A lazy line of a quote its marker line opened (`- > q` / `   r`)
        // goes on in the item's block: it needs the paragraph the quote
        // holds, which a quote block begun on it would not have. A line with
        // its own `>` starts a quote block, drawn with its bar. A quote open
        // below an item's block is one the marker line opened — a later one
        // has a block of its own, the open one.
        if (read.walk.quote != null) {
          return LineSyntax.quoteDepth(read.text) == 0;
        }
        return (read.kind == BlockKind.paragraph &&
                read.carried &&
                entering.openParagraph) ||
            underlineLevel(open, end) > 0;
      case BlockKind.paragraph:
        // Paragraph text goes on with the paragraph — an item's block is its
        // first one — indented into it or lazily, which keeps a wrapped item
        // whole. A setext underline goes on with the paragraph it heads
        // ([underlineLevel]), which the builder then makes a heading. A line
        // that opens a block of its own — a marker, a heading, a rule, a
        // fence, a quote — does not: taking any line without a marker
        // swallowed `# Heading` under a list into the item's text.
        return (read.kind == BlockKind.paragraph &&
                read.carried &&
                entering.openParagraph) ||
            underlineLevel(open, end) > 0;
      case BlockKind.quote:
        // The quote's line, by its `>` or lazily.
        return read.walk.quote != null;
      case BlockKind.fencedCode:
        return read.kind == BlockKind.fencedCode &&
            read.carried &&
            entering.fence != null;
      case BlockKind.indentedCode:
        return read.kind == BlockKind.indentedCode &&
            read.carried &&
            entering.indentedCode;
      case BlockKind.html:
        return read.kind == BlockKind.html &&
            read.carried &&
            entering.html != null;
      case BlockKind.table:
        return read.kind == BlockKind.table && read.carried && entering.table;
      case BlockKind.frontmatter:
        return entering.frontmatter;
      case BlockKind.blank:
        return read.kind == BlockKind.blank;
      case BlockKind.math:
        // A display block runs while it is open, and the state entering the
        // line is the only thing that knows: the line that *closes* a block
        // starts with `$$` as much as the line that opens one does. Asking
        // the line instead of the state stitched two neighbouring formulas
        // into one block whose tex was both of them (#252).
        return read.carried && entering.math;
    }
  }

  /// The level of the setext heading [line] makes of [paragraph], the
  /// paragraph the scan has open, when it is its underline — or 0.
  ///
  /// A setext heading is a paragraph and the underline under it: the whole
  /// paragraph is the heading's text, as CommonMark and the export's
  /// `SetextHeaderWithIdSyntax` read it (#361). So what the line above is
  /// is asked of the block, not of its text: a table row, a quote, a list
  /// item's marker line are no paragraph, and none of them is headed.
  ///
  /// And the underline has to stand in the paragraph's own container, read
  /// there with the paragraph still open — in a quote it is the quote's
  /// reading that heads it.
  int underlineLevel(Block paragraph, int line) {
    final read = _lines.read(line);
    if (!read.carried || !_lines.entering(line).openParagraph) return 0;
    // A table's head is tried first: a line over a delimiter row ends the
    // paragraph, whether or not it is a table.
    final next = read.walk.next;
    if (next != null && TableLineSyntax.isDelimiter(next)) return 0;
    return LineSyntax.setextLevel(read.text);
  }

  /// Where the item starting at [line] sits in its list.
  ///
  /// A continuation of the list already in progress — the previous block was an
  /// item at the same indent, and both are written as ordered items — keeps
  /// counting. Anything else starts a list, and starts it at the number the
  /// note wrote.
  int ordinalOf(int line, int listDepth, int quoteDepth, Block? previous) {
    final written = LineSyntax.writtenOrdinal(_lines.lineText(line));
    // The same list is the same depth in the same quote: an item after a
    // quote's list is a list of its own, not the quote's list counted on.
    if (previous != null &&
        previous.kind == BlockKind.listItem &&
        previous.listDepth == listDepth &&
        previous.quoteDepth == quoteDepth &&
        previous.listOrdinal > 0 &&
        written > 0) {
      return previous.listOrdinal + 1;
    }
    return written;
  }

  /// The fence's info string on [text], the line as its container reads
  /// it: the first word after the fence run, which is the language a
  /// highlighter wants.
  static String? _fenceInfo(String text) {
    final fence = LineSyntax.fenceOpen(text);
    if (fence == null) return null;
    final rest = text.substring(fence.indent + fence.length).trim();
    return rest.isEmpty ? null : rest.split(RegExp(r'\s+')).first;
  }
}
