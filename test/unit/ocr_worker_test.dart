import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_worker.dart';
import 'package:niman/src/ocr/tesseract.dart';

import '../fakes/ocr_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final skip = liveOcrEngine == null || liveTessdata == null
      ? 'no Tesseract engine or English model on this machine'
      : false;

  test('a worker reads page after page off the UI isolate', () async {
    final worker = await OcrWorker.start(
      engine: liveOcrEngine!,
      datapath: liveTessdata!,
      languages: 'eng',
    );
    addTearDown(worker.close);
    for (final words in ['First page here', 'Second page there']) {
      final page = await renderOcrPage([words]);
      final lines = await worker.recognize((
        data: TransferableTypedData.fromList([page.rgba]),
        width: page.width,
        height: page.height,
        bgra: false,
        ppi: 300,
      ));
      expect(lines.single.text, words);
    }
  }, skip: skip);

  test('closing the worker answers the page in flight', () async {
    final worker = await OcrWorker.start(
      engine: liveOcrEngine!,
      datapath: liveTessdata!,
      languages: 'eng',
    );
    final page = await renderOcrPage(['Never read']);
    final pending = worker.recognize((
      data: TransferableTypedData.fromList([page.rgba]),
      width: page.width,
      height: page.height,
      bgra: false,
      ppi: 300,
    ));
    // Both ports close here: the reply and the exit can no longer come,
    // and the page answers rather than waiting forever (#608).
    worker.close();
    await expectLater(pending, throwsA(isA<TesseractException>()));
  }, skip: skip);

  test('languages that do not load fail the start', () async {
    await expectLater(
      OcrWorker.start(
        engine: liveOcrEngine!,
        datapath: liveTessdata!,
        languages: 'xyz',
      ),
      throwsA(isA<TesseractException>()),
    );
  }, skip: skip);

  test('an engine that does not load fails the start', () async {
    await expectLater(
      OcrWorker.start(
        engine: '/nonexistent/libnope.so',
        datapath: '/tmp',
        languages: 'eng',
      ),
      throwsA(isA<TesseractException>()),
    );
  });
}
