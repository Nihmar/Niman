/// The HTML tags the app reads as styles — `<u>`, `<sup>`, `<sub>` — made
/// nodes of their own around what they hold (`docs/dev/block-tree.md`,
/// phase 4): the toolbar writes `<u>` into a note, and the views draw what
/// it means, not the tags.
library;

import 'package:niman/src/markdown/inline/inline_build.dart';

/// Pairs the style tags in a parse.
abstract final class StyleTags {
  /// The tags read as styles.
  static const Set<String> tags = <String>{'u', 'sup', 'sub'};

  /// Wraps what each `<u>`, `<sup>` and `<sub>` under [root] holds up to
  /// its closing tag — among the same siblings, on the same line, as the
  /// app has always read them — in a node of its own.
  static void apply(InlineBuild root) {
    final containers = <InlineBuild>[root];
    while (containers.isNotEmpty) {
      final container = containers.removeLast();
      // The tags that found no closing one before the line's end: one
      // after them on the line will not either.
      final unclosed = <String>{};
      for (var node = container.first; node != null; node = node.next) {
        if (node.kind == InlineKind.softBreak ||
            node.kind == InlineKind.hardBreak) {
          unclosed.clear();
          continue;
        }
        final tag = _opening(node);
        if (tag != null && !unclosed.contains(tag)) {
          final close = _closing(node, tag);
          if (close == null) {
            unclosed.add(tag);
          } else {
            final styled = InlineBuild(
              InlineKind.styled,
              start: node.start,
              end: close.end,
              text: tag,
            )..wrapBetween(node, close);
            node.unlink();
            close.unlink();
            containers.add(styled);
            node = styled;
            continue;
          }
        }
        if (_holds(node.kind)) containers.add(node);
      }
    }
  }

  /// The style tag [node] opens, or null.
  static String? _opening(InlineBuild node) {
    if (node.kind != InlineKind.html) return null;
    final html = node.text.toLowerCase();
    for (final tag in tags) {
      if (html == '<$tag>') return tag;
    }
    return null;
  }

  /// The `</tag>` among [open]'s siblings after it, before a line break.
  static InlineBuild? _closing(InlineBuild open, String tag) {
    for (var node = open.next; node != null; node = node.next) {
      if (node.kind == InlineKind.softBreak ||
          node.kind == InlineKind.hardBreak) {
        return null;
      }
      if (node.kind == InlineKind.html &&
          node.text.toLowerCase() == '</$tag>') {
        return node;
      }
    }
    return null;
  }

  static bool _holds(InlineKind kind) => switch (kind) {
    InlineKind.emphasis ||
    InlineKind.strong ||
    InlineKind.strikethrough ||
    InlineKind.highlight ||
    InlineKind.link ||
    InlineKind.image => true,
    InlineKind.root ||
    InlineKind.text ||
    InlineKind.code ||
    InlineKind.html ||
    InlineKind.softBreak ||
    InlineKind.hardBreak ||
    InlineKind.footnoteRef ||
    InlineKind.math ||
    InlineKind.wikilink ||
    InlineKind.tag ||
    InlineKind.styled => false,
  };
}
