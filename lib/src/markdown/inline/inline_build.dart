/// The inline tree while the parser builds it: linked nodes it can cut
/// out and wrap, as emphasis and links need, made [InlineNode]s at the end.
library;

import 'package:niman/src/markdown/inline/inline_node.dart';

/// What a node being built is.
enum InlineKind {
  /// The node the leaf's inlines are children of.
  root,

  /// Text.
  text,

  /// A code span.
  code,

  /// Emphasis.
  emphasis,

  /// Strong emphasis.
  strong,

  /// A strikethrough.
  strikethrough,

  /// A link.
  link,

  /// An image.
  image,

  /// Raw HTML.
  html,

  /// A soft line break.
  softBreak,

  /// A hard line break.
  hardBreak,

  /// A footnote reference.
  footnoteRef,
}

/// One node being built, linked to its siblings and its children.
final class InlineBuild {
  /// A node of [kind] over `[start, end)`, holding [text].
  new(this.kind, {required this.start, required this.end, this.text = ''});

  /// What it is.
  final InlineKind kind;

  /// Where it starts in the leaf's text.
  int start;

  /// Where it ends.
  int end;

  /// Its text: the text of a text node, a code span's code, raw HTML, a
  /// footnote's label.
  String text;

  /// A link's or an image's destination.
  String destination = '';

  /// A link's or an image's title.
  String? title;

  /// Whether a link is an autolink.
  bool auto = false;

  /// The node it is a child of.
  InlineBuild? parent;

  /// The sibling before it.
  InlineBuild? previous;

  /// The sibling after it.
  InlineBuild? next;

  /// Its first child.
  InlineBuild? first;

  /// Its last child.
  InlineBuild? last;

  /// Adds [child] as the last of its children.
  void append(InlineBuild child) {
    child
      ..parent = this
      ..previous = last
      ..next = null;
    if (last == null) {
      first = child;
    } else {
      last!.next = child;
    }
    last = child;
  }

  /// Puts [node] right after this one, among the same siblings.
  void insertAfter(InlineBuild node) {
    node
      ..parent = parent
      ..previous = this
      ..next = next;
    if (next == null) {
      parent?.last = node;
    } else {
      next!.previous = node;
    }
    next = node;
  }

  /// Takes this node out from among its siblings.
  void unlink() {
    if (previous == null) {
      parent?.first = next;
    } else {
      previous!.next = next;
    }
    if (next == null) {
      parent?.last = previous;
    } else {
      next!.previous = previous;
    }
    parent = null;
    previous = null;
    next = null;
  }

  /// Moves the siblings strictly between [from] and [to] — to the last when
  /// [to] is null — into this node,
  /// which then stands where they stood.
  void wrapBetween(InlineBuild from, InlineBuild? to) {
    var node = from.next;
    while (node != null && !identical(node, to)) {
      final after = node.next;
      node.unlink();
      append(node);
      node = after;
    }
    from.insertAfter(this);
  }

  /// The finished node.
  InlineNode freeze() {
    final children = <InlineNode>[
      for (var child = first; child != null; child = child.next) child.freeze(),
    ];
    return switch (kind) {
      InlineKind.root ||
      InlineKind.text => TextNode(text, start: start, end: end),
      InlineKind.code => CodeNode(text, start: start, end: end),
      InlineKind.emphasis => EmphasisNode(
        start: start,
        end: end,
        children: children,
      ),
      InlineKind.strong => StrongNode(
        start: start,
        end: end,
        children: children,
      ),
      InlineKind.strikethrough => StrikethroughNode(
        start: start,
        end: end,
        children: children,
      ),
      InlineKind.link => LinkNode(
        destination: destination,
        title: title,
        auto: auto,
        start: start,
        end: end,
        children: children,
      ),
      InlineKind.image => ImageNode(
        destination: destination,
        title: title,
        start: start,
        end: end,
        children: children,
      ),
      InlineKind.html => HtmlNode(text, start: start, end: end),
      InlineKind.softBreak => SoftBreakNode(start: start, end: end),
      InlineKind.hardBreak => HardBreakNode(start: start, end: end),
      InlineKind.footnoteRef => FootnoteRefNode(text, start: start, end: end),
    };
  }
}
