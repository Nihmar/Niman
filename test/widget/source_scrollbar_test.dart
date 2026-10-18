// The editor's scrollbar is the scrollbar's (#1106): hovering it keeps the
// arrow, and a drag on it scrolls without moving the caret or the selection.
import 'package:flutter/gestures.dart';
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

/// A note long enough to scroll in a 900x500 pane.
String _note() =>
    [for (var i = 0; i < 80; i++) 'riga numero $i con un po di testo']
        .join('\n');

Future<MarkdownSourceViewState> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      // The desktop scrollbar: MaterialScrollBehavior adds it only on a
      // desktop platform.
      theme: ThemeData(platform: TargetPlatform.linux),
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(_note()),
          theme: _theme,
          showLineNumbers: false,
        ),
      ),
    ),
  );
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// The pane's scroll position.
ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(MarkdownSourceView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// The pane's scroll offset.
double _offset(WidgetTester tester) => _position(tester).pixels;

/// The note's own mouse cursor, read off the region that wraps it.
MouseCursor _cursor(WidgetTester tester) => tester
    .widget<MouseRegion>(
      find
          .ancestor(
            of: find.descendant(
              of: find.byType(MarkdownSourceView),
              matching: find.byType(CustomScrollView),
            ),
            matching: find.byType(MouseRegion),
          )
          .first,
    )
    .cursor;

void main() {
  testWidgets('the desktop scrollbar is there', (tester) async {
    await _pump(tester);
    expect(find.byType(Scrollbar), findsOneWidget);
  });

  testWidgets('hovering the scrollbar keeps the arrow, not the I-beam', (
    tester,
  ) async {
    await _pump(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(896, 50));
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(const Offset(896, 50));
    await tester.pump();
    expect(_cursor(tester), SystemMouseCursors.basic);

    // Back over the text, the I-beam returns.
    await gesture.moveTo(const Offset(200, 50));
    await tester.pump();
    expect(_cursor(tester), SystemMouseCursors.text);
  });

  testWidgets('dragging the scrollbar scrolls and takes no selection', (
    tester,
  ) async {
    final state = await _pump(tester);
    expect(state.selection.isCollapsed, isTrue);
    // Show the bar the way a scroll does, so its thumb is painted and the
    // drag can take it.
    final position = _position(tester);
    for (final to in const <double>[1, 0]) {
      position.jumpTo(to);
      await tester.pump(const Duration(milliseconds: 100));
    }
    final before = position.pixels;

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(896, 30));
    addTearDown(gesture.removePointer);
    await tester.pump();
    // Hover first: the bar fades in and its thumb is measured, so the drag
    // is taken as a thumb drag and not as a track tap.
    await gesture.moveTo(const Offset(896, 30));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.down(const Offset(896, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(state.selection.isCollapsed, isTrue, reason: 'no text was selected');
    expect(state.selection.caret, 0, reason: 'the caret did not move');
    expect(_offset(tester), greaterThan(before), reason: 'it scrolled');
  });

  testWidgets('dragging the text still selects', (tester) async {
    final state = await _pump(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(200, 50));
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.down(const Offset(200, 50));
    await tester.pump();
    await gesture.moveTo(const Offset(320, 50));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(state.selectedText, isNotEmpty);
  });
}
