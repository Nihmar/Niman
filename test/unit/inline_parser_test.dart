// Our inline parser (docs/dev/block-tree.md): what the spec examples do not
// check — where each node stands in the leaf's text.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';

/// [nodes] as `kind[start,end)`, children in braces.
String _shape(List<InlineNode> nodes) => nodes
    .map(
      (node) =>
          '${switch (node) {
            TextNode() => 'text',
            CodeNode() => 'code',
            EmphasisNode() => 'em',
            StrongNode() => 'strong',
            StrikethroughNode() => 'del',
            LinkNode() => 'a',
            ImageNode() => 'img',
            HtmlNode() => 'html',
            SoftBreakNode() => 'soft',
            HardBreakNode() => 'hard',
            FootnoteRefNode() => 'fn',
            MathNode() => 'math',
            WikiLinkNode() => 'wiki',
            TagNode() => 'tag',
            HighlightNode() => 'mark',
            StyledNode() => 'styled',
          }}[${node.start},${node.end})'
          '${node is InlineContainer ? '{${_shape(node.children)}}' : ''}',
    )
    .join(' ');

void main() {
  test('emphasis spans its delimiters, its text inside them', () {
    expect(
      _shape(InlineParser('a *b* **c**').parse()),
      'text[0,2) em[2,5){text[3,4)} text[5,6) strong[6,11){text[8,9)}',
    );
  });

  test('a link spans its text and destination', () {
    expect(
      _shape(InlineParser('x [a *b*](/u) y').parse()),
      'text[0,2) a[2,13){text[3,5) em[5,8){text[6,7)}} text[13,15)',
    );
  });

  test('a code span and a hard break keep their source', () {
    expect(
      _shape(InlineParser('`c`  \nd').parse()),
      'code[0,3) hard[3,6) text[6,7)',
    );
  });

  test('an escaped character reads as itself over two characters', () {
    final nodes = InlineParser(r'\*a').parse();
    expect(_shape(nodes), 'text[0,2) text[2,3)');
    expect((nodes.first as TextNode).text, '*');
  });

  test('a bare URL is a link over its own characters', () {
    expect(
      _shape(InlineParser('see www.example.com.').parse()),
      'text[0,4) a[4,19){text[4,19)} text[19,20)',
    );
  });
}
