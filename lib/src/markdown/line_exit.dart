/// The state a line leaves: what the block scan records for the line after
/// it, shared between lines wherever the state is the same.
library;

import 'package:niman/src/markdown/line_state.dart';

/// Makes the states a scanned line leaves.
abstract final class LineExit {
  /// The state after a line entered in [state]: the shared one where it can
  /// be, and [state] itself when the line leaves it as it was.
  static LineState after(
    LineState state,
    List<OpenItem> items, {
    required List<OpenDiv> divs,
    required int footnote,
    required int definition,
    required int quoteDepth,
    required int quoteLast,
    required FenceMarker? fence,
    required bool math,
    required bool frontmatter,
    required HtmlBlockKind? html,
    required String? htmlClosing,
    required bool indentedCode,
    required bool table,
    required bool openParagraph,
    required bool definitionsOnly,
    required bool tableTried,
  }) {
    // A line that leaves the scan outside every construct is the shared
    // state, not a new object equal to it. That is the common line of a long
    // note of prose, and a state apiece was 68 MB of the shell running the
    // million-line fixture (#346: 281 MB held after that scan, 213 MB with
    // the shared state, `ProcessInfo` RSS) — a million copies of one value,
    // held for as long as the scan is. A plain paragraph line is
    // [LineState.paragraphOpen], the second shared constant.
    if (items.isEmpty &&
        footnote == 0 &&
        definition == 0 &&
        quoteDepth == 0 &&
        fence == null &&
        !math &&
        !frontmatter &&
        html == null &&
        !indentedCode &&
        !table &&
        !definitionsOnly &&
        !tableTried) {
      if (divs.isEmpty) {
        return openParagraph ? LineState.paragraphOpen : LineState.initial;
      }
      // The same two in a column, one pair for each stack of divs: a long
      // column of prose allocates no state a line either.
      if (!identical(divs, _sharedDivs)) {
        _sharedDivs = divs;
        _initialIn = LineState(divs: divs);
        _paragraphIn = LineState(openParagraph: true, divs: divs);
      }
      return openParagraph ? _paragraphIn! : _initialIn!;
    }
    // Inside a construct, a line that leaves the state as it found it — the
    // next line of an item's paragraph, of a quote, of a code block — hands
    // on the state it entered in, for the same reason: the run's lines share
    // one object.
    if (identical(state.listStack, items) &&
        identical(state.divs, divs) &&
        state.footnote == footnote &&
        state.definition == definition &&
        state.quoteDepth == quoteDepth &&
        state.quoteLast == quoteLast &&
        state.fence == fence &&
        state.math == math &&
        state.frontmatter == frontmatter &&
        state.html == html &&
        state.htmlClosing == htmlClosing &&
        state.indentedCode == indentedCode &&
        state.table == table &&
        state.openParagraph == openParagraph &&
        state.definitionsOnly == definitionsOnly &&
        state.tableTried == tableTried) {
      return state;
    }
    return LineState(
      fence: fence,
      math: math,
      frontmatter: frontmatter,
      indentedCode: indentedCode,
      html: html,
      htmlClosing: htmlClosing,
      quoteDepth: quoteDepth,
      quoteLast: quoteLast,
      listStack: items,
      table: table,
      openParagraph: openParagraph,
      footnote: footnote,
      definition: definition,
      definitionsOnly: definitionsOnly,
      tableTried: tableTried,
      divs: divs,
    );
  }

  /// The divs [_initialIn] and [_paragraphIn] stand in.
  static List<OpenDiv>? _sharedDivs;

  /// [LineState.initial] inside [_sharedDivs].
  static LineState? _initialIn;

  /// [LineState.paragraphOpen] inside [_sharedDivs].
  static LineState? _paragraphIn;

  /// [state] inside the footnote definition its line opened.
  static LineState footnoted(LineState state) => LineState(
    fence: state.fence,
    math: state.math,
    frontmatter: state.frontmatter,
    indentedCode: state.indentedCode,
    html: state.html,
    htmlClosing: state.htmlClosing,
    quoteDepth: state.quoteDepth,
    quoteLast: state.quoteLast,
    listStack: state.listStack,
    table: state.table,
    openParagraph: state.openParagraph,
    footnote: LineState.footnoteOpen,
    definition: state.definition,
    definitionsOnly: state.definitionsOnly,
    tableTried: state.tableTried,
    divs: state.divs,
  );
}
