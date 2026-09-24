// Typewriter mode and the Zen caret on the source surface (#245, phase 3;
// the legacy editor's #70 and #69): the row being written keeps to the middle
// and is lit, and Zen draws a thicker caret.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
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

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester, {
  bool typewriter = false,
  double? caretWidth,
  bool live = false,
}) async {
  tester.view.physicalSize = const Size(600, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final text = List<String>.generate(80, (at) => 'riga $at').join('\n');
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          typewriter: typewriter,
          caretWidth: caretWidth,
          // The mode hides markers; this note has none, and what is under test
          // is where the row being written is kept.
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// Where the caret's row is, as a share of the pane's height.
double _caretShare(WidgetTester tester, MarkdownSourceViewState state) {
  final pane = tester.getRect(find.byType(CustomScrollView));
  return (state.caretRect!.center.dy - pane.top) / pane.height;
}

/// Whether a line paints the typewriter's row light.
bool _rowLit(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .any((paint) => paint.painter?.runtimeType.toString() == '_RowPainter');

void main() {
  /// The same test in `source` and in `live` (#246).
  void both(
    String name,
    Future<void> Function(WidgetTester tester, _Mode mode) body,
  ) {
    for (final mode in _Mode.values) {
      testWidgets('$name (${mode.name})', (tester) => body(tester, mode));
    }
  }

  both('typewriter mode keeps the caret row in the middle', (
    tester,
    mode,
  ) async {
    final state = await _pump(
      tester,
      typewriter: true,
      live: mode == _Mode.live,
    );
    state.focusNode.requestFocus();
    await tester.pump();
    for (var line = 0; line < 40; line++) {
      state.moveCaretVertically(1);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(_caretShare(tester, state), closeTo(0.5, 0.06));
    expect(_rowLit(tester), isTrue);
  });

  both('the last line can reach the middle too', (tester, mode) async {
    final state = await _pump(
      tester,
      typewriter: true,
      live: mode == _Mode.live,
    );
    state.focusNode.requestFocus();
    await tester.pump();
    state.moveCaretBy(CaretMotion.documentEnd);
    await tester.pumpAndSettle();
    expect(_caretShare(tester, state), closeTo(0.5, 0.06));
  });

  both('without it the caret row stays where it is drawn', (
    tester,
    mode,
  ) async {
    final state = await _pump(tester, live: mode == _Mode.live);
    state.focusNode.requestFocus();
    await tester.pump();
    state.moveCaretBy(CaretMotion.documentEnd);
    await tester.pumpAndSettle();
    expect(_caretShare(tester, state), greaterThan(0.8));
    expect(_rowLit(tester), isFalse);
  });

  both('a note put back without the focus is not moved', (tester, mode) async {
    final state = await _pump(
      tester,
      typewriter: true,
      live: mode == _Mode.live,
    );
    // Line 15: on screen, well below the middle.
    state.placeCaret(110);
    await tester.pumpAndSettle();
    expect(state.scrollOffset, lessThan(1));
  });

  both('Zen draws the caret thicker', (tester, mode) async {
    final plain = await _pump(tester, live: mode == _Mode.live);
    await tester.pump();
    expect(plain.caretRect!.width, 1.5);
    final zen = await _pump(tester, caretWidth: 3, live: mode == _Mode.live);
    await tester.pump();
    expect(zen.caretRect!.width, 3);
  });
}
