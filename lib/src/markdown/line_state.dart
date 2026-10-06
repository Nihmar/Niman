/// The block state a line inherits from the one before it.
///
/// This is the generalization of `editor/highlighting.dart`'s private state —
/// which already carries a fence, inline math and the frontmatter — to the
/// containers Markdown actually has (`docs/records/unified-surface.md` §8.5.1). The
/// point of it is that a line's *block* meaning is a function of the line and
/// the state entering it, so a scan can stop as soon as the state converges and
/// everything after it is known to be unchanged.
///
/// Containers are recorded by depth rather than as a tree: a block knows it is
/// in three levels of list and one of quote, which is all the layout and the
/// inline phase need, and which keeps the state a small value that can be
/// compared for convergence.
library;

import 'package:meta/meta.dart';

/// A fenced code block's opening run.
@immutable
final class FenceMarker {
  /// Creates a marker for [length] of [char] at [indent] spaces.
  const new({required this.char, required this.length, required this.indent});

  /// The fence character: a backtick or a tilde.
  final int char;

  /// How many of them open the block.
  final int length;

  /// The opening line's indentation, which the content is dedented by.
  final int indent;

  @override
  bool operator ==(Object other) =>
      other is FenceMarker &&
      other.char == char &&
      other.length == length &&
      other.indent == indent;

  @override
  int get hashCode => Object.hash(char, length, indent);

  @override
  String toString() => 'Fence(${String.fromCharCode(char)} x$length)';
}

/// Which of the seven HTML block types a line opened, since each ends
/// differently.
enum HtmlBlockKind {
  /// `<pre`, `<script`, `<style` or `<textarea`: ends at its closing tag.
  rawText,

  /// `<!--`: ends at `-->`.
  comment,

  /// `<?`: ends at `?>`.
  processingInstruction,

  /// `<!` and a letter: ends at `>`.
  declaration,

  /// `<![CDATA[`: ends at `]]>`.
  cdata,

  /// A known block-level tag: ends at a blank line.
  blockTag,

  /// A complete open or closing tag alone on its line: ends at a blank line,
  /// and cannot interrupt a paragraph.
  completeTag,
}

/// One open list item, as `package:markdown` — the parser the read view
/// draws with — keeps it while it gathers the item's lines.
///
/// * `indent` is how far in the item's lines stand **in the item's own
///   coordinates**: the text its list read, which is the parent item's
///   text with the parent's indent taken off. A line at least this far in
///   is the item's, with that much taken off it; a line short of it is the
///   item's only lazily, and then it is read as it stands.
/// * `content` is where those lines' text starts on the note's line when
///   every item around them took them by their indent: the sum of the
///   indents, outermost first. It is what a reader of a block in the item
///   takes off its lines (`BlockParser.itemPrefixLength`). Not the column of
///   the item's own text on its marker line: a sublist opened by a lazy
///   line stands somewhere else on that line.
/// * `blanks` counts the blank lines after a marker with no text after it,
///   which may be followed by one blank line at most; null for an item
///   whose marker line had text.
/// * `lastBlank` is whether the last line the item took was blank: text
///   short of its indent after one is not lazy, and ends the list.
typedef OpenItem = ({int indent, int content, int? blanks, bool lastBlank});

/// The block state entering a line.
@immutable
final class LineState {
  /// Creates a state.
  const new({
    this.fence,
    this.math = false,
    this.frontmatter = false,
    this.indentedCode = false,
    this.html,
    this.htmlClosing,
    this.quoteDepth = 0,
    this.quoteLast = 0,
    this.listStack = const <OpenItem>[],
    this.table = false,
    this.openParagraph = false,
    this.footnote = 0,
    this.definition = 0,
    this.definitionsOnly = false,
  });

  /// [footnote] when a footnote definition is open.
  static const int footnoteOpen = 1;

  /// [footnote] when a footnote definition is open and its last line was
  /// blank: a line not four spaces in ends it.
  static const int footnoteAfterBlank = 2;

  /// [quoteLast]'s bit for a blank last line.
  static const int lastBlank = 1;

  /// [quoteLast]'s bit for a last line that is a code fence.
  static const int lastFence = 2;

  /// [quoteLast]'s bit for a last line that closed its block on it: a
  /// heading, a rule. No paragraph is open after it.
  static const int lastClosed = 8;

  /// [quoteLast]'s bit for a last line indented four spaces or more.
  static const int lastIndented = 4;

  /// The top-level state, where a document starts and where a scan converges.
  static const LineState initial = LineState();

  /// The shared state after a plain line of paragraph text: nothing is open
  /// but the paragraph the line goes on with. A second shared constant, for
  /// the common line of a long note of prose, beside [initial] (#346).
  static const LineState paragraphOpen = LineState(openParagraph: true);

  /// The open fence, if a fenced code block is running.
  final FenceMarker? fence;

  /// Whether a `$$…$$` block is running.
  final bool math;

  /// Whether the leading frontmatter block is running.
  final bool frontmatter;

  /// Whether an indented code block is running.
  final bool indentedCode;

  /// Which HTML block type is running, if any.
  final HtmlBlockKind? html;

  /// The tag that closes a [HtmlBlockKind.rawText] block (`pre`, `script`,
  /// `style` or `textarea`), matched case-insensitively in the text.
  final String? htmlClosing;

  /// How many blockquote levels the open quote's first line had, or 0 when
  /// no quote is open.
  ///
  /// A quote is one block to the scan, inside the items [listStack] holds:
  /// what is inside it — items, further quotes — is read again from its
  /// content, the way the read view draws it.
  final int quoteDepth;

  /// What the open quote's last line was, inside the quote — the bits
  /// [lastBlank], [lastFence] and [lastIndented] — which is what decides
  /// whether a line without a `>` goes on with it lazily: paragraph text
  /// does unless that line was blank or a fence, and an indented line does
  /// unless it was indented too (`> w` / `    w` / `    w` is a quote of
  /// one paragraph, then code).
  final int quoteLast;

  /// The list items this line sits inside, outermost first, outside any
  /// quote (see [OpenItem]).
  final List<OpenItem> listStack;

  /// The content indentation of the innermost open item, or -1 outside a list.
  int get listIndent => listStack.isEmpty ? -1 : listStack.last.content;

  /// How many list levels deep the innermost open item is (0 at the top
  /// level), or -1 outside a list.
  int get listDepth => listStack.isEmpty ? -1 : listStack.length - 1;

  /// Whether a GFM table is running.
  final bool table;

  /// Whether a paragraph is open in the innermost container: the line
  /// before was paragraph text there.
  ///
  /// A paragraph decides what may interrupt it: an indented code block
  /// cannot, so a four-space line after paragraph text is the paragraph's;
  /// an ordered list may only from 1, and an empty item not at all. Only
  /// set for paragraph text, so a heading, a fence or a blank line keeps
  /// the shared state.
  final bool openParagraph;

  /// Whether a footnote definition is open around everything else —
  /// [footnoteOpen], [footnoteAfterBlank] — or 0. One opens only at the
  /// note's margin, outside every item and quote, the only place the read
  /// view's parser takes it out to the footnotes; the items and the quote
  /// this state holds are inside it.
  final int footnote;

  /// How many more lines the open link reference definition takes, or 0:
  /// its first line decided them (`LinkDefinitionSyntax`).
  final int definition;

  /// Whether the paragraph open ([openParagraph]) holds link reference
  /// definitions and nothing else yet. A definition is a paragraph's text
  /// until the paragraph closes, as `cmark` reads it — what follows goes
  /// on with it, `2) x` and four-space lines too — but an underline under
  /// definitions alone heads nothing: they leave no text to head.
  final bool definitionsOnly;

  /// Whether the line is anywhere a block-level construct can still start —
  /// outside every fence, math block, frontmatter, HTML block and indented
  /// code.
  bool get isPlain =>
      fence == null && !math && !frontmatter && !indentedCode && html == null;

  @override
  bool operator ==(Object other) =>
      other is LineState &&
      other.fence == fence &&
      other.math == math &&
      other.frontmatter == frontmatter &&
      other.indentedCode == indentedCode &&
      other.html == html &&
      other.htmlClosing == htmlClosing &&
      other.quoteDepth == quoteDepth &&
      other.quoteLast == quoteLast &&
      _sameStack(other.listStack, listStack) &&
      other.table == table &&
      other.openParagraph == openParagraph &&
      other.footnote == footnote &&
      other.definition == definition &&
      other.definitionsOnly == definitionsOnly;

  /// Whether two stacks hold the same items: records compare by value, so a
  /// plain element-wise walk is the whole of it (the engine has no
  /// `package:collection`).
  static bool _sameStack(List<OpenItem> a, List<OpenItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at] != b[at]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    fence,
    math,
    frontmatter,
    indentedCode,
    html,
    htmlClosing,
    quoteDepth,
    quoteLast,
    Object.hashAll(listStack),
    table,
    openParagraph,
    footnote,
    definition,
    definitionsOnly,
  );

  @override
  String toString() =>
      'LineState(fence: $fence, math: $math, frontmatter: $frontmatter, '
      'code: $indentedCode, html: $html, quote: $quoteDepth, '
      'quoteLast: $quoteLast, '
      'list: $listDepth at $listIndent, table: $table, '
      'paragraph: $openParagraph, footnote: $footnote, '
      'definition: $definition, definitionsOnly: $definitionsOnly)';
}
