// A leaf's inline text and the way back to the note (`source_map.dart`,
// `leaf_inline.dart`): what `live` puts our parser's offsets back on its
// lines with.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_map.dart';

import '../../tool/spec_suite.dart';

/// Every piece of inline text of every block of [text], read.
List<ReadInline> _inlines(String text) {
  final buffer = SourceBuffer.fromText(text);
  final parser = ReadParser();
  final out = <ReadInline>[];
  for (final block in BlockScanner(buffer).index.blocks) {
    final read = parser.of(block, buffer);
    void visit(BlockNode node) {
      switch (node) {
        case QuoteNode(:final children) ||
            ItemNode(:final children) ||
            FootnoteNode(:final children):
          children.forEach(visit);
        case ListNode(:final items):
          items.forEach(visit);
        case LeafNode():
          final leaf = read.leaf(node);
          if (leaf.inline != null) out.add(leaf.inline!);
          leaf.rows.forEach(out.addAll);
      }
    }

    visit(read.node);
  }
  return out;
}

/// Where each character of [inline] is in the note, as the map says, as
/// `line:column` — `-` for one no line has.
List<String> _positions(ReadInline inline) => [
  for (var at = 0; at < inline.text.length; at++)
    switch (inline.map.positionOf(at)) {
      null => '-',
      final p => '${p.line}:${p.column}',
    },
];

void main() {
  test('a stretch maps one to one, the line endings between nowhere', () {
    final map = SourceMap()
      ..add(0, 3, 4, 2)
      ..add(4, 2, 5, 6);
    expect(map.positionOf(0), (line: 4, column: 2));
    expect(map.positionOf(2), (line: 4, column: 4));
    expect(map.positionOf(3), isNull);
    expect(map.positionOf(5), (line: 5, column: 7));
    expect(map.spans(1, 6), [
      (line: 4, start: 3, end: 5),
      (line: 5, start: 6, end: 8),
    ]);
    final rest = map.from(2);
    expect(rest.positionOf(0), (line: 4, column: 4));
    expect(rest.positionOf(2), (line: 5, column: 6));
  });

  test('a paragraph in a quoted item: its lines past their marks', () {
    final inline = _inlines('> - a *b*\n>   c').single;
    expect(inline.text, 'a *b*\nc');
    expect(_positions(inline), [
      '0:4', '0:5', '0:6', '0:7', '0:8', '-', '1:4', //
    ]);
  });

  test("a heading's words, a task's text past its box", () {
    expect(_positions(_inlines('  ## *t* ##').single), [
      '0:5', '0:6', '0:7', //
    ]);
    final task = _inlines('- [x] do').single;
    expect(task.text, 'do');
    expect(_positions(task), ['0:6', '0:7']);
  });

  test("a cell's escaped pipe is a pipe, its backslash nowhere", () {
    final cells = _inlines('| a | b\\|c |\n|---|---|');
    expect(cells.map((cell) => cell.text), ['a', 'b|c']);
    expect(_positions(cells[1]), ['0:6', '0:8', '0:9']);
    // A construct over it covers the backslash too, which is a gap.
    expect(cells[1].map.spans(0, 3), [(line: 0, start: 6, end: 10)]);
    expect(cells[1].map.gaps(), [(line: 0, start: 7, end: 8)]);
  });

  test('every character of every example maps to itself', () {
    // The specs' examples hold every shape a leaf's text is cut from:
    // containers, tabs, lazy lines, headings, tables, definitions.
    var checked = 0;
    for (final suite in loadSpecSuites()) {
      for (final example in suite.examples) {
        final lines = example.markdown.split('\n');
        for (final inline in _inlines(example.markdown)) {
          for (var at = 0; at < inline.text.length; at++) {
            final position = inline.map.positionOf(at);
            if (position == null) {
              expect(
                inline.text[at],
                '\n',
                reason: '${suite.name}/${example.number}: $at unmapped',
              );
              continue;
            }
            checked++;
            expect(
              lines[position.line][position.column],
              inline.text[at],
              reason: '${suite.name}/${example.number} at $at',
            );
          }
        }
      }
    }
    expect(checked, greaterThan(10000));
  });
}
