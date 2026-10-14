// #844: the blocks of a note that end with a ` ^id`, enumerated line by line
// the way the outline enumerates headings.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/markdown/buffer_block_anchors.dart';
import 'package:niman/src/markdown/source_buffer.dart';

List<(String, int)> _anchors(String text) => [
  for (final a in blockAnchorsOfText(text)) (a.id, a.line),
];

void main() {
  group('trailingBlockId', () {
    test('a space, a caret and letters, digits or dashes at the end', () {
      expect(trailingBlockId('A paragraph ^37066d'), '37066d');
      expect(trailingBlockId('A paragraph ^a-b-9  '), 'a-b-9');
      expect(trailingBlockId('^alone'), 'alone');
      expect(trailingBlockId('- item\t^Item-1'), 'Item-1');
    });

    test('not in the middle, not without the space, not other characters', () {
      expect(trailingBlockId('a ^id and more'), isNull);
      expect(trailingBlockId('x^id'), isNull);
      expect(trailingBlockId('a ^i d'), isNull);
      expect(trailingBlockId('a ^ünï'), isNull);
      expect(trailingBlockId('plain'), isNull);
      expect(trailingBlockId('a ^'), isNull);
    });

    test('withoutTrailingBlockId drops the id and the space before it', () {
      expect(withoutTrailingBlockId('A paragraph ^37066d'), 'A paragraph');
      expect(withoutTrailingBlockId('^alone'), '');
      expect(withoutTrailingBlockId('no id here'), 'no id here');
    });
  });

  group('blockAnchorsOfText', () {
    test('a paragraph ends with its id: the anchor is the paragraph', () {
      expect(_anchors('First\n\nSecond line\nruns on ^second\n\nThird'), [
        ('second', 2),
      ], reason: 'the line the paragraph starts on');
    });

    test('the line ending with the id, for a one-line block', () {
      final anchors = blockAnchorsOfText('Intro ^37066d\n');
      expect(anchors.single.id, '37066d');
      expect(anchors.single.line, 0);
      expect(anchors.single.excerpt, 'Intro');
    });

    test('each list item carries its own id', () {
      expect(_anchors('- one ^first\n- two\n- three ^third\n'), [
        ('first', 0),
        ('third', 2),
      ]);
    });

    test('an item of a task or numbered list, markers off the excerpt', () {
      final anchors = blockAnchorsOfText('- [ ] buy milk ^milk\n1. second ^n2');
      expect(anchors.map((a) => a.excerpt), ['buy milk', 'second']);
    });

    test('an id in the middle of a paragraph names nothing', () {
      expect(_anchors('first ^x\nsecond\n'), isEmpty);
      expect(_anchors('first\nsecond ^x\nmore\n'), isEmpty);
    });

    test('a quote carries its id at the end of its last line', () {
      expect(_anchors('> first\n> second ^deep\n'), [('deep', 0)]);
      expect(blockAnchorsOfText('> first\n\n^q').single.excerpt, 'first');
    });

    test('an id in the middle of a quote names nothing', () {
      expect(_anchors('> first ^q\n> second\n'), isEmpty);
    });

    test('a table carries it below too; so does a whole list', () {
      expect(_anchors('| a | b |\n| - | - |\n| 1 | 2 |\n\n^tbl\n'), [
        ('tbl', 0),
      ]);
      expect(_anchors('- a\n- b\n\n^whole-list\n'), [('whole-list', 0)]);
    });

    test('a heading can carry one', () {
      expect(_anchors('## Title ^head\n\ntext'), [('head', 0)]);
    });

    test('an id in a fence, a formula or the frontmatter is not one', () {
      const text =
          '---\ntitle: x ^fm\n---\n'
          '```\ncode ^fence\n```\n'
          r'$$'
          '\nmath ^math\n'
          r'$$'
          '\nreal ^real\n';
      expect(_anchors(text).map((a) => a.$1), ['real']);
    });

    test('an own-line id below a fence names nothing above it', () {
      expect(_anchors('para\n\n```\ncode\n```\n\n^after\n'), isEmpty);
    });

    test('an own-line id below another own-line id names nothing (#915)', () {
      expect(_anchors('- item\n\n^a\n\n^b\n'), [('a', 0)]);
      expect(_anchors('- item\n\n^a\n\n^b\n\n^c\n'), [('a', 0)]);
      expect(_anchors('^a\n\n^b\n'), isEmpty);
    });

    test('a block between two own-line ids is named by the second', () {
      expect(_anchors('> one\n\n^a\n\n> two\n\n^b\n'), [('a', 0), ('b', 4)]);
    });

    test('an id in indented code is not an anchor', () {
      expect(_anchors('    indented ^code\n'), isEmpty);
      expect(_anchors('\tindented ^code\n'), isEmpty);
      expect(_anchors('para\n\n    indented ^code\n\n^own\n'), isEmpty);
    });

    test('an escaped caret is not an id', () {
      expect(trailingBlockId(r'text \^id'), isNull);
      expect(
        _anchors(
          'text '
          r'\^id'
          '\n',
        ),
        isEmpty,
      );
    });

    test('the first block that carries an id owns it', () {
      expect(_anchors('a ^same\n\nb ^same\n').map((a) => a.$2), [0]);
    });

    test('a note without a caret has none, and costs no walk', () {
      expect(blockAnchorsOfText('# H\n\nplain\n'), isEmpty);
    });

    test('text then a heading: each its own block', () {
      expect(_anchors('# H\ntext ^t\n'), [('t', 1)]);
    });
  });

  group('BufferBlockAnchors', () {
    test(
      'reads a buffer, keeps the answer per revision, reads again',
      () async {
        final buffer = SourceBuffer.fromText('a ^one\n\nb\n');
        final anchors = BufferBlockAnchors(() => buffer);

        final first = await anchors.read();
        expect(first.map((a) => a.id), ['one']);
        expect(identical(await anchors.read(), first), isTrue);

        buffer.insert(buffer.length, 'c ^two\n');
        final second = await anchors.read();
        expect(second.map((a) => a.id), ['one', 'two']);
      },
    );

    test('a long note is walked in slices and answers the same', () async {
      final text = StringBuffer();
      for (var i = 0; i < 25000; i++) {
        text
          ..writeln(i % 5000 == 0 ? 'line $i ^b$i' : 'line $i')
          ..writeln();
      }
      final buffer = SourceBuffer.fromText(text.toString());
      expect(buffer.length, greaterThan(BufferBlockAnchors.sliceAbove));

      final anchors = await BufferBlockAnchors(() => buffer).read();

      expect(anchors.map((a) => a.id), [
        'b0',
        'b5000',
        'b10000',
        'b15000',
        'b20000',
      ]);
      expect(anchors.map((a) => a.line), [0, 10000, 20000, 30000, 40000]);
    });
  });
}
