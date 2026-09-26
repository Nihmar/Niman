// Drawing a note as rastered PDF pages (#63): the whole offscreen layout,
// the page count, and the file the printer writes.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_pdf.dart';
import 'package:niman/src/export/pdf_breaks.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_raster.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:path/path.dart' as p;

/// A 2×2 PNG, every pixel red: the picture the fallback has to draw.
const String _redPng =
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAE0lEQVR4nGP4'
    'z8DwnwGM/zMwAAAf7gP9NRsAMwAAAABJRU5ErkJggg==';

/// The pixels of the PDF's one image stream, RGB per pixel.
Uint8List _pageRgb(Uint8List pdf) => _imageStreams(pdf).single;

/// Every image stream in the PDF, inflated.
List<Uint8List> _imageStreams(Uint8List pdf) {
  final text = latin1.decode(pdf);
  final pages = <Uint8List>[];
  var at = 0;
  while (true) {
    final image = text.indexOf('/Subtype /Image', at);
    if (image < 0) break;
    final start = text.indexOf('stream\n', image) + 'stream\n'.length;
    final end = text.indexOf('\nendstream', start);
    pages.add(Uint8List.fromList(ZLibCodec().decode(pdf.sublist(start, end))));
    at = end;
  }
  return pages;
}

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

  testWidgets('a short note is one page of pixels', (tester) async {
    await pumpTheme(tester);
    // The capture and the read-back of its pixels are engine work the
    // fake-async zone a widget test runs in cannot wait on.
    final bytes = await tester.runAsync(
      () => rasterPdf(
        text: '# Title\n\nA paragraph, and **bold**.\n',
        theme: theme,
        mathCache: cache,
      ),
    );
    expect(latin1.decode(bytes!.sublist(0, 8)), '%PDF-1.4');
    final text = latin1.decode(bytes);
    expect(text, contains('/Count 1'));
    expect(text, contains('/Subtype /Image'));
    expect(text, contains('/ColorSpace /DeviceRGB'));
    // A4 in points, not the layout's logical pixels: the raster pages are
    // an A4 sheet, not 4/3 of one (#63 review, H2).
    expect(text, contains('/MediaBox [0 0 595.28 841.89]'));
  });

  testWidgets('a note that lays out to nothing is still one page', (
    tester,
  ) async {
    await pumpTheme(tester);
    final bytes = await tester.runAsync(
      () => rasterPdf(text: '', theme: theme, mathCache: cache),
    );
    expect(latin1.decode(bytes!.sublist(0, 8)), '%PDF-1.4');
    expect(latin1.decode(bytes), contains('/Count 1'));
    // A page of paper, not a zero-height capture (P5).
    expect(_imageStreams(bytes), hasLength(1));
  });

  testWidgets('a long note is several pages', (tester) async {
    await pumpTheme(tester);
    final note = StringBuffer();
    for (var at = 0; at < 120; at++) {
      note
        ..writeln('Paragraph $at, long enough to take a line or two. ')
        ..writeln();
    }
    final bytes = await tester.runAsync(
      () => rasterPdf(text: note.toString(), theme: theme, mathCache: cache),
    );
    final text = latin1.decode(bytes!);
    final count = RegExp(r'/Count (\d+)').firstMatch(text)!.group(1);
    expect(int.parse(count!), greaterThan(1));
    // The pages are slices of the one recording: each shows its own part
    // of the note, not the first one repeated.
    final pages = _imageStreams(bytes);
    expect(pages.length, int.parse(count));
    expect(pages.first, isNot(equals(pages[1])));
  });

  testWidgets('a page never breaks through a line of text', (tester) async {
    await pumpTheme(tester);
    // A surface tall enough for the whole column: the note is wider than a
    // page's height and a viewport would only cut it off.
    tester.view.physicalSize = const Size(400, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: Column(
              key: key,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var at = 0; at < 40; at++) ...[
                  Text(
                    'Paragraph $at, long enough to wrap over more than one '
                    'line of a narrow column.',
                    style: theme.body,
                  ),
                  // A picture, a rule, a formula: a leaf box, drawn as one
                  // piece and not to be broken through.
                  if (at == 20) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final box = tester.renderObject<RenderBox>(find.byKey(key));
    final spans = rasterInkSpans(box);
    // One span per line, not one per paragraph: the break has to be able to
    // fall inside a paragraph (#63). And the leaf box is one of them.
    expect(spans.length, greaterThan(40));
    expect(
      spans.where((span) => span.$2 - span.$1 == 12),
      hasLength(1),
      reason: 'the picture is a span of its own',
    );
    final breaks = rasterBreaks(
      total: box.size.height,
      spans: spans,
      contentHeight: 120,
    );
    expect(breaks.length, greaterThan(2));
    expect(breaks.last, box.size.height);
    for (final at in breaks.skip(1)) {
      for (final (top, bottom) in spans) {
        expect(
          at > top && at < bottom,
          isFalse,
          reason: 'the break at $at cuts the line that runs $top..$bottom',
        );
      }
    }
  });

  testWidgets('a picture handed in is drawn on the page', (tester) async {
    await pumpTheme(tester);
    final bytes = await tester.runAsync(
      () => rasterPdf(
        text: 'A red picture:\n\n![red](red.png)\n',
        theme: theme,
        mathCache: cache,
        images: <String, Uint8List>{'red.png': base64Decode(_redPng)},
      ),
    );
    final rgb = _pageRgb(bytes!);
    // A red pixel is somewhere on the page: without the decode-and-draw the
    // picture would be the alt text, and no pixel would be red (H3).
    var red = false;
    for (var at = 0; at + 2 < rgb.length; at += 3) {
      if (rgb[at] > 200 && rgb[at + 1] < 60 && rgb[at + 2] < 60) {
        red = true;
        break;
      }
    }
    expect(red, isTrue);
  });

  testWidgets('the printer writes the file', (tester) async {
    await pumpTheme(tester);
    // Sync: a real `await` in the fake-async zone a widget test runs in
    // never completes.
    final dir = Directory.current.createTempSync('niman_pdf_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final pdfPath = p.join(dir.path, 'out.pdf');
    final printer = RasterPdfPrinter(
      text: '# Title\n',
      theme: theme,
      mathCache: cache,
    );

    // A real write: the fake-async zone a widget test runs in cannot wait
    // on it, so it runs in `runAsync`.
    final outcome = await tester.runAsync(
      () => printer.print('ignored.html', pdfPath),
    );
    expect(outcome, isA<PdfPrinted>());
    expect(File(pdfPath).lengthSync(), greaterThan(100));
  });

  testWidgets('a print that fails draws the note instead', (tester) async {
    await pumpTheme(tester);
    final dir = Directory.current.createTempSync('niman_pdf_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final stages = <PdfExportStage>[];
    final result = await tester.runAsync(
      () => exportNotePdf(
        text: '# Title\n',
        title: 'Title',
        path: 'Title.md',
        root: dir.path,
        language: 'en',
        printer: const _Fails(),
        theme: theme,
        mathCache: cache,
        onProgress: (report) => stages.add(report.stage),
      ),
    );
    // The PDF is a picture of the pages, and the caller is told so.
    expect(result!.selectable, isFalse);
    expect(latin1.decode(result.payload.bytes.sublist(0, 8)), '%PDF-1.4');
    // The failing engine's drawing reports like the no-engine one's: without
    // them the dialog sat on the indeterminate printing bar (P2).
    expect(stages.first, PdfExportStage.printing);
    expect(stages, contains(PdfExportStage.drawing));
  });

  testWidgets("a cancel during a failing engine's drawing stops it", (
    tester,
  ) async {
    await pumpTheme(tester);
    final dir = Directory.current.createTempSync('niman_pdf_');
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    // The first check is the one after the failed print; the second is the
    // fallback's own, before its first page: the note is never drawn to the
    // end (P2).
    var checks = 0;
    final outcome = await tester.runAsync(() async {
      try {
        await exportNotePdf(
          text: '# Title\n',
          title: 'Title',
          path: 'Title.md',
          root: dir.path,
          language: 'en',
          printer: const _Fails(),
          theme: theme,
          mathCache: cache,
          isCancelled: () => ++checks >= 2,
        );
        return 'drawn';
      } on PdfExportCancelled {
        return 'cancelled';
      }
    });
    expect(outcome, 'cancelled');
  });

  testWidgets('drawing reports its pages as it goes', (tester) async {
    await pumpTheme(tester);
    final note = StringBuffer();
    for (var at = 0; at < 120; at++) {
      note
        ..writeln('Paragraph $at, long enough to take a line or two. ')
        ..writeln();
    }
    final reports = <int>[];
    final bytes = await tester.runAsync(
      () => rasterPdf(
        text: note.toString(),
        theme: theme,
        mathCache: cache,
        onProgress: (done, _) => reports.add(done),
      ),
    );
    expect(bytes, isNotNull);
    // 0 first, then one report per page: the caller can say how far it is.
    expect(reports.first, 0);
    expect(reports.last, greaterThan(1));
    expect(reports.last, reports.length - 1);
    expect(
      reports,
      orderedEquals(List<int>.generate(reports.length, (i) => i)),
    );
  });

  testWidgets('a cancelled drawing stops before the next page', (tester) async {
    await pumpTheme(tester);
    final note = StringBuffer();
    for (var at = 0; at < 120; at++) {
      note
        ..writeln('Paragraph $at, long enough to take a line or two. ')
        ..writeln();
    }
    var cancelled = false;
    final outcome = await tester.runAsync(() async {
      try {
        await rasterPdf(
          text: note.toString(),
          theme: theme,
          mathCache: cache,
          onProgress: (done, _) => cancelled = done >= 1,
          isCancelled: () => cancelled,
        );
        return 'drawn';
      } on PdfExportCancelled {
        return 'cancelled';
      }
    });
    expect(outcome, 'cancelled');
  });
}

/// A printer that is there and fails: the note must be drawn anyway.
final class _Fails implements PdfPrinter {
  const new();

  @override
  Future<bool> get canPrint async => true;

  @override
  Future<PdfOutcome> print(String htmlPath, String pdfPath) async =>
      const PdfFailed('the engine exited with 2');
}
