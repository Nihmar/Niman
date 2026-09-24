// The adversarial fixture: that it still has the shape §5.7 of the design
// document specifies, and that the engine survives it.
//
// `Geometria 1.md` proves the math and the layout and exercises almost nothing
// else — no code spans, no fences, no links, no entities, no escapes, no
// reference definitions. This fixture is the union of what each document in
// the corpus lacks, so one file can stand in for all of them; the assertions
// below are its contract, and regenerating it with
// `dart run tool/make_worst_note.dart` that breaks one is a change to the spec
// rather than a drift.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_masker.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:path/path.dart' as p;

/// Where the generator writes it.
final String _path = p.join('test', 'fixtures', 'spec', 'worst-note.md');

void main() {
  late String text;
  late List<String> lines;

  setUpAll(() {
    text = File(_path).readAsStringSync();
    lines = text.split('\n');
  });

  group('the fixture keeps the shape the spec asks for', () {
    test('it is bigger than any note or fixture the repo has', () {
      // 1 200 000 B asked for; the geometry note is 934 769 and the largest
      // fixture is 1 050 145.
      expect(text.length, greaterThan(1200000));
      expect(lines.length, greaterThan(10000));
    });

    test('its blank lines stay a realistic share', () {
      final blank = lines.where((line) => line.trim().isEmpty).length;
      expect(blank / lines.length, greaterThan(0.08));
    });

    test('it has lines longer than the corpus has', () {
      final over2000 = lines.where((line) => line.length > 2000).length;
      final longest = lines.fold(0, (a, b) => a > b.length ? a : b.length);
      expect(longest, greaterThan(4000), reason: 'the corpus reaches 2 568');
      expect(over2000, greaterThanOrEqualTo(40));
    });

    test('it carries the constructs the corpus is missing', () {
      expect(
        RegExp(r'^\s*(~~~|```)', multiLine: true).allMatches(text).length,
        greaterThanOrEqualTo(8),
        reason: 'fences: the geometry note has none',
      );
      expect(
        RegExp(r'^    \S', multiLine: true).allMatches(text),
        isNotEmpty,
        reason: 'an indented code block',
      );
      expect(
        RegExp(r'^\[[^\]]+\]:', multiLine: true).allMatches(text).length,
        greaterThanOrEqualTo(5),
        reason: 'link reference definitions: the corpus has none',
      );
      expect(
        RegExp(r'^\[\^[^\]]+\]:', multiLine: true).allMatches(text).length,
        greaterThanOrEqualTo(60),
        reason: 'footnote definitions',
      );
      expect(
        RegExp(r'!\[\[[^\]\n]*\]\]').allMatches(text).length,
        greaterThanOrEqualTo(38),
        reason: 'embeds: the corpus has 38',
      );
      expect(
        RegExp(r'\r\n').allMatches(text).length,
        greaterThanOrEqualTo(120),
        reason: 'a CRLF region',
      );
    });

    test('it goes deeper than the corpus goes', () {
      // Seven levels of list and four of quote, against the corpus's three
      // and one.
      expect(text, contains('${'  ' * 6}- level 6 item'));
      expect(text, contains('> > > > quote at depth 4'));
      // Ordered lists with both delimiters and a start that is not one.
      expect(text, contains('3) starts at three'));
      expect(text, contains('1. dot delimiter'));
      // Task items, nested.
      expect(text, contains('- [x] task at level 1'));
      // Display math inside a list item and inside a quote.
      expect(
        text,
        contains(r'$$\begin{pmatrix} a & b \\ c & d \end{pmatrix}$$'),
      );
      expect(text, contains(r'> > > \int_0^1'));
    });

    test('it has more math than the corpus, and all six environments', () {
      final inline = RegExp(r'(?<!\\)\$[^$\n]+\$').allMatches(text).length;
      final display = RegExp(
        r'^\s*\$\$',
        multiLine: true,
      ).allMatches(text).length;
      expect(inline, greaterThanOrEqualTo(13004));
      expect(display, greaterThanOrEqualTo(902));
      for (final environment in <String>[
        'pmatrix',
        'bmatrix',
        'vmatrix',
        'cases',
        'aligned',
        'array',
      ]) {
        expect(text, contains('\\begin{$environment}'));
      }
      // A brace depth of five, which the corpus never reaches.
      expect(text, contains(r'\left\{ \frac{ \sqrt{ \frac{a}{b} } }'));
    });

    test('it has a table wider and longer than any in the corpus', () {
      final header = lines.firstWhere((line) => line.startsWith('| col 0'));
      expect('|'.allMatches(header).length - 1, greaterThanOrEqualTo(12));
      // The scanner's own view: the table is one block, header and delimiter
      // rows included, so its length is the whole table.
      final table = BlockScanner(SourceBuffer.fromText(text)).index.blocks
          .firstWhere((block) => block.kind == BlockKind.table);
      expect(table.lineCount, greaterThanOrEqualTo(41));
      expect(text, contains(r'escaped \| pipe'));
    });
  });

  group('the engine survives it', () {
    late SourceBuffer buffer;
    late BlockScanner scanner;

    setUpAll(() {
      buffer = SourceBuffer.fromText(text);
      scanner = BlockScanner(buffer);
    });

    test('the scanner reads it whole', () {
      expect(scanner.index.blocks.length, greaterThan(2000));
      expect(scanner.scannedLineCount, buffer.lineCount);
    });

    test('every line belongs to exactly one block', () {
      var expected = 0;
      for (final block in scanner.index.blocks) {
        expect(block.startLine, expected);
        expected = block.endLine;
      }
      expect(expected, buffer.lineCount);
    });

    test('the block kinds it should find are all there', () {
      final kinds = <String, int>{};
      for (final block in scanner.index.blocks) {
        kinds[block.kind.name] = (kinds[block.kind.name] ?? 0) + 1;
      }
      for (final wanted in <String>[
        'paragraph',
        'heading',
        'thematicBreak',
        'fencedCode',
        'indentedCode',
        'math',
        'frontmatter',
        'html',
        'quote',
        'listItem',
        'table',
        'blank',
      ]) {
        expect(kinds[wanted], isNotNull, reason: 'no $wanted block');
        expect(kinds[wanted], greaterThan(0), reason: 'no $wanted block');
      }
      // Four fence pairs: no info string, a language, an empty one, and the
      // 2 000-line one.
      expect(kinds['fencedCode'], greaterThanOrEqualTo(4));
      expect(kinds['table'], greaterThanOrEqualTo(1));
      expect(kinds['frontmatter'], 1);
    });

    test('every block masks with both properties intact', () {
      const masker = ExtensionMasker();
      final counts = <ExtensionKind, int>{};
      var blocksWithSpans = 0;
      for (final block in scanner.index.blocks) {
        final parts = <String>[];
        for (var line = block.startLine; line < block.endLine; line++) {
          parts.add(buffer.lineAt(line));
        }
        final blockText = parts.join('\n');
        final masked = masker.mask(blockText);
        expect(masked.text.length, blockText.length, reason: '$block');
        var at = 0;
        for (final span in masked.spans) {
          expect(span.start, greaterThanOrEqualTo(at), reason: '$block');
          at = span.end;
          counts[span.kind] = (counts[span.kind] ?? 0) + 1;
        }
        if (masked.isMasked) blocksWithSpans++;
      }
      expect(blocksWithSpans, greaterThan(500));
      expect(counts[ExtensionKind.inlineMath], greaterThan(13000));
      expect(counts[ExtensionKind.embed], greaterThanOrEqualTo(38));
      expect(counts[ExtensionKind.codeSpan], greaterThanOrEqualTo(8));
    });

    test('a keystroke in prose re-scans a few lines', () {
      // Line 10 is in the headings, where blocks are a line or two long; line
      // 100 is already inside the 2 000-line paragraph.
      final before = scanner.scannedLineTotal;
      final edit = buffer.insert(buffer.offsetOfLine(10), 'x');
      scanner.edited(edit);
      expect(scanner.scannedLineTotal - before, lessThan(30));
    });

    test('a keystroke in the 2 000-line paragraph costs a line or two', () {
      // This fixture has the worst block there is: one paragraph of 2 000
      // lines. The bound used to be that block — a rebuild began at its first
      // line and found no place to stop until it ended. It begins at the edit
      // now, and stops where the state and the block agree with what was
      // there, which inside a paragraph is the line after the edit
      // (`docs/dev/huge-notes.md` item 3).
      var start = -1;
      for (final block in scanner.index.blocks) {
        if (block.lineCount >= 2000) {
          start = block.startLine;
          break;
        }
      }
      expect(start, greaterThan(0), reason: 'no 2 000-line block');
      final before = scanner.scannedLineTotal;
      final edit = buffer.insert(buffer.offsetOfLine(start + 10), 'x');
      scanner.edited(edit);
      final cost = scanner.scannedLineTotal - before;
      expect(cost, lessThan(5), reason: 'the edit, not the paragraph');
      final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
      expect(
        scanner.index.blocks.map((block) => block.toString()),
        fresh.index.blocks.map((block) => block.toString()),
      );
    });
  });
}
