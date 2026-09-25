// Selecting by touch on the source surface (#245, phase 3): a long press
// takes a word, the handles move its ends, the toolbar acts on it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/touch_selection.dart';
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

/// Column [column] of line [line], as the view lays the text out (14 px a
/// glyph, a 5 px inset, an 8 px top margin, 21 px rows).
Offset _at(int line, int column) =>
    Offset(5 + column * 14.0 + 7, 8 + line * 21.0 + 10);

/// Which unified mode a body is being run in: the same tests, twice.
enum _Mode { source, live }

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester,
  String text, {
  bool live = false,
}) async {
  tester.view.physicalSize = const Size(700, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

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

  both('a long press takes the word, and shows the handles', (
    tester,
    mode,
  ) async {
    final state = await _pump(
      tester,
      'una parola sola\n',
      live: mode == _Mode.live,
    );
    await tester.longPressAt(_at(0, 6));
    await tester.pumpAndSettle();
    expect(state.selectedText, 'parola');
    expect(find.byKey(const ValueKey(SelectionHandle.start)), findsOneWidget);
    expect(find.byKey(const ValueKey(SelectionHandle.end)), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget, reason: 'the toolbar is up');
  });

  both('a double tap takes the word, and shows the handles and the toolbar', (
    tester,
    mode,
  ) async {
    final state = await _pump(
      tester,
      'una parola sola\n',
      live: mode == _Mode.live,
    );
    final at = _at(0, 6);
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(at);
    await tester.pumpAndSettle();
    expect(state.selectedText, 'parola');
    expect(find.byKey(const ValueKey(SelectionHandle.start)), findsOneWidget);
    expect(find.byKey(const ValueKey(SelectionHandle.end)), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget, reason: 'the toolbar is up');
  });

  both('dragging the end handle moves the end of the selection', (
    tester,
    mode,
  ) async {
    final state = await _pump(
      tester,
      'una parola sola\n',
      live: mode == _Mode.live,
    );
    await tester.longPressAt(_at(0, 6));
    await tester.pumpAndSettle();
    // Five glyphs to the right: over " sola".
    await tester.drag(
      find.byKey(const ValueKey(SelectionHandle.end)),
      const Offset(5 * 14.0, 0),
    );
    await tester.pumpAndSettle();
    expect(state.selectedText, 'parola sola');
  });

  both('Copy puts the selection on the clipboard', (tester, mode) async {
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, 'una parola sola\n', live: mode == _Mode.live);
    await tester.longPressAt(_at(0, 6));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(clipboard, 'parola');
    expect(find.text('Copy'), findsNothing, reason: 'the toolbar went');
  });

  both('a tap elsewhere puts the handles away', (tester, mode) async {
    final state = await _pump(
      tester,
      'una parola sola\n\n\n\n\n\n\nfine\n',
      live: mode == _Mode.live,
    );
    await tester.longPressAt(_at(0, 6));
    await tester.pumpAndSettle();
    await tester.tapAt(_at(7, 2));
    await tester.pumpAndSettle();
    expect(state.selection.isCollapsed, isTrue);
    expect(find.byKey(const ValueKey(SelectionHandle.end)), findsNothing);
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('in live the handles follow the word the press revealed', (
    tester,
  ) async {
    // The press lands on `parola` while its `**` are hidden and take no room;
    // taking the word puts the caret in its run, which draws them, and the
    // word moves right by their width. The handles are read from the layout,
    // so they must be read from the one drawn *after* the reveal — which is
    // the line as `source` draws it.
    const note = 'una **parola** sola\n';
    Future<Rect> handleAfterPress(int column, {required bool live}) async {
      final state = await _pump(tester, note, live: live);
      await tester.longPressAt(_at(0, column));
      await tester.pumpAndSettle();
      expect(state.selectedText, 'parola');
      return tester.getRect(find.byKey(const ValueKey(SelectionHandle.end)));
    }

    final source = await handleAfterPress(8, live: false);
    // Two glyphs to the left: where `parola` is while its markers are hidden.
    final live = await handleAfterPress(6, live: true);
    expect(live.left, closeTo(source.left, 1), reason: 'the drawn word');
  });
}
