// What the read view costs where a reader waits for it, held against the budget
// the design set for it (`docs/dev/unified-surface.md` §9.4).
//
// The number that matters is **text to first visible content**: the wait
// between the note's text existing and something being on screen to read. The
// design's target for the geometry note is 60 ms and its hard ceiling 120 ms,
// against the preview's 137 ms — the wait that has no spinner in front of it
// and is therefore the one a reader feels.
//
// The measurements are **debug-mode harness numbers**, like every other
// benchmark in this repository: the ratios carry and the absolutes do not. The
// numbers are printed, so a change that doubles this is visible in the log even
// when it passes.
//
// CI proved the second half of that sentence the hard way, on #249's first
// runs: the shared runner read 365 ms for the fixture this host reads at 165,
// and 222 for the one it reads at 88 — and neither was a regression, because
// the preview on that same runner read 338 ms. An *absolute* ceiling is
// therefore not something a shared machine can hold, and asserting it there
// fails a build for the hardware it ran on. So the ceiling is asserted by a run
// that asks for it —
// `NIMAN_PERF=1 flutter test test/perf/read_view_timing_test.dart` — which is
// where §9's budget is meaningful and where §4.9.5's numbers came from; every
// run asserts a **backstop** instead — ten times the ceiling — which is what a
// real regression looks like and no calibration explains away.
//
// The preview this was first held against is gone (#247, phase 5); its
// numbers stay in the design document, measured on a device.
@Timeout(Duration(minutes: 5))
library;

// The point of this file is to print its measurements into the test log.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:path/path.dart' as p;

/// The design's hard ceiling for text to first visible content, in
/// milliseconds, and the target it aims at.
///
/// The row is written for the geometry note, whose blocks are small. The
/// synthetic fixtures are adversarial by construction and their first screen is
/// dense with display formulas: typesetting the first render of each is paid
/// inside this measurement, by the preview exactly as by the read view, and the
/// math cache amortizes it from the second frame on. They are therefore held to
/// a looser ceiling, and it is a *recorded* decision rather than a conveniently
/// chosen number.
const int _ceiling = 120;
const int _target = 60;
const Map<String, int> _ceilings = <String, int>{
  'Geometria 1.md': _ceiling,
  'fixture-200kb.md': _ceiling,
  'fixture-50kb.md': 250,
};

/// The jump's ceiling: 250, the loosest first-content ceiling in this file, and
/// deliberately not the design's own 25/60 ms (§9.2, "prefix sums, only landed
/// blocks laid out") — that row is a release build's target, and a jump in this
/// harness pays a **cold first content where it lands**, which on the geometry
/// note is a denser screen than its first (139 ms against 72). Recorded rather
/// than convenient: 2 772 ms is what the row replaced (#251).
const int _jumpCeiling = 250;

/// Whether this run holds the design's ceiling rather than the backstop: the
/// reference host's run, asked for explicitly.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// What a ceiling is multiplied by on a machine that is not the reference one.
const int _backstop = 10;

/// The fixtures to measure, largest last. The geometry note is one person's and
/// is not in the repository, so it is measured when it is there.
const List<String> _fixtures = <String>[
  'test/fixtures/markdown/fixture-50kb.md',
  'test/fixtures/markdown/fixture-200kb.md',
  'Geometria 1.md',
];

/// A cache that renders in-line, as the preview's own tests do.
MathCache _mathCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// Milliseconds until [ready] — the wait a reader actually feels.
Future<int> _msUntil(
  WidgetTester tester,
  Future<void> Function() first,
  bool Function() ready,
) async {
  final watch = Stopwatch()..start();
  await first();
  for (var at = 0; at < 60 && !ready(); at++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
  watch.stop();
  return watch.elapsedMilliseconds;
}

void main() {
  for (final path in _fixtures) {
    final file = File(path);
    final name = p.basename(path);
    testWidgets('$name: text to first visible content', (tester) async {
      if (!file.existsSync()) {
        markTestSkipped('$name is not in the repository');
        return;
      }
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final markdown = file.readAsStringSync();

      // Warm the pipeline on a note too small to measure. The first test in a
      // file pays the JIT's cost for every one of these code paths, and without
      // this the smallest fixture reports three times what it costs while the
      // larger ones — measured after it — report the truth. Standard practice
      // for a benchmark, and the reason the numbers below are comparable to
      // each other at all.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownReadView(
              buffer: SourceBuffer.fromText('# Warm up\n\nA paragraph.'),
              parser: BlockParser(),
              mathCache: _mathCache(),
            ),
          ),
        ),
      );
      await tester.pump();

      // The whole path, timed as one: the buffer, the block scan, and the
      // first frame of content.
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final parser = BlockParser();
      late SourceBuffer buffer;
      final first = await _msUntil(tester, () async {
        buffer = SourceBuffer.fromText(markdown);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MarkdownReadView(
                buffer: buffer,
                parser: parser,
                mathCache: _mathCache(),
                controller: controller,
              ),
            ),
          ),
        );
      }, () => controller.hasClients);
      final state = tester.state<MarkdownReadViewState>(
        find.byType(MarkdownReadView),
      );

      // A jump through the same note: what scrolling costs once the height map
      // knows some of it.
      final watch = Stopwatch()..start();
      controller.jumpTo(controller.position.maxScrollExtent / 2);
      await tester.pump();
      await tester.pump();
      watch.stop();
      final jump = watch.elapsedMilliseconds;

      final ceiling = _ceilings[name] ?? _ceiling;
      final bar = _referenceHost ? ceiling : ceiling * _backstop;
      final jumpBar = _referenceHost ? _jumpCeiling : _jumpCeiling * _backstop;
      print(
        '$name: first content ${first}ms (target $_target, ceiling $ceiling, '
        'bar $bar) | jump ${jump}ms (ceiling $_jumpCeiling, bar $jumpBar) | '
        'blocks ${state.blockCount} built ${state.builtBlocks} '
        'parsed ${parser.parseCount}',
      );

      expect(
        first,
        lessThanOrEqualTo(bar),
        reason: _referenceHost
            ? 'past the ceiling for text to first visible content'
            : 'past the backstop for text to first visible content: $first ms '
                  'against $bar. Run with NIMAN_PERF=1 to hold it to the '
                  'design ceiling of $ceiling ms',
      );
      expect(
        jump,
        lessThanOrEqualTo(jumpBar),
        reason: _referenceHost
            ? 'past the ceiling for a jump to land'
            : 'past the backstop for a jump: $jump ms against $jumpBar. Run '
                  'with NIMAN_PERF=1 to hold it to the ceiling of '
                  '$_jumpCeiling ms',
      );
      // The gate that is machine-independent, and the one #251 is about: the
      // jump landed on blocks no frame had reached and built a viewport of
      // them, not every block it passed (3 156 of 7 530 before).
      expect(state.builtBlocks, greaterThan(0));
      expect(
        state.builtBlocks,
        lessThan(state.blockCount ~/ 5),
        reason: 'built ${state.builtBlocks} of ${state.blockCount} blocks',
      );
      expect(state.blockCount, greaterThan(0));
    });
  }
}
