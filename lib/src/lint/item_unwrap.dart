/// A list item's text on one line (#549).
///
/// An item wrapped by hand over several lines is one paragraph to every
/// reader, and a line of its own to edit and to diff: the corrector writes
/// it back on the line its marker is on. Only an item's paragraphs are
/// read — a paragraph outside any item is prose, which the tidying never
/// reflows — and a line ending in a hard break keeps it.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';

/// [source] with each paragraph inside a list item written on one line:
/// a line that goes on with it joins the one above, one space between
/// them — the container marks the joined line was written with (`>`, the
/// item's indent) going with it.
String joinWrappedItems(String source) {
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
        case LeafNode(:final kind, :final lines):
          if (!inItem || kind != BlockKind.paragraph) continue;
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
    final text = line.substring(start).trim();
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
