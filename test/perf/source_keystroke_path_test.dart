// What a keystroke costs through the *whole* source surface, not only through
// its data layers (#245, phase 3; §10.4, spike 7).
//
// `source_edit_timing_test.dart` times the buffer, the tokenizer and the height
// map, and reads 0.075 ms — but a device run showed a surface that was slow
// anyway, because the cost was elsewhere: the whole note joined to answer the
// platform, the height map rebuilt, a view that rebuilt every line. This times
// the path a keystroke really takes — a delta from the platform (built on the
// platform's own copy, `oldText` and all, the way Android sends it), the
// surface applying it, and the frame that draws it — at two note sizes.
//
// The property held on any host is the **ratio**: a keystroke on a note fifty
// times larger may not cost anywhere near fifty times more, which is what an
// O(n) step on the path looks like. The absolute numbers are printed.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

import '../fakes/fake_embedder.dart';

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

/// A note of about [lines] lines of prose.
String _note(int lines) => List<String>.generate(
  lines,
  (at) => at % 10 == 0
      ? '# Capitolo $at'
      : 'Una riga di prosa con **grassetto** e un [[wikilink]], $at.',
).join('\n');

/// Microseconds per keystroke typed at the top of a note of [lines] lines.
Future<double> _perKeystroke(WidgetTester tester, int lines) async {
  final buffer = SourceBuffer.fromText(_note(lines));
  final platform = FakeEmbedder(tester, EmbedderProfile.android)..install();
  tester.view.physicalSize = const Size(600, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          key: UniqueKey(),
          buffer: buffer,
          theme: _theme,
          showLineNumbers: false,
          onChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tapAt(const Offset(30, 40));
  await tester.pump();
  // Warm up, then time.
  await platform.type('abcdefghij');
  await tester.pump();
  const keys = 60;
  final clock = Stopwatch()..start();
  for (var at = 0; at < keys; at++) {
    await platform.type('x');
    await tester.pump();
  }
  clock.stop();
  // The platform holds a window of the note, and that window is the note.
  final view = tester.state<MarkdownSourceViewState>(
    find.byType(MarkdownSourceView),
  );
  final from = view.platformWindowStart;
  expect(
    platform.text,
    buffer.substring(from, from + platform.text.length),
    reason: 'the two copies stayed in step',
  );
  expect(
    platform.text.length,
    lessThan(buffer.length ~/ 10),
    reason: 'the platform holds a window, not the note',
  );
  return clock.elapsedMicroseconds / keys;
}

void main() {
  testWidgets('a keystroke does not cost the note', (tester) async {
    final small = await _perKeystroke(tester, 400);
    final large = await _perKeystroke(tester, 20000);
    print(
      'keystroke, delta to frame: ${(small / 1000).toStringAsFixed(3)} ms at '
      '400 lines, ${(large / 1000).toStringAsFixed(3)} ms at 20 000 lines '
      '(×${(large / small).toStringAsFixed(1)})',
    );
    // Fifty times the note. An O(n) step on the path would make this ratio
    // follow the size — the platform message was one, `oldText` the whole
    // note, until the platform was given a window of it.
    expect(large / small, lessThan(4));
  });
}
