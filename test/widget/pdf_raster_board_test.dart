// A kanban board drawn as rastered PDF pages (#1170): the sheet, the
// columns to a row, and a page break that never falls inside a card.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/board_raster_content.dart';
import 'package:niman/src/export/board_raster_context.dart';
import 'package:niman/src/export/board_raster_head.dart';
import 'package:niman/src/export/board_raster_plan.dart';
import 'package:niman/src/export/export_pdf.dart';
import 'package:niman/src/export/kanban_sheet.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_raster.dart';
import 'package:niman/src/export/pdf_raster_board.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A board of [columns] columns of [cards] cards each; every card has a
/// title long enough to wrap, a tag, a due date and, on the even ones, a
/// body, so the cards differ in height.
String _board(int columns, int cards, {bool intro = false}) {
  final out = StringBuffer('---\ntype: kanban\n---\n');
  if (intro) out.writeln('An intro before the board.\n');
  for (var c = 1; c <= columns; c++) {
    out.writeln('## Column $c');
    for (var i = 1; i <= cards; i++) {
      final box = i % 3 == 0 ? 'x' : ' ';
      out.writeln(
        '- [$box] Card $c.$i has a title long enough to wrap over a few '
        'lines of the column #tag due:2026-11-1${i % 9}',
      );
      if (i.isEven) {
        out.writeln('  A body line for card $i.\n  - one\n  - two');
      }
    }
    out.writeln();
  }
  return out.toString();
}

/// A machine with nothing to print with.
final class _NoEngine implements PdfPrinter {
  new();

  @override
  Future<bool> get canPrint async => false;

  @override
  Future<PdfOutcome> print(
    String htmlPath,
    String pdfPath, {
    PdfPaper paper = PdfPaper.a4,
  }) async => const PdfNoEngine();
}

String _mediaBox(Uint8List pdf) =>
    RegExp(r'/MediaBox \[[^\]]*\]').firstMatch(latin1.decode(pdf))!.group(0)!;

int _pageCount(Uint8List pdf) => int.parse(
  RegExp(r'/Count (\d+)').firstMatch(latin1.decode(pdf))!.group(1)!,
);

void main() {
  late MarkdownTheme theme;
  late MathCache cache;

  setUp(() {
    cache = MathCache();
  });

  tearDown(() => cache.dispose());

  Future<void> pumpTheme(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            theme = markdownThemeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  BoardRasterContent content(String text, double contentWidth) {
    final board = parseKanban(text);
    return BoardRasterContent(
      board: board,
      sheet: kanbanSheetFor(board.columns.length),
      contentWidth: contentWidth,
      context: BoardRasterContext(board: board, theme: theme, mathCache: cache),
    );
  }

  /// The content width of a page of [paper] with the print margin.
  double contentWidthOf(KanbanSheet sheet) =>
      (sheet == KanbanSheet.landscape ? a4HeightPx : a4WidthPx) -
      2 * pdfPageMarginPx;

  group('the sheet', () {
    testWidgets('four columns are drawn on A4 landscape', (tester) async {
      await pumpTheme(tester);
      final bytes = await tester.runAsync(
        () => rasterPdf(
          text: '',
          theme: theme,
          mathCache: cache,
          board: parseKanban(_board(4, 1)),
        ),
      );
      expect(_mediaBox(bytes!), '/MediaBox [0 0 841.89 595.28]');
      expect(_pageCount(bytes), 1);
    });

    testWidgets('five columns are drawn on A4 portrait', (tester) async {
      await pumpTheme(tester);
      final bytes = await tester.runAsync(
        () => rasterPdf(
          text: '',
          theme: theme,
          mathCache: cache,
          board: parseKanban(_board(5, 3)),
        ),
      );
      expect(_mediaBox(bytes!), '/MediaBox [0 0 595.28 841.89]');
    });

    testWidgets('the export draws the board when the feature is on, the '
        'note when it is off', (tester) async {
      await pumpTheme(tester);
      final root = Directory.systemTemp.createTempSync('niman_board_raster_');
      addTearDown(() => root.deleteSync(recursive: true));
      Future<Uint8List> export({required bool kanban}) async {
        final result = await tester.runAsync(
          () => exportNotePdf(
            text: _board(3, 3),
            title: 'Board',
            path: 'Board.md',
            root: root.path,
            language: 'en',
            printer: _NoEngine(),
            theme: theme,
            mathCache: cache,
            kanban: kanban,
          ),
        );
        expect(result!.selectable, isFalse);
        return result.payload.bytes;
      }

      expect(_mediaBox(await export(kanban: true)), contains('841.89 595.28'));
      expect(_mediaBox(await export(kanban: false)), contains('595.28 841.89'));
    });
  });

  group('the columns of a row', () {
    testWidgets('are all in one row on a landscape sheet, sharing the width', (
      tester,
    ) async {
      await pumpTheme(tester);
      final width = contentWidthOf(KanbanSheet.landscape);
      for (final columns in [1, 2, 4]) {
        final built = content(_board(columns, 2), width);
        expect(built.bands, hasLength(1));
        final lanes = built.bands.single;
        expect(lanes, hasLength(columns));
        final total =
            lanes.fold<double>(0, (sum, lane) => sum + lane.width) +
            (columns - 1) * built.gap;
        expect(total, closeTo(width, 0.001));
        expect(lanes.map((lane) => lane.width).toSet(), hasLength(1));
      }
    });

    testWidgets('wrap two to a row on a portrait sheet, as wide as a cell', (
      tester,
    ) async {
      await pumpTheme(tester);
      final width = contentWidthOf(KanbanSheet.portrait);
      final built = content(_board(5, 2), width);
      expect(built.bands.map((band) => band.length), [2, 2, 1]);
      final cell = (width - built.gap) / 2;
      for (final band in built.bands) {
        for (final lane in band) {
          expect(lane.width, closeTo(cell, 0.001));
        }
      }
      // A column is never narrower than the printed page's minimum.
      expect(cell / pxPerMm, greaterThanOrEqualTo(kanbanColumnMinMm));
    });

    testWidgets('the text before the board is a row of its own', (
      tester,
    ) async {
      await pumpTheme(tester);
      final built = content(
        _board(3, 1, intro: true),
        contentWidthOf(KanbanSheet.landscape),
      );
      expect(built.bands, hasLength(2));
      expect(built.bands.first.single.framed, isFalse);
      expect(built.bands.last, hasLength(3));
    });
  });

  group('a page break', () {
    testWidgets('never falls inside a card', (tester) async {
      await pumpTheme(tester);
      for (final columns in [3, 6]) {
        final sheet = kanbanSheetFor(columns);
        final width = contentWidthOf(sheet);
        final height =
            (sheet == KanbanSheet.landscape ? a4WidthPx : a4HeightPx) -
            2 * pdfPageMarginPx;
        final built = content(_board(columns, 22), width);
        final measured = measureBoardContent(built, width, height);
        // Real cards: every one has a height of its own, and they differ.
        final heights = {
          for (final band in measured)
            for (final lane in band) ...lane.items,
        };
        expect(heights.length, greaterThan(1));
        expect(heights, everyElement(greaterThan(0)));

        final pages = planBoardPages(
          bands: measured,
          pageHeight: height,
          bandGap: built.gap,
        );
        expect(pages.length, greaterThan(1));
        final placed = <String, int>{};
        for (final page in pages) {
          var used = 0.0;
          for (final slice in page) {
            var tallest = 0.0;
            for (final part in slice.lanes) {
              if (!part.visible) continue;
              final lane = measured[slice.band][part.lane];
              // A whole card or none: a slice is a run of items, and the
              // heights of the run, with the column's head and box, fit.
              var h = lane.chrome + lane.head;
              for (var i = part.from; i < part.to; i++) {
                h += lane.items[i];
              }
              if (h > tallest) tallest = h;
              final key = '${slice.band}:${part.lane}';
              expect(part.from, placed[key] ?? 0);
              placed[key] = part.to;
            }
            used += tallest + (used == 0 ? 0 : built.gap);
          }
          expect(used, lessThanOrEqualTo(height + 0.001));
        }
        // Every card is on a page, once.
        for (var b = 0; b < measured.length; b++) {
          for (var l = 0; l < measured[b].length; l++) {
            expect(placed['$b:$l'], measured[b][l].items.length);
          }
        }
      }
    });

    testWidgets('makes a page of each run of cards, in the PDF', (
      tester,
    ) async {
      await pumpTheme(tester);
      final bytes = await tester.runAsync(
        () => rasterPdf(
          text: '',
          theme: theme,
          mathCache: cache,
          board: parseKanban(_board(3, 22)),
        ),
      );
      expect(_pageCount(bytes!), greaterThan(1));
      // One image a page.
      final text = latin1.decode(bytes);
      expect('/Subtype /Image'.allMatches(text), hasLength(_pageCount(bytes)));
    });
  });

  group('the column names', () {
    testWidgets("take the read view's h2 when every name fits its column", (
      tester,
    ) async {
      await pumpTheme(tester);
      final context = BoardRasterContext(
        board: parseKanban('---\ntype: kanban\n---\n## A\n'),
        theme: theme,
        mathCache: cache,
      );
      final style = boardHeadStyle(context, ['To do', 'Done'], 400);
      expect(style.fontSize, theme.heading2.fontSize);
      expect(style.fontWeight, theme.heading2.fontWeight);
    });

    testWidgets("fall back to a heading of the body's type when one does "
        'not fit', (tester) async {
      await pumpTheme(tester);
      final context = BoardRasterContext(
        board: parseKanban('---\ntype: kanban\n---\n## A\n'),
        theme: theme,
        mathCache: cache,
      );
      final style = boardHeadStyle(context, [
        'To do',
        'A column name too long to sit on one line of a narrow column',
      ], 200);
      expect(style.fontSize, theme.body.fontSize! * 1.1);
      expect(style.fontWeight, theme.heading2.fontWeight);
    });
  });

  group('the definitions of the note', () {
    const head = '---\ntype: kanban\n---\n';

    /// Draws every row of [text]'s board in a tree of its own and answers,
    /// per row, the text of each RichText in it, and the texts that are
    /// links.
    Future<List<({List<String> texts, List<String> links})>> draw(
      WidgetTester tester,
      String text,
    ) async {
      final built = content(text, contentWidthOf(KanbanSheet.landscape));
      final rows = <({List<String> texts, List<String> links})>[];
      for (final band in built.bands) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final lane in band)
                      lane.slice(0, lane.items.length, withHead: false),
                  ],
                ),
              ),
            ),
          ),
        );
        final texts = <String>[];
        final links = <String>[];
        for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
          texts.add(rich.text.toPlainText());
          rich.text.visitChildren((span) {
            if (span is TextSpan && span.recognizer != null) {
              links.add(span.toPlainText());
            }
            return true;
          });
        }
        rows.add((texts: texts, links: links));
      }
      return rows;
    }

    testWidgets('a reference link in a card resolves against a definition '
        'after the board, and the definition is not drawn', (tester) async {
      await pumpTheme(tester);
      final rows = await draw(
        tester,
        '$head## Todo\n'
        '- [ ] See [the docs][docs] now\n'
        '- [ ] Other\n'
        '\n'
        '[docs]: https://example.org/docs\n',
      );
      expect(rows, hasLength(1));
      expect(rows.single.links, ['the docs']);
      final text = rows.single.texts.join('|');
      expect(text, contains('See the docs now'));
      expect(text, isNot(contains('[docs]')));
      expect(text, isNot(contains('example.org')));
    });

    testWidgets('a reference resolves against another card, both ways, and '
        'a card of definitions alone has no body', (tester) async {
      await pumpTheme(tester);
      final rows = await draw(
        tester,
        '$head## Todo\n'
        '- [ ] First [x][ref]\n'
        '- [ ] Second [y][later]\n'
        '  [ref]: https://example.org/r\n'
        '## Doing\n'
        '- [ ] Third\n'
        '  [later]: <https://example.org/l> "Title"\n',
      );
      expect(rows.single.links, ['x', 'y']);
      // Three titles and nothing else: no definition, no empty body.
      expect(rows.single.texts, ['First x', 'Second y', 'Third']);
    });

    testWidgets('a reference with no definition stays text', (tester) async {
      await pumpTheme(tester);
      final rows = await draw(tester, '$head## Todo\n- [ ] See [a][none]\n');
      expect(rows.single.links, isEmpty);
      expect(rows.single.texts, ['See [a][none]']);
    });

    testWidgets('footnotes are numbered over the note and listed once '
        'after the board', (tester) async {
      await pumpTheme(tester);
      final rows = await draw(
        tester,
        '${head}Before[^b] the board.\n'
        '\n'
        '## Todo\n'
        '- [ ] Claim[^a] and again[^b]\n'
        '  Body cites[^c].\n'
        '- [ ] Holds the notes\n'
        '  [^c]: Note c, in a card.\n'
        '## Done\n'
        '- [x] Cites a missing one[^9]\n'
        '  \n'
        '[^a]: Note a, after the board.\n'
        '[^b]: Note b.\n',
      );
      // The text before the board, the columns, then the footnotes.
      expect(rows, hasLength(3));
      final lead = rows[0].texts.join('|');
      final board = rows[1].texts.join('|');
      final list = rows[2].texts;
      // Numbered by first citation over the whole note: b, a, c.
      expect(lead, 'Before1 the board.');
      expect(board, contains('Claim2 and again1'));
      expect(board, contains('Body cites3.'));
      expect(board, contains('Cites a missing one[^9]'));
      // The definitions are not card text.
      expect(board, isNot(contains('Note c')));
      expect(board, isNot(contains('[^c]')));
      // One list, in citation order, numbered from one.
      expect(list.where((text) => text.startsWith('Note ')), [
        'Note b.',
        'Note a, after the board.',
        'Note c, in a card.',
      ]);
      expect(list.where((text) => RegExp(r'^\d\.$').hasMatch(text)), [
        '1.',
        '2.',
        '3.',
      ]);
    });

    testWidgets('a board that cites no footnote has no list', (tester) async {
      await pumpTheme(tester);
      final built = content(
        '$head## Todo\n- [ ] A card\n',
        contentWidthOf(KanbanSheet.landscape),
      );
      expect(built.bands, hasLength(1));
    });

    testWidgets('the footnotes are paged with the board, after its last '
        'card', (tester) async {
      await pumpTheme(tester);
      final text = StringBuffer('$head## Todo\n');
      for (var i = 1; i <= 30; i++) {
        text.writeln('- [ ] Card $i cites[^n$i]');
      }
      text.writeln();
      for (var i = 1; i <= 30; i++) {
        text.writeln('[^n$i]: Footnote number $i with a few words to say.');
      }
      final bytes = await tester.runAsync(
        () => rasterPdf(
          text: '',
          theme: theme,
          mathCache: cache,
          board: parseKanban(text.toString()),
        ),
      );
      expect(_pageCount(bytes!), greaterThan(1));
      // The list is the last row of the board, so the planner pages it: a
      // rule and a row each, drawn bare, not in a column's box.
      final built = content(
        text.toString(),
        contentWidthOf(KanbanSheet.landscape),
      );
      expect(built.bands.last.single.items, hasLength(31));
      expect(built.bands.last.single.framed, isFalse);
    });
  });
}
