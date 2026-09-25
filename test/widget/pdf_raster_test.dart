// Drawing a note as rastered PDF pages (#63): the whole offscreen layout,
// the page count, and the file the printer writes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_pdf.dart';
import 'package:niman/src/export/pdf_printer.dart';
import 'package:niman/src/export/pdf_raster.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:path/path.dart' as p;

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
