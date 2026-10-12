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
    final opener = tester.getRect(
      find.text(':::: columns', findRichText: true),
    );
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

  testWidgets('in live on a wide pane the columns sit side by side', (
    tester,
  ) async {
    await _pump(tester, _two, live: true);
    final left = tester.getRect(find.text('first left', findRichText: true));
    final right = tester.getRect(find.text('first right', findRichText: true));
    expect(right.left, greaterThan(left.right));
    expect((right.top - left.top).abs(), lessThan(2));
    final after = tester.getRect(find.text('After', findRichText: true));
    final second = tester.getRect(find.text('second left', findRichText: true));
    expect(after.top, greaterThanOrEqualTo(second.bottom));
  });

  testWidgets('in source the columns stay line by line', (tester) async {
    await _pump(tester, _two);
    final left = tester.getRect(find.text('first left', findRichText: true));
    final right = tester.getRect(find.text('first right', findRichText: true));
    expect(right.top, greaterThan(left.bottom));
  });

  group('editing side by side', () {
    testWidgets('a tap in a column puts the caret in that column', (
      tester,
    ) async {
      final state = await _pump(tester, _two, live: true);
      final right = find.text('first right', findRichText: true);
      await tester.tapAt(tester.getRect(right).centerLeft + const Offset(2, 0));
      await tester.pump();
      final start = _two.indexOf('first right');
      expect(state.selection.extent, inInclusiveRange(start, start + 1));
      final left = find.text('first left', findRichText: true);
      await tester.tapAt(tester.getRect(left).centerRight - const Offset(2, 0));
      await tester.pump(const Duration(milliseconds: 500));
      final end = _two.indexOf('first left') + 'first left'.length;
      expect(state.selection.extent, inInclusiveRange(end - 1, end));
    });

    testWidgets('typing in a column keeps the columns side by side', (
      tester,
    ) async {
      final state = await _pump(tester, _two, live: true);
      final at = _two.indexOf('first right');
      state.replaceText(at, at, 'new\nlines\n');
      await tester.pump();
      await tester.pump();
      final left = tester.getRect(find.text('first left', findRichText: true));
      final right = tester.getRect(
        find.text('first right', findRichText: true),
      );
      final added = tester.getRect(find.text('new', findRichText: true));
      expect(added.left, greaterThan(left.right));
      expect(right.top, greaterThan(added.bottom));
      // The caret is drawn where it is, in the right column.
      final caret = state.caretRect!;
      expect(caret.left, greaterThan(left.right));
    });

    testWidgets('a jump to a line in a column scrolls to it', (tester) async {
      final note = StringBuffer();
      for (var at = 0; at < 80; at++) {
        note.writeln('line $at');
      }
      note.write(_two);
      for (var at = 0; at < 80; at++) {
        note.writeln('more $at');
      }
      final state = await _pump(tester, note.toString(), live: true);
      // "first right" is line 80 + 10.
      state.jumpToLine(90);
      await tester.pump();
      await tester.pump();
      final right = tester.getRect(
        find.text('first right', findRichText: true),
      );
      expect(right.top, lessThan(60));
      expect(right.top, greaterThanOrEqualTo(-1));
    });
  });
}
