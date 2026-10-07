import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/tesseract.dart';
import 'package:path/path.dart' as p;

/// The engine and the English model, where this machine has them: the
/// distribution's (CI installs tesseract-ocr), or the library named by
/// `NIMAN_OCR_ENGINE` (a build of scripts/ocr-engine.sh). A bare machine
/// skips the live tests.
final String? _engine =
    Platform.environment['NIMAN_OCR_ENGINE'] ?? findInstalledOcrEngine()?.name;

final String? _tessdata = [
  '/usr/share/tessdata',
  '/usr/share/tesseract-ocr/5/tessdata',
  '/usr/share/tesseract-ocr/4.00/tessdata',
].where((dir) => File(p.join(dir, 'eng.traineddata')).existsSync()).firstOrNull;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('version', () {
    test('LSTM models need 4.1 or later', () {
      expect(ocrEngineVersionSupported('5.5.3'), isTrue);
      expect(ocrEngineVersionSupported('4.1.1-rc2-21-g'), isTrue);
      expect(ocrEngineVersionSupported('4.0.0'), isFalse);
      expect(ocrEngineVersionSupported('3.05.02'), isFalse);
      expect(ocrEngineVersionSupported('garbage'), isFalse);
    });

    test('names that do not open are skipped, none found is null', () {
      final tried = <String>[];
      final found = findInstalledOcrEngine(
        linux: true,
        open: (name) {
          tried.add(name);
          throw ArgumentError(name);
        },
      );
      expect(found, isNull);
      expect(tried, [...bundledOcrEngineNames, ...systemOcrEngineNames]);
    });

    test('a library that is not Tesseract is not an engine', () {
      expect(openOcrEngine('x', open: (_) => DynamicLibrary.process()), isNull);
    });
  });

  test(
    'reads a rendered page into lines with their places',
    () async {
      final page = await _render([
        'Il contratto scade il 28 febbraio.',
        '',
        'Second paragraph, first line',
      ]);
      final tesseract = Tesseract.open(
        openOcrEngine(_engine!)!,
        datapath: _tessdata!,
        languages: 'eng',
      );
      addTearDown(tesseract.dispose);
      final lines = tesseract.recognize(
        page.gray,
        width: page.width,
        height: page.height,
      );
      expect(lines, hasLength(2));
      expect(lines[0].text, contains('contratto scade'));
      expect(lines[1].text, contains('Second paragraph'));
      expect(lines.every((l) => l.paragraphStart), isTrue);
      final first = lines[0];
      expect(first.left, inInclusiveRange(0.02, 0.1));
      expect(first.top, lessThan(lines[1].top));
      expect(first.right, lessThanOrEqualTo(1));
      expect(first.bottom, greaterThan(first.top));
    },
    skip: _engine == null || _tessdata == null
        ? 'no Tesseract engine or English model on this machine'
        : false,
  );
}

/// [lines] in Literata at 300 DPI on a white page, as 8-bit gray.
Future<({Uint8List gray, int width, int height})> _render(
  List<String> lines,
) async {
  final font = File(
    p.join('assets', 'fonts', 'literata', 'Literata-Regular.ttf'),
  ).readAsBytesSync();
  await (FontLoader(
    'OcrLiterata',
  )..addFont(Future.value(ByteData.sublistView(font)))).load();
  const width = 1600;
  const height = 600;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)
    ..drawRect(
      const ui.Rect.fromLTWH(0, 0, width + 0.0, height + 0.0),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(fontFamily: 'OcrLiterata', fontSize: 56),
        )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF000000)))
        ..addText(lines.join('\n'));
  canvas.drawParagraph(
    builder.build()..layout(const ui.ParagraphConstraints(width: width - 160)),
    const ui.Offset(80, 60),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  final gray = Uint8List(width * height);
  for (var i = 0; i < gray.length; i++) {
    gray[i] =
        (rgba[i * 4] * 77 + rgba[i * 4 + 1] * 150 + rgba[i * 4 + 2] * 29) >> 8;
  }
  return (gray: gray, width: width, height: height);
}
