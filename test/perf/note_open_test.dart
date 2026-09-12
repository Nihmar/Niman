// What opening a big note costs, measured where the user waits for it.
//
// The note the 2026-09-11 device report came from is ~930K of maths: 10.4K
// lines, ~840 `$$` blocks and ~13K inline `$…$` spans. Opening it showed a
// 1.2 s spinner, and the frame after the load painted in 0.4 ms — so the
// wait was never the painting, and never the disk either (the read is
// ~44 ms). It was `statsFor`, bundled into the same isolate task: the
// outline comes from the tokenizer, so asking for 84 headings highlights
// the whole document.
//
// `read` therefore returns the text alone. This file is the guard on that:
// the assertion is not a millisecond budget (machines differ) but the
// *ratio* — reading has to stay far cheaper than the stats it used to drag
// along. A change that re-bundles them fails here.
@Timeout(Duration(minutes: 5))
library;

// The whole point of this file is to print its measurements into the test
// log, so the print lint is off for it.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/preview/preview_work.dart';

int _ms(void Function() body) {
  final clock = Stopwatch()..start();
  body();
  return clock.elapsedMilliseconds;
}

/// A maths-dense note in the shape of the one that was slow: prose with
/// inline spans, and a display block every few lines.
String _mathNote({required int blocks}) {
  final out = StringBuffer('# Geometry\n\n');
  for (var i = 0; i < blocks; i++) {
    if (i % 40 == 0) out.writeln('\n## Section ${i ~/ 40}\n');
    out
      ..writeln(
        'Let \$ x_$i \$ be a point and \$ y_$i \$ its image, with '
        '\$ d(x_$i, y_$i) < \\varepsilon \$ for every \$ \\varepsilon > 0 \$.',
      )
      ..writeln()
      ..writeln(r'$$')
      ..writeln(
        '\\sum_{k=0}^{$i} \\frac{(-1)^k}{2k+1} '
        '= \\arctan(1) + O(2^{-$i})',
      )
      ..writeln(r'$$')
      ..writeln();
  }
  return out.toString();
}

void main() {
  test('reading a big note does not pay for its stats', () async {
    final dir = await Directory.systemTemp.createTemp('niman_open_');
    addTearDown(() => dir.delete(recursive: true));
    final text = _mathNote(blocks: 800);
    final file = File('${dir.path}/Geometry.md');
    await file.writeAsString(text);
    print(
      'fixture: ${text.length} chars, ${'\n'.allMatches(text).length + 1} '
      'lines, ${r'$'.allMatches(text).length} dollars',
    );

    final readClock = Stopwatch()..start();
    final loaded = await PreviewWork.run('read', file.path);
    readClock.stop();
    expect(loaded, isA<String>(), reason: 'read returns the text alone');
    expect((loaded! as String).length, text.length);

    final statsClock = Stopwatch()..start();
    final stats = statsFor(text);
    statsClock.stop();
    expect(stats.$1, greaterThan(0));

    final read = readClock.elapsedMilliseconds;
    final computed = statsClock.elapsedMilliseconds;
    print('read (isolate spawn + file): $read ms');
    print('statsFor (highlight + count): $computed ms');

    // The point of the split, stated as a ratio so a slow CI box cannot
    // fail it on absolute numbers: the stats are the expensive half, and
    // the open path must not be carrying them. On the report's note the
    // real figures were 44 ms against ~1160 ms.
    expect(
      computed,
      greaterThan(read),
      reason: 'if the stats got cheap enough to bundle, revisit read',
    );
  });

  // The note the report came from, on the machine that has it:
  //   NIMAN_BIG_NOTE="…/Geometria 1.md" flutter test test/perf/note_open_test.dart
  // Skipped everywhere else, so a real library's note can be measured
  // without its path ever being committed.
  test('stage breakdown of a real note (NIMAN_BIG_NOTE)', () {
    final path = Platform.environment['NIMAN_BIG_NOTE'];
    if (path == null || path.isEmpty) {
      print('NIMAN_BIG_NOTE unset — skipping the real-note breakdown');
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      print('NIMAN_BIG_NOTE points at no file — skipping');
      return;
    }

    late String text;
    final read = _ms(() => text = file.readAsStringSync());
    late HighlightDocument doc;
    final highlight = _ms(() => doc = HighlightDocument.fromText(text));
    final words = _ms(() => countWords(text));
    late List<OutlineEntry> viaTokens;
    final outline = _ms(() => viaTokens = outlineOf(doc.lines));
    late List<OutlineEntry> viaScan;
    final fast = _ms(() => viaScan = outlineOfText(text));
    final stats = _ms(() => statsFor(text));

    print(
      '${file.uri.pathSegments.last}: ${text.length} chars, '
      '${'\n'.allMatches(text).length + 1} lines, '
      '${r'$'.allMatches(text).length} dollars',
    );
    print('  read:          $read ms   <- all the open path pays now');
    print('  countWords:    $words ms');
    print('  outlineOfText: $fast ms   (${viaScan.length} headings)');
    print('  statsFor now:  $stats ms');
    print('  -- what it replaced --');
    print('  highlight:     $highlight ms');
    print('  outlineOf:     $outline ms   (${viaTokens.length} headings)');

    expect(viaScan, isNotEmpty);
    // The strongest equivalence check there is: a real 900K note, with its
    // own maths blocks deciding which `#` lines are headings.
    expect(
      viaScan.map((e) => '${e.line}|${e.level}|${e.text}').toList(),
      viaTokens.map((e) => '${e.line}|${e.level}|${e.text}').toList(),
      reason: 'the fast outline disagrees with the tokenizer on a real note',
    );
    expect(
      highlight,
      greaterThan(fast),
      reason: 'the scan is the point: it must beat tokenizing the document',
    );
  });
}
