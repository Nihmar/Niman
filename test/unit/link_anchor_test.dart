// #844 / #845: what the part after a link's `#` names inside a note, and the
// line it lands on — a heading, a path of headings read by level order, or a
// block by the id it ends with, matched literally.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/anchor.dart';
import 'package:niman/src/links/block_anchors.dart';

void main() {
  group('parseAnchor', () {
    test('an empty fragment names nothing', () {
      expect(parseAnchor(''), isNull);
      expect(parseAnchor('  '), isNull);
      expect(parseAnchor('#'), isNull);
    });

    test('^id is a block, matched literally and not slugified', () {
      final anchor = parseAnchor('^37066d');
      expect(anchor, isA<BlockIdAnchor>());
      expect((anchor! as BlockIdAnchor).id, '37066d');
      expect((parseAnchor('^My-Id')! as BlockIdAnchor).id, 'My-Id');
    });

    test('anything else is a heading path', () {
      expect((parseAnchor('Heading')! as HeadingAnchor).path, ['Heading']);
      expect((parseAnchor('A#B')! as HeadingAnchor).path, ['A', 'B']);
      expect((parseAnchor('^two words')! as HeadingAnchor).path, [
        '^two words',
      ], reason: 'a caret that is not an id is heading text');
    });
  });

  group('headingLineOf', () {
    // # Top
    // ## A
    // ### C
    // ## B
    // ## Details      (under Top, after B)
    // # Other
    // ## A
    // ## Details      (under Other)
    final outline = outlineOfText(
      '# Top\n## A\n### C\n## B\n## Details\n# Other\n## A\n## Details\n',
    );

    test('a single heading lands on the first one of that name', () {
      expect(headingLineOf(outline, HeadingAnchor(['A'])), 1);
      expect(headingLineOf(outline, HeadingAnchor(['Top'])), 0);
      expect(headingLineOf(outline, HeadingAnchor(['Details'])), 4);
    });

    test('A#C lands on C, B#C is not found', () {
      expect(headingLineOf(outline, HeadingAnchor(['A', 'C'])), 2);
      expect(
        headingLineOf(outline, HeadingAnchor(['B', 'C'])),
        isNull,
        reason: 'C is in the section of A, not of B',
      );
    });

    test('the parent tells a repeated heading apart', () {
      expect(headingLineOf(outline, HeadingAnchor(['Top', 'Details'])), 4);
      expect(headingLineOf(outline, HeadingAnchor(['Other', 'Details'])), 7);
      expect(
        headingLineOf(outline, HeadingAnchor(['A', 'Details'])),
        isNull,
        reason: 'the Details of Top is after B, outside the section of A',
      );
    });

    test('a path tries the next heading of its first level', () {
      // Two `## A`; only the second holds `### D`.
      final deep = outlineOfText('## A\n### X\n## A\n### D\n');
      expect(headingLineOf(deep, HeadingAnchor(['A', 'D'])), 3);
      expect(headingLineOf(deep, HeadingAnchor(['A', 'X'])), 1);
    });

    test('levels are matched by the shared slug', () {
      expect(headingLineOf(outline, HeadingAnchor(['top', 'a'])), 1);
      expect(headingLineOf(outline, HeadingAnchor(['TOP', 'c'])), 2);
    });

    test('a level may be any depth below its parent', () {
      expect(headingLineOf(outline, HeadingAnchor(['Top', 'C'])), 2);
    });

    test('a missing heading is not found', () {
      expect(headingLineOf(outline, HeadingAnchor(['Nope'])), isNull);
      expect(headingLineOf(outline, HeadingAnchor(const <String>[])), isNull);
      expect(headingLineOf(outline, HeadingAnchor(['A', 'Nope'])), isNull);
    });
  });

  // A `#` in a heading's own text is not always a level separator: the link
  // `[[Notes#Issue #12]]` names the heading "Issue #12" as the fragment
  // always did before paths existed. The path is tried first; when it names
  // no heading, the whole fragment is one heading.
  group('a heading whose text holds a #', () {
    int? lineOf(String text, String fragment) => headingLineOf(
      outlineOfText(text),
      parseAnchor(fragment)! as HeadingAnchor,
    );

    test('the whole fragment is the heading when the path finds none', () {
      const text = '# Intro\n## C#\n## F# tips\n## Issue #12\n';
      expect(lineOf(text, 'C#'), 1);
      expect(lineOf(text, 'F# tips'), 2);
      expect(lineOf(text, 'Issue #12'), 3);
      expect(lineOf(text, 'issue #12'), 3, reason: 'case does not matter');
    });

    test('the path wins when it names a heading', () {
      const text = '# Issue #12\n# Issue\n## 12\n';
      expect(lineOf(text, 'Issue #12'), 2, reason: '12 under Issue');
      expect(lineOf(text, 'Issue'), 1);
    });

    test('a fragment that names nothing, as a path or whole, is null', () {
      const text = '# C#\n# Issue #12\n';
      expect(lineOf(text, 'Issue #13'), isNull);
      expect(lineOf(text, 'Nope #1'), isNull);
    });

    test('the parsed anchor keeps the fragment as written', () {
      final anchor = parseAnchor(' Issue #12 ')! as HeadingAnchor;
      expect(anchor.path, ['Issue', '12']);
      expect(anchor.whole, 'Issue #12');
    });
  });

  group('blockLineOf', () {
    final blocks = <BlockAnchor>[
      const BlockAnchor(id: 'abc', line: 3, excerpt: ''),
      const BlockAnchor(id: 'Quote-2', line: 9, excerpt: ''),
    ];

    test('finds the block of an id, exactly', () {
      expect(blockLineOf(blocks, 'abc'), 3);
      expect(blockLineOf(blocks, 'Quote-2'), 9);
    });

    test('ids are not slugified or case-folded', () {
      expect(blockLineOf(blocks, 'ABC'), isNull);
      expect(blockLineOf(blocks, 'quote-2'), isNull);
      expect(blockLineOf(blocks, 'quote2'), isNull);
    });

    test('a missing id is not found', () {
      expect(blockLineOf(blocks, 'zzz'), isNull);
      expect(blockLineOf(const <BlockAnchor>[], 'abc'), isNull);
    });
  });
}
