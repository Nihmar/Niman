import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ocr/ocr_engine_build.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_language_catalog.dart';
import 'package:niman/src/ocr/ocr_settings.dart';

void main() {
  final hex64 = RegExp(r'^[0-9a-f]{64}$');

  test('every language file pins a size and a SHA-256, under a unique id', () {
    final ids = <String>{};
    for (final language in ocrLanguages) {
      expect(language.native, isNotEmpty, reason: language.code);
      expect(language.english, isNotEmpty, reason: language.code);
      for (final quality in OcrQuality.values) {
        final file = language.file(quality);
        if (file == null) continue;
        expect(file.bytes, greaterThan(1024), reason: file.id);
        expect(file.sha256, matches(hex64), reason: file.id);
        expect(ids.add(file.id), isTrue, reason: 'duplicate ${file.id}');
        expect(file.fileName, '${quality.name}/${language.code}.traineddata');
      }
    }
  });

  test('language files come from the pinned tessdata commits', () {
    final ita = ocrLanguageByCode('ita')!;
    expect(
      ita.file(OcrQuality.fast)!.uri.toString(),
      'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/'
      '$tessdataFastCommit/ita.traineddata',
    );
    expect(
      ita.file(OcrQuality.best)!.uri.path,
      contains('/tessdata_best/$tessdataBestCommit/'),
    );
  });

  test('every app language the OCR maps to is in the catalog', () {
    for (final id in ['en', 'it', 'zh', 'nb', 'sq', 'tr']) {
      expect(
        ocrLanguageByCode(ocrCodeOfAppLanguage(id)),
        isNotNull,
        reason: id,
      );
    }
  });

  test('search matches the native name, the English name and the code', () {
    final deu = ocrLanguageByCode('deu')!;
    expect(deu.matches('deut'), isTrue);
    expect(deu.matches('GERM'), isTrue);
    expect(deu.matches('de'), isTrue);
    expect(deu.matches('ital'), isFalse);
    expect(deu.matches('  '), isTrue);
  });

  test('every engine build is published for its own platform', () {
    expect(ocrEngineBuildFor(Abi.androidArm64)!.target, 'android-arm64-v8a');
    expect(ocrEngineBuildFor(Abi.androidX64)!.target, 'android-x86_64');
    expect(ocrEngineBuildFor(Abi.linuxX64)!.target, 'linux-x64');
    expect(ocrEngineBuildFor(Abi.windowsX64)!.fileName, endsWith('.dll'));
    expect(ocrEngineBuildFor(Abi.macosArm64), isNull);
    for (final build in ocrEngineBuilds) {
      expect(build.sha256, matches(hex64), reason: build.target);
      expect(build.bytes, greaterThan(0), reason: build.target);
      expect(
        build.uri.toString(),
        startsWith(
          'https://github.com/Nihmar/Niman/releases/download/'
          '${OcrEngineBuild.release}/',
        ),
      );
    }
  });
}
