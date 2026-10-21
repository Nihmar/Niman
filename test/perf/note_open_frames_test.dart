// The first frames of a 1.5 MB note (#1132): the frame that opens it, and
// the one that opens the read pane beside it.
//
// The 2026-10-20 device log measured 20.6 ms for the first and 38.7 ms for
// the second on a tablet, a 1.5 MB note of 16 000 lines. Profiled here, the
// open's frame was the source pane's block scan of the whole note — done in
// place below `MarkdownSourceViewState.backgroundLines` — and it now reads
// the top of the note and the rest after the frame. The flip re-parsed the
// frontmatter panel's YAML at every build.
//
// The fixture is three copies of the 500 KB one: 1.5 MB, 46 000 lines. The
// numbers are printed on every run; the design's ceilings are asserted only
// by a run that asks for them — `NIMAN_PERF=1 flutter test
// test/perf/note_open_frames_test.dart` — and a backstop ten times as wide on
// any other, so a shared runner cannot fail it for its hardware. On the
// reference host the open's frame reads 92 ms with the whole scan in it and
// 52–54 without; the read pane's 31–34.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:path/path.dart' as p;

/// Whether this run is the one that holds the design's ceilings.
final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

void main() {
  testWidgets('a 1.5 MB note opens, and opens its read pane, in time', (
    tester,
  ) async {
    final one = File(p.join('test', 'fixtures', 'markdown', 'fixture-500kb.md'))
        .readAsStringSync();
    final text = [one, one, one].join('\n');
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    Widget view({required bool preview}) => MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/notes/a.md',
          showLineNumbers: false,
          autofocusEditor: false,
          toolbarTop: true,
          showPreview: preview,
          readNote: (_) async => text,
          writeNote: (_, _) async {},
        ),
      ),
    );
    Future<int> timed(Future<void> Function() frame) async {
      final clock = Stopwatch()..start();
      await frame();
      return clock.elapsedMicroseconds;
    }

    // Frames a display draws, so the timers a frame leaves run between
    // them: the rest of the open's scan is carried on that way.
    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    final opens = <int>[];
    final flips = <int>[];
    // The first round warms the code up; the rest are measured.
    for (var round = 0; round < 6; round++) {
      await tester.pumpWidget(view(preview: false));
      // The frame the loaded note is drawn in.
      final open = await timed(tester.pump);
      await settle();
      final flip = await timed(() => tester.pumpWidget(view(preview: true)));
      await settle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      if (round == 0) continue;
      opens.add(open);
      flips.add(flip);
    }
    int median(List<int> values) =>
        (values.toList()..sort())[values.length ~/ 2];
    final open = median(opens) / 1000;
    final flip = median(flips) / 1000;
    const openCeiling = 75.0;
    const flipCeiling = 50.0;
    final openBar = _referenceHost ? openCeiling : openCeiling * 10;
    final flipBar = _referenceHost ? flipCeiling : flipCeiling * 10;
    print(
      '1.5 MB note: open frame ${open.toStringAsFixed(1)} ms '
      '(held to $openBar), read pane frame ${flip.toStringAsFixed(1)} ms '
      '(held to $flipBar)',
    );
    expect(open, lessThan(openBar));
    expect(flip, lessThan(flipBar));
  });
}
