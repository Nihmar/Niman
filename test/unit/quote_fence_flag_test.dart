// The quotes that can hold a `columns` block (#1048): the scan marks a quote
// block when one of its lines opens a fenced div behind its `>`, and `live`
// reads only those, so a note of thousands of plain quotes pays nothing for
// them per keystroke.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/live_quote_runs.dart';
import 'package:niman/src/markdown/render/live_run.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The start lines of the quotes that have a `:::` line behind their `>`,
/// by reading every line: the answer the flag has to cover.
Set<int> _truth(SourceBuffer buffer) {
  final starts = <int>{};
  for (final block in BlockScanner(buffer).index.blocks) {
    if (block.kind != BlockKind.quote) continue;
    for (var line = block.startLine; line < block.endLine; line++) {
      final text = buffer.lineAt(line).trimLeft();
      final inside = text.startsWith('>') ? text.substring(1).trimLeft() : text;
      if (inside.startsWith(':::')) starts.add(block.startLine);
    }
  }
  return starts;
}

String _plainQuotes(int count) => List<String>.generate(
  count,
  (i) => '> quote $i\n> second line',
).join('\n\n');

void main() {
  test('a plain quote is not marked, a quote with a fence line is', () {
    final buffer = SourceBuffer.fromText(
      '> plain\n\n> :::: columns\n> ::: column\n> a\n> :::\n> ::::\n\ntext\n',
    );
    final scanner = BlockScanner(buffer);
    expect(scanner.fenceQuoteBlocks.map((b) => b.startLine), [2]);
  });

  test('a note of plain quotes has none to read', () {
    final buffer = SourceBuffer.fromText(_plainQuotes(5000));
    final scanner = BlockScanner(buffer);
    expect(
      scanner.index.blocks.where((b) => b.kind == BlockKind.quote),
      hasLength(5000),
    );
    expect(scanner.fenceQuoteBlocks, isEmpty);
    // A keystroke at the top: still none, and the runs read nothing.
    scanner.edited(buffer.replaceRange(0, 0, 'x'));
    expect(scanner.fenceQuoteBlocks, isEmpty);
    final runs = LiveQuoteRuns();
    final watch = Stopwatch()..start();
    expect(runs.of(scanner.fenceQuoteBlocks, buffer), isEmpty);
    // A perf figure printed, as the other timing tests do.
    // ignore: avoid_print
    print(
      'live quote runs, 5000 plain quotes: ${watch.elapsedMicroseconds} us '
      '(no quote is read)',
    );
  });

  test('the marked quotes follow edits, and none with a fence is missed', () {
    const pieces = <String>[
      '> text',
      '> :::: columns',
      '> ::: column',
      '> :::',
      '> ::::',
      '>   ::: column',
      '> > ::: x',
      ':::: columns',
      'plain',
      '',
      '- item',
      '```',
      '> quote',
    ];
    final random = Random(1048);
    for (var round = 0; round < 300; round++) {
      final buffer = SourceBuffer.fromText(
        List<String>.generate(
          2 + random.nextInt(8),
          (_) => pieces[random.nextInt(pieces.length)],
        ).join('\n'),
      );
      final scanner = BlockScanner(buffer, budget: 1 + random.nextInt(3));
      for (var step = 0; step < 6; step++) {
        final line = random.nextInt(buffer.lineCount);
        final at = buffer.offsetOfLine(line);
        final end = at + buffer.lineAt(line).length;
        final text = pieces[random.nextInt(pieces.length)];
        final edit = switch (random.nextInt(3)) {
          0 => buffer.replaceRange(at, at, '$text\n'),
          1 => buffer.replaceRange(at, end, text),
          _ =>
            line > 0
                ? buffer.replaceRange(at - 1, at, '')
                : buffer.replaceRange(end, end, '\n$text'),
        };
        scanner.edited(edit);
        if (random.nextBool()) scanner.advance(random.nextInt(4));
        scanner.settle();
        final marked = scanner.fenceQuoteBlocks.map((b) => b.startLine).toSet();
        expect(
          marked,
          containsAll(_truth(buffer)),
          reason: 'round $round step $step: ${buffer.text}',
        );
      }
    }
  });

  test('columns in a quote still lay out after edits above it', () {
    final buffer = SourceBuffer.fromText(
      '${_plainQuotes(50)}\n\n> :::: columns\n> ::: column\n> a\n> :::\n'
      '> ::: column\n> b\n> :::\n> ::::\n',
    );
    final scanner = BlockScanner(buffer);
    final runs = LiveQuoteRuns()..of(scanner.fenceQuoteBlocks, buffer);
    for (var n = 0; n < 5; n++) {
      final edit = buffer.replaceRange(0, 0, 'new line\n');
      scanner
        ..edited(edit)
        ..settle();
      runs.edited(edit);
      final got = runs.of(scanner.fenceQuoteBlocks, buffer);
      final fresh = LiveRun.inQuotes(
        BlockScanner(buffer).index.blocks
            .where((b) => b.kind == BlockKind.quote),
        buffer,
      );
      expect(got, hasLength(1));
      expect(got, fresh);
    }
  });
}
