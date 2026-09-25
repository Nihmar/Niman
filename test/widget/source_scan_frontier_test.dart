// An edit that changes what the rest of the note is (#246, and
// `docs/records/huge-notes.md` item 3): the keystroke scans a budget of lines, the
// lines drawn catch the scan up as far as they need, and the rest is carried
// on while the app is idle — with the same colours a fresh read gives.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_styler.dart';

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

void main() {
  testWidgets(r'a `$$` opened at the top is carried on, and draws right', (
    tester,
  ) async {
    // Five thousand formulas, each with a heading and prose after it: far
    // more lines than one keystroke's budget, all of them turned inside out
    // by one more `$$` above them.
    final note = [
      for (var at = 0; at < 5000; at++) ...[
        r'$$',
        'x_$at',
        r'$$',
        '# h$at',
        '',
      ],
    ].join('\n');
    final buffer = SourceBuffer.fromText(note);
    expect(buffer.lineCount, greaterThan(4 * BlockScanner.defaultBudget));
    tester.view.physicalSize = const Size(700, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownSourceView(buffer: buffer, theme: _theme),
        ),
      ),
    );
    await tester.pump();
    final view = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    expect(view.headings, hasLength(5000));

    view.replaceText(
      0,
      0,
      r'$$'
      '\n',
    );
    expect(view.scanSettled, isFalse, reason: 'the keystroke paid its budget');
    expect(view.headings, isNull, reason: 'the outline waits for the scan');

    // The lines on screen are coloured as a fresh read colours them.
    var fresh = SourceStyler(SourceBuffer.fromText(buffer.text));
    for (var line = 0; line < 20; line++) {
      expect(
        view.tokensOf(line),
        fresh.tokensOf(line),
        reason: 'line $line: ${buffer.lineAt(line)}',
      );
    }
    expect(view.scanSettled, isFalse, reason: 'and only they were caught up');

    // The rest is carried on a slice at a time, each a timer of its own, so
    // the next turn of the event loop — a frame, a key — waits for one slice
    // at most. (The unit test counts the slices; here they all run inside
    // one pump, which is what fake time does with zero-length timers.)
    await tester.pump(Duration.zero);
    expect(view.scanSettled, isTrue);
    // Every `$$` now opens where it closed, so every heading is inside a
    // formula — which is what a fresh read says too.
    expect(view.headings, hasLength(fresh.headings!.length));
    expect(view.headings, isEmpty);

    // Closed again, and a line far down asked for at once — a jump to the
    // end draws it before any slice has run: it is scanned up to, and right.
    view.replaceText(0, 3, '');
    expect(view.scanSettled, isFalse);
    fresh = SourceStyler(SourceBuffer.fromText(buffer.text));
    for (final line in <int>[20000, 24990, 3, 0]) {
      expect(
        view.tokensOf(line),
        fresh.tokensOf(line),
        reason: 'line $line: ${buffer.lineAt(line)}',
      );
    }
    await tester.pump(Duration.zero);
    expect(view.scanSettled, isTrue);
    expect(view.headings, hasLength(5000));
  });
}
