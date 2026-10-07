/// A line walked through the containers open around it — a footnote
/// definition, the list items inside it, outermost first, and the quote
/// inside them — the way `package:markdown`
/// (the parser the read view draws with) hands each of them its lines.
///
/// That parser does not keep CommonMark's container stack. A list gathers
/// each item's lines and parses them again on their own, a quote likewise
/// with its `>` taken off, so every container reads the line in its own
/// coordinates: an item takes a line that stands at least its indent in,
/// with that much taken off, or — short of it — lazily, and then **as it
/// stands**. Measuring every container from the margin instead is what
/// six attempts at the old scanner could not reconcile
/// (`docs/dev/block-scanner-indent-model.md`); walking the containers in
/// order makes each measure where its parent left the line.
library;

import 'package:niman/src/markdown/footnote_syntax.dart';
import 'package:niman/src/markdown/html_block_syntax.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/table_line_syntax.dart';

/// What the containers open before a line make of it.
final class ContainerWalk {
  const new _(
    this.items,
    this.closed,
    this.text,
    this.lazy,
    this.quote,
    this.next,
    this.remaining,
    this.footnote, {
    this.quoteLazy = false,
  });

  /// [raw], entered in [entering], walked through the items and the quote
  /// open around it; [next] is the line after it, which a table's head row
  /// is told by.
  ///
  /// [leftOver] is what a tab left of the line's indent before the text
  /// being scanned began: a container's content read again — an item's,
  /// whose indent ended inside a tab — hands each line on with it, as the
  /// parser does (`BlockTree`).
  factory of(LineState entering, String raw, String? next, [int leftOver = 0]) {
    final open = entering.listStack;
    var footnote = entering.footnote;
    var line = raw;
    var below = next;
    var carried = leftOver;
    if (footnote != 0) {
      // A footnote definition holds every other container. It takes a blank
      // line, a line four columns in — those four off — and, lazily, a line
      // that goes on with its paragraph, opening no block that interrupts
      // one; after a blank line, only the indented one. Any other line ends
      // it, and everything open inside it, and is read at the margin. A
      // blank line is one only empty or four columns in: `cmark-gfm` asks
      // the line's first character, so one to three spaces alone end it.
      final blank = LineSyntax.indentOf(line) == line.length;
      if (blank && (line.isEmpty || FootnoteSyntax.indented(line))) {
        footnote = LineState.footnoteAfterBlank;
      } else if (!blank && FootnoteSyntax.indented(line)) {
        (line, carried) = FootnoteSyntax.content(line);
        footnote = LineState.footnoteOpen;
      } else if (blank ||
          footnote == LineState.footnoteAfterBlank ||
          !paragraphOpen(entering) ||
          startsBlock(LineSyntax.expandIndent(line))) {
        return ContainerWalk._(
          const <OpenItem>[],
          true,
          line,
          false,
          null,
          next,
          leftOver,
          0,
        );
      } else {
        footnote = LineState.footnoteOpen;
      }
      if (below != null && FootnoteSyntax.indented(below)) {
        below = FootnoteSyntax.content(below).$1;
      }
    }
    if (open.isEmpty && entering.quoteDepth == 0) {
      return ContainerWalk._(
        open,
        false,
        line,
        false,
        null,
        below,
        carried,
        footnote,
      );
    }
    final blank = LineSyntax.indentOf(line) == line.length;
    var text = line;
    // Columns a tab an item took off left over, which count toward the
    // next item's indent (`LineSyntax.dedent`).
    var remaining = carried;
    // The line after it, as each item in turn reads it.
    var after = below;
    var lazy = false;
    var kept = open.length;
    List<OpenItem>? changed;
    for (var at = 0; at < open.length; at++) {
      final item = open[at];
      if (blank) {
        // A blank line is every item's, and the last one each took. One
        // short of an item's indent counts against an item with no content
        // yet; one that reaches it is the item's as any line is.
        final blanks = item.blanks;
        if (!item.lastBlank || blanks != null) {
          final short = LineSyntax.columnsOf(text, remaining) < item.content;
          (changed ??= [...open])[at] = (
            indent: item.indent,
            content: item.content,
            blanks: blanks == null || !short ? blanks : blanks + 1,
            lastBlank: true,
          );
        }
        after = _reach(after, item.indent);
        continue;
      }
      if (LineSyntax.columnsOf(text, remaining) >= item.indent) {
        // At least the item's indent in: the item's, read without it — but
        // an item whose marker had no text takes one blank line at most.
        if ((item.blanks ?? 0) > 1) {
          kept = at;
          break;
        }
        (text, remaining) = LineSyntax.dedent(text, item.indent, remaining);
        // Its first content: no blank line counts against it from here.
        if (item.lastBlank || item.blanks != null) {
          (changed ??= [...open])[at] = (
            indent: item.indent,
            content: item.content,
            blanks: null,
            lastBlank: false,
          );
        }
        after = _reach(after, item.indent);
        continue;
      }
      // Short of it: the item's lazily, read as it stands, when a paragraph
      // is open at the innermost and the line opens no block — any marker
      // of a list, an empty one or one not at 1 included, `cmark`'s
      // container being the list there, not the paragraph. Anything else
      // ends the item.
      if (item.lastBlank ||
          !paragraphOpen(entering) ||
          startsBlock(LineSyntax.expandIndent(text))) {
        kept = at;
        break;
      }
      lazy = true;
      after = _reach(after, item.indent);
    }
    final items = kept < open.length
        ? (changed ?? open).sublist(0, kept)
        : changed ?? open;
    String? quote;
    var quoteLazy = false;
    if (kept == open.length && entering.quoteDepth > 0) {
      // A block's marker stands up to three spaces in; a tab is four.
      final columns = LineSyntax.expandIndent(text);
      if (LineSyntax.quoteDepth(columns) > 0) {
        quote = LineSyntax.quoteChild(text);
      } else if (_quoteTakesLazily(columns, entering.quoteLast)) {
        quote = text;
        quoteLazy = true;
      }
    }
    return ContainerWalk._(
      items,
      kept < open.length,
      text,
      lazy,
      quote,
      after,
      remaining,
      footnote,
      quoteLazy: quoteLazy,
    );
  }

  /// The items the line stays in, outermost first: the ones open before it,
  /// less the ones it ends, each with the line taken into account. Not an
  /// item the line itself opens.
  final List<OpenItem> items;

  /// Whether an item open before the line ends on it, or the footnote
  /// definition: the line is read in the container around it, with nothing
  /// open there.
  final bool closed;

  /// The footnote definition the line stays in ([LineState.footnote]), 0
  /// when none is open or the line ends it. Not one the line opens.
  final int footnote;

  /// The line as the innermost of [items] reads it: each item's indent
  /// taken off where the line reached it.
  final String text;

  /// Whether an item took the line lazily, short of its indent.
  final bool lazy;

  /// The columns of a tab the last item's indent ended inside of, left over
  /// past [text]: they count toward the indent of an item [text] opens, as
  /// they count toward an open one's.
  final int remaining;

  /// The line after it as the same items read it — each one's indent taken
  /// off where that line reaches it, as the items will take it — which is
  /// where a table's delimiter row is looked for. Not as this line was
  /// taken: an item that took this line lazily may take the next by its
  /// indent.
  final String? next;

  /// [line] as an item of [indent] reads it: the indent off a line that
  /// reaches it, the line as it stands otherwise.
  static String? _reach(String? line, int indent) {
    if (line == null) return null;
    return LineSyntax.columnsOf(line) >= indent
        ? LineSyntax.dedent(line, indent).$1
        : line;
  }

  /// What the line holds inside the open quote, when it is the quote's —
  /// by its `>` or lazily; null when no quote is open or the line leaves it.
  final String? quote;

  /// Whether the quote took the line lazily, without a `>`: a line of the
  /// paragraph open in it, whatever it looks like.
  final bool quoteLazy;

  /// Whether [text], a line short of a container it is under, opens a block
  /// of its own — and so is no lazy line of a paragraph open in the
  /// container: a quote, a heading, a fence, an HTML block of any kind, a
  /// rule, a footnote definition, or a list item, empty or not at 1 too.
  ///
  /// What `cmark` tries on such a line, where the container it reached is
  /// the one above the paragraph — so nothing is asked whether it may
  /// interrupt a paragraph. Indented code is not tried (a lazy line may be
  /// one), nor a table's head or a link reference definition, which only a
  /// paragraph's lines make.
  static bool startsBlock(String text) {
    if (LineSyntax.indentOf(text) > 3) return false;
    if (LineSyntax.quoteDepth(text) > 0) return true;
    if (LineSyntax.headingLevel(text) > 0) return true;
    if (LineSyntax.fenceOpen(text) != null) return true;
    if (HtmlBlockSyntax.open(text) != null) return true;
    if (LineSyntax.isHr(text, 0)) return true;
    if (FootnoteSyntax.opening(text) != null) return true;
    return LineSyntax.listMarker(text) != null;
  }

  /// Whether a paragraph is open at the innermost of the containers
  /// [state] enters a line in — inside its quote, when one is innermost:
  /// what a lazy line goes on with.
  static bool paragraphOpen(LineState state) => state.quoteDepth > 0
      ? _quoteParagraphOpen(state.quoteLast)
      : state.openParagraph;

  /// Whether a quote whose last line inside was [last] has a paragraph open.
  static bool _quoteParagraphOpen(int last) =>
      last &
          (LineState.lastBlank |
              LineState.lastFence |
              LineState.lastIndented |
              LineState.lastClosed) ==
      0;

  /// Whether [text] would open a block that interrupts a paragraph open in
  /// its own container — the head of a table ([next] its delimiter row,
  /// as many columns as its cells), a fence, an HTML block (all but a lone
  /// tag), a heading, a quote, a rule, a footnote definition, or a list
  /// marker that may ([LineSyntax.markerInterrupts]): where a link
  /// reference definition's lines end, they being a paragraph's.
  static bool interruptsParagraph(String text, String? next) {
    if (TableLineSyntax.heads(text, next)) return true;
    if (LineSyntax.fenceOpen(text) != null) return true;
    if (LineSyntax.indentOf(text) <= 3) {
      final html = HtmlBlockSyntax.open(text);
      if (html != null && html.$1 != HtmlBlockKind.completeTag) return true;
    }
    if (LineSyntax.headingLevel(text) > 0) return true;
    if (LineSyntax.quoteDepth(text) > 0) return true;
    if (LineSyntax.isHr(text, 0)) return true;
    if (FootnoteSyntax.opening(text) != null) return true;
    final marker = LineSyntax.listMarker(text);
    return marker != null && LineSyntax.markerInterrupts(marker, text);
  }

  /// Whether the open quote takes [text], a line without a `>`, lazily: a
  /// paragraph is open in it, by its last line ([last],
  /// [LineState.quoteLast]), and the line opens no block ([startsBlock]).
  static bool _quoteTakesLazily(String text, int last) =>
      LineSyntax.indentOf(text) < text.length &&
      _quoteParagraphOpen(last) &&
      !startsBlock(text);

  /// The bits of [LineState.quoteLast] for [child], a line inside a quote
  /// whose last line had [previous]: blank, a fence, indented code — four
  /// columns in where no paragraph is open, which a paragraph's line is
  /// not — or a block that closes at once, a heading or a rule.
  static int lastOf(String child, [int previous = LineState.lastBlank]) {
    final indent = LineSyntax.columnsOf(child);
    // Four spaces and nothing else are blank and indented both.
    if (LineSyntax.indentOf(child) == child.length) {
      return indent >= 4
          ? LineState.lastBlank | LineState.lastIndented
          : LineState.lastBlank;
    }
    final columns = LineSyntax.expandIndent(child);
    if (indent >= 4) {
      return _quoteParagraphOpen(previous) ? 0 : LineState.lastIndented;
    }
    if (LineSyntax.fenceOpen(columns) != null) return LineState.lastFence;
    if (LineSyntax.headingLevel(columns) > 0 || LineSyntax.isHr(columns, 0)) {
      return LineState.lastClosed;
    }
    return 0;
  }
}
