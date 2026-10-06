import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/block_tree.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// [nodes] written out: `Q[…]` a quote, `ul[…]` / `ol3[…]` a list (and the
/// number it starts at), `-[…]` an item by its delimiter, and a leaf as its
/// kind and the text of the note its spans cover.
String _shape(String text, List<BlockNode> nodes) {
  final lines = text.split('\n');
  String spanned(List<SourceSpan> spans) =>
      spans.map((s) => lines[s.line].substring(s.start, s.end)).join('/');
  String of(BlockNode node) => switch (node) {
    QuoteNode(:final children, :final callout) =>
      '${callout == null ? 'Q' : 'C:${callout.type}'}'
          '[${children.map(of).join(' ')}]',
    FootnoteNode(:final label, :final children) =>
      'F$label[${children.map(of).join(' ')}]',
    ListNode(:final items, :final ordered, :final start) =>
      '${ordered ? 'ol$start' : 'ul'}[${items.map(of).join(' ')}]',
    ItemNode(:final delimiter, :final children) =>
      '$delimiter[${children.map(of).join(' ')}]',
    LeafNode(:final kind, lines: final spans) =>
      '${kind.name}"${spanned(spans)}"',
  };
  return nodes.map(of).join(' ');
}

String _treeOf(String text) => _shape(text, BlockTree.of(text));

/// The node of each block the scanner makes of [text], on its own.
List<String> _blocksOf(String text) {
  final buffer = SourceBuffer.fromText(text);
  return [
    for (final block in BlockScanner(buffer).index.blocks)
      _shape(text, [BlockTree.ofBlock(block, buffer)]),
  ];
}

void main() {
  test('items of one delimiter are one list, another starts a list', () {
    expect(
      _treeOf('- a\n- b\n+ c'),
      'ul[-[paragraph"a"] -[paragraph"b"]] ul[+[paragraph"c"]]',
    );
  });

  test('an ordered list starts at the number it was written with', () {
    expect(_treeOf('3. a\n4. b'), 'ol3[.[paragraph"a"] .[paragraph"b"]]');
  });

  test('a sublist on the marker line holds the blocks after it', () {
    // `- - a` is one block to the scanner; the inner item is found in the
    // outer one's content, and `    b` is in the inner item.
    expect(
      _treeOf('- - a\n\n    b'),
      'ul[-[ul[-[paragraph"a" blank"" paragraph"b"]]]]',
    );
  });

  test('a quote is read again inside its marks', () {
    expect(_treeOf('> a\n> > b'), 'Q[paragraph"a" Q[paragraph"b"]]');
  });

  test('a leaf maps each line to where it stands in the note', () {
    final nodes = BlockTree.of('- > x\n  > y');
    final list = nodes.single as ListNode;
    final quote = list.items.single.children.single as QuoteNode;
    final leaf = quote.children.single as LeafNode;
    expect(leaf.lines, [
      (line: 0, start: 4, end: 5),
      (line: 1, start: 4, end: 5),
    ]);
    expect(list.items.single.marker, (line: 0, start: 0, end: 1));
  });

  test('a fence after a marker runs on to its closing fence', () {
    expect(
      _treeOf('- ```js\n  code\n  ```\n- b'),
      'ul[-[fencedCode"```js/code/```"] -[paragraph"b"]]',
    );
  });

  test('a quote after a marker goes on over its own marks', () {
    expect(_treeOf('- > x\n  > y'), 'ul[-[Q[paragraph"x/y"]]]');
  });

  test('a blank line ends the quote a marker opened', () {
    expect(
      _treeOf('- > x\n\n  > y'),
      'ul[-[Q[paragraph"x"] blank"" Q[paragraph"y"]]]',
    );
  });

  test('a footnote definition holds its indented and lazy lines', () {
    expect(
      _treeOf('[^n]: a\n    b\nc\n\n    d\n\ne'),
      'Fn[paragraph"a/b/c" blank"" paragraph"d" blank""] paragraph"e"',
    );
  });

  test("a footnote's indent is four columns, a tab among them", () {
    // `cmark-gfm` counts columns, where the package wanted four spaces.
    expect(_treeOf('[^n]: a\n\n\tb'), 'Fn[paragraph"a" blank"" paragraph"b"]');
  });

  test('a line that interrupts no paragraph goes on with the footnote', () {
    // An ordered marker past 1 cannot interrupt a paragraph: the line is
    // the footnote's lazily, as `cmark-gfm` reads it. A bullet can, and
    // ends it.
    expect(_treeOf('[^n]: a\n2. b'), 'Fn[paragraph"a/2. b"]');
    expect(_treeOf('[^n]: a\n- b'), 'Fn[paragraph"a"] ul[-[paragraph"b"]]');
  });

  test('a footnote definition interrupts a paragraph and ends at a block', () {
    expect(
      _treeOf('p\n[^n]: a\n# h'),
      'paragraph"p" Fn[paragraph"a"] heading"# h"',
    );
  });

  test('a footnote definition ends the list before it', () {
    expect(_treeOf('- i\n[^n]: a'), 'ul[-[paragraph"i"]] Fn[paragraph"a"]');
  });

  test('the blocks in a footnote are read past its four spaces', () {
    expect(
      // Four spaces for the footnote, two for the item, four for code.
      _treeOf('[^n]:\n    - x\n\n          code'),
      'Fn[blank"" ul[-[paragraph"x" blank"" indentedCode"    code"]]]',
    );
  });

  test('a link definition leaves no paragraph open behind it', () {
    // After the definition, a tab-indented line is code and `2)` opens a
    // list, as neither could after paragraph text.
    expect(
      _treeOf('[r]: /u\n\tcode'),
      'paragraph"[r]: /u" indentedCode"\tcode"',
    );
    expect(
      _treeOf('[r]: /u\n2) item'),
      'paragraph"[r]: /u" ol2[)[paragraph"item"]]',
    );
    final nodes = BlockTree.of('[r]:\n/u\n"t"\ntext');
    expect((nodes.first as LeafNode).definition, isTrue);
    expect((nodes.first as LeafNode).lines, hasLength(3));
    expect((nodes.last as LeafNode).definition, isFalse);
  });

  test('a line like a definition that is none is paragraph text', () {
    final nodes = BlockTree.of('[a link](u) and text\n\tmore');
    expect(nodes, hasLength(1));
    expect((nodes.single as LeafNode).definition, isFalse);
  });

  test("a tab's columns past an item's indent count toward the next", () {
    // The outer item takes two of the tab's four columns; the other two
    // put `---` inside the inner item, as the underline of its text.
    expect(_treeOf('- - w\n\t---'), 'ul[-[ul[-[heading"w/---"]]]]');
  });

  group('a block on its own', () {
    test('an item is its marker and its content read again', () {
      expect(_blocksOf('- > q\n  > r\n- - a\n  b'), [
        '-[Q[paragraph"q"]]',
        'Q[paragraph"r"]',
        '-[ul[-[paragraph"a/b"]]]',
      ]);
    });

    test('a block in an item is read past its items', () {
      expect(_blocksOf('1. a\n\n   b\n   > c'), [
        '.[paragraph"a"]',
        'blank""',
        'paragraph"b"',
        'Q[paragraph"c"]',
      ]);
    });

    test('a quote holds the list in it', () {
      expect(_blocksOf('> - a\n>   b\n> - c'), [
        'Q[ul[-[paragraph"a/b"] -[paragraph"c"]]]',
      ]);
    });

    test('a leaf maps its lines to the note', () {
      final buffer = SourceBuffer.fromText('x\n\n- y\n\n  > z');
      final blocks = BlockScanner(buffer).index.blocks;
      final quote = BlockTree.ofBlock(blocks.last, buffer) as QuoteNode;
      expect((quote.children.single as LeafNode).lines, [
        (line: 4, start: 4, end: 5),
      ]);
    });
  });

  group('a callout', () {
    test('its title is its own, its body the lines after it', () {
      expect(
        _treeOf('> [!tip] Title\n>     code\n> text'),
        'C:tip[indentedCode"    code" paragraph"text"]',
      );
    });

    test('a callout with no body, and one inside a quote', () {
      expect(_treeOf('> [!note]'), 'C:note[]');
      expect(_treeOf('> > [!warning]- t\n> > x'), 'Q[C:warning[paragraph"x"]]');
    });

    test('without the app syntax it is a quote', () {
      expect(
        _shape('> [!tip] T', BlockTree.of('> [!tip] T', appSyntax: false)),
        'Q[paragraph"[!tip] T"]',
      );
    });
  });
}
