// A scroll frame at the end of a note of 500 side-by-side `columns`
// blocks in `live` (#729, `docs/records/note-columns.md`, "Many blocks"):
// each block is a sliver of its own, and so is each run of rows between
// two, so the note is a thousand slivers. A sliver wholly off screen lays
// out nothing; one that laid out its last child — what a run of rows did
// before — would lay out a line apiece each frame, off screen.
//
// Every run holds the count: the lines built — on screen or off — are a
// viewport's and its cache area's, not a line for each block. The time is
// printed, and a run with `NIMAN_PERF=1` holds a frame's cost a line built
// to 1.5 times a frame's of the same lines without columns: a block of
// short columns puts twice the lines on a screen.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

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

/// How much more a frame may cost than one without columns.
const double _ratio = 1.5;

/// [blocks] blocks of two short columns, with a line of prose between two,
/// or the same lines without the fences.
String _note(int blocks, {required bool columns}) {
  final note = StringBuffer();
  for (var at = 0; at < blocks; at++) {
    note.writeln('Between $at.');
    if (columns) note.writeln('\n:::: columns\n::: column');
    note.writeln('Left $at.');
    if (columns) note.writeln(':::\n::: column');
    note.writeln('Right $at.');
    if (columns) note.writeln(':::\n::::\n');
  }
  return note.toString();
}

/// A scroll frame at the end of [text]: what it took, and how many lines
/// are built.
Future<({double micros, int built})> _scrollAtEnd(
  WidgetTester tester,
  String text,
) async {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = ScrollController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          key: UniqueKey(),
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          hideMarkers: true,
          showLineNumbers: false,
          controller: controller,
        ),
      ),
    ),
  );
  await tester.pump();
  // To the end, as far as frames take it.
  for (var frame = 0; frame < 20; frame++) {
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
  }
  const frames = 20;
  final clock = Stopwatch()..start();
  for (var frame = 0; frame < frames; frame++) {
    controller.jumpTo(controller.position.maxScrollExtent - 40 * (frame % 2));
    await tester.pump();
  }
  clock.stop();
  final built = find.byType(SourceLine, skipOffstage: false).evaluate().length;
  return (micros: clock.elapsedMicroseconds / frames, built: built);
}

void main() {
  testWidgets('a scroll frame at the end of 500 columns blocks', (
    tester,
  ) async {
    final plain = await _scrollAtEnd(tester, _note(500, columns: false));
    final columns = await _scrollAtEnd(tester, _note(500, columns: true));
    print(
      'columns scroll frame: ${(columns.micros / 1000).toStringAsFixed(3)} '
      'ms, ${columns.built} lines built; without columns '
      '${(plain.micros / 1000).toStringAsFixed(3)} ms, ${plain.built} '
      'built. Bar: fewer than 200 built; $_ratio x the time a line built '
      'under NIMAN_PERF',
    );
    expect(columns.built, lessThan(200));
    if (Platform.environment['NIMAN_PERF'] == '1') {
      expect(
        columns.micros / columns.built,
        lessThanOrEqualTo(_ratio * plain.micros / plain.built),
      );
    }
  });
}
