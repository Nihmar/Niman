/// What the block scan makes of one line: what it is, the state it leaves,
/// the block it starts, and whether it goes on with the block before it.
///
/// A function of the line's text, the lines next to it and the state it
/// enters in — `docs/records/unified-surface.md` §8.5 — so a scan can stop
/// where the states agree. The states are the scanner's: it records them,
/// and these rules read them.
library;

import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/html_block_syntax.dart';
import 'package:niman/src/markdown/line_containers.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The rules the block scan applies to each line of [buffer].
final class LineRules {
  /// Rules over [buffer], reading the state entering each line from the
  /// scanner's own list of them, which it keeps up to date.
  new(this.buffer, this._entering);

  /// The text being scanned.
  final SourceBuffer buffer;

  /// The state entering each scanned line.
  final List<LineState> _entering;

  /// The line [kindOf] last classified, the state it entered in and the
  /// buffer's revision then; [_kind] is the answer. One line, because a
  /// scan asks about the line it is on: whether it goes on with the open
  /// block, what block it starts, and which items it leaves open all ask
  /// what it is, and classifying it afresh each time doubled the scan of a
  /// note that is one long list (`list_count_check_test`, 86 → 188 ms).
  int _kindLine = -1;
  LineState? _kindState;
  int _kindRevision = -1;
  BlockKind _kind = BlockKind.blank;

  /// The line's text, without a byte-order mark on the first line.
  String lineText(int line) {
    final text = buffer.lineAt(line);
    if (line == 0 && text.startsWith('\uFEFF')) return text.substring(1);
    return text;
  }

  /// What line [line] is: a function of the line's text, the lines next to
  /// it and the state it enters in, so the answer is kept while none of
  /// them has changed.
  BlockKind kindOf(int line) {
    final state = _entering[line];
    if (line == _kindLine &&
        identical(state, _kindState) &&
        buffer.revision == _kindRevision) {
      return _kind;
    }
    _kind = _classify(line, state);
    _kindLine = line;
    _kindState = state;
    _kindRevision = buffer.revision;
    return _kind;
  }

  /// What line [line], entered in [state], is.
  BlockKind _classify(int line, LineState state) {
    final text = lineText(line);
    if (state.fence != null) {
      // Inside a fence: every line is code until the closing fence, except a
      // line that ends the item and the fence with it ([_fenceClosesItem]) —
      // a non-blank line short of the content column that opens a new block,
      // or any such line after a blank one. Such a line is read as if no
      // fence were open.
      if (_fenceClosesItem(line, text, state)) {
        return _kindOutsideFence(line, text, state);
      }
      return BlockKind.fencedCode;
    }
    if (LineSyntax.fenceOpen(text, LineContainers.contentColumn(text, state)) !=
        null) {
      return BlockKind.fencedCode;
    }
    if (state.math || _isDisplayLineAt(line, text, state)) {
      return BlockKind.math;
    }
    if (state.frontmatter || LineSyntax.opensFrontmatter(line, text)) {
      return BlockKind.frontmatter;
    }
    if (state.html != null &&
        !(text.trim().isEmpty &&
            (state.html == HtmlBlockKind.blockTag ||
                state.html == HtmlBlockKind.completeTag))) {
      return BlockKind.html;
    }
    if (HtmlBlockSyntax.open(text) != null) return BlockKind.html;
    if (text.trim().isEmpty) return BlockKind.blank;
    if (_isTableRow(line)) return BlockKind.table;
    // Not a setext heading, which no line is on its own: it is a paragraph
    // whose underline goes on with it ([underlineLevel]).
    if (LineContainers.isRule(text, state)) return BlockKind.thematicBreak;
    if (LineSyntax.headingLevel(
          text,
          LineContainers.contentColumn(text, state),
        ) >
        0) {
      return BlockKind.heading;
    }
    // Code while it is four spaces in: a line less than that ends the block.
    if (_indentedCodeContinues(line, text, state)) {
      return BlockKind.indentedCode;
    }
    // A second indented line under a quote leaves it for code ([LineState.
    // quoteIndented]): the quote has already taken its one continuation.
    if (LineContainers.quoteClosesToCode(text, state)) {
      return BlockKind.indentedCode;
    }
    // Containers, innermost first: a line with its own quote marker is a quote
    // line, a line with a list marker starts an item, and a line with neither
    // either continues the item it is indented into or the quote it is lazily
    // part of.
    if (LineSyntax.quoteDepth(text, LineContainers.contentColumn(text, state)) >
        0) {
      return BlockKind.quote;
    }
    final marker = LineSyntax.listMarker(
      text,
      LineContainers.markerReach(state),
    );
    if (marker != null) {
      // An ordered list not starting at 1, or an empty item, under an open
      // paragraph goes on with it lazily: not a new item.
      return LineContainers.markerContinuesParagraph(marker, text, state)
          ? BlockKind.paragraph
          : BlockKind.listItem;
    }
    if (text.trim().isNotEmpty && state.listIndent >= 0) {
      return BlockKind.paragraph;
    }
    if (text.trim().isNotEmpty && state.quoteDepth > 0) return BlockKind.quote;
    return BlockKind.paragraph;
  }

  /// Classifies [line] as if no fence were open: the checks that decide
  /// whether the line opens a block of its own, without the fence guard.
  /// Used by [kindOf] to detect a line that closes an item's fence.
  BlockKind _kindOutsideFence(int line, String text, LineState state) {
    if (text.trim().isEmpty) return BlockKind.blank;
    if (LineContainers.isRule(text, state)) return BlockKind.thematicBreak;
    if (LineSyntax.headingLevel(
          text,
          LineContainers.contentColumn(text, state),
        ) >
        0) {
      return BlockKind.heading;
    }
    if (LineSyntax.quoteDepth(text, LineContainers.contentColumn(text, state)) >
        0) {
      return BlockKind.quote;
    }
    final marker = LineSyntax.listMarker(
      text,
      LineContainers.markerReach(state),
    );
    if (marker != null) return BlockKind.listItem;
    if (_indentedCodeContinues(line, text, state)) {
      return BlockKind.indentedCode;
    }
    return BlockKind.paragraph;
  }

  /// Whether [text] ends the item a running fence is in: a non-blank line
  /// short of the innermost item's content column that opens a new block,
  /// or any such line after a blank one. [kindOf] decides the
  /// same thing for the line's kind; this is what [blockStarting] and
  /// [exitOf] ask to drop the item with the fence.
  bool _fenceClosesItem(int line, String text, LineState state) {
    if (state.fence == null ||
        state.listIndent < 0 ||
        text.trim().isEmpty ||
        LineSyntax.indentOf(text) >= state.listIndent) {
      return false;
    }
    final outside = _kindOutsideFence(line, text, state);
    if (outside != BlockKind.paragraph && outside != BlockKind.blank) {
      return true;
    }
    return line > 0 && lineText(line - 1).trim().isEmpty;
  }

  /// Whether [line] is display math — either form — rather than code.
  ///
  /// Two rules, both of them the preview's rather than the scanner's own:
  ///
  /// * **The shared rule says what a display line is** (`math_rule.dart`):
  ///   a `$$…$$` that opens and closes on one line is a display block too.
  ///   Keeping a private copy here is what made `$$x$$` a paragraph in the
  ///   read view and a centered block in the preview (#252).
  /// * **An indented `$$` line is code.** The preview's parser runs its
  ///   indented-code syntax before the math one, so a `$$` line indented four
  ///   spaces never opens a formula; display math is otherwise indent-blind.
  bool _isDisplayLineAt(int line, String text, LineState state) =>
      !_indentedCodeContinues(line, text, state) && isDisplayLine(text.trim());

  /// The state after line [line], given the state entering it.
  LineState exitOf(int line) => _exitOfFrom(line, _entering[line]);

  /// The state after [line], entered in [state]. When a fence it is in ends
  /// the item on this line, the caller passes [LineState.initial] so the line
  /// opens (or is) what it reads as outside the item, not nothing.
  LineState _exitOfFrom(int line, LineState state) {
    final text = lineText(line);
    // A fence, a formula or an HTML block in a list item keeps the items it
    // is in, and leaves them open when it ends: dropping them made the item
    // after a fence a list of its own, one level up.
    if (state.fence != null) {
      // A non-blank line short of the innermost item's content column that
      // opens a new block ends the item and the fence with it; after a blank
      // line, even plain text does. The line is then read as if no fence were
      // open, so the item it opens (or the text it is) is the state after it.
      if (_fenceClosesItem(line, text, state)) {
        return _exitOfFrom(line, LineState.initial);
      }
      return LineSyntax.isFenceClose(text, state.fence!, state.listIndent)
          ? LineContainers.inItems(state.listStack)
          : state;
    }
    if (state.math) {
      return LineSyntax.closesMath(text)
          ? LineContainers.inItems(state.listStack)
          : state;
    }
    if (state.frontmatter) {
      return LineSyntax.closesFrontmatter(text) ? LineState.initial : state;
    }
    if (state.html != null) {
      return HtmlBlockSyntax.closes(text, state)
          ? LineContainers.inItems(state.listStack)
          : state;
    }
    if (LineSyntax.opensFrontmatter(line, text)) {
      return const LineState(frontmatter: true);
    }
    final fence = LineSyntax.fenceOpen(
      text,
      LineContainers.contentColumn(text, state),
    );
    if (fence != null) {
      return LineState(fence: fence, listStack: _listAfter(line, text, state));
    }
    // Only the multi-line form opens a state: a `$$…$$` written on one line
    // is over on that line, and leaving the state open swallowed whatever
    // followed it.
    if (_isDisplayLineAt(line, text, state) && isDisplayOpen(text.trim())) {
      return LineState(math: true, listStack: _listAfter(line, text, state));
    }
    final html = HtmlBlockSyntax.open(text);
    if (html != null) {
      final opened = LineState(
        html: html.$1,
        htmlClosing: html.$2,
        listStack: _listAfter(line, text, state),
      );
      // A comment, a raw-text tag, a processing instruction, a declaration or
      // a CDATA section ends on the line with its end marker — which can be
      // the line it opens on. Left open, a one-line `<!-- note -->` made an
      // HTML block of everything under it until the next `-->`: 1 656 lines
      // of the worst-note fixture drawn as raw HTML, and their links unread.
      if (!HtmlBlockSyntax.closesOnItsOwnLine(text, opened)) return opened;
    }
    final quoteDepth = LineContainers.quoteClosesToCode(text, state)
        ? 0
        : LineContainers.quoteDepthAfter(text, state);
    final quoteItems = LineContainers.quoteItems(text, state);
    final listStack = quoteItems ?? _listAfter(line, text, state);
    final table = _tableContinues(line, state);
    final indentedCode =
        _indentedCodeContinues(line, text, state) ||
        LineContainers.quoteClosesToCode(text, state);
    final openParagraph =
        !table && !indentedCode && LineContainers.isParagraphText(text, state);
    // A quote takes one indented continuation of its paragraph; a second in
    // a row is not a lazy continuation any more and opens code, which closes
    // it. A line that is not indented breaks the run: the next indented line
    // is a first continuation again (`> w` / `    ---` / `w` / `    w` keeps
    // the last line in the quote).
    final quoteIndented =
        quoteDepth > 0 &&
        (LineContainers.quoteClosesToCode(text, state) ||
            LineContainers.isIndented(text, state));
    // A line that leaves the scan outside every construct is the shared
    // state, not a new object equal to it. That is the common line of a long
    // note of prose, and a state apiece was 68 MB of the shell running the
    // million-line fixture (#346: 281 MB held after that scan, 213 MB with
    // the shared state, `ProcessInfo` RSS) — a million copies of one value,
    // held for as long as the scan is. [LineState.initial] is what this would
    // build, field for field, and everything that reads a state compares it
    // by value, the scan's own convergence check included. A plain paragraph
    // line is [LineState.paragraphOpen], the second shared constant.
    if (quoteDepth == 0 && listStack.isEmpty && !table && !indentedCode) {
      return openParagraph ? LineState.paragraphOpen : LineState.initial;
    }
    // Inside a construct, a line that leaves the state as it found it — the
    // next line of an item's paragraph, of a quote, of a code block — hands
    // on the state it entered in, for the same reason: the run's lines share
    // one object. A long paragraph in an item now keeps the item open, as
    // CommonMark does, where it used to close it after its first lazy line.
    if (state.fence == null &&
        !state.math &&
        !state.frontmatter &&
        state.html == null &&
        state.quoteDepth == quoteDepth &&
        state.quoteIndented == quoteIndented &&
        identical(state.listStack, listStack) &&
        state.table == table &&
        state.indentedCode == indentedCode &&
        state.openParagraph == openParagraph) {
      return state;
    }
    return LineState(
      quoteDepth: quoteDepth,
      quoteIndented: quoteIndented,
      listStack: listStack,
      table: table,
      indentedCode: indentedCode,
      openParagraph: openParagraph,
    );
  }

  /// The open list items after line [line], whose text is [text], given
  /// those entering it.
  ///
  /// A marker opens an item: it keeps every open item whose content column it
  /// starts at or past, and closes the rest — an item written to the left of
  /// an open one's content is outside it. What survives is its parents.
  ///
  /// Any other line is in the items whose content column it reaches, and
  /// closes the rest — `  back in A` after a blank line under `  - B` is A's
  /// text, not a line outside the list. Unless it is lazy: paragraph text
  /// that goes on with the paragraph before it keeps every item open.
  List<({int marker, int content})> _listAfter(
    int line,
    String text,
    LineState state,
  ) {
    final marker = LineSyntax.listMarker(
      text,
      LineContainers.markerReach(state),
    );
    // A line the scanner reads as indented code is not a marker: four spaces
    // in from the margin with no open item reaching it is code, not an item
    // (`  2) w` / `` / `    - w` has the last line as code outside the
    // list). [kindOf] decides this first; [_listAfter] follows it.
    if (marker != null && kindOf(line) != BlockKind.indentedCode) {
      // A marker that goes on with the paragraph opens no item, and the
      // items already open stay as they are (`w` / `2) w` / `2) w` is one
      // paragraph, not a list). Left to open an item here, the state carried
      // it and the next line read as the item's.
      if (LineContainers.markerContinuesParagraph(marker, text, state)) {
        return state.listStack;
      }
      final (start, _, content) = marker;
      final open = <({int marker, int content})>[];
      for (final item in state.listStack) {
        if (item.content > start) break;
        open.add(item);
      }
      open.add((marker: start, content: content));
      return open;
    }
    if (text.trim().isEmpty) return state.listStack;
    if (state.listStack.isEmpty) return const <({int marker, int content})>[];
    final indent = LineSyntax.indentOf(text);
    if (indent >= state.listIndent) return state.listStack;
    // Paragraph text written short of the item's content column goes on with
    // the item, lazily — after a heading or a rule in the item too, where
    // the app's parser (`package:markdown`) keeps it in the item: `* w` /
    // `  # w` / `w` has the last line in the item. A blank line above it ends
    // the lazy run: `1. w` / `` / `w` has the last line outside the item.
    // Only a line that opens a block of its own closes the items it does not
    // reach otherwise.
    final afterBlank = line > 0 && lineText(line - 1).trim().isEmpty;
    if (!afterBlank && kindOf(line) == BlockKind.paragraph) {
      return state.listStack;
    }
    var reached = 0;
    while (reached < state.listStack.length &&
        state.listStack[reached].content <= indent) {
      reached++;
    }
    return reached == 0
        ? const <({int marker, int content})>[]
        : state.listStack.sublist(0, reached);
  }

  /// The block that starts on [line], one line long: the builder extends it.
  ///
  /// [previous] is the last non-blank block before it, which an ordered item
  /// counts on from.
  Block blockStarting(int line, Block? previous) {
    final kind = kindOf(line);
    final text = lineText(line);
    // The depth *on* the line, not the one entering it: a quote's first line
    // has no depth before its own `>`, so taking the entering state left
    // every quote block at depth 0 — which made the renderer draw it as an
    // unnested quote and the parser read the `>` as text.
    final entering = _entering[line];
    // A line that ends an item's fence (opens a block short of the content
    // column) is not in the item: the state it enters carries the item the
    // fence was in, but the fence closes it here, so depth and items start
    // from nothing (`* w` / `  ``` ` / `* w` / `  * w` has the second item at
    // 0 and its sublist at 1, not both at 0).
    final base = _fenceClosesItem(line, text, entering)
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
    final listStack = quoteItems ?? _listAfter(line, text, base);
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
      entering: _entering[line],
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
        return kindOf(end) == BlockKind.paragraph ||
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
        return kindOf(end) == BlockKind.paragraph ||
            underlineLevel(open, end) > 0;
      case BlockKind.quote:
        // A blank line ends the quoted run; a line that is still a quote line —
        // with a marker or lazily without one — continues it. A quote short
        // of the open item's content column is a quote of its own, outside:
        // it closes the item, so it does not go on with this block.
        return kindOf(end) == BlockKind.quote &&
            LineContainers.quoteItems(lineText(end), _entering[end]) == null;
      case BlockKind.fencedCode:
      case BlockKind.indentedCode:
      case BlockKind.frontmatter:
      case BlockKind.html:
      case BlockKind.table:
      case BlockKind.blank:
        return kindOf(end) == open.kind;
      case BlockKind.math:
        // A display block runs while it is open, and the state entering the
        // line is the only thing that knows: the line that *closes* a block
        // starts with `$$` as much as the line that opens one does. Asking
        // the line instead of the state stitched two neighbouring formulas
        // into one block whose tex was both of them (#252).
        return _entering[end].math;
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
    final state = _entering[line];
    if (state.quoteDepth != 0 || state.listDepth != paragraph.listDepth) {
      return 0;
    }
    final text = lineText(line);
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
    final written = LineSyntax.writtenOrdinal(lineText(line));
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
    final text = lineText(line);
    final fence = LineSyntax.fenceOpen(
      text,
      LineContainers.contentColumn(text, _entering[line]),
    );
    if (fence == null) return null;
    final rest = text.substring(fence.indent + fence.length).trim();
    return rest.isEmpty ? null : rest.split(RegExp(r'\s+')).first;
  }

  /// Whether [line] is inside a GFM table.
  bool _isTableRow(int line) {
    final text = lineText(line);
    if (text.trim().isEmpty) return false;
    if (_entering[line].table) return LineSyntax.hasPipe(text);
    if (line + 1 >= buffer.lineCount) return false;
    return LineSyntax.hasPipe(text) &&
        LineSyntax.isDelimiterRow(lineText(line + 1));
  }

  bool _tableContinues(int line, LineState state) {
    final text = lineText(line);
    if (text.trim().isEmpty) return false;
    if (state.table) return LineSyntax.hasPipe(text);
    if (line + 1 >= buffer.lineCount) return false;
    return LineSyntax.hasPipe(text) &&
        LineSyntax.isDelimiterRow(lineText(line + 1));
  }

  /// Whether an indented code block opens: four spaces, after a blank line.
  bool _opensIndentedCode(int line, String text) {
    final state = _entering[line];
    if (text.trim().isEmpty) return false;
    // Four spaces in from the item's content column, as the block opened:
    // absolute at top level, relative inside a list.
    final indent = text.length - text.trimLeft().length;
    if (indent < LineContainers.contentColumn(text, state) + 4) return false;
    // An indented code block cannot interrupt a paragraph: a four-space line
    // after paragraph text is the paragraph's, not code's. It may open at the
    // start of a note, or after a heading, a rule or a fence — anything that
    // is not an open paragraph.
    return !state.openParagraph;
  }

  /// Whether an indented code block runs on after [text].
  bool _indentedCodeContinues(int line, String text, LineState state) {
    if (!state.indentedCode) return _opensIndentedCode(line, text);
    if (text.trim().isEmpty) return true;
    // Four spaces in from the item's content column, as the block opened.
    return LineSyntax.indentOf(text) >=
        LineContainers.contentColumn(text, state) + 4;
  }
}
