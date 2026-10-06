// Where a block's lines stand in the containers around them: the prefixes
// the tree reads a container's content past, and `live` puts a line's marks
// by — and the note's definitions, which no block resolves on its own.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The lines of the first leaf of block [index] of [document], as the tree
/// reads them in its container, joined.
String _text(String document, int index) {
  final buffer = SourceBuffer.fromText(document);
  final block = BlockScanner(buffer).index.blocks[index];
  var node = BlockTree.ofBlock(block, buffer);
  while (node is! LeafNode) {
    node = switch (node) {
      QuoteNode(:final children) ||
      ItemNode(:final children) ||
      FootnoteNode(:final children) => children.first,
      ListNode(:final items) => items.first,
      LeafNode() => node,
    };
  }
  return [
    for (final span in node.lines)
      buffer.lineAt(span.line).substring(span.start, span.end),
  ].join('\n');
}

void main() {
  group('a block in a list item, read in its container', () {
    test('a quote in an item has its marks taken off past the item', () {
      // `    > b` is a quote in the item (content at 2): its `>` stands two
      // spaces past the item, more than three from the margin.
      expect(_text('- a\n    > b', 1), 'b');
      expect(_text('  1. a\n       > b\n       > c', 1), 'b\nc');
    });

    test('a paragraph and a heading deep in an item lose its indent', () {
      expect(_text('- A\n  - B\n\n    para of B', 3), 'para of B');
      // Three spaces past the item's content: still a heading.
      expect(_text('- a\n\n     # deep', 2), '   # deep');
    });

    test('a lazy line keeps what the item did not take', () {
      // `    ---` is four spaces into an item of five: the item's lazily,
      // so it stands as it is — the quote's paragraph goes on, and is not
      // headed by an underline.
      expect(_text('   - w\n      > w\n    ---', 1), 'w\n    ---');
      // Lazy for the outer item, and so for the inner one, however far in
      // it stands: the inner item's paragraph goes on with it, as
      // `cmark-gfm` reads it — no quote, and no indent taken off.
      expect(_text('  2) w\n      - w\n    > w', 1), 'w\n    > w');
    });

    test('a block outside every item keeps its text', () {
      expect(_text('    code', 0), '    code');
      expect(_text('> a\n    > b', 0), 'a\n    > b');
    });
  });

  test("a hand-built item's lines lose its marker's indent and its column", () {
    // A block built without the scanner's state cannot be read in its
    // parent's coordinates: an item three levels down stands four spaces
    // in, which alone is an indented code block.
    const raw = '  - a **bold** word\n    and more';
    const block = Block(
      kind: BlockKind.listItem,
      startLine: 0,
      endLine: 2,
      listDepth: 1,
    );
    final lines = raw.split('\n');
    expect(
      [
        for (var at = 0; at < lines.length; at++)
          lines[at].substring(
            BlockParser.linePrefixLength(
              block,
              lines[at],
              BlockParser.listStripOf(block, lines.first, at, lines[at]),
            ),
          ),
      ],
      ['- a **bold** word', 'and more'],
    );
  });

  group("the scope's definitions, as our inline parser reads them", () {
    DocumentScope scopeOf(String text) =>
        DocumentScope.scan(SourceBuffer.fromText(text), 0);

    test('a definition over three lines, by its normalized label', () {
      final scope = scopeOf('[Foo  Bar]:\n</a b>\n"the title"\n\ntext');
      expect(scope.references, {
        'FOO BAR': (destination: '/a b', title: 'the title'),
      });
    });

    test('escapes and entities in a destination are read', () {
      final scope = scopeOf(r'[a]: /x\_y&amp;z');
      expect(scope.references['A']?.destination, '/x_y&z');
    });

    test('the first definition of a label wins', () {
      final scope = scopeOf('[a]: /one\n[A]: /two');
      expect(scope.references['A']?.destination, '/one');
    });

    test('a line that only starts like one is none', () {
      expect(scopeOf('[a link](u) and text').references, isEmpty);
    });

    test('the footnotes defined, by their normalized label', () {
      expect(scopeOf('[^Note]: body').footnoteKeys, {'NOTE'});
    });
  });
}
