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
/// An annotation's line back to the passage it quotes is its own line too,
/// and no line joins onto it (`_opensLinkBack`, #1183).
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
  // Where each paragraph line's text starts, by line, and which of the
  // lines go on with the one above.
  final starts = <int, int>{};
  final joins = <int, int>{};
  void walk(List<BlockNode> nodes, {required bool inItem}) {
    for (final node in nodes) {
      switch (node) {
        case ItemNode(:final children):
          walk(children, inItem: true);
        case ListNode(:final items):
          walk(items, inItem: inItem);
        case ColumnsNode(:final columns):
          walk(columns, inItem: inItem);
        case ColumnNode(:final children):
          walk(children, inItem: inItem);
        case QuoteNode(:final children) || FootnoteNode(:final children):
          walk(children, inItem: inItem);
        case LeafNode(:final kind, :final lines, :final definition):
          if (kind != BlockKind.paragraph || definition) continue;
          if (!(inItem ? inItems : outside)) continue;
          for (final span in lines) {
            starts[span.line] = span.start;
            joins[span.line] = span.start;
          }
          // A paragraph's first line has nothing above it to join.
          joins.remove(lines.first.line);
      }
    }
  }

  walk(BlockTree.of(source), inItem: false);
  if (joins.isEmpty) return source;
  final lines = source.split('\n');

  // Whether the paragraph line at [at] opens an annotation's line back to
  // its quote: no line joins onto it either, or the quote reads empty
  // (#1183).
  bool opensLinkBack(int at) {
    final start = starts[at];
    return start != null && _opensLinkBack(_contentOf(lines[at], start));
  }

  final out = <String>[];
  // The line last written opens an annotation's link back: the line below
  // is its own, not a continuation of it (#1183).
  var afterLinkBack = false;
  for (var at = 0; at < lines.length; at++) {
    final start = joins[at];
    final line = lines[at];
    if (start == null || out.isEmpty) {
      out.add(line);
      afterLinkBack = opensLinkBack(at);
      continue;
    }
    final cr = line.endsWith('\r') ? '\r' : '';
    // Its trailing spaces stay: a hard break at its end is the next
    // line's to keep.
    final text = _contentOf(line, start);
    if (_opensLinkBack(text) || afterLinkBack || _breaks(out.last)) {
      out.add(line);
      afterLinkBack = _opensLinkBack(text);
      continue;
    }
    out.last = '${out.last.trimRight()} $text$cr';
    afterLinkBack = false;
  }
  return out.join('\n');
}

/// [line]'s text past [start]: its `\r` and its leading white space off.
String _contentOf(String line, int start) => line
    .substring(0, line.length - (line.endsWith('\r') ? 1 : 0))
    .substring(start)
    .trimLeft();

/// The `— [[…]]` an annotation's line back to its place opens with.
final RegExp _linkBack = RegExp(r'^—\s*\[{1,2}');

/// Whether [text], past the container marks it was written with, opens an
/// annotation's line back to the place it quotes:
/// `— [[Books/Dune.pdf#page=34]]`, or the Markdown link a library writes
/// instead (`Annotation.toMarkdown`).
/// The line is the annotation's, not a continuation of the quote above it:
/// joined, the quote loses its passage and the companion its mark (#1183).
bool _opensLinkBack(String text) => _linkBack.hasMatch(text);

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
