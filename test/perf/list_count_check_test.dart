// What the tools sheet pays to decide whether to offer the list count.
//
// The sheet lists every tool and greys the ones that cannot run, so the
// question "does this note hold a list?" is asked every time it opens. It
// used to be answered by reading the note and tokenizing it whole
// (`tallyTargetsIn` builds a `HighlightDocument`): on the 246 MB note of the
// 0.0.9 stress test that is a 190 ms join and a full highlight, for a yes or
// a no. It is now answered off the blocks the pane already scanned
// (`blockList`), which is O(blocks).
//
// Same shape as the other benchmarks here (see `read_view_timing_test.dart`):
// the numbers are printed, a **backstop** is asserted on any host, and the
// design's ceiling is asserted only by a run that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/list_count_check_test.dart`.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_tally_edit.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Whether this run is the one that holds the design's ceiling.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// A backstop for the hosts that are not the reference one.
const double _backstop = 20;

/// The design's ceiling for the check itself, in milliseconds.
const double _ceiling = 0.5;

/// A note of [lines] lines with a list 40 % of the way in.
String _note(int lines) {
  final buffer = StringBuffer();
  for (var line = 0; line < lines; line++) {
    if (line == lines * 2 ~/ 5) {
      buffer.writeln('- [ ] a chore to count');
    } else {
      buffer.writeln('prose line $line with a few words on it');
    }
  }
  return buffer.toString();
}

void main() {
  for (final lines in const [100000, 1000000]) {
    test('the list check on $lines lines does not read the note', () {
      final buffer = SourceBuffer.fromText(_note(lines));
      final scan = Stopwatch()..start();
      final scanned = BlockScanner(buffer).index;
      final scanMs = scan.elapsedMilliseconds;

      final check = Stopwatch()..start();
      final hasList = blockList(scanned.blocks);
      final checkMs = check.elapsedMicroseconds / 1000;

      print(
        'the list check, $lines lines (${buffer.length} chars): '
        'scan ${scanMs}ms, check ${checkMs.toStringAsFixed(3)}ms '
        '(${hasList ? 'a list' : 'no list'}, ${scanned.length} blocks)',
      );
      expect(hasList, isTrue);

      // The check is a walk of the blocks the scan already produced, so it
      // is orders of magnitude under the scan itself, and it does not grow
      // with the note the way the scan does.
      if (_referenceHost) {
        expect(checkMs, lessThan(_ceiling));
      }
      expect(checkMs, lessThan(_backstop));
    });
  }

  test('the check walks blocks, not lines', () {
    // The same list, once at the top of the note and once at the bottom: the
    // check has the same work to do, because the scan has done it already.
    final top = SourceBuffer.fromText('- [ ] one\n${_note(200000)}');
    final bottom = SourceBuffer.fromText('${_note(200000)}- [ ] one\n');
    final topScan = BlockScanner(top).index.blocks;
    final bottomScan = BlockScanner(bottom).index.blocks;
    final topCheck = Stopwatch()..start();
    blockList(topScan);
    final topMs = topCheck.elapsedMicroseconds / 1000;
    final bottomCheck = Stopwatch()..start();
    blockList(bottomScan);
    final bottomMs = bottomCheck.elapsedMicroseconds / 1000;
    print(
      'the list check, at the top ${topMs.toStringAsFixed(3)}ms and at the '
      'bottom ${bottomMs.toStringAsFixed(3)}ms (${topScan.length} blocks)',
    );
    expect(blockList(topScan), isTrue);
    expect(blockList(bottomScan), isTrue);
    expect(bottomMs, lessThan(_backstop));
  });

  test('a note of prose is answered without one', () {
    final buffer = SourceBuffer.fromText(
      List<String>.generate(200000, (i) => 'prose line $i').join('\n'),
    );
    final blocks = BlockScanner(buffer).index.blocks;
    final items = blocks
        .where((block) => block.kind == BlockKind.listItem)
        .length;
    final check = Stopwatch()..start();
    final hasList = blockList(blocks);
    print(
      'the list check on prose: '
      '${(check.elapsedMicroseconds / 1000).toStringAsFixed(3)}ms '
      '(${blocks.length} blocks, $items list items)',
    );
    expect(hasList, isFalse);
  });
}
