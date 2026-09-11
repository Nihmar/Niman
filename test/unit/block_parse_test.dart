// block_parse: the preview's two-phase parse — the block phase is cheap,
// and a block's inlined form is exactly what the old whole-document parse
// produced for that block (the WYSIWYG codec's parse).
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:niman/src/editor/wysiwyg/markdown_parse.dart';
import 'package:niman/src/preview/block_parse.dart';

/// A note with everything the preview's parse turns into blocks: prose,
/// inlines, math (both kinds), lists, a GFM table, an HTML table, a
/// footnote, an embed and a wikilink.
const String _note = r'''
# Heading

Paragraph with **bold**, *italic*, `code`, [link](https://e.com), $x^2$ and a [[wiki link]].

- item one
- item two

1. first
2. second

> quoted

| A | B |
| --- | --- |
| 1 | 2 |

```
x = 1;
```

$$
x^2 + y^2
$$

<table><tr><td>h</td></tr></table>

Note[^one].

[^one]: the first note

![[image.png]]
''';

void main() {
  test('parseBlocks leaves the inlines raw', () {
    final blocks = parseBlocks(_note);
    expect(blocks, isNotEmpty);
    // The paragraph's text is still UnparsedContent (no inline parse ran):
    // the inline phase is per-block, on demand (withInlines).
    final para =
        blocks.firstWhere((n) => n is md.Element && n.tag == 'p') as md.Element;
    final text = para.children!.firstWhere((c) => c is md.UnparsedContent);
    expect(text, isA<md.UnparsedContent>());
  });

  test('trailing punctuation glues to the math element, '
      'so it can\'t wrap away from the formula', () {
    const source = r'aaaa $x^2$. bbbb cccc';
    final blocks = parseBlocks(source);
    final doc = makeDocument();
    final parsed = withInlines(doc, blocks.first);
    final p = parsed.first as md.Element;
    final kids = p.children!;
    // [Text('aaaa '), math(trailing '. '), Text('bbbb cccc')].
    expect(kids, hasLength(3));
    final math = kids[1] as md.Element;
    expect(math.tag, 'math');
    expect(math.attributes[mathTrailingAttribute], '. ');
    expect((kids[2] as md.Text).text, 'bbbb cccc');
  });

  test('a comma right after the math glues too (no space to move)', () {
    const source = r'aaaa $x^2$,bbbb cccc';
    final blocks = parseBlocks(source);
    final doc = makeDocument();
    final parsed = withInlines(doc, blocks.first);
    final p = parsed.first as md.Element;
    final kids = p.children!;
    // The comma moves into the math as well — with no space in between,
    // the line layout can't split it from the formula anyway, but keeping
    // it inside the atomic span is the same contract.
    final math = kids[kids.length - 2] as md.Element;
    expect(math.attributes[mathTrailingAttribute], ',');
    expect((kids.last as md.Text).text, 'bbbb cccc');
  });

  test('withInlines matches the whole-document parse, block for block', () {
    final blocks = parseBlocks(_note);
    final full = parseMarkdownDocument(_note);
    expect(blocks.length, full.length);
    final doc = makeDocument();
    prepareInlines(doc, blocks);
    for (var i = 0; i < blocks.length; i++) {
      expect(
        _describe(withInlines(doc, blocks[i])),
        _describe(full[i]),
        reason:
            'block $i:\n'
            '  mine:    ${_describe(withInlines(doc, blocks[i]))}\n'
            '  full:    ${_describe([full[i]])}',
      );
    }
  });
}

String _describe(dynamic node) {
  if (node is List) {
    return node.map(_describe).join('|');
  }
  node = node as md.Node;
  if (node is md.Text) return 'T:${node.text}';
  if (node is md.UnparsedContent) return 'U:${node.textContent}';
  if (node is md.Element) {
    final attrs = node.attributes.isEmpty
        ? ''
        : '[${node.attributes.entries.map((kv) => '${kv.key}=${kv.value}').join(', ')}]';
    final kids = node.children;
    final children = kids == null ? '' : '<${kids.map(_describe).join(' ')}>';
    return '${node.tag}$attrs$children';
  }
  return '?:${node.runtimeType}';
}
