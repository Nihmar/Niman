// The definitions a styler keeps while a note is edited are what a fresh read
// of the note finds (#1372): each definition line is read once, an edit reads
// again the lines it changed and the lines above that read them, and the scope
// is combined from what was read.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

String _scopeOf(DocumentScope scope) => [
  for (final entry in scope.references.entries)
    '${entry.key}=${entry.value.destination}|${entry.value.title}',
  '${scope.footnoteCounts}',
  '${scope.footnoteKeys.toList()..sort()}',
  '${scope.footnoteLabels}',
  for (final note in scope.footnotes) '${note.label}:${note.body}',
].join('\n');

void _expectFresh(SourceStyler styler, String reason) {
  final buffer = styler.buffer;
  expect(
    _scopeOf(styler.scope),
    _scopeOf(DocumentScope.scan(buffer, buffer.revision)),
    reason: '$reason:\n${buffer.text}',
  );
}

void main() {
  group('a line a definition reads from, edited, changes the definition', () {
    test("a definition's destination on the line under its label", () {
      final buffer = SourceBuffer.fromText('[a]:\n  /one\n\nsee [a]');
      final styler = SourceStyler(buffer);
      expect(styler.scope.references['A']?.destination, '/one');
      final at = buffer.offsetOfLine(1);
      styler.edited(buffer.replaceRange(at, at + 6, '  /two'));
      expect(styler.scope.references['A']?.destination, '/two');
      _expectFresh(styler, 'the destination changed');
      // The destination goes: the label alone defines nothing.
      styler.edited(buffer.replaceRange(at, at + 6, ''));
      _expectFresh(styler, 'the destination removed');
      expect(styler.scope.references, isEmpty);
    });

    test("a definition's title on a third line", () {
      final buffer = SourceBuffer.fromText('[a]: /u\n  "first"\n\nend');
      final styler = SourceStyler(buffer);
      expect(styler.scope.references['A']?.title, 'first');
      final at = buffer.offsetOfLine(1);
      styler.edited(buffer.replaceRange(at, at + 10, '  "second"'));
      expect(styler.scope.references['A']?.title, 'second');
      _expectFresh(styler, 'the title changed');
    });

    test("a footnote's body, on the lines indented under it", () {
      final buffer = SourceBuffer.fromText('[^n]: one\n    two\n    three\nx');
      final styler = SourceStyler(buffer);
      final at = buffer.offsetOfLine(2);
      styler.edited(buffer.replaceRange(at, at + 9, '    other'));
      _expectFresh(styler, 'the last line of the body');
      expect(styler.footnotes, isEmpty);
    });
  });

  test('random edits leave the scope a fresh read finds', () {
    const pieces = <String>[
      '[a]: /one',
      '[b]: /two "t"',
      '[a]: /dup',
      '[c]:',
      '  /three',
      '  "title"',
      '[^n]: note',
      '[^m]: more',
      '    continues',
      '    [^n] cited',
      'see [^n] and [^m]',
      '[^n]: again',
      '',
      'text',
      '> [x]: /quoted',
      '    code [^m]',
      '- [d]: /item',
    ];
    final random = Random(1372);
    for (var round = 0; round < 400; round++) {
      final lines = [
        for (var i = 0; i < 2 + random.nextInt(14); i++)
          pieces[random.nextInt(pieces.length)],
      ];
      final buffer = SourceBuffer.fromText(lines.join('\n'));
      final styler = SourceStyler(buffer);
      _expectFresh(styler, 'round $round as loaded');
      for (var step = 0; step < 8; step++) {
        final line = random.nextInt(buffer.lineCount);
        final start = buffer.offsetOfLine(line);
        final end = start + buffer.lineLengthAt(line);
        final piece = pieces[random.nextInt(pieces.length)];
        final edit = switch (random.nextInt(5)) {
          0 => buffer.replaceRange(start, end, piece),
          1 => buffer.insert(start, '$piece\n'),
          2 => buffer.replaceRange(start, min(buffer.length, end + 1), ''),
          3 => buffer.replaceRange(end, end, 'x'),
          _ => buffer.replaceRange(
            start,
            end,
            random.nextBool() ? '' : '    ${pieces[random.nextInt(8)]}',
          ),
        };
        styler.edited(edit);
        _expectFresh(styler, 'round $round step $step');
      }
    }
  });

  test('an edit reads the lines it changed, not every definition', () {
    final buffer = SourceBuffer.fromText(
      [for (var i = 0; i < 2000; i++) '[l$i]: /u$i'].join('\n'),
    );
    final styler = SourceStyler(buffer);
    final at = buffer.offsetOfLine(1000) + 10;
    styler.edited(buffer.insert(at, 'x'));
    expect(styler.definitionLinesRescanned, lessThan(10));
    expect(styler.scope.references['L1000']?.destination, '/xu1000');
    _expectFresh(styler, 'one definition edited');
  });
}
