// The note's columns in the source surface (#729,
// `docs/records/note-columns.md`, "Live: side by side, and editable"):
// `source` line by line, `live` side by side where the pane allows.
import 'package:flutter/material.dart';
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

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester,
  String note, {
  bool live = false,
  double width = 1000,
  double height = 700,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(note),
          theme: _theme,
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// Whether a line with [text] is drawn.
bool _drawn(String text) =>
    find.text(text, findRichText: true).evaluate().isNotEmpty;

const String _two = '''
# Top
:::: columns
::: {.column width="40%"}
## Left
first left
second left
:::

::: column
## Right
first right
:::
::::
After
''';

void main() {
  for (final live in [false, true]) {
    final mode = live ? 'live' : 'source';
    testWidgets('the outer opener folds the block to itself ($mode)', (
      tester,
    ) async {
      final state = await _pump(tester, _two, live: live);
      expect(find.byKey(const ValueKey<String>('fold-1')), findsOneWidget);
      state.toggleFold(1);
      await tester.pump();
      expect(_drawn('first left'), isFalse);
      expect(_drawn('first right'), isFalse);
      expect(_drawn('After'), isTrue);
    });

    testWidgets('a heading in a column folds inside the column ($mode)', (
      tester,
    ) async {
      final state = await _pump(tester, _two, live: live);
      state.toggleFold(3);
      await tester.pump();
      expect(_drawn('first left'), isFalse);
      expect(_drawn('second left'), isFalse);
      expect(_drawn('first right'), isTrue);
      // The heading above the block folds the block with it.
      state
        ..toggleFold(3)
        ..toggleFold(0);
      await tester.pump();
      expect(_drawn('first right'), isFalse);
      expect(_drawn('After'), isFalse);
    });
  }

  testWidgets('in live a fence line is a band of half an em', (tester) async {
    await _pump(tester, _two, live: true, width: 500);
    // 0.5 em of the 14 px body text.
    final opener = tester.getRect(find.text(':::: columns', findRichText: true));
    expect(opener.height, closeTo(7, 0.5));
    final closer = tester.getRect(find.text('::::', findRichText: true));
    expect(closer.height, closeTo(7, 0.5));
  });

  testWidgets('the caret on a fence line shows its source', (tester) async {
    final state = await _pump(tester, _two, live: true, width: 500);
    // Line 2, the column's opener.
    state.placeCaret(_two.indexOf('::: {.column'));
    await tester.pump();
    final opener = tester.getRect(
      find.text('::: {.column width="40%"}', findRichText: true),
    );
    expect(opener.height, greaterThan(14));
  });
}
