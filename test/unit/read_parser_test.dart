// The read view's reading of a block: its node of the tree, and each
// leaf's inline text read by our own parser (docs/dev/block-tree.md,
// phase 5).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// Every block of [text], read.
List<ReadBlock> _read(String text) {
  final buffer = SourceBuffer.fromText(text);
  final parser = ReadParser();
  return [
    for (final block in BlockScanner(buffer).index.blocks)
      parser.of(block, buffer),
  ];
}

/// The leaves of [block], in order.
List<ReadLeaf> _leaves(ReadBlock block) {
  final out = <ReadLeaf>[];
  void visit(BlockNode node) {
    switch (node) {
      case QuoteNode(:final children) ||
          ItemNode(:final children) ||
          FootnoteNode(:final children):
        children.forEach(visit);
      case ListNode(:final items):
        items.forEach(visit);
      case LeafNode():
        out.add(block.leaf(node));
    }
  }

  visit(block.node);
  return out;
}

/// The inline text of the first leaf of the first block of [text].
String _inline(String text) => _leaves(_read(text).first).first.inline!.text;

void main() {
  group('a leaf is read without its syntax', () {
    test("a paragraph's lines lose their leading white space", () {
      expect(_inline('  a\n   b  '), 'a\nb');
    });

    test("a heading's marks are off", () {
      expect(_inline('## Title ##'), 'Title');
      expect(_inline('Title\n==='), 'Title');
    });

    test("an item's marker and indent, a quote's marks", () {
      expect(_inline('- a\n  b'), 'a\nb');
      expect(_inline('> a\n> b'), 'a\nb');
    });

    test('the definitions a paragraph starts with', () {
      final blocks = _read('[a]: /u\n\n[x][a]');
      expect(_leaves(blocks.first).first.inline!.isEmpty, isTrue);
      final link = _leaves(blocks.last).first.inline!.nodes.single;
      expect(link, isA<LinkNode>());
      expect((link as LinkNode).destination, '/u');
    });
  });

  group('an item', () {
    test('a task box is read off its text', () {
      final block = _read('- [x] done').single;
      final item = block.node as ItemNode;
      expect(block.taskOf(item), isTrue);
      expect(_leaves(block).single.inline!.text, 'done');
    });

    test('an item with no box is no task', () {
      final block = _read('- [-] maybe').single;
      expect(block.taskOf(block.node as ItemNode), isNull);
      expect(_leaves(block).single.inline!.text, '[-] maybe');
    });
  });

  group('references', () {
    test('a definition over lines resolves a link anywhere in the note', () {
      final blocks = _read('see [x]\n\n[X]:\n/far "t"');
      final link = _leaves(blocks.first).first.inline!.nodes[1] as LinkNode;
      expect(link.destination, '/far');
      expect(link.title, 't');
    });

    test('a footnote is numbered as the section numbers it', () {
      final blocks = _read('a[^b] c[^a]\n\n[^a]: one\n[^b]: two');
      expect(blocks.first.footnoteNumbers, {'B': 1, 'A': 2});
      final nodes = _leaves(blocks.first).first.inline!.nodes;
      expect(nodes.whereType<FootnoteRefNode>().map((n) => n.label), [
        'b',
        'a',
      ]);
    });
  });

  group('a table', () {
    test('its rows are cells read, as many as its head', () {
      final leaf = _leaves(
        _read('| a | *b* |\n|:-|-:|\n| 1 |\n| 2 | 3 | 4 |').single,
      ).single;
      expect(leaf.aligns, [TableAlign.left, TableAlign.right]);
      expect(
        [
          for (final row in leaf.rows) [for (final cell in row) cell.text],
        ],
        [
          ['a', '*b*'],
          ['1', ''],
          ['2', '3'],
        ],
      );
      expect(leaf.rows.first[1].nodes.single, isA<EmphasisNode>());
    });
  });

  group('code', () {
    test("a fence's code, its fences off", () {
      final leaf = _leaves(_read('```js\n  a\nb\n```').single).single;
      expect(leaf.code, ['  a', 'b']);
      expect(leaf.closed, isTrue);
      expect(leaf.continued, isFalse);
    });

    test('a fence an item opened goes on in the block after it', () {
      final blocks = _read('- ```js\n  a\n  ```\n- b');
      final opened = _leaves(blocks.first).single;
      expect(opened.code, isEmpty);
      expect(opened.closed, isFalse);
      final rest = _leaves(blocks[1]).single;
      expect(rest.kind, BlockKind.fencedCode);
      expect(rest.continued, isTrue);
      expect(rest.code, ['a']);
      expect(rest.closed, isTrue);
    });

    test('indented code loses four columns, a tab split', () {
      final leaf = _leaves(_read('para\n\n      a\n\tb').last).single;
      expect(leaf.code, ['  a', 'b']);
    });
  });

  group('containers', () {
    test('a quote holds the list inside it', () {
      final block = _read('> - a\n> - b').single;
      final quote = block.node as QuoteNode;
      expect((quote.children.single as ListNode).items, hasLength(2));
    });

    test("a callout's body is what follows its title", () {
      final block = _read('> [!tip] Mind\n> body').single;
      final quote = block.node as QuoteNode;
      expect(quote.callout?.title, 'Mind');
      expect(_leaves(block).single.inline!.text, 'body');
    });
  });

  test('plain text, as a passage is quoted', () {
    expect(
      _read(r'- [ ] a **b** $x^2$ [[Note|alias]] #tag').single.plainText,
      'a b x^2 alias #tag',
    );
    expect(_read('> q\n>\n> r').single.plainText, 'q r');
  });

  test('a block is read once until the buffer changes', () {
    final buffer = SourceBuffer.fromText('a\n\nb');
    final parser = ReadParser();
    final blocks = BlockScanner(buffer).index.blocks;
    parser
      ..of(blocks.first, buffer)
      ..of(blocks.first, buffer);
    expect(parser.parseCount, 1);
    buffer.replaceRange(0, 1, 'c');
    parser.of(blocks.first, buffer);
    expect(parser.parseCount, 2);
  });
}
