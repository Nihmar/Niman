/// Each line of a paragraph a paragraph of its own
/// (`LintRule.splitParagraphLines`).
///
/// Text pasted from elsewhere often sets its paragraphs one per line, with
/// no blank line between them: to Markdown that is a single paragraph, its
/// lines run together where the note is read. The corrector sets them
/// apart with a blank line, so each line reads as the paragraph it was
/// written as.
///
/// What a paragraph is, is the engine's own block tree's to say, so code —
/// fenced or indented — tables, math, HTML, frontmatter, headings and link
/// reference definitions are never touched. A quote's lines stay together,
/// and a list item's are the list's. Only a soft line break is split: a
/// line ending in a hard break keeps the line under it.
///
/// A blank line can change what the line under it is: `2001. A year` goes
/// on with a paragraph, and after a blank line opens a list; a lazy line
/// of a footnote leaves it. So the note is read again with its blank lines
/// in, and a line that does not come back as a paragraph of its own, where
/// it was, is left joined to the one above.
library;

import 'package:niman/src/lint/hard_break.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';

/// Where a paragraph line sits: the containers around it, and whether it
/// is its paragraph's first.
typedef _Place = ({String path, bool first});

/// [source] with a blank line before every line that goes on with a
/// paragraph after a soft break. A line keeps the `\r` it ended with, and
/// the blank line gets one too.
String splitParagraphLines(String source) {
  final before = _paragraphLines(source);
  final lines = source.split('\n');
  final cuts = <int>{
    for (final line in before.keys)
      if (!before[line]!.first && !endsInHardBreak(lines[line - 1])) line,
  };
  while (cuts.isNotEmpty) {
    final cut = _cut(lines, cuts);
    final wrong = _wrongCuts(before, cuts, _paragraphLines(cut));
    if (wrong == null) return cut;
    if (wrong.isEmpty) return source;
    // Every misread line takes back its cut in the one reading: a note
    // with a thousand of them is read twice, not a thousand times.
    cuts.removeAll(wrong);
  }
  return source;
}

/// [lines] joined back, a blank line before each of [cuts].
String _cut(List<String> lines, Set<int> cuts) {
  final out = <String>[];
  for (var at = 0; at < lines.length; at++) {
    if (cuts.contains(at)) out.add(lines[at].endsWith('\r') ? '\r' : '');
    out.add(lines[at]);
  }
  return out.join('\n');
}

/// The cuts to take back: for each paragraph line of [before] that does
/// not come back in [after] where [cuts] moved it — in the same
/// containers, opening a paragraph exactly when it was cut or opened one
/// already — the nearest cut above it. Null when every line came back as
/// it should; empty when a line did not and no cut is above it to blame,
/// and the note is left as it was.
Set<int>? _wrongCuts(
  Map<int, _Place> before,
  Set<int> cuts,
  Map<int, _Place> after,
) {
  final sorted = cuts.toList()..sort();
  final wrong = <int>{};
  var passed = 0;
  int? last;
  for (final line in before.keys.toList()..sort()) {
    while (passed < sorted.length && sorted[passed] <= line) {
      last = sorted[passed];
      passed++;
    }
    final was = before[line]!;
    final now = after[line + passed];
    final first = was.first || cuts.contains(line);
    if (now != null && now.path == was.path && now.first == first) continue;
    if (last == null) return const <int>{};
    wrong.add(last);
  }
  return wrong.isEmpty ? null : wrong;
}

/// Every line of a paragraph the rule works on, by line: a note's own
/// paragraphs, a footnote's and a column's — not a quote's, nor a list
/// item's.
Map<int, _Place> _paragraphLines(String source) {
  final out = <int, _Place>{};
  void walk(List<BlockNode> nodes, String path) {
    for (final node in nodes) {
      switch (node) {
        case FootnoteNode(:final children):
          walk(children, '${path}f');
        case ColumnsNode(:final columns):
          walk(columns, path);
        case ColumnNode(:final children):
          walk(children, '${path}c');
        case QuoteNode() || ListNode() || ItemNode():
          // A quote's lines stay together, and an item's are the list's.
          continue;
        case LeafNode(:final kind, :final lines, :final definition):
          if (kind != BlockKind.paragraph || definition) continue;
          for (var at = 0; at < lines.length; at++) {
            out[lines[at].line] = (path: path, first: at == 0);
          }
      }
    }
  }

  walk(BlockTree.of(source), '');
  return out;
}
