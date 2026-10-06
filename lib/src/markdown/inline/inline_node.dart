/// What our inline parser makes of a leaf's text: a tree of inline nodes,
/// each with where it stands in that text (`docs/dev/block-tree.md`).
///
/// The kinds are one family, read by exhaustive switches, so they share
/// this file.
library;

import 'package:meta/meta.dart';

/// One inline node, over `[start, end)` of the leaf's inline text.
@immutable
sealed class InlineNode {
  const new({required this.start, required this.end});

  /// Where the node starts in the leaf's text.
  final int start;

  /// Where it ends.
  final int end;
}

/// A node with nodes inside it.
sealed class InlineContainer extends InlineNode {
  const new({required super.start, required super.end, required this.children});

  /// The nodes inside it.
  final List<InlineNode> children;
}

/// Text, its escapes and character references resolved.
final class TextNode extends InlineNode {
  /// [text] over `[start, end)`.
  const new(this.text, {required super.start, required super.end});

  /// What it reads as.
  final String text;
}

/// A code span: its content, line endings made spaces and one space
/// stripped either side when both are there.
final class CodeNode extends InlineNode {
  /// [code] over `[start, end)`, backticks included.
  const new(this.code, {required super.start, required super.end});

  /// The code.
  final String code;
}

/// Emphasis: `*a*`, `_a_`.
final class EmphasisNode extends InlineContainer {
  /// Emphasis over its delimiters and [children].
  const new({
    required super.start,
    required super.end,
    required super.children,
  });
}

/// Strong emphasis: `**a**`, `__a__`.
final class StrongNode extends InlineContainer {
  /// Strong emphasis over its delimiters and [children].
  const new({
    required super.start,
    required super.end,
    required super.children,
  });
}

/// GFM's strikethrough: `~a~`, `~~a~~`.
final class StrikethroughNode extends InlineContainer {
  /// A strikethrough over its delimiters and [children].
  const new({
    required super.start,
    required super.end,
    required super.children,
  });
}

/// A link: inline, by reference, or an autolink.
final class LinkNode extends InlineContainer {
  /// A link to [destination].
  const new({
    required this.destination,
    required super.start,
    required super.end,
    required super.children,
    this.title,
    this.auto = false,
  });

  /// Where it goes, its escapes and references resolved.
  final String destination;

  /// Its title, or null.
  final String? title;

  /// Whether it is an autolink — `<…>` or, in GFM, a bare URL or address.
  final bool auto;
}

/// An image: [children] are its description.
final class ImageNode extends InlineContainer {
  /// An image of [destination].
  const new({
    required this.destination,
    required super.start,
    required super.end,
    required super.children,
    this.title,
  });

  /// Its source.
  final String destination;

  /// Its title, or null.
  final String? title;
}

/// Raw HTML, as written.
final class HtmlNode extends InlineNode {
  /// [html] over `[start, end)`.
  const new(this.html, {required super.start, required super.end});

  /// The HTML.
  final String html;
}

/// A line ending that is a space.
final class SoftBreakNode extends InlineNode {
  /// A soft break over its line ending.
  const new({required super.start, required super.end});
}

/// A line ending that is a line break: two spaces or a backslash before it.
final class HardBreakNode extends InlineNode {
  /// A hard break over its spaces or backslash and its line ending.
  const new({required super.start, required super.end});
}

/// A footnote reference, `[^label]`, to a definition the note has.
final class FootnoteRefNode extends InlineNode {
  /// A reference to [label].
  const new(this.label, {required super.start, required super.end});

  /// The label as written.
  final String label;
}
