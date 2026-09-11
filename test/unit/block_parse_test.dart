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

  test('math followed by punctuation matches the whole-document parse', () {
    // No preview-only transform may touch the nodes: the inline phase must
    // produce exactly what the codec's full parse produces.
    const source = r'Visto che $x$ vale, e $y$. Infine $z$.';
    final phase = parseBlockPhase(source);
    final full = parseMarkdownDocument(source);
    expect(phase.nodes.length, full.length);
    final doc = makeDocument();
    prepareInlines(doc, phase);
    for (var i = 0; i < phase.nodes.length; i++) {
      expect(
        _describe(withInlines(doc, phase.nodes[i])),
        _describe(full[i]),
        reason: 'block $i',
      );
    }
  });

  test('withInlines matches the whole-document parse, block for block', () {
    final phase = parseBlockPhase(_note);
    final blocks = phase.nodes;
    final full = parseMarkdownDocument(_note);
    expect(blocks.length, full.length);
    final doc = makeDocument();
    prepareInlines(doc, phase);
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

  test('reference-style links resolve against the block-phase definitions', () {
    const source =
        '[hello][ref] and ![alt][img] and [shortcut]\n'
        '\n'
        '[ref]: https://example.com\n'
        '[img]: pic.png\n'
        '[shortcut]: https://shortcut.example\n';
    final phase = parseBlockPhase(source);
    final full = parseMarkdownDocument(source);
    // The definitions never become blocks, but they travel with the phase.
    expect(phase.linkReferences['ref']?.destination, 'https://example.com');
    expect(phase.nodes.length, full.length);
    final doc = makeDocument();
    prepareInlines(doc, phase);
    for (var i = 0; i < phase.nodes.length; i++) {
      expect(
        _describe(withInlines(doc, phase.nodes[i])),
        _describe(full[i]),
        reason: 'block $i',
      );
    }
  });

  test('a footnote reference inside a code span stays literal text', () {
    const source = 'Use `[^a]` here.\n\n[^a]: real note\n';
    final full = parseMarkdownDocument(source);
    // The full parse drops the unreferenced definition: one block, no
    // footnotes section.
    expect(full, hasLength(1));
    final phase = parseBlockPhase(source);
    expect(phase.nodes, hasLength(1));
    final doc = makeDocument();
    prepareInlines(doc, phase);
    expect(
      _describe(withInlines(doc, phase.nodes.first)),
      _describe(full.first),
    );
  });

  test('a footnote referenced from another definition is kept', () {
    const source = 'Text[^a].\n\n[^a]: see [^b]\n\n[^b]: the bee\n';
    final full = parseMarkdownDocument(source);
    final phase = parseBlockPhase(source);
    expect(phase.nodes.length, full.length);
    final doc = makeDocument();
    prepareInlines(doc, phase);
    for (var i = 0; i < phase.nodes.length; i++) {
      expect(
        _describe(withInlines(doc, phase.nodes[i])),
        _describe(full[i]),
        reason: 'block $i',
      );
    }
  });
}

String _describe(dynamic node) {
  if (node is List) {
    return node.map(_describe).join('|');
  }
  final item = node as md.Node;
  if (item is md.Text) return 'T:${item.text}';
  if (item is md.UnparsedContent) return 'U:${item.textContent}';
  if (item is md.Element) {
    final pairs = item.attributes.entries
        .map((kv) => '${kv.key}=${kv.value}')
        .join(', ');
    final attrs = item.attributes.isEmpty ? '' : '[$pairs]';
    final kids = item.children;
    final children = kids == null ? '' : '<${kids.map(_describe).join(' ')}>';
    return '${item.tag}$attrs$children';
  }
  return '?:${item.runtimeType}';
}
