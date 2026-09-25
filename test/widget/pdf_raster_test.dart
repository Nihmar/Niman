// Drawing a note as rastered PDF pages (#63): the whole offscreen layout,
// the page count, and the file the printer writes.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_pdf.dart';
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
      ),
    );
    // The PDF is a picture of the pages, and the caller is told so.
    expect(result!.selectable, isFalse);
    expect(latin1.decode(result.payload.bytes.sublist(0, 8)), '%PDF-1.4');
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
