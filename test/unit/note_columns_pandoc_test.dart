// The note's columns held to Pandoc's reading of the same notes (#729):
// fenced divs are Pandoc's syntax, so its nesting is the oracle. The cases
// and Pandoc's shapes are in `test/fixtures/columns/pandoc-divs.json`,
// written by `tool/pandoc_divs.py`, which says what a shape keeps.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/div_syntax.dart';
import 'package:niman/src/markdown/html/leaf_text.dart';
import 'package:path/path.dart' as p;

/// [nodes] of [text] in the shape `tool/pandoc_divs.py` writes Pandoc's
/// blocks in. An implicit column is its blocks where they stand: Pandoc
/// has the blocks in the `columns` div. An unknown div's fence lines are
/// text to the tree, and nothing to the shape, as its div is to Pandoc's.
String _shape(String text, List<BlockNode> nodes) {
  final lines = text.split('\n');
  String collapsed(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();
  late final String Function(List<BlockNode> nodes) all;
  var unknown = 0;
  String of(BlockNode node) => switch (node) {
    QuoteNode(:final children) => 'Q[${all(children)}]',
    FootnoteNode() => '',
    ListNode(:final items) => 'L[${all(items)}]',
    ItemNode(:final children) => 'I[${all(children)}]',
    ColumnsNode(:final columns) => 'cols[${all(columns)}]',
    ColumnNode(:final children, implicit: true) => all(children),
    ColumnNode(:final children, :final width) =>
      'col${width == null ? '' : '${_share(width)}%'}[${all(children)}]',
    LeafNode(:final kind) => switch (kind) {
      BlockKind.paragraph => () {
        final paragraph = collapsed(
          LeafText.paragraph(LeafText.linesOf(node, lines)),
        );
        // An unknown div's opener, and the closer that matches it.
        if (DivSyntax.opening(paragraph) != null) {
          unknown++;
          return '';
        }
        if (unknown > 0 && DivSyntax.closes(paragraph)) {
          unknown--;
          return '';
        }
        return 'P"$paragraph"';
      }(),
      BlockKind.heading =>
        'H${node.headingLevel}'
            '"${collapsed(LeafText.atxHeading(lines[node.line]))}"',
      BlockKind.fencedCode || BlockKind.indentedCode => 'Code',
      BlockKind.thematicBreak => 'HR',
      BlockKind.table => 'T',
      _ => '',
    },
  };
  all = (nodes) => nodes.map(of).where((part) => part.isNotEmpty).join(' ');
  return all(nodes);
}

/// A width as Python's `%g` writes it.
String _share(double width) => width == width.roundToDouble()
    ? width.round().toString()
    : width.toString();

void main() {
  final cases = jsonDecode(
    File(p.join('test', 'fixtures', 'columns', 'pandoc-divs.json'))
        .readAsStringSync(),
  ) as List<Object?>;
  for (final entry in cases.cast<Map<String, Object?>>()) {
    test(entry['about']! as String, () {
      final markdown = entry['markdown']! as String;
      expect(
        _shape(markdown, BlockTree.of(markdown)),
        entry['pandoc'],
        reason: markdown,
      );
    });
  }
}
