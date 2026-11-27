// A rescan after an edit that takes out more lines than it puts in agrees with
// a fresh scan (#1329). The old block an edit touched began in the lines
// before it, in the coordinates from before the edit, and the rebuild is in
// the coordinates after it: comparing the two dropped that block when the
// start was past the line the rebuild stood at, and a paragraph made up for
// it was never corrected — a setext underline below it was not seen.
//
// Edits the whole-line generator of `block_scanner_rescan_test.dart` does not
// make: a range from the middle of one line to the middle of another, replaced
// by shorter text, pastes, and single characters, with the scan left owed at
// budgets of one to three lines.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A block, compared whole: its shape, number, level, language and state.
String? _described(Block? block) => block == null
    ? null
    : <Object?>[
        block,
        '#${block.listOrdinal}',
        'h${block.headingLevel}',
        block.fenceInfo,
        block.entering,
      ].join(' ');

/// Every line's block, as one string.
String _all(BlockScanner scanner, SourceBuffer buffer) => [
  for (var line = 0; line < buffer.lineCount; line++)
    '$line ${_described(scanner.blockAt(line))}',
].join('\n');

const List<String> _pieces = <String>[
  '',
  'prose',
  r'$$',
  '```',
  '~~~',
  '# h',
  '- item',
  '1. one',
  '   cont',
  '> quote',
  'lazy',
  '    code',
  '---',
  '===',
  '<div>',
  '</div>',
  '<a href="x">',
  '</pre>',
  '| a | b |',
  '|---|---|',
  '\t',
  '#tag',
  '[r]: /u',
  '[^f]: note',
  ':::: columns',
  '::: column',
  ':::',
  'a b',
  '+ item',
];

void main() {
  test("an edit that removes lines does not make up a paragraph (the review's "
      'minimum)', () {
    final text = [
      '<a href="x">',
      r'$$',
      '+ item',
      '\t',
      'a b',
      '</pre>',
      '#tag',
      '    code',
      '<a href="x">',
      '---',
    ].join('\n');
    final buffer = SourceBuffer.fromText(text);
    final scanner = BlockScanner(buffer, budget: 1);
    // From line 0 column 6 to line 4 column 2, with one character.
    final start = buffer.offsetOfLine(0) + 6;
    final end = buffer.offsetOfLine(4) + 2;
    scanner.edited(buffer.replaceRange(start, end, 'Q'));
    final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
    expect(_all(scanner, buffer), _all(fresh, buffer));
  });

  test('the plain document of the same edit, as the review gave it', () {
    final buffer = SourceBuffer.fromText(
      '<a href="x">\n\$\$\n+ item\n\na b\n</pre>\n#tag\n    code\n'
      '<a href="x">\n---',
    );
    final scanner = BlockScanner(buffer, budget: 1)
      ..edited(
        buffer.replaceRange(
          buffer.offsetOfLine(0) + 6,
          buffer.offsetOfLine(4) + 2,
          'Q',
        ),
      );
    final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
    expect(_all(scanner, buffer), _all(fresh, buffer));
  });

  group('after ranges, pastes and characters, at any budget', () {
    // The documents and the edits are the property: a scan kept up with
    // edits is the scan of the text they leave.
    void run(int seed, {required bool typing}) {
      final random = Random(seed);
      String piece() => _pieces[random.nextInt(_pieces.length)];
      for (var round = 0; round < 700; round++) {
        final initial = [
          for (var i = 0; i < 8 + random.nextInt(23); i++) piece(),
        ].join('\n');
        final buffer = SourceBuffer.fromText(initial);
        final scanner = BlockScanner(buffer, budget: 1 + random.nextInt(3));
        for (var step = 0; step < 4; step++) {
          final length = buffer.length;
          final int from;
          final int to;
          final String text;
          if (typing) {
            from = random.nextInt(length + 1);
            to = random.nextInt(3) == 0 ? min(length, from + 1) : from;
            text = ['x', '\n', '#', '-', ' ', '`', '>'][random.nextInt(7)];
          } else {
            from = random.nextInt(length + 1);
            to = min(length, from + random.nextInt(60));
            text = [
              '',
              piece(),
              '${piece()}\n${piece()}',
              '\n',
            ][random.nextInt(4)];
          }
          scanner.edited(buffer.replaceRange(from, to, text));
          if (random.nextBool()) scanner.advance(random.nextInt(4));
          final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
          expect(
            _all(scanner, buffer),
            _all(fresh, buffer),
            reason:
                'seed $seed from ${initial.replaceAll('\n', r'\n')}, '
                'step $step: [$from, $to) -> ${text.replaceAll('\n', r'\n')}',
          );
        }
      }
    }

    for (final seed in [1, 2, 3, 4]) {
      test('ranges replaced, seed $seed', () => run(seed, typing: false));
    }
    for (final seed in [5, 6]) {
      test('characters typed, seed $seed', () => run(seed, typing: true));
    }
  });
}
