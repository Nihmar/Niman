import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:path/path.dart' as p;

/// The OCR engine for the live OCR tests: the library named by
/// `NIMAN_OCR_ENGINE` (a build of scripts/ocr-engine.sh), or the
/// distribution's (CI installs tesseract-ocr). Null skips the live cases.
final String? liveOcrEngine =
    Platform.environment['NIMAN_OCR_ENGINE'] ?? findInstalledOcrEngine()?.name;

/// Where the English model is, next to [liveOcrEngine]; null skips the
/// live cases.
final String? liveTessdata = [
  '/usr/share/tessdata',
  '/usr/share/tesseract-ocr/5/tessdata',
  '/usr/share/tesseract-ocr/4.00/tessdata',
].where((dir) => File(p.join(dir, 'eng.traineddata')).existsSync()).firstOrNull;

/// [lines] in Literata on a white 1600 × 600 page, as RGBA.
Future<({Uint8List rgba, int width, int height})> renderOcrPage(
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
  return (rgba: rgba, width: width, height: height);
}

/// [rgba] as 8-bit luminance.
Uint8List grayOf(Uint8List rgba) {
  final gray = Uint8List(rgba.length ~/ 4);
  for (var i = 0; i < gray.length; i++) {
    gray[i] =
        (rgba[i * 4] * 77 + rgba[i * 4 + 1] * 150 + rgba[i * 4 + 2] * 29) >> 8;
  }
  return gray;
}
