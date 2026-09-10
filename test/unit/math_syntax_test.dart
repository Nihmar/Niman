// T-M2-05 M-05-1: the math syntaxes — display blocks (top level, lists,
// blockquotes), inline splitting with the shared rules, frontmatter strip.
import 'dart:convert';

import 'package:copist/src/preview/math_syntax.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

List<md.Node> _parse(String text) {
  final document = md.Document(
    blockSyntaxes: <md.BlockSyntax>[
      const MathBlockSyntax(),
      ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
    ],
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  return splitInlineMath(document.parseLines(text.split('\n')));
}

List<md.Node> _mathblocks(List<md.Node> nodes) {
  final out = <md.Node>[];
  void walk(md.Node node) {
    if (node is md.Element && node.tag == 'mathblock') out.add(node);
    if (node is md.Element && node.children != null) {
      node.children!.forEach(walk);
    }
  }

  nodes.forEach(walk);
  return out;
}

List<md.Node> _maths(List<md.Node> nodes) {
  final out = <md.Node>[];
  void walk(md.Node node) {
    if (node is md.Element && node.tag == 'math') out.add(node);
    if (node is md.Element && node.children != null) {
      node.children!.forEach(walk);
    }
  }

  nodes.forEach(walk);
  return out;
}

String _latex(md.Element e) => e.attributes['latex']!;

void main() {
  group('MathBlockSyntax', () {
    test('single-line display math', () {
      final nodes = _parse('before\n\$\$x^2\$\$\nafter');
      final blocks = _mathblocks(nodes);
      expect(blocks, hasLength(1));
      expect(_latex(blocks.first as md.Element), 'x^2');
      expect((blocks.first as md.Element).attributes['display'], 'true');
    });

    test('multi-line display math consumes to the close', () {
      final nodes = _parse('\$\$\nx^2\n+ y^2\n\$\$\nplain');
      final blocks = _mathblocks(nodes);
      expect(blocks, hasLength(1));
      expect(_latex(blocks.first as md.Element), 'x^2\n+ y^2');
    });

    test('unterminated display math runs to EOF (tokenizer parity)', () {
      final blocks = _mathblocks(_parse('\$\$\nx^2\nno close'));
      expect(blocks, hasLength(1));
      expect(_latex(blocks.first as md.Element), 'x^2\nno close');
    });

    test('display math inside a list item', () {
      final nodes = _parse('- item\n\n  \$\$\n  x\n  \$\$');
      final blocks = _mathblocks(nodes);
      expect(blocks, hasLength(1));
      expect(_latex(blocks.first as md.Element), 'x');
    });

    test('display math inside a blockquote', () {
      final nodes = _parse('> a quote\n> \$\$\n> y\n> \$\$');
      final blocks = _mathblocks(nodes);
      expect(blocks, hasLength(1));
      expect(_latex(blocks.first as md.Element), 'y');
    });

    test('inline dollar math is not a display block', () {
      expect(_parse(r'x $y$ z'), isNotEmpty);
      expect(_mathblocks(_parse(r'$x^2$')), isEmpty);
    });
  });

  group('splitInlineMath', () {
    test('inline math inside a paragraph becomes a math element', () {
      final nodes = _parse(r'the $x^2$ case');
      final maths = _maths(nodes);
      expect(maths, hasLength(1));
      expect(_latex(maths.first as md.Element), 'x^2');
      expect((maths.first as md.Element).attributes['display'], 'false');
    });

    test(r'\$ escaped dollars stay plain text', () {
      final nodes = _parse(r'this is \$5 only');
      expect(_maths(nodes), isEmpty);
    });

    test(
      r'$n$ digit math is extracted (the corpus uses $1$, $2 \times 2$)',
      () {
        final nodes = _parse(r'ha dimensione $1$ e $2 \times 2$');
        final maths = _maths(nodes);
        expect(maths, hasLength(2));
        expect(_latex(maths[0] as md.Element), '1');
        expect(_latex(maths[1] as md.Element), r'2 \times 2');
      },
    );

    test('inline code and fenced code keep their dollars', () {
      final nodes = _parse('with `\$x\$` and\n\n```\n\$y\$\n```');
      expect(_maths(nodes), isEmpty);
    });

    test('multiple spans in one paragraph split in order', () {
      final nodes = _parse(r'$a$ and $b$');
      final maths = _maths(nodes);
      expect(maths, hasLength(2));
      expect(_latex(maths[0] as md.Element), 'a');
      expect(_latex(maths[1] as md.Element), 'b');
    });

    test('escaped dollar is not math', () {
      final nodes = _parse(r'this is \$5 not math');
      expect(_maths(nodes), isEmpty);
    });
  });

  group('stripFrontmatter', () {
    test('strips a leading YAML block', () {
      expect(stripFrontmatter('---\ntitle: Note\n---\n# Body'), '# Body');
    });

    test('strips until a ... close', () {
      expect(stripFrontmatter('---\ntitle: Note\n...\nbody'), 'body');
    });

    test('unterminated frontmatter strips everything', () {
      expect(stripFrontmatter('---\ntitle: Note'), '');
    });

    test('no frontmatter leaves the text untouched', () {
      expect(stripFrontmatter('# Head'), '# Head');
    });

    // The scroll map answers in the note's line numbers, and the editor
    // beside it counts the frontmatter (device report, 2026-09-10).
    test('the stripped lines are counted', () {
      expect(frontmatterLines('---\ntitle: Note\n---\n# Body'), 3);
      expect(frontmatterLines('---\ntitle: Note\n...\nbody'), 3);
      expect(frontmatterLines('# Head'), 0);
      expect(frontmatterLines(''), 0);
      // Unterminated: every line is metadata.
      expect(frontmatterLines('---\ntitle: Note'), 2);
    });

    test('the count and the strip agree', () {
      const text = '---\nid: 1\ntitle: Note\n---\n\n# Body\n\ntext';
      final lines = const LineSplitter().convert(text);
      final kept = const LineSplitter().convert(stripFrontmatter(text));
      expect(frontmatterLines(text) + kept.length, lines.length);
    });
  });
}
