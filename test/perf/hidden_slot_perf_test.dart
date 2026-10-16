// Issue #1079: what a divider drag costs with five kept-alive notes behind
// the one showing. Each note is a column of text lines standing for the
// editor; `Offstage` lays all five out on every frame, `HiddenSlot` only
// the one on stage.
//
// The numbers are printed. The backstop every run asserts is relative —
// hidden slots must not cost more than `Offstage` — because wall-clock
// absolutes differ between hosts; the design's ceiling (a drag frame at
// least twice as cheap) is asserted by `NIMAN_PERF=1`.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/hidden_slot.dart';

void main() {
  const notes = 5;
  const frames = 60;

  Widget note(int index) => ListView(
    children: [
      for (var line = 0; line < 400; line++)
        Text('note $index line $line ' * 6, softWrap: true),
    ],
  );

  /// Pumps [frames] widths and returns the elapsed milliseconds.
  Future<double> drag(WidgetTester tester, {required bool hidden}) async {
    Widget stack(double width) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            height: 600,
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (var i = 0; i < notes; i++)
                  if (hidden)
                    HiddenSlot(hidden: i != 0, child: note(i))
                  else
                    Offstage(offstage: i != 0, child: note(i)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(stack(800));
    final watch = Stopwatch()..start();
    for (var frame = 0; frame < frames; frame++) {
      await tester.pumpWidget(stack(800 - frame * 3.0));
    }
    return watch.elapsedMicroseconds / 1000;
  }

  testWidgets('a divider drag over five kept notes lays out only the shown', (
    tester,
  ) async {
    // Warm up, then measure each twice and keep the better.
    await drag(tester, hidden: false);
    final offstage = [
      await drag(tester, hidden: false),
      await drag(tester, hidden: false),
    ].reduce((a, b) => a < b ? a : b);
    final slot = [
      await drag(tester, hidden: true),
      await drag(tester, hidden: true),
    ].reduce((a, b) => a < b ? a : b);

    // The number is the output of this test: a perf round reads it.
    // ignore: avoid_print
    print(
      'divider drag, $frames frames, $notes kept notes: '
      'Offstage ${offstage.toStringAsFixed(0)} ms, '
      'HiddenSlot ${slot.toStringAsFixed(0)} ms '
      '(${(offstage / slot).toStringAsFixed(1)}x)',
    );

    final ceiling = Platform.environment['NIMAN_PERF'] == '1';
    // The backstop: never slower than the Offstage it replaces, with the
    // noise of a shared runner allowed for.
    expect(slot, lessThan(offstage * 1.5));
    // The design: the four hidden notes drop out of the frame (a frame here
    // also rebuilds all five, which no layout skip can save).
    if (ceiling) expect(slot, lessThan(offstage / 1.2));
  });
}
