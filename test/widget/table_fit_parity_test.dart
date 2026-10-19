// A table's columns are fitted to the pane by one rule (#1108): the read view
// and `live` draw one table with the same column widths, the words of a
// styled cell are not broken, a table that fits keeps the columns it has, and
// a column that holds a widget is no narrower than the widget.
//
// The test font (Ahem) draws every glyph a square of its size, so the words
// of these tables do not fit a phone's pane together: they exercise the
// branch that shares the room by level. The tables that fit are given a
// wider pane.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex/katex.dart' show boxSizePx;
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/inline/inline_parser.dart';
import 'package:niman/src/markdown/read_block.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/inline_spans.dart';
import 'package:niman/src/markdown/render/live_table_grid.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/markdown/render/read_table.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';
import 'package:niman/src/preview/math_cache.dart';

/// The reported four-column table (#1108): short first and last columns,
/// long prose in the middle.
const String _wide =
    '| Area | Word-Smith 1.8.6 | Niman 0.2.4 | Ahead |\n'
    '|---|---|---|---|\n'
    "| Markdown surface | Obsidian's (source + Live Preview) | "
    "Niman's own: source, live and read, one widget | Tie |\n"
    '| Table over notes | The Organizer: any frontmatter key as a column, '
    'computed readings, filters | none (a table inside a note only) | '
    'Word-Smith |\n';

/// A small table that fits a wide pane.
const String _small = '| a | bb |\n|---|---|\n| ccc | d |\n';

void _pane(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

MathCache _cache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

Future<void> _pumpLive(WidgetTester tester, String note) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSurface(
            buffer: SourceBuffer.fromText(note),
            mode: MarkdownSurfaceMode.live,
            theme: markdownThemeOf(context),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  expect(find.byType(MarkdownSourceView), findsOneWidget);
}

Future<void> _pumpRead(
  WidgetTester tester,
  String note, {
  MathCache? cache,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(note),
          parser: ReadParser(),
          mathCache: cache ?? _cache(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The width of each column `live` laid the table out in.
List<double> _liveColumns(WidgetTester tester) {
  final edges = tester
      .widgetList<CustomPaint>(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is LiveTableGridPainter,
        ),
      )
      .map((paint) => (paint.painter! as LiveTableGridPainter).row.edges)
      .first;
  return [
    for (var at = 0; at < edges.length - 1; at++) edges[at + 1] - edges[at],
  ];
}

/// The width of each column of the read view's table.
List<double> _readColumns(WidgetTester tester) {
  final table = tester.renderObject<RenderTable>(find.byType(Table));
  return [for (final cell in table.row(0)) cell.size.width];
}

double _sum(List<double> widths) => widths.fold(0, (sum, w) => sum + w);

/// The columns `live` fits [note] into when it has [room] to draw the table
/// in, as the read view has it: the two surfaces keep their own margins, so
/// the pane is widened (or narrowed) by what the margins differ by.
Future<List<double>> _liveColumnsIn(
  WidgetTester tester,
  String note,
  double room,
) async {
  final pane = tester.view.physicalSize.width;
  await _pumpLive(tester, note);
  final margins = pane - _sum(_liveColumns(tester));
  _pane(tester, room + margins);
  await _pumpLive(tester, note);
  final live = _liveColumns(tester);
  expect(_sum(live), closeTo(room, 0.6), reason: 'the room is the same');
  return live;
}

void _expectSame(List<double> read, List<double> live, {String? reason}) {
  expect(read.length, live.length, reason: reason);
  for (var at = 0; at < live.length; at++) {
    expect(read[at], closeTo(live[at], 0.6), reason: '$reason, column $at');
  }
}

void main() {
  testWidgets('the read view and live give a narrow table the same columns', (
    tester,
  ) async {
    _pane(tester, 360);
    await _pumpRead(tester, _wide);
    final read = _readColumns(tester);
    expect(_sum(read), lessThanOrEqualTo(360.5));
    final live = await _liveColumnsIn(tester, _wide, _sum(read));
    _expectSame(read, live, reason: 'a table fitted to 360');
  });

  testWidgets('the same with marks in the cells: bold, code, a link', (
    tester,
  ) async {
    _pane(tester, 360);
    const note =
        '| **Area** | `code_identifier` | Notes |\n|---|---|---|\n'
        '| **bold words here** | a [link text](https://example.com) and '
        'more prose to make the cell long | ok |\n';
    await _pumpRead(tester, note);
    final read = _readColumns(tester);
    final live = await _liveColumnsIn(tester, note, _sum(read));
    _expectSame(read, live, reason: 'a table with marks');
  });

  testWidgets('a table that fits the pane keeps the columns it has', (
    tester,
  ) async {
    _pane(tester, 800);
    await _pumpLive(tester, _small);
    final live = _liveColumns(tester);
    await _pumpRead(tester, _small);
    final read = _readColumns(tester);

    _expectSame(read, live, reason: 'a table that fits');
    // Each column as wide as its widest cell, the padding either side: the
    // two do not share the pane out.
    expect(read.reduce((a, b) => a + b), lessThan(400));
    expect(read[0], greaterThan(read[1]), reason: '"ccc" is wider than "bb"');
  });

  testWidgets('a styled word is not broken in the read view', (tester) async {
    _pane(tester, 360);
    const word = '`identifier_name`';
    const note =
        '| $word | prose that goes on for some time, so the table is wider '
        'than the pane |\n|---|---|\n| **boldwordhere** | and more prose to '
        'fill the second column up to the end |\n';
    await _pumpRead(tester, note);
    for (final text in ['identifier_name', 'boldwordhere']) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining(text, findRichText: true).first,
      );
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: paragraph.text.toPlainText().length,
        ),
      );
      expect(
        {for (final box in boxes) box.top}.length,
        1,
        reason: '"$text" stands whole on its line',
      );
    }
  });

  testWidgets('a column holding a formula is no narrower than it', (
    tester,
  ) async {
    _pane(tester, 360);
    const tex =
        r'\frac{a_1 + b_2}{c_3 + d_4} = \sum_{i=1}^{n} x_i + \frac{e_5}{g_7}';
    const note =
        '| Formula | Prose |\n|---|---|\n'
        '| \$$tex\$ | '
        'prose that goes on for quite some time, so the table is wider than '
        'the pane and has to be fitted to it |\n';
    final cache = _cache();
    await _pumpRead(tester, note, cache: cache);
    // The formula is rendered a frame after it is asked for.
    await tester.pumpAndSettle();

    // The formula's own width: the cell it is in is cut to the column it is
    // given, and what is drawn past that is outside the cell.
    final theme = markdownThemeOf(tester.element(find.byType(Table)));
    final box = cache.boxFor(tex, displayMode: false)!;
    final formula = boxSizePx(
      box,
      mathStyleFor(theme.tableCell).fontSize,
    ).width;
    final column = _readColumns(tester).first;
    expect(
      column,
      greaterThanOrEqualTo(formula + 2 * theme.tableCellPadding.left),
      reason: 'the column is as wide as its formula',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chunk of a table with rows of different lengths is fitted', (
    tester,
  ) async {
    _pane(tester, 360);
    ReadInline cell(String text) =>
        ReadInline(text: text, nodes: InlineParser(text).parse());
    late MarkdownTheme theme;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              theme = markdownThemeOf(context);
              return ReadTable(
                rows: [
                  [cell('one'), cell('two')],
                  [
                    cell('three'),
                    cell('four words that go on and on for a long while'),
                    cell(
                      'and a third cell the first row has none of, long too',
                    ),
                  ],
                ],
                aligns: const <TableAlign>[],
                head: false,
                theme: theme,
                spansOf: (base) => InlineSpans(
                  theme: theme,
                  base: base,
                  mathCache: _cache(),
                  taps: (
                    onTapLink: null,
                    onTapWikiLink: null,
                    embedResolver: null,
                    embedImages: null,
                    deadLinks: null,
                    linkPreview: null,
                  ),
                ),
                availableWidth: 330,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final table = tester.renderObject<RenderTable>(find.byType(Table));
    expect(table.columns, 3, reason: 'the longest row sets the columns');
    final widths = [for (final cell in table.row(1)) cell.size.width];
    expect(
      widths.reduce((a, b) => a + b),
      lessThanOrEqualTo(330.5),
      reason: 'every cell of the widest row is inside the fitted widths',
    );
  });
}
