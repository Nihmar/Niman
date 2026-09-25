// One note's PDF (#63): the engine's file when it prints, an error when
// nothing can.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/export/export_pdf.dart';
import 'package:niman/src/export/pdf_printer.dart';

final class _Prints implements PdfPrinter {
  const new();

  @override
  Future<PdfOutcome> print(String htmlPath, String pdfPath) async {
    await File(pdfPath).writeAsBytes(<int>[1, 2, 3, 4]);
    return const PdfPrinted();
  }
}

final class _NoEngine implements PdfPrinter {
  const new();

  @override
  Future<PdfOutcome> print(String htmlPath, String pdfPath) async =>
      const PdfNoEngine();
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_export_pdf_');
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('a printed file is the payload', () async {
    final result = await exportNotePdf(
      text: '# T\n',
      title: 'A title',
      path: 'Notes/T.md',
      root: root.path,
      language: 'en',
      printer: const _Prints(),
    );
    expect(result.selectable, isTrue);
    expect(result.payload.name, 'T.pdf');
    expect(result.payload.mimeType, 'application/pdf');
    expect(result.payload.bytes, Uint8List.fromList(<int>[1, 2, 3, 4]));
  });

  test('no engine and nothing to draw with is an error', () async {
    await expectLater(
      exportNotePdf(
        text: 'x\n',
        title: 'x',
        path: 'Notes/x.md',
        root: root.path,
        language: 'en',
        printer: const _NoEngine(),
      ),
      throwsA(isA<NoPdfEngine>()),
    );
  });
}
