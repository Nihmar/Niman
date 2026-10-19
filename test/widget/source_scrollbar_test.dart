// The editor's scrollbar is the scrollbar's (#1106): hovering it keeps the
// arrow, and a drag on it scrolls without moving the caret or the selection.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
String _note([int lines = 80]) =>
    [for (var i = 0; i < lines; i++) 'riga numero $i con un po di testo']
        .join('\n');

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester, {
  TargetPlatform platform = TargetPlatform.linux,
  String? note,
  ScrollbarThemeData? scrollbarTheme,
  EdgeInsets padding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = const Size(900, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      // The desktop scrollbar: MaterialScrollBehavior adds it only on a
      // desktop platform.
      theme: ThemeData(platform: platform, scrollbarTheme: scrollbarTheme),
      home: Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(padding: padding),
            child: MarkdownSourceView(
              buffer: SourceBuffer.fromText(note ?? _note()),
              theme: _theme,
              showLineNumbers: false,
            ),
          ),
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

/// Shows the bar the way a scroll does, so its thumb is painted and a press
/// can take it, then comes back to the top.
Future<void> _showBar(WidgetTester tester) async {
  final position = _position(tester);
  for (final to in const <double>[1, 0]) {
    position.jumpTo(to);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The scrollbar's own painter box, the one that decides what it takes.
RenderCustomPaint _barPaint(WidgetTester tester) => tester
    .renderObjectList<RenderCustomPaint>(
      find.descendant(
        of: find.byType(MarkdownSourceView),
        matching: find.byType(CustomPaint),
      ),
    )
    .firstWhere((paint) => paint.foregroundPainter is ScrollbarPainter);

/// The x range, in the window, where the scrollbar takes a mouse press at
/// [y]: read off the painter's own hit test, not worked out again here.
({double left, double right}) _barSpan(WidgetTester tester, double y) {
  final paint = _barPaint(tester);
  final painter = paint.foregroundPainter! as ScrollbarPainter;
  final xs = <double>[
    for (var x = 0.0; x < 900; x += 0.5)
      if (painter.hitTestInteractive(
        paint.globalToLocal(Offset(x, y)),
        PointerDeviceKind.mouse,
      ))
        x,
  ];
  expect(xs, isNotEmpty, reason: 'the scrollbar takes a press somewhere');
  return (left: xs.first, right: xs.last);
}

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

  testWidgets('a plain click on the scrollbar leaves the caret where it was', (
    tester,
  ) async {
    final state = await _pump(tester);
    await _showBar(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    // The caret goes to the text first.
    await gesture.addPointer(location: const Offset(200, 100));
    await gesture.down(const Offset(200, 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    final caret = state.selection.caret;
    expect(caret, greaterThan(0));

    // Then a click on the bar, down and up, with no drag.
    await gesture.moveTo(const Offset(896, 300));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.down(const Offset(896, 300));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(state.selection.caret, caret);
    expect(state.selection.isCollapsed, isTrue);
  });

  testWidgets('a drag from the text into the strip still selects', (
    tester,
  ) async {
    final state = await _pump(tester);
    await _showBar(tester);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(200, 50));
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.down(const Offset(200, 50));
    await tester.pump();
    await gesture.moveTo(const Offset(896, 50));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(state.selectedText, isNotEmpty);
    // Past the end of the line: the whole rest of it.
    expect(state.selectedText, endsWith('testo'));
  });

  // The strip is what the scrollbar takes, to the pixel: read off its own
  // painter, so a theme, a margin or an inset moves both together.
  final bars = <String, ({ScrollbarThemeData? theme, EdgeInsets padding})>{
    'default': (theme: null, padding: EdgeInsets.zero),
    'a themed thickness and margin': (
      theme: const ScrollbarThemeData(
        thickness: WidgetStatePropertyAll<double>(14),
        crossAxisMargin: 5,
      ),
      padding: EdgeInsets.zero,
    ),
    'a right inset': (theme: null, padding: const EdgeInsets.only(right: 20)),
    // The track, shown, grows under the pointer: the strip with it.
    'a visible track': (
      theme: const ScrollbarThemeData(
        trackVisibility: WidgetStatePropertyAll<bool>(true),
      ),
      padding: EdgeInsets.zero,
    ),
  };
  for (final MapEntry(key: name, value: bar) in bars.entries) {
    testWidgets('the strip is exactly where the scrollbar takes a press '
        '($name)', (tester) async {
      final state = await _pump(
        tester,
        scrollbarTheme: bar.theme,
        padding: bar.padding,
      );
      await _showBar(tester);
      // The pointer is over the bar, as it is when a press comes: the
      // scrollbar has taken its hovered shape, which is the one it measures.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(898, 300));
      await gesture.moveTo(const Offset(898, 300));
      await tester.pump(const Duration(milliseconds: 300));
      final span = _barSpan(tester, 300);

      Future<void> press(double x) async {
        await gesture.moveTo(Offset(x, 300));
        await tester.pump(const Duration(milliseconds: 300));
        await gesture.down(Offset(x, 300));
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 400));
      }

      // Just inside the bar, at either edge: the scrollbar's.
      await press(span.left + 0.5);
      expect(state.selection.caret, 0, reason: 'inside, left edge');
      await press(span.right - 0.5);
      expect(state.selection.caret, 0, reason: 'inside, right edge');

      // Just outside it, on the text's side: the text's.
      await press(span.left - 1);
      expect(state.selection.caret, greaterThan(0), reason: 'outside');
    });
  }

  testWidgets('a note with nothing to scroll has no strip', (tester) async {
    final state = await _pump(tester, note: _note(3));
    expect(_position(tester).maxScrollExtent, 0);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(896, 30));
    addTearDown(gesture.removePointer);
    await tester.pump();

    // The I-beam, as anywhere on the text.
    await gesture.moveTo(const Offset(896, 30));
    await tester.pump();
    expect(_cursor(tester), SystemMouseCursors.text);

    await gesture.down(const Offset(896, 30));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.selection.caret, greaterThan(0));
  });

  // The strip belongs to the *mouse's* scrollbar. A finger there is on the
  // text: Android builds no scrollbar at all, and a desktop touchscreen taps
  // text like a phone does.
  for (final platform in const <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.linux,
  ]) {
    testWidgets('a finger tap in the right strip places the caret '
        '(${platform.name})', (tester) async {
      final state = await _pump(tester, platform: platform);
      expect(state.selection.caret, 0);

      await tester.tapAt(const Offset(896, 50));
      await tester.pump(const Duration(milliseconds: 400));

      expect(state.selection.caret, greaterThan(0));
    });
  }
}
