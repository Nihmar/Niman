// The block scanner's rescan against a fresh scan, over sequences of edits
// to small documents made of the lines the scanner finds hard: containers
// opened after a marker, tables, tabs, underlines. Each divergence is kept
// as the shortest document and edit sequence found for its kind, which is
// what made the rescan's faults readable.
//
// A short run always; the long one under NIMAN_SCANNER_DIFF=1, like the
// CommonMark harness.
//
// ignore_for_file: avoid_print
import 'dart:io';
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

const List<String> _pieces = <String>[
  '',
  '',
  'prose',
  r'$$',
  '```',
  '# h',
  '- item',
  '1. one',
  '2) two',
  '   cont',
  '> quote',
  '> - q',
  'lazy',
  '    code',
  '---',
  '===',
  '  ---',
  '   ===',
  '    - deeper',
  '  back',
  '  ```',
  '  > q',
  '  # h',
  '<div>',
  '| a | b |',
  '|---|---|',
  '-',
  '- > q',
  '- - a',
  '\t- tab',
  '* * *',
  '  |---|---|',
  'a | b',
  '[^f]: note',
  '[^f]:',
  '    more',
];

/// Divergences found over [rounds] documents from each seed in [seeds],
/// the shortest for each kind.
Map<String, String> _search(Iterable<int> seeds, int rounds) {
  final shortest = <String, String>{};
  for (final seed in seeds) {
    final random = Random(seed);
    String piece() => _pieces[random.nextInt(_pieces.length)];
    for (var round = 0; round < rounds; round++) {
      final initial = List<String>.generate(
        2 + random.nextInt(5),
        (_) => piece(),
      ).join('\n');
      final buffer = SourceBuffer.fromText(initial);
      final scanner = BlockScanner(buffer, budget: 1 + random.nextInt(3));
      final edits = <String>[];
      for (var step = 0; step < 3; step++) {
        final line = random.nextInt(buffer.lineCount);
        final at = buffer.offsetOfLine(line);
        final end = at + buffer.lineAt(line).length;
        final text = piece();
        final kind = random.nextInt(4);
        final edit = switch (kind) {
          0 => buffer.replaceRange(at, at, '$text\n'),
          1 => buffer.replaceRange(at, end, text),
          2 when line > 0 => buffer.replaceRange(at - 1, at, ''),
          _ => buffer.replaceRange(end, end, '\n$text'),
        };
        edits.add('$kind@$line "$text"');
        scanner.edited(edit);
        if (random.nextBool()) scanner.advance(random.nextInt(4));
        final fresh = BlockScanner(SourceBuffer.fromText(buffer.text));
        String? found;
        for (
          var probe = 0;
          probe < buffer.lineCount && found == null;
          probe++
        ) {
          final got = _described(scanner.blockAt(probe));
          final want = _described(fresh.blockAt(probe));
          if (got == want) continue;
          final kindOf =
              '${got?.split(' ').first} -> '
              '${want?.split(' ').first}';
          found = kindOf;
          final report =
              'from ${initial.replaceAll('\n', r'\n')}, '
              'edits ${edits.join('; ')}: line $probe is $got, '
              'a fresh scan has $want';
          final kept = shortest[kindOf];
          if (kept == null || report.length < kept.length) {
            shortest[kindOf] = report;
          }
        }
        if (found != null) break;
      }
    }
  }
  return shortest;
}

void main() {
  test('a rescan agrees with a fresh scan after edits of hard lines', () {
    final found = _search(const [1], 4000);
    expect(found.values.toList(), isEmpty);
  });

  test(
    'a rescan agrees with a fresh scan, at length',
    skip: Platform.environment['NIMAN_SCANNER_DIFF'] != '1',
    () {
      final found = _search(const [1, 2, 3, 4], 60000);
      print('kinds of divergence: ${found.length}');
      for (final report in found.values) {
        print('== $report');
      }
      expect(found, isEmpty);
    },
  );
}
