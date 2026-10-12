// A keystroke in the middle of a long side-by-side `columns` block in
// `live` (#729, `docs/records/note-columns.md`, "Performance bars"): the
// block is one row of the note and each column a windowed sliver, so a
// character typed in a column costs what a character costs anywhere — a
// rescan of the lines it changed, and a frame of the lines on screen.
//
// Every run holds the counts — the rescan reads fewer than 64 lines, the
// frame lays out fewer than 200 — and prints the time. The time is a
// debug harness's (the ratios carry, the absolutes do not), so the bar a
// run asks for with `NIMAN_PERF=1` is a ratio: a keystroke in a column
// costs no more than 1.5 times one in a note of the same lines without
// columns.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_line.dart';
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

/// How much more a keystroke in a column may cost than one outside.
const double _ratio = 1.5;

/// A note of [lines] lines of prose a side, in two columns of one block
/// when [columns], one side after the other otherwise.
String _note(int lines, {required bool columns}) {
  final note = StringBuffer(columns ? ':::: columns\n::: column\n' : '');
  for (final side in ['Left', 'Right']) {
    if (columns && side == 'Right') note.writeln(':::\n::: column');
    for (var at = 0; at < lines; at++) {
      note.writeln('$side line $at of prose, with **bold** and a [[link]].');
    }
  }
  if (columns) note.writeln(':::\n::::');
  return note.toString();
}

/// What a keystroke costs in the middle of the left side of [text]: the
/// time, the lines the scan read and the lines laid out.
Future<({double micros, int scanned, int laidOut})> _keystroke(
  WidgetTester tester,
  String text,
  int line,
) async {
  final buffer = SourceBuffer.fromText(text);
  final platform = FakeEmbedder(tester, EmbedderProfile.android)..install();
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          key: UniqueKey(),
          buffer: buffer,
          theme: _theme,
          hideMarkers: true,
          showLineNumbers: false,
          onChanged: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  final view = tester.state<MarkdownSourceViewState>(
    find.byType(MarkdownSourceView),
  );
  await tester.tapAt(const Offset(60, 40));
  await tester.pump();
  view
    ..jumpToLine(line)
    ..placeCaret(buffer.offsetOfLine(line) + 5);
  await tester.pump();
  await tester.pump();
  // Warm up, then time.
  await platform.type('abcdefghij');
  await tester.pump();
  const keys = 40;
  final scannedBefore = view.scanProgress;
  final clock = Stopwatch()..start();
  for (var at = 0; at < keys; at++) {
    await platform.type('x');
    await tester.pump();
  }
  clock.stop();
  return (
    micros: clock.elapsedMicroseconds / keys,
    scanned: ((view.scanProgress - scannedBefore) / keys).ceil(),
    laidOut: find.byType(SourceLine).evaluate().length,
  );
}

void main() {
  testWidgets('a keystroke in a 5 000-line columns block', (tester) async {
    final plain = await _keystroke(tester, _note(2500, columns: false), 1250);
    final columns = await _keystroke(tester, _note(2500, columns: true), 1252);
    print(
      'columns keystroke: ${(columns.micros / 1000).toStringAsFixed(3)} ms, '
      '${columns.scanned} lines rescanned, ${columns.laidOut} laid out; '
      'without columns ${(plain.micros / 1000).toStringAsFixed(3)} ms. '
      'Bar: fewer than 64 rescanned, 200 laid out; $_ratio x the time '
      'under NIMAN_PERF',
    );
    expect(columns.scanned, lessThan(64));
    expect(columns.laidOut, lessThan(200));
    if (Platform.environment['NIMAN_PERF'] == '1') {
      expect(columns.micros, lessThanOrEqualTo(_ratio * plain.micros));
    }
  });
}
