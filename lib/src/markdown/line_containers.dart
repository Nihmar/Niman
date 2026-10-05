/// Where a line stands among the containers already open — the list items
/// and quotes the state entering it carries — and which of them it stays
/// in.
///
/// What a line says on its own is `line_syntax.dart`'s; here it is read
/// against a [LineState]. This is the part `docs/dev/block-scanner-indent-
/// model.md` rewrites: every reader below measures the line's indent from
/// the margin or from an item's content column, and the remaining
/// differences from CommonMark are the ones that measure is wrong for.
library;

import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';

/// A line read against the containers open around it.
abstract final class LineContainers {
  /// The content column of the innermost item in [state] that [text] is
  /// indented into, or 0 when it reaches none: where a block on the line
  /// counts its own up-to-three spaces of indent from.
  static int contentColumn(String text, LineState state) {
    final indent = LineSyntax.indentOf(text);
    var column = 0;
    for (final item in state.listStack) {
      if (item.content > indent) break;
      column = item.content;
    }
    return column;
  }

  /// How far in a marker may stand on a line entering in [state]: three
  /// spaces past the content column of the innermost open item, or past the
  /// margin outside a list.
  static int markerReach(LineState state) =>
      (state.listIndent < 0 ? 0 : state.listIndent) + 3;

  /// Whether [text] is a thematic break, counting up to three spaces of its
  /// leading indent from the innermost item's content column (or the margin
  /// outside a list): `····---` inside an item whose content starts at two is
  /// the item's rule, not text.
  static bool isRule(String text, LineState state) {
    if (LineSyntax.isHr(text, 0)) return true;
    final column = contentColumn(text, state);
    return column > 0 && column <= text.length && LineSyntax.isHr(text, column);
  }

  /// Whether [text], entered in [state], is a line of paragraph text: an
  /// item's marker with text after it, or a line no other block takes.
  static bool isParagraphText(String text, LineState state) {
    if (text.trim().isEmpty || isRule(text, state)) return false;
    if (LineSyntax.headingLevel(text, contentColumn(text, state)) > 0) {
      return false;
    }
    final marker = LineSyntax.listMarker(text, markerReach(state));
    return marker == null || text.substring(marker.$3).trim().isNotEmpty;
  }

  /// Whether [text], entered in [state], opens a block that ends a paragraph
  /// rather than going on with it.
  static bool opensBlock(String text, LineState state) =>
      LineSyntax.listMarker(text, markerReach(state)) != null ||
      LineSyntax.headingLevel(text, contentColumn(text, state)) > 0 ||
      isRule(text, state) ||
      LineSyntax.fenceOpen(text, contentColumn(text, state)) != null;

  /// Whether [marker] on [text], entered in [state], goes on with the open
  /// paragraph lazily instead of starting an item — what the scan reads the
  /// line as, and keeps the items open by.
  ///
  /// Only a paragraph outside every item and quote is protected, and only
  /// from a marker that may not interrupt it
  /// ([LineSyntax.markerInterrupts]). Inside an item, or under a quote whose
  /// line this is not, a marker always breaks the paragraph: `1. w` /
  /// `  2) w` starts a second list, and `> w` / `2) w` starts a list
  /// outside the quote.
  static bool markerContinuesParagraph(
    (int, int, int) marker,
    String text,
    LineState state,
  ) =>
      state.openParagraph &&
      state.listStack.isEmpty &&
      state.quoteDepth == 0 &&
      !LineSyntax.markerInterrupts(marker, text);

  /// Whether [text] starts four spaces or more in from the innermost item's
  /// content column (the margin at top level), blank lines aside: the
  /// indented code a quote has no room left for.
  static bool isIndented(String text, LineState state) =>
      text.trim().isNotEmpty &&
      LineSyntax.indentOf(text) >= contentColumn(text, state) + 4;

  /// The quote depth after [text], keeping a lazily continued paragraph in
  /// its quote.
  ///
  /// Only paragraph text is lazy: a line that opens a block of its own — an
  /// item's marker, a heading, a rule, a fence — is outside the quote.
  static int quoteDepthAfter(String text, LineState state) {
    final own = LineSyntax.quoteDepth(text, contentColumn(text, state));
    if (own > 0) return own;
    if (state.quoteDepth > 0 &&
        text.trim().isNotEmpty &&
        !opensBlock(text, state)) {
      return state.quoteDepth;
    }
    return 0;
  }

  /// The items [text] stays inside when it is a quote line short of the
  /// innermost item's content column: a `>` marker opens a block of its own,
  /// so it never goes on with the item lazily, but it is still inside every
  /// item whose content column its indent reaches (`1. w` / `    1. w` /
  /// `    > w` is a quote in the outer item). The items it does not reach
  /// close. Null when the line is not such a quote line.
  static List<({int marker, int content})>? quoteItems(
    String text,
    LineState state,
  ) {
    if (state.listIndent < 0 ||
        LineSyntax.indentOf(text) >= state.listIndent ||
        LineSyntax.quoteDepth(text, contentColumn(text, state)) == 0) {
      return null;
    }
    final indent = LineSyntax.indentOf(text);
    var reached = 0;
    while (reached < state.listStack.length &&
        state.listStack[reached].content <= indent) {
      reached++;
    }
    return state.listStack.sublist(0, reached);
  }

  /// Whether [text] is a quote line whose indent makes it the indented
  /// continuation that the open quote has no room left for: the state
  /// entered with [LineState.quoteIndented] set and the line is indented
  /// four spaces or more past the quote's content, so it opens an indented
  /// code block outside the quote instead of going on with its paragraph.
  static bool quoteClosesToCode(String text, LineState state) =>
      state.quoteDepth > 0 && state.quoteIndented && isIndented(text, state);

  /// The state of a line in [items] and in nothing else: the shared plain
  /// state outside a list.
  static LineState inItems(List<({int marker, int content})> items) =>
      items.isEmpty ? LineState.initial : LineState(listStack: items);
}
