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

```dart
void main() { print('hi'); }
```

<table><tr><td>cell</td></tr></table>

$$
x^2 + y^2
$$

A reference[^one] and another[^two], twice[^one].

[^one]: the first note

[^two]: the second note

![[image.png]]
''';

void main() {
  group('parseBlocks', () {
    test('leaves the inlines raw', () {
      final blocks = parseBlocks(_note);
      // The paragraph's inlines are still an UnparsedContent leaf.
      final para = _topLevel(blocks, 'p');
      expect(para.children, isNotNull);
      expect(para.children!.single, isA<md.UnparsedContent>());
      // The display math is block-phase: it is already there, before any
      // inlines run.
      expect(
        blocks.any((node) => node is md.Element && node.tag == 'mathblock'),
        isTrue,
      );
    });

    test('footnote definitions gather at the end as one block', () {
      final blocks = parseBlocks(_note);
      // No definition left in the body.
      expect(
        blocks.where(
          (node) =>
              node is md.Element &&
              node.tag == 'li' &&
              node.footnoteLabel != null,
        ),
        isEmpty,
      );
      // The section is the last block, with the two definitions.
      final section = blocks.last as md.Element;
      expect(section.tag, 'section');
      final list = section.children!.single as md.Element;
      expect(list.tag, 'ol');
      expect(list.children, hasLength(2));
    });

    test('a definition nothing references is dropped, matching the '
        'whole-document parse', () {
      const source = 'text\n\n[^ghost]: note\n\nlast\n';
      final blocks = parseBlocks(source);
      final full = parseMarkdownDocument(source);
      // The unreferenced definition does not survive either parse: two
      // paragraphs, no definition block.
      expect(blocks.length, full.length);
      expect(
        blocks.where(
          (node) =>
              node is md.Element &&
              node.tag == 'li' &&
              node.footnoteLabel != null,
        ),
        isEmpty,
      );
    });
  });

  group('withInlines', () {
    test('matches the whole-document parse, block for block', () {
      final blocks = parseBlocks(_note);
      final full = parseMarkdownDocument(_note);
      expect(
        blocks.length,
        full.length,
        reason: 'the two parses must see the same top-level blocks',
      );
      final doc = makeDocument();
      prepareInlines(doc, blocks);
      for (var i = 0; i < blocks.length; i++) {
        expect(
          _describeList(withInlines(doc, blocks[i])),
          _describeList([full[i]]),
          reason:
              'block $i diverges from the whole-document parse:\n'
              '${_describeList(withInlines(doc, blocks[i]))}\nvs\n'
              '${_describeList([full[i]])}',
        );
      }
    });
  });
}

md.Element _topLevel(List<md.Node> blocks, String tag) {
  for (final block in blocks) {
    if (block is md.Element && block.tag == tag) return block;
  }
  throw StateError('no top-level $tag in the fixture');
}

String _describeList(List<md.Node> nodes) => nodes.map(_describe).join('|');

/// The node, in a comparable form (the AST is mutable, so compare shapes,
/// not instances).
String _describe(md.Node node) {
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
