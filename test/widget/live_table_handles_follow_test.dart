// The + handles of a table in `live` (#261) stand where the table does, at
// every frame of a scroll and of an edit above it: a column bar as tall as the
// grid, a row bar at its foot.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

String _lines(String name, int count) =>
    [for (var i = 0; i < count; i++) '$name line $i'].join('\n\n');

const String _rows =
    '| head | b |\n| --- | --- |\n| first | 2 |\n| second | 1 |\n| third | 3 |';

String _noteWith(String rows) =>
    '${_lines('above', 30)}\n\n$rows\n\n'
    '## Next heading\n\n${_lines('below', 30)}';

Future<SourceBuffer> _pump(
  WidgetTester tester, {
  String rows = _rows,
  double width = 900,
}) async {
  final buffer = SourceBuffer.fromText(_noteWith(rows));
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSurface(
            buffer: buffer,
            mode: MarkdownSurfaceMode.live,
            theme: markdownThemeOf(context),
            showLineNumbers: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return buffer;
}

Iterable<RenderParagraph> _paragraphs(WidgetTester tester) =>
    tester.renderObjectList<RenderParagraph>(find.byType(RichText));

RenderParagraph? _find(WidgetTester tester, String word) =>
    _paragraphs(tester)
        .where((p) => p.text.toPlainText().contains(word))
        .firstOrNull;

Rect _rectOf(RenderParagraph p) => p.localToGlobal(Offset.zero) & p.size;

EdgeInsets _padding(WidgetTester tester) =>
    markdownThemeOf(tester.element(find.byType(Scaffold))).tableCellPadding;

/// Scrolls the table into the middle of the pane and hovers [word]'s cell,
/// so the handles show. Returns the note's scrollable.
Future<ScrollableState> _hover(WidgetTester tester, String word) async {
  final scroller = tester.state<ScrollableState>(find.byType(Scrollable).first);
  // Down to the table, which the list builds only once it is near.
  for (var i = 0; _find(tester, 'first') == null; i++) {
    expect(i, lessThan(200), reason: 'the table is never built');
    scroller.position.jumpTo(scroller.position.pixels + 200);
    await tester.pump();
  }
  scroller.position.jumpTo(
    scroller.position.pixels + _rectOf(_find(tester, 'first')!).center.dy - 300,
  );
  await tester.pump();
  await tester.pump();
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  final cell = _rectOf(_find(tester, word)!).center;
  await mouse.addPointer(location: cell);
  await mouse.moveTo(cell + const Offset(1, 0));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('table-add-column')), findsOneWidget);
  return scroller;
}

/// Checks the handles against the cells now on screen: the column bar spans
/// the header's top, less the cell padding, to the foot of the paragraphs
/// whose text matches [lastRow], plus it; the row bar stands a gap under it.
void _expectAligned(
  WidgetTester tester,
  String reason, {
  Pattern lastRow = 'third',
}) {
  final head = _rectOf(_find(tester, 'head')!);
  final foot = _paragraphs(tester)
      .where((p) => p.text.toPlainText().contains(lastRow))
      .map((p) => _rectOf(p).bottom)
      .reduce((a, b) => a > b ? a : b);
  final padding = _padding(tester);
  final column = tester.getRect(find.byKey(const Key('table-add-column')));
  final row = tester.getRect(find.byKey(const Key('table-add-row')));
  expect(
    column.top,
    closeTo(head.top - padding.top, 0.5),
    reason: '$reason: column top',
  );
  expect(
    column.bottom,
    closeTo(foot + padding.bottom, 0.5),
    reason: '$reason: column foot',
  );
  expect(
    row.top,
    closeTo(foot + padding.bottom + 2, 0.5),
    reason: '$reason: row top',
  );
}

void main() {
  final desktop = TargetPlatformVariant.only(TargetPlatform.linux);

  // 2026-10-21 report: scrolled, the column bar ran past the table and the
  // row bar stood under the next heading.
  testWidgets('the handles follow the table when the note scrolls', (
    tester,
  ) async {
    await _pump(tester);
    final scroller = await _hover(tester, 'second');
    _expectAligned(tester, 'at rest');
    for (final delta in <double>[40, 120, -200, 75]) {
      scroller.position.jumpTo(scroller.position.pixels + delta);
      // One frame, as the wheel's next one: the handles are the table's now.
      await tester.pump();
      _expectAligned(tester, 'scrolled by $delta');
    }
  }, variant: desktop);

  testWidgets('the handles follow the table when a line above grows', (
    tester,
  ) async {
    final buffer = await _pump(tester);
    await _hover(tester, 'second');
    final view = tester.state<MarkdownSourceViewState>(
      find.byType(MarkdownSourceView),
    );
    // The line above the table grows to three rows of text: its rows are
    // pushed down, and no line is added, so the hovered table is the same.
    const at = 'above line 29';
    final start = buffer.text.indexOf(at);
    final long = List.filled(60, 'wrapping').join(' ');
    final caret = buffer.text.indexOf('second') + long.length - at.length;
    view.replaceText(
      start,
      start + at.length,
      long,
      caret: SelectionModel.at(caret),
    );
    // The frame that lays the grown line out moves the table, which no
    // build before it could know; the handles are built on the drawn table
    // for the frame after.
    await tester.pump();
    await tester.pump();
    _expectAligned(tester, 'a taller line above');
  }, variant: desktop);

  testWidgets('the handles reach the foot of a table of fitted rows', (
    tester,
  ) async {
    const words = 'zz1 zz2 zz3 zz4 zz5 zz6 zz7 zz8 zz9 zz10 zz11 zz12 zz13';
    await _pump(
      tester,
      width: 360,
      rows:
          '| head | b |\n| --- | --- |\n| first | 2 |\n| second | 1 |\n'
          '| third | $words |',
    );
    final scroller = await _hover(tester, 'second');
    final lastRow = RegExp('third|zz');
    _expectAligned(tester, 'at rest', lastRow: lastRow);
    for (final delta in <double>[60, -90]) {
      scroller.position.jumpTo(scroller.position.pixels + delta);
      await tester.pump();
      _expectAligned(tester, 'scrolled by $delta', lastRow: lastRow);
    }
  }, variant: desktop);
}
