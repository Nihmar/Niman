import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_node.dart';
import 'package:niman/src/markdown/block_tree.dart';

/// [nodes] written out: `Q[…]` a quote, `ul[…]` / `ol3[…]` a list (and the
/// number it starts at), `-[…]` an item by its delimiter, and a leaf as its
/// kind and the text of the note its spans cover.
String _shape(String text, List<BlockNode> nodes) {
  final lines = text.split('\n');
  String spanned(List<SourceSpan> spans) =>
      spans.map((s) => lines[s.line].substring(s.start, s.end)).join('/');
  String of(BlockNode node) => switch (node) {
    QuoteNode(:final children) => 'Q[${children.map(of).join(' ')}]',
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

  test("a tab's columns past an item's indent count toward the next", () {
    // The outer item takes two of the tab's four columns; the other two
    // put `---` inside the inner item, as the underline of its text.
    expect(_treeOf('- - w\n\t---'), 'ul[-[ul[-[heading"w/---"]]]]');
  });
}
