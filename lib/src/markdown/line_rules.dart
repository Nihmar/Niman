/// What the block scan makes of one line: what it is, the containers it
/// stands in, and the state it leaves.
///
/// A function of the line's text, the line after it (a table's head row is
/// told by its delimiter row) and the state it enters in —
/// `docs/records/unified-surface.md` §8.5 — so a scan can stop where the
/// states agree. The states are the scanner's: it records them, and these
/// rules read them.
///
/// A line is read in two steps. The containers open before it walk it
/// first ([ContainerWalk]): the items it stays in, whether the open quote
/// takes it, and the text the innermost item reads. What is left is read
/// in that item's coordinates, as if at a margin of its own — so no rule
/// below measures from the note's margin.
library;

import 'package:niman/src/editor/math_rule.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/container_walk.dart';
import 'package:niman/src/markdown/footnote_syntax.dart';
import 'package:niman/src/markdown/html_block_syntax.dart';
import 'package:niman/src/markdown/line_read.dart';
import 'package:niman/src/markdown/line_state.dart';
import 'package:niman/src/markdown/line_syntax.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/table_line_syntax.dart';

/// The rules the block scan applies to each line of [buffer].
final class LineRules {
  /// Rules over [buffer], reading the state entering each line from the
  /// scanner's own list of them, which it keeps up to date.
  new(this.buffer, this._entering, [this._leftOver = const <int>[]]);

  /// The text being scanned.
  final SourceBuffer buffer;

  /// The state entering each scanned line.
  final List<LineState> _entering;

  /// What a tab left over before each line, for a container's content read
  /// again ([ContainerWalk.of]); empty for a note.
  final List<int> _leftOver;

  int _leftOverAt(int line) => line < _leftOver.length ? _leftOver[line] : 0;

  /// The line [read] last read, the state it entered in and the buffer's
  /// revision then; [_last] is the read. One line, because a scan asks
  /// about the line it is on several times — whether it goes on with the
  /// open block, what block it starts, the state it leaves — and reading it
  /// afresh each time doubled the scan of a note that is one long list
  /// (`list_count_check_test`, 86 → 188 ms).
  int _lastLine = -1;
  LineState? _lastState;
  int _lastRevision = -1;
  LineRead? _last;

  /// The state entering [line], as the scanner recorded it.
  LineState entering(int line) => _entering[line];

  /// The line's text, without a byte-order mark on the first line.
  String lineText(int line) {
    final text = buffer.lineAt(line);
    if (line == 0 && text.startsWith('﻿')) return text.substring(1);
    return text;
  }

  /// What the scan makes of line [line], entered in the state recorded for
  /// it: kept while neither that state nor the buffer has changed.
  LineRead read(int line) {
    final state = _entering[line];
    final last = _last;
    if (last != null &&
        line == _lastLine &&
        identical(state, _lastState) &&
        buffer.revision == _lastRevision) {
      return last;
    }
    final read = _read(line, state);
    _last = read;
    _lastLine = line;
    _lastState = state;
    _lastRevision = buffer.revision;
    return read;
  }

  /// What line [line] is.
  BlockKind kindOf(int line) => read(line).kind;

  /// The state after line [line], given the state entering it.
  LineState exitOf(int line) => read(line).exit;

  /// Line [line], entered in [state], read.
  LineRead _read(int line, LineState state) {
    final next = line + 1 < buffer.lineCount ? lineText(line + 1) : null;
    final walk = ContainerWalk.of(
      state,
      lineText(line),
      next,
      _leftOverAt(line),
    );
    final quoted = walk.quote;
    if (quoted != null) {
      // The quote's line: what is inside the quote is the quote's content's
      // to read, scanned again on its own.
      return _made(
        BlockKind.quote,
        state,
        walk,
        carried: false,
        quoteDepth: state.quoteDepth,
        quoteLast: ContainerWalk.lastOf(quoted),
      );
    }
    // What was open in the line's container goes on only while the
    // container does: a line that ends an item, or leaves a quote, is read
    // with nothing open where it lands.
    final carried = !walk.closed && state.quoteDepth == 0;
    return _readLeaf(
      line,
      state,
      walk,
      carried ? state : LineState.initial,
      carried,
      walk.next,
    );
  }

  /// The line [walk] leaves, read in its container, where [open] holds what
  /// was open there before it — or [content], what a marker line holds
  /// after its marker, read in the item it opens, [within].
  LineRead _readLeaf(
    int line,
    LineState state,
    ContainerWalk walk,
    LineState open,
    bool carried,
    String? next, {
    String? content,
    List<OpenItem>? within,
  }) {
    // A block's marker stands up to three spaces in, and four are code: a
    // tab is four columns to the parser's patterns.
    final text = LineSyntax.expandIndent(content ?? walk.text);
    final base = within ?? walk.items;
    // A table's head: the next line is a delimiter row in the same
    // container. The parser looks for it among that container's lines only;
    // one that ends the container is no row of this line's.
    final heads =
        LineSyntax.indentOf(text) < text.length &&
        next != null &&
        TableLineSyntax.isDelimiter(next) &&
        _stays(line + 1, base, walk.footnote);
    LineRead made(
      BlockKind kind, {
      List<OpenItem>? items,
      int quoteDepth = 0,
      int quoteLast = 0,
      FenceMarker? fence,
      bool math = false,
      bool frontmatter = false,
      HtmlBlockKind? html,
      String? htmlClosing,
      bool indentedCode = false,
      bool table = false,
      bool openParagraph = false,
    }) => _made(
      kind,
      state,
      walk,
      carried: carried,
      items: items ?? base,
      quoteDepth: quoteDepth,
      quoteLast: quoteLast,
      fence: fence,
      math: math,
      frontmatter: frontmatter,
      html: html,
      htmlClosing: htmlClosing,
      indentedCode: indentedCode,
      table: table,
      openParagraph: openParagraph,
      heads: heads,
    );

    // Inside a block that runs to an end marker, every line is the block's.
    final fence = open.fence;
    if (fence != null) {
      final closes = LineSyntax.isFenceClose(text, fence, -1);
      return made(BlockKind.fencedCode, fence: closes ? null : fence);
    }
    if (open.math) {
      return made(BlockKind.math, math: !LineSyntax.closesMath(text));
    }
    if (open.frontmatter) {
      return made(
        BlockKind.frontmatter,
        frontmatter: !LineSyntax.closesFrontmatter(text),
      );
    }
    final indent = LineSyntax.indentOf(text);
    final blank = indent == text.length;
    final html = open.html;
    if (html != null) {
      // A tag's block ends at a blank line, which is a blank line.
      final endsOnBlank =
          html == HtmlBlockKind.blockTag || html == HtmlBlockKind.completeTag;
      if (!(blank && endsOnBlank)) {
        final closes = HtmlBlockSyntax.closes(text, open);
        return made(
          BlockKind.html,
          html: closes ? null : html,
          htmlClosing: closes ? null : open.htmlClosing,
        );
      }
      return made(BlockKind.blank);
    }
    if (line == 0 && base.isEmpty && LineSyntax.opensFrontmatter(line, text)) {
      return made(BlockKind.frontmatter, frontmatter: true);
    }
    final opened = LineSyntax.fenceOpen(text);
    if (opened != null) return made(BlockKind.fencedCode, fence: opened);
    // Indented code: four spaces in from the container's margin. It runs on
    // over blank lines, whatever its lines look like — a table's head
    // included; it cannot interrupt a paragraph, so a four-space line after
    // paragraph text is the paragraph's.
    if (open.indentedCode && !blank && indent >= 4) {
      return made(BlockKind.indentedCode, indentedCode: true);
    }
    // A table, as GFM reads one: its rows run on until a line that would
    // start a block of its own. A line whose next is a delimiter row is a
    // head, tried before anything but a fence — and before a paragraph goes
    // on: it ends the paragraph even when its cells do not fit the
    // delimiter's columns, and is then read as if nothing were open.
    if (open.table && !blank && !_endsTableRow(text, next, base.isNotEmpty)) {
      return made(BlockKind.table, table: true);
    }
    if (heads && TableLineSyntax.heads(text, next)) {
      return made(BlockKind.table, table: true);
    }
    // A footnote definition, at the note's margin only — in an item or a
    // quote the parser leaves it where it stands. It interrupts a
    // paragraph; what follows its label is its first line, read inside it
    // with nothing open, as an item's marker line is.
    final opening = content == null && base.isEmpty && walk.footnote == 0
        ? FootnoteSyntax.opening(text)
        : null;
    if (opening != null) {
      final inner = _readLeaf(
        line,
        state,
        walk,
        LineState.initial,
        false,
        next,
        content: text.substring(opening.$2),
        within: const <OpenItem>[],
      );
      return LineRead(
        kind: inner.kind,
        walk: walk,
        items: inner.items,
        quoteDepth: inner.quoteDepth,
        carried: false,
        exit: _footnoted(inner.exit),
        heads: inner.heads,
        footnote: Block.opensFootnote,
      );
    }
    final paragraph = open.openParagraph && !heads;
    final code = open.indentedCode
        ? blank || indent >= 4
        : !blank && indent >= 4 && !paragraph;
    // Display math, either form — `math_rule.dart` says what a display line
    // is, as the preview reads it (#252) — unless it is indented code, which
    // the preview's parser reads first. Only the multi-line form opens a
    // state: a `$$…$$` on one line is over on it.
    if (!code && isDisplayLine(text.trim())) {
      return made(BlockKind.math, math: isDisplayOpen(text.trim()));
    }
    // Up to three spaces in, as every block's marker: four are code.
    final tag = indent <= 3 ? HtmlBlockSyntax.open(text) : null;
    if (tag != null) {
      // A comment, a raw-text tag, a processing instruction, a declaration
      // or a CDATA section ends on the line with its end marker — which can
      // be the line it opens on. Left open, a one-line `<!-- note -->` made
      // an HTML block of everything under it until the next `-->`: 1 656
      // lines of the worst-note fixture drawn as raw HTML, and their links
      // unread.
      final closes = HtmlBlockSyntax.closesOnItsOwnLine(
        text,
        LineState(html: tag.$1, htmlClosing: tag.$2),
      );
      return made(
        BlockKind.html,
        html: closes ? null : tag.$1,
        htmlClosing: closes ? null : tag.$2,
      );
    }
    if (blank) return made(BlockKind.blank, indentedCode: open.indentedCode);
    // Not a setext heading, which no line is on its own: it is a paragraph
    // whose underline goes on with it (`BlockRules.underlineLevel`).
    if (LineSyntax.isHr(text, 0)) return made(BlockKind.thematicBreak);
    if (LineSyntax.headingLevel(text) > 0) return made(BlockKind.heading);
    if (code) return made(BlockKind.indentedCode, indentedCode: true);
    final quoteDepth = LineSyntax.quoteDepth(text);
    if (quoteDepth > 0) {
      return made(
        BlockKind.quote,
        quoteDepth: quoteDepth,
        quoteLast: ContainerWalk.lastOf(LineSyntax.quoteChild(text)),
      );
    }
    final items = base;
    final marker = LineSyntax.listMarker(text);
    if (marker != null) {
      // An ordered list not starting at 1, or an empty item, goes on with an
      // open paragraph lazily — a marker in an item starts a list whatever
      // its number.
      if (paragraph &&
          !LineSyntax.markerInterrupts(
            marker,
            text,
            inItem: items.isNotEmpty,
          )) {
        return made(BlockKind.paragraph, openParagraph: true);
      }
      final (marked, empty) = LineSyntax.itemIndent(text, marker);
      // The columns a tab left over count toward the item's indent, as they
      // count toward an open item's (`ContainerWalk.remaining`).
      final itemIndent = marked + (content == null ? walk.remaining : 0);
      final parent = items.isEmpty ? 0 : items.last.content;
      final opened = <OpenItem>[
        ...items,
        (
          indent: itemIndent,
          content: parent + itemIndent,
          blanks: empty ? 1 : null,
          lastBlank: empty,
        ),
      ];
      // What follows the marker and its one space is the item's first line,
      // read in the item with nothing open there: a fence, a quote, a
      // sublist or indented code opens in the item on the marker's own line
      // (`- > q`, `- - a`, `- ```` `). The line is still the item's block.
      final (start, width, _) = marker;
      final after = start + width + 1;
      final inner = _readLeaf(
        line,
        state,
        walk,
        LineState.initial,
        carried,
        next,
        content: after < text.length ? text.substring(after) : '',
        within: opened,
      );
      // The block is the first item's — a sublist opened after its marker is
      // in its content, which the read view parses with it — and the state
      // after it holds whatever the content opened.
      return LineRead(
        kind: BlockKind.listItem,
        walk: walk,
        items: opened,
        quoteDepth: 0,
        carried: carried,
        exit: inner.exit,
        footnote: walk.footnote == 0 ? 0 : Block.inFootnote,
      );
    }
    // A setext underline heads the paragraph above it and ends it.
    final underline = carried && paragraph && LineSyntax.setextLevel(text) > 0;
    return made(BlockKind.paragraph, openParagraph: !underline);
  }

  /// Whether line [line] stays in [items], the items of the line before it:
  /// it does not end any of them.
  bool _stays(int line, List<OpenItem> items, int footnote) {
    if (items.isEmpty) return true;
    if (line >= buffer.lineCount) return false;
    return !ContainerWalk.of(
      LineState(listStack: items, footnote: footnote),
      lineText(line),
      line + 1 < buffer.lineCount ? lineText(line + 1) : null,
      _leftOverAt(line),
    ).closed;
  }

  /// Whether [text], following a table's rows, ends the table: a line that
  /// would start a block of its own — another table's head, a fence, an HTML
  /// block (all but a lone tag), a heading, a quote, a rule, a footnote
  /// definition, or a marker that may interrupt a paragraph. Anything else
  /// is a row, pipes or not.
  static bool _endsTableRow(String text, String? next, bool inItem) {
    if (next != null && TableLineSyntax.isDelimiter(next)) return true;
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
    return marker != null &&
        LineSyntax.markerInterrupts(marker, text, inItem: inItem);
  }

  /// The read of a line of [kind], entered in [state] and walked as [walk],
  /// leaving [items] (the walk's when null) and the rest.
  static LineRead _made(
    BlockKind kind,
    LineState state,
    ContainerWalk walk, {
    required bool carried,
    List<OpenItem>? items,
    int quoteDepth = 0,
    int quoteLast = 0,
    FenceMarker? fence,
    bool math = false,
    bool frontmatter = false,
    HtmlBlockKind? html,
    String? htmlClosing,
    bool indentedCode = false,
    bool table = false,
    bool openParagraph = false,
    bool heads = false,
  }) {
    final stack = items ?? walk.items;
    return LineRead(
      kind: kind,
      walk: walk,
      items: stack,
      quoteDepth: quoteDepth,
      carried: carried,
      heads: heads,
      footnote: walk.footnote == 0 ? 0 : Block.inFootnote,
      exit: _exit(
        state,
        stack,
        footnote: walk.footnote,
        quoteDepth: quoteDepth,
        quoteLast: quoteLast,
        fence: fence,
        math: math,
        frontmatter: frontmatter,
        html: html,
        htmlClosing: htmlClosing,
        indentedCode: indentedCode,
        table: table,
        openParagraph: openParagraph,
      ),
    );
  }

  /// The state after a line entered in [state]: the shared one where it can
  /// be, and [state] itself when the line leaves it as it was.
  static LineState _exit(
    LineState state,
    List<OpenItem> items, {
    required int footnote,
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
        quoteDepth == 0 &&
        fence == null &&
        !math &&
        !frontmatter &&
        html == null &&
        !indentedCode &&
        !table) {
      return openParagraph ? LineState.paragraphOpen : LineState.initial;
    }
    // Inside a construct, a line that leaves the state as it found it — the
    // next line of an item's paragraph, of a quote, of a code block — hands
    // on the state it entered in, for the same reason: the run's lines share
    // one object.
    if (identical(state.listStack, items) &&
        state.footnote == footnote &&
        state.quoteDepth == quoteDepth &&
        state.quoteLast == quoteLast &&
        state.fence == fence &&
        state.math == math &&
        state.frontmatter == frontmatter &&
        state.html == html &&
        state.htmlClosing == htmlClosing &&
        state.indentedCode == indentedCode &&
        state.table == table &&
        state.openParagraph == openParagraph) {
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
    );
  }

  /// [state] inside the footnote definition its line opened.
  static LineState _footnoted(LineState state) => LineState(
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
  );
}
