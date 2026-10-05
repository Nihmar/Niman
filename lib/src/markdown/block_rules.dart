/// What block a line starts, and whether it goes on with the block the scan
/// has open: the block-level half of the scan's rules, over what
/// `line_rules.dart` says each line is.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/line_containers.dart';
import 'package:niman/src/markdown/line_rules.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';

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
    final kind = _lines.kindOf(line);
    final text = _lines.lineText(line);
    // The depth *on* the line, not the one entering it: a quote's first line
    // has no depth before its own `>`, so taking the entering state left
    // every quote block at depth 0 — which made the renderer draw it as an
    // unnested quote and the parser read the `>` as text.
    final entering = _lines.entering(line);
    // A line that ends an item's fence (opens a block short of the content
    // column) is not in the item: the state it enters carries the item the
    // fence was in, but the fence closes it here, so depth and items start
    // from nothing (`* w` / `  ``` ` / `* w` / `  * w` has the second item at
    // 0 and its sublist at 1, not both at 0).
    final base = _lines.fenceClosesItem(line, text, entering)
        ? LineState.initial
        : entering;
    final quoteDepth = LineContainers.quoteClosesToCode(text, base)
        ? 0
        : LineContainers.quoteDepthAfter(text, base);
    // The depth *on* the line, like the quote's: the state entering a marker
    // line describes the item before it, so a block that took its depth from
    // there was drawn at the previous item's indent — siblings at different
    // indents, the item after a sublist pushed right (device report,
    // 2026-09-21).
    final quoteItems = LineContainers.quoteItems(text, base);
    final listStack = quoteItems ?? _lines.listAfter(line, text, base);
    final listDepth = listStack.isEmpty ? -1 : listStack.length - 1;
    return Block(
      kind: kind,
      startLine: line,
      endLine: line + 1,
      quoteDepth: quoteDepth,
      listDepth: listDepth,
      // An ordered list counts from its first item on, wherever the list
      // starts; a list written `1. 1. 1.` renders 1, 2, 3, which is CommonMark
      // and what the preview draws. The count lives here because this is where
      // the *list* is still visible: a block knows only its own item.
      listOrdinal: kind == BlockKind.listItem
          ? ordinalOf(line, listDepth, quoteDepth, previous)
          : 0,
      // An ATX heading's: a setext one starts as its paragraph, and is
      // made a heading when its underline goes on with it. Read past the
      // indent the kind was already decided with: a heading in an item
      // stands up to three spaces past the item's content, more than three
      // from the margin.
      headingLevel: kind == BlockKind.heading
          ? LineSyntax.headingMarkerOf(text)?.$2 ?? 0
          : 0,
      fenceInfo: kind == BlockKind.fencedCode ? _fenceInfo(line) : null,
      entering: _lines.entering(line),
    );
  }

  /// Whether line [end] belongs to [open], the block the scan has open.
  bool mergesInto(Block open, int end) {
    switch (open.kind) {
      case BlockKind.heading:
        // An ATX heading is its own line, and a setext one ends with its
        // underline: nothing goes on with either.
        return false;
      case BlockKind.paragraph:
        // A setext underline goes on with the paragraph it heads
        // ([underlineLevel]), which the builder then makes a heading.
        return _lines.kindOf(end) == BlockKind.paragraph ||
            underlineLevel(open, end) > 0;
      case BlockKind.thematicBreak:
        return false;
      case BlockKind.listItem:
        // The item's block is its first paragraph: paragraph text goes on
        // with it, indented into the item or lazily, which keeps a wrapped
        // item whole. A setext underline under it heads the item's text, as
        // it does a paragraph's. A line that opens a block of its own — a
        // marker, a heading, a rule, a fence, a quote — does not: taking any
        // line without a marker swallowed `# Heading` under a list into the
        // item's text.
        return _lines.kindOf(end) == BlockKind.paragraph ||
            underlineLevel(open, end) > 0;
      case BlockKind.quote:
        // A blank line ends the quoted run; a line that is still a quote line —
        // with a marker or lazily without one — continues it. A quote short
        // of the open item's content column is a quote of its own, outside:
        // it closes the item, so it does not go on with this block.
        return _lines.kindOf(end) == BlockKind.quote &&
            LineContainers.quoteItems(
                  _lines.lineText(end),
                  _lines.entering(end),
                ) ==
                null;
      case BlockKind.fencedCode:
      case BlockKind.indentedCode:
      case BlockKind.frontmatter:
      case BlockKind.html:
      case BlockKind.table:
      case BlockKind.blank:
        return _lines.kindOf(end) == open.kind;
      case BlockKind.math:
        // A display block runs while it is open, and the state entering the
        // line is the only thing that knows: the line that *closes* a block
        // starts with `$$` as much as the line that opens one does. Asking
        // the line instead of the state stitched two neighbouring formulas
        // into one block whose tex was both of them (#252).
        return _lines.entering(end).math;
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
  /// And the underline has to stand in the paragraph's own container,
  /// because a paragraph continues lazily and an underline never does: in
  /// a quote it would need its own `>` (and then the quote's reading heads
  /// it), in a list item it has to be indented into the item.
  int underlineLevel(Block paragraph, int line) {
    final state = _lines.entering(line);
    if (state.quoteDepth != 0 || state.listDepth != paragraph.listDepth) {
      return 0;
    }
    final text = _lines.lineText(line);
    // In an item, the underline's up to three spaces are counted from the
    // item's content column, which it has to reach.
    final column = state.listIndent < 0 ? 0 : state.listIndent;
    for (var at = 0; at < column; at++) {
      if (at >= text.length || !LineSyntax.isSpace(text.codeUnitAt(at))) {
        return 0;
      }
    }
    return LineSyntax.setextLevel(text, column);
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

  /// The fence's info string: the first word after the fence run, which is the
  /// language a highlighter wants.
  String? _fenceInfo(int line) {
    final text = _lines.lineText(line);
    final fence = LineSyntax.fenceOpen(
      text,
      LineContainers.contentColumn(text, _lines.entering(line)),
    );
    if (fence == null) return null;
    final rest = text.substring(fence.indent + fence.length).trim();
    return rest.isEmpty ? null : rest.split(RegExp(r'\s+')).first;
  }
}
