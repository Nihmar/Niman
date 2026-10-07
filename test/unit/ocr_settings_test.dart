import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_settings.dart';

void main() {
  test('a missing, broken or foreign file reads as the defaults', () {
    for (final json in [null, 'x', 3, <String, Object?>{}]) {
      expect(OcrSettings.fromJson(json), const OcrSettings());
    }
    expect(
      OcrSettings.fromJson(const {'quality': 'huge', 'language': 'klingon'}),
      const OcrSettings(),
    );
  });

  test('settings round-trip through JSON', () {
    const settings = OcrSettings(
      quality: OcrQuality.best,
      language: 'deu',
      also: 'eng',
    );
    expect(OcrSettings.fromJson(settings.toJson()), settings);
  });

  test('the default language follows the app until one is chosen', () {
    const settings = OcrSettings();
    expect(settings.defaultLanguage(AppLanguage.italian).code, 'ita');
    expect(settings.defaultLanguage(AppLanguage.system).code, 'eng');
    expect(
      settings.withLanguage('fra').defaultLanguage(AppLanguage.italian).code,
      'fra',
    );
  });

  test('"Also" the default language itself means none', () {
    final settings = const OcrSettings().withAlso('ita');
    expect(settings.alsoLanguage(AppLanguage.italian), isNull);
    expect(settings.alsoLanguage(AppLanguage.english)!.code, 'ita');
    expect(settings.withAlso(null).also, isNull);
  });
}
