/// The block state a line inherits from the one before it.
///
/// This is the generalization of `editor/highlighting.dart`'s private state —
/// which already carries a fence, inline math and the frontmatter — to the
/// containers Markdown actually has (`docs/dev/unified-surface.md` §8.5.1). The
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
    this.listIndent = -1,
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

  /// The content indentation of the innermost list item, or -1 outside a list.
  final int listIndent;

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
      other.listIndent == listIndent &&
      other.table == table;

  @override
  int get hashCode => Object.hash(
    fence,
    math,
    frontmatter,
    indentedCode,
    html,
    htmlClosing,
    quoteDepth,
    listIndent,
    table,
  );

  @override
  String toString() =>
      'LineState(fence: $fence, math: $math, frontmatter: $frontmatter, '
      'code: $indentedCode, html: $html, quote: $quoteDepth, '
      'list: $listIndent, table: $table)';
}
