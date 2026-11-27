// A line of Hebrew or Arabic is drawn right to left, and Left and Right move
// the caret the way they point on it (#1352).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// A Latin line, a Hebrew one and an Arabic one, in `source` or in `live`.
Future<MarkdownSourceViewState> _pump(
  WidgetTester tester, {
  bool live = false,
}) async {
  tester.view.physicalSize = const Size(500, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText('abc def\nשלום עולם\nمرحبا بالعالم'),
          look: SourceLook(
            theme: _theme,
            showLineNumbers: false,
            hideMarkers: live,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.byType(MarkdownSourceView));
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// The direction the paragraph that draws [text] is laid out in.
TextDirection? _directionOf(WidgetTester tester, String text) => tester
    .widgetList<RichText>(find.byType(RichText))
    .firstWhere((rich) => rich.text.toPlainText().contains(text))
    .textDirection;

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
  await tester.pump();
}

void main() {
  for (final live in <bool>[false, true]) {
    final mode = live ? 'live' : 'source';

    testWidgets('each line has the direction of its first letter ($mode)', (
      tester,
    ) async {
      await _pump(tester, live: live);
      expect(_directionOf(tester, 'abc def'), TextDirection.ltr);
      expect(_directionOf(tester, 'שלום'), TextDirection.rtl);
      expect(_directionOf(tester, 'مرحبا'), TextDirection.rtl);
    });

    testWidgets('Right moves the caret to the right on a Hebrew line ($mode)', (
      tester,
    ) async {
      final state = await _pump(tester, live: live);
      state.placeCaret(8 + 4);
      await tester.pump();
      await tester.pump();
      for (var step = 0; step < 3; step++) {
        final before = state.caretRect!.left;
        final offset = state.selection.extent;
        await _press(tester, LogicalKeyboardKey.arrowRight);
        expect(state.caretRect!.left, greaterThan(before), reason: 'Right');
        expect(state.selection.extent, offset - 1, reason: 'logically back');
      }
      for (var step = 0; step < 3; step++) {
        final before = state.caretRect!.left;
        await _press(tester, LogicalKeyboardKey.arrowLeft);
        expect(state.caretRect!.left, lessThan(before), reason: 'Left');
      }
    });

    testWidgets('and on an Arabic one, with Shift selecting ($mode)', (
      tester,
    ) async {
      final state = await _pump(tester, live: live);
      const start = 8 + 9 + 1;
      state.placeCaret(start + 3);
      await tester.pump();
      await tester.pump();
      final before = state.caretRect!.left;
      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(state.caretRect!.left, greaterThan(before));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(state.selection.isCollapsed, isFalse);
      expect(state.selection.extent, start + 3, reason: 'one to the left');
    });

    testWidgets('a Latin line is as it was ($mode)', (tester) async {
      final state = await _pump(tester, live: live);
      state.placeCaret(2);
      await tester.pump();
      await tester.pump();
      final before = state.caretRect!.left;
      await _press(tester, LogicalKeyboardKey.arrowRight);
      expect(state.selection.extent, 3);
      expect(state.caretRect!.left, greaterThan(before));
      await _press(tester, LogicalKeyboardKey.arrowLeft);
      expect(state.selection.extent, 2);
    });
  }
}
