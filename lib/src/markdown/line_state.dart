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
    this.listStack = const <({int marker, int content})>[],
    this.table = false,
  });

  /// The top-level state, where a document starts and where a scan converges.
  static const LineState initial = LineState();

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

  /// How many blockquote levels the line sits in.
  final int quoteDepth;

  /// The list items this line sits inside, outermost first.
  ///
  /// Each open item is kept as the column its marker *starts* at and the
  /// column its content starts at, because the two answer different
  /// questions: a marker is a child when it starts at or past the open item's
  /// content column, and a sibling when it starts at the same column as that
  /// item's own marker — which is how `9. ` and `10. ` stay one list however
  /// much their content columns differ.
  final List<({int marker, int content})> listStack;

  /// The content indentation of the innermost open item, or -1 outside a list.
  int get listIndent => listStack.isEmpty ? -1 : listStack.last.content;

  /// How many list levels deep the innermost open item is (0 at the top
  /// level), or -1 outside a list.
  int get listDepth => listStack.isEmpty ? -1 : listStack.length - 1;

  /// Whether a GFM table is running.
  final bool table;

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
      _sameStack(other.listStack, listStack) &&
      other.table == table;

  /// Whether two stacks hold the same items: records compare by value, so a
  /// plain element-wise walk is the whole of it (the engine has no
  /// `package:collection`).
  static bool _sameStack(
    List<({int marker, int content})> a,
    List<({int marker, int content})> b,
  ) {
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
    Object.hashAll(listStack),
    table,
  );

  @override
  String toString() =>
      'LineState(fence: $fence, math: $math, frontmatter: $frontmatter, '
      'code: $indentedCode, html: $html, quote: $quoteDepth, '
      'list: $listDepth at $listIndent, table: $table)';
}
