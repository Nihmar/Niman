import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/transcription/transcription_settings.dart';
import 'package:niman/src/transcription/transcription_settings_store.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TranscriptionSettings', () {
    test('reads defaults from anything that is not a settings object', () {
      for (final json in <Object?>[null, 42, 'x', <Object?>[]]) {
        expect(
          TranscriptionSettings.fromJson(json),
          const TranscriptionSettings(),
        );
      }
      expect(
        TranscriptionSettings.fromJson(const {'model': 7, 'language': ''}),
        const TranscriptionSettings(),
      );
    });

    test('round-trips through JSON', () {
      const settings = TranscriptionSettings(modelId: 'base', language: 'de');
      expect(TranscriptionSettings.fromJson(settings.toJson()), settings);
    });

    test('hands whisper the app language, its own codes, or auto', () {
      const app = TranscriptionSettings();
      expect(app.whisperLanguage(AppLanguage.italian), 'it');
      expect(app.whisperLanguage(AppLanguage.norwegian), 'no');
      expect(app.whisperLanguage(AppLanguage.system), 'auto');
      expect(
        app
            .withLanguage(TranscriptionSettings.detect)
            .whisperLanguage(AppLanguage.italian),
        'auto',
      );
      expect(app.withLanguage('fr').whisperLanguage(AppLanguage.italian), 'fr');
    });
  });

  group('TranscriptionSettingsStore', () {
    late Directory dir;
    late TranscriptionSettingsStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('niman_transcription_');
      store = TranscriptionSettingsStore(() async => dir.path);
    });

    tearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    test('a missing file reads as the defaults', () async {
      expect(await store.load(), const TranscriptionSettings());
    });

    test('saves and loads', () async {
      const settings = TranscriptionSettings(modelId: 'small', language: 'es');
      await store.save(settings);
      expect(await store.load(), settings);
      expect(dir.listSync().map((e) => p.basename(e.path)), [
        TranscriptionSettingsStore.fileName,
      ]);
    });

    test('a corrupt file reads as the defaults', () async {
      await File(p.join(dir.path, TranscriptionSettingsStore.fileName))
          .writeAsString('{not json');
      expect(await store.load(), const TranscriptionSettings());
    });
  });
}
