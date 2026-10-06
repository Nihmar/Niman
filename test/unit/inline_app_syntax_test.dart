// The app's own inline syntax in our parser (docs/dev/block-tree.md, phase
// 4): math, wikilinks and embeds, tags, `==highlight==` and the HTML style
// tags, read in the masker's order, CommonMark's constructs around them.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/inline/inline_node.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';

/// [text]'s nodes as `kind[start,end)`, children in braces.
String _shape(String text, {bool appSyntax = true}) {
  String of(List<InlineNode> nodes) => nodes
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
              MathNode(:final display) => display ? 'display' : 'math',
              WikiLinkNode(:final embed) => embed ? 'embed' : 'wiki',
              TagNode() => 'tag',
              HighlightNode() => 'mark',
              StyledNode(:final tag) => tag,
            }}[${node.start},${node.end})'
            '${node is InlineContainer ? '{${of(node.children)}}' : ''}',
      )
      .join(' ');
  return of(InlineParser(text, appSyntax: appSyntax).parse());
}

void main() {
  group('math', () {
    test('a formula is one node, its underscores no emphasis', () {
      expect(
        _shape(r'$a_1 + b_1$ and _x_'),
        'math[0,11) text[11,16) '
        'em[16,19){text[17,18)}',
      );
      final math = InlineParser(r'$a_1$').parse().single as MathNode;
      expect(math.tex, 'a_1');
    });

    test('display math in a line is display', () {
      expect(_shape(r'$$x$$ y'), 'display[0,5) text[5,7)');
    });

    test('an escaped dollar and a price are text', () {
      expect(_shape(r'\$5'), 'text[0,2) text[2,3)');
      expect(_shape(r'20$ + 0,10$/Kg'), 'text[0,14)');
      expect(_shape(r'costs $5 and $10'), 'text[0,16)');
    });

    test('a code span and raw HTML hold their dollars', () {
      expect(_shape(r'`$x$`'), 'code[0,5)');
      expect(_shape(r'<a title="$x$">'), 'html[0,15)');
    });
  });

  group('wikilinks and tags', () {
    test('a wikilink and an embed', () {
      expect(
        _shape('see [[Note|alias]] and ![[pic.png]]'),
        'text[0,4) wiki[4,18) text[18,23) embed[23,35)',
      );
      final nodes = InlineParser('[[Note|alias]]').parse();
      expect((nodes.single as WikiLinkNode).inner, 'Note|alias');
    });

    test('a tag, and a hash inside a word', () {
      expect(_shape('#città and a#b'), 'tag[0,6) text[6,14)');
    });
  });

  group('highlight and style tags', () {
    test('a highlight holds inline text', () {
      expect(
        _shape('==hi== and ==*x*=='),
        'mark[0,6){text[2,4)} text[6,11) mark[11,18){em[13,16){text[14,15)}}',
      );
    });

    test('a spaced pair of equals signs is a comparison', () {
      expect(_shape('a == b == c'), 'text[0,11)');
    });

    test('an underline holds inline text', () {
      expect(_shape('<u>**x**</u>'), 'u[0,12){strong[3,8){text[5,6)}}');
    });

    test('a style tag with no closing one on its line is HTML', () {
      expect(
        _shape('<u>x\ny</u>'),
        'html[0,3) text[3,4) soft[4,5) '
        'text[5,6) html[6,10)',
      );
    });
  });

  test('without the app syntax, all of it is CommonMark text', () {
    expect(_shape(r'$x$ [[a]] #t ==h==', appSyntax: false), 'text[0,18)');
  });
}
