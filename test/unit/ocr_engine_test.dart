import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/tesseract.dart';

import '../fakes/ocr_page.dart';

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
      final page = await renderOcrPage([
        'Il contratto scade il 28 febbraio.',
        '',
        'Second paragraph, first line',
      ]);
      final tesseract = Tesseract.open(
        openOcrEngine(liveOcrEngine!)!,
        datapath: liveTessdata!,
        languages: 'eng',
      );
      addTearDown(tesseract.dispose);
      final lines = tesseract.recognize(
        grayOf(page.rgba),
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
    skip: liveOcrEngine == null || liveTessdata == null
        ? 'no Tesseract engine or English model on this machine'
        : false,
  );
}
