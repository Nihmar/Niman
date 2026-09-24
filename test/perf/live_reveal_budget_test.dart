// What the marker reveal costs per caret move (#246, phase 4; §8.6.2).
//
// The design's budget is two claims, and this test holds the one a host can
// hold: **the flip costs one line's re-layout, and never fires more than once
// per run change**. The reveal is a style, so nothing is re-parsed and no
// offset moves; the only work is the line that lost the caret and the line
// that gained it.
//
// What is timed is the *frame* a move causes — build, layout and paint of the
// viewport's lines — because that is the quantity a writer feels and it is an
// upper bound on the re-layout inside it. The absolute number is printed; the
// ceiling (3 ms, §9.2) is asserted only under `NIMAN_PERF=1`, since a shared
// runner reads different numbers on the same commit for the hardware, not for
// the code (`AGENTS.md`). The property that holds on any host is the ratio: a
// note ten times larger may not make a reveal frame cost anywhere near ten
// times more, which is what an O(note) step on the path would look like.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

/// A note of about [lines] lines, every third of them carrying a bold run and a
/// link — the syntax the reveal has to flip.
String _note(int lines) => List<String>.generate(
  lines,
  (at) => at % 10 == 0
      ? '# Capitolo $at'
      : 'Una riga con **grassetto** e un [link](u) numero $at.',
).join('\n');

/// Microseconds per reveal frame in a [lines]-line note in `live` mode.
///
/// The caret is moved between two words of the *same* line, so each move
/// crosses a run boundary and flips the reveal — the thing the budget is
/// about. A move inside a word is the free case and is held elsewhere
/// (`markdown_surface_test.dart`), by the value the lines listen to.
Future<double> _perReveal(WidgetTester tester, int lines) async {
  final buffer = SourceBuffer.fromText(_note(lines));
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSurface(
          key: UniqueKey(),
          buffer: buffer,
          mode: MarkdownSurfaceMode.live,
          theme: _theme,
          showLineNumbers: false,
        ),
      ),
    ),
  );
  await tester.pump();
  final view = tester.state<MarkdownSourceViewState>(
    find.byType(MarkdownSourceView),
  );
  // Two offsets in the first line's own text, in different runs: `Una` and
  // `riga`, the words before and after the first space.
  const first = 1;
  const second = 5;
  // Warm up, so the timing is of a settled note rather than of the first frame
  // that colours it.
  for (var at = 0; at < 5; at++) {
    view.placeCaret(first);
    await tester.pump();
    view.placeCaret(second);
    await tester.pump();
  }
  const moves = 40;
  final clock = Stopwatch()..start();
  for (var at = 0; at < moves; at++) {
    view.placeCaret(at.isEven ? second : first);
    await tester.pump();
  }
  clock.stop();
  // The two offsets are one space apart inside one line, so the run really did
  // change: the test would be measuring nothing otherwise.
  expect(
    runAround(buffer.lineAt(0), first),
    isNot(runAround(buffer.lineAt(0), second)),
  );
  return clock.elapsedMicroseconds / moves;
}

void main() {
  testWidgets('a reveal frame does not cost the note', (tester) async {
    final small = await _perReveal(tester, 2000);
    final large = await _perReveal(tester, 20000);
    print(
      'reveal frame, caret across a word boundary: '
      '${(small / 1000).toStringAsFixed(3)} ms at 2 000 lines, '
      '${(large / 1000).toStringAsFixed(3)} ms at 20 000 lines '
      '(×${(large / small).toStringAsFixed(1)})',
    );
    // Ten times the note. A step proportional to the note would show up here.
    expect(large / small, lessThan(4));
    // The backstop every run keeps: a frame this slow would be visible on any
    // host, whatever the hardware.
    expect(large, lessThan(40 * 1000));
    if (Platform.environment['NIMAN_PERF'] == '1') {
      // §9.2's budget, asked for rather than assumed.
      expect(
        large,
        lessThan(3 * 1000),
        reason: 'the reveal must fit in one line re-layout (3 ms)',
      );
    }
  });
}
