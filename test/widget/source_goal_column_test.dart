// Up and Down keep their column across a line that is shorter, or empty
// (#1348).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
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

/// `abcdefghij`, an empty line, `abcdefghij`: the caret at line 0, column 8.
Future<MarkdownSourceViewState> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(500, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText('abcdefghij\n\nabcdefghij'),
          look: const SourceLook(theme: _theme, showLineNumbers: false),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.byType(MarkdownSourceView));
  await tester.pump();
  final state = tester.state<MarkdownSourceViewState>(
    find.byType(MarkdownSourceView),
  )..placeCaret(8);
  await tester.pump();
  await tester.pump();
  return state;
}

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('Down through an empty line comes back to the column', (
    tester,
  ) async {
    final state = await _pump(tester);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(state.selection, const SelectionModel.at(11), reason: 'empty line');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(state.selection, const SelectionModel.at(20), reason: 'column 8');
  });

  testWidgets('Up likewise', (tester) async {
    final state = await _pump(tester);
    state.placeCaret(20);
    await tester.pump();
    await tester.pump();
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(state.selection, const SelectionModel.at(11));
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(state.selection, const SelectionModel.at(8));
  });

  testWidgets('a horizontal move starts the column again', (tester) async {
    final state = await _pump(tester);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(state.selection, const SelectionModel.at(11));
    await _press(tester, LogicalKeyboardKey.arrowRight);
    expect(state.selection, const SelectionModel.at(12));
    await _press(tester, LogicalKeyboardKey.arrowUp);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(state.selection, const SelectionModel.at(0), reason: 'column 0');
  });

  testWidgets('a caret put somewhere else starts the column again', (
    tester,
  ) async {
    final state = await _pump(tester);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    state.placeCaret(3);
    await tester.pump();
    await tester.pump();
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(state.selection, const SelectionModel.at(15), reason: 'column 3');
  });
}
