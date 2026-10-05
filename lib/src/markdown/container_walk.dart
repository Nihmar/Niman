/// A line walked through the containers open around it — the list items,
/// outermost first, and the quote inside them — the way `package:markdown`
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
  );

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
    if (open.isEmpty && entering.quoteDepth == 0) {
      return ContainerWalk._(open, false, raw, false, null, next, leftOver);
    }
    final blank = LineSyntax.indentOf(raw) == raw.length;
    var text = raw;
    // Columns a tab an item took off left over, which count toward the
    // next item's indent (`LineSyntax.dedent`).
    var remaining = leftOver;
    // The line after it, as each item in turn reads it.
    var after = next;
    var lazy = false;
    var kept = open.length;
    List<OpenItem>? changed;
    for (var at = 0; at < open.length; at++) {
      final item = open[at];
      if (blank) {
        // A blank line is every item's, and the last one each took.
        final blanks = item.blanks;
        if (!item.lastBlank || blanks != null) {
          (changed ??= [...open])[at] = (
            indent: item.indent,
            content: item.content,
            blanks: blanks == null ? null : blanks + 1,
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
        (text, remaining) = LineSyntax.dedent(text, item.indent);
        if (item.lastBlank) {
          (changed ??= [...open])[at] = (
            indent: item.indent,
            content: item.content,
            blanks: item.blanks,
            lastBlank: false,
          );
        }
        after = _reach(after, item.indent);
        continue;
      }
      // Short of it: a rule, a marker or a block that may interrupt ends the
      // list, and so does anything after a blank line. Anything else is the
      // item's lazily, read as it stands.
      if (item.lastBlank || _endsList(LineSyntax.expandIndent(text), after)) {
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
    if (kept == open.length && entering.quoteDepth > 0) {
      // A block's marker stands up to three spaces in; a tab is four.
      final columns = LineSyntax.expandIndent(text);
      if (LineSyntax.quoteDepth(columns) > 0) {
        quote = LineSyntax.quoteChild(text);
      } else if (_quoteTakesLazily(columns, entering.quoteLast, after)) {
        quote = text;
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
    );
  }

  /// The items the line stays in, outermost first: the ones open before it,
  /// less the ones it ends, each with the line taken into account. Not an
  /// item the line itself opens.
  final List<OpenItem> items;

  /// Whether an item open before the line ends on it: the line is read in
  /// the container around that item, with nothing open there.
  final bool closed;

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

  /// Whether [text], short of an open item's indent, ends its list: a rule,
  /// a list marker, or a block that may interrupt a paragraph — a fence, a
  /// heading, a quote, an HTML block (all but a lone tag) or a table's
  /// head.
  static bool _endsList(String text, String? next) {
    if (LineSyntax.isHr(text, 0)) return true;
    if (LineSyntax.listMarker(text) != null) return true;
    if (LineSyntax.fenceOpen(text) != null) return true;
    if (LineSyntax.headingLevel(text) > 0) return true;
    if (LineSyntax.quoteDepth(text) > 0) return true;
    if (LineSyntax.indentOf(text) <= 3) {
      final html = HtmlBlockSyntax.open(text);
      if (html != null && html.$1 != HtmlBlockKind.completeTag) return true;
    }
    // A table's head: the parser tries it on any line whose next is a
    // delimiter row, and it may end a block whether or not the head fits.
    return next != null && TableLineSyntax.isDelimiter(next);
  }

  /// Whether the open quote takes [text], a line without a `>`, lazily: the
  /// first block it could start is a paragraph and the quote's last line
  /// ([last], [LineState.quoteLast]) was neither blank nor a fence, or it
  /// is indented code and that line was not indented; [next] heading a
  /// table makes it a table's head instead.
  static bool _quoteTakesLazily(String text, int last, String? next) {
    if (LineSyntax.indentOf(text) == text.length) return false;
    // A table's head is tried first, a paragraph's line after it.
    if (next != null && TableLineSyntax.isDelimiter(next)) return false;
    if (LineSyntax.fenceOpen(text) != null) return false;
    final indent = LineSyntax.indentOf(text);
    if (indent <= 3 && HtmlBlockSyntax.open(text) != null) return false;
    if (LineSyntax.headingLevel(text) > 0) return false;
    if (indent >= 4) return last & LineState.lastIndented == 0;
    if (LineSyntax.isHr(text, 0)) return false;
    if (LineSyntax.listMarker(text) != null) return false;
    if (LineSyntax.startsLinkReference(text)) return false;
    return last & (LineState.lastBlank | LineState.lastFence) == 0;
  }

  /// The bits of [LineState.quoteLast] for [child], a line inside a quote.
  static int lastOf(String child) {
    final indent = LineSyntax.columnsOf(child);
    // Four spaces and nothing else are blank and indented both.
    if (LineSyntax.indentOf(child) == child.length) {
      return indent >= 4
          ? LineState.lastBlank | LineState.lastIndented
          : LineState.lastBlank;
    }
    var bits = 0;
    if (indent >= 4) bits |= LineState.lastIndented;
    if (LineSyntax.fenceOpen(LineSyntax.expandIndent(child)) != null) {
      bits |= LineState.lastFence;
    }
    return bits;
  }
}
