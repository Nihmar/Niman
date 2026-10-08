/// A paragraph's text on one line: a list item's (#549), and any other's.
///
/// A paragraph wrapped by hand over several lines is one paragraph to
/// every reader, and a line of its own to edit and to diff: the corrector
/// writes it back on the line it starts on, and the editor wraps it on
/// screen. What a paragraph is, is the engine's own block tree's to say —
/// the reading every surface draws from — so a heading (setext ones
/// included: their lines are a heading's, not a paragraph's), a fence, a
/// table, math, HTML, frontmatter and a link reference definition are
/// never joined, and neither is a line that starts a block of its own.
/// Only a soft line break is: a line ending in a hard break keeps it.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';

/// [source] with each paragraph written on one line: a line that goes on
/// with it joins the one above, one space between them — the container
/// marks the joined line was written with (`>`, an item's indent) and its
/// leading white space going with it.
///
/// [inItems] joins the paragraphs inside a list item; [outside] the rest:
/// a note's own paragraphs, a quote's, a footnote's. A line keeps the
/// `\r` it ended with.
String joinWrappedLines(
  String source, {
  required bool inItems,
  required bool outside,
}) {
  if (!inItems && !outside) return source;
  // The line each joining line's text starts at, by line.
  final joins = <int, int>{};
  void walk(List<BlockNode> nodes, {required bool inItem}) {
    for (final node in nodes) {
      switch (node) {
        case ItemNode(:final children):
          walk(children, inItem: true);
        case ListNode(:final items):
          walk(items, inItem: inItem);
        case QuoteNode(:final children) || FootnoteNode(:final children):
          walk(children, inItem: inItem);
        case LeafNode(:final kind, :final lines, :final definition):
          if (kind != BlockKind.paragraph || definition) continue;
          if (!(inItem ? inItems : outside)) continue;
          for (final span in lines.skip(1)) {
            joins[span.line] = span.start;
          }
      }
    }
  }

  walk(BlockTree.of(source), inItem: false);
  if (joins.isEmpty) return source;
  final lines = source.split('\n');
  final out = <String>[];
  for (var at = 0; at < lines.length; at++) {
    final start = joins[at];
    final line = lines[at];
    if (start == null || out.isEmpty || _breaks(out.last)) {
      out.add(line);
      continue;
    }
    final cr = line.endsWith('\r') ? '\r' : '';
    // Its trailing spaces stay: a hard break at its end is the next
    // line's to keep.
    final text = line
        .substring(0, line.length - cr.length)
        .substring(start)
        .trimLeft();
    out.last = '${out.last.trimRight()} $text$cr';
  }
  return out.join('\n');
}

/// Whether [line] ends in a hard break: two spaces, or a backslash that
/// escapes none.
bool _breaks(String line) {
  final text = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
  if (text.endsWith('  ')) return true;
  var slashes = 0;
  while (slashes < text.length &&
      text.codeUnitAt(text.length - 1 - slashes) == 0x5C) {
    slashes++;
  }
  return slashes.isOdd;
}
