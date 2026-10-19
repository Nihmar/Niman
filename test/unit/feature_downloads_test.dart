// #1109 phase 5: no Tesseract file and no whisper model is fetched while the
// feature that wants it is off -- refused at the download itself, so a
// click, a recognition waiting on a language and the resume on returning
// to the app are all stopped, and nothing on disk is touched.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/download/download_files.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/library/feature_download_gate.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/transcription/transcription_models.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  late Directory dir;
  var allowed = false;
  var started = <Uri>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_feature_dl_');
    allowed = false;
    started = [];
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  /// A starter that only records the request: it fails the download, which
  /// is all a test of whether it started needs.
  Future<Never> record({
    required Uri uri,
    required String target,
    required void Function(int received) onProgress,
    String? sha256,
    void Function(int? total, int elapsedMs, int resumedFrom)? onHeaders,
  }) async {
    started.add(uri);
    throw StateError('no network in this test');
  }

  final eng = ocrLanguageByCode('eng')!;
  final engFast = eng.file(OcrQuality.fast)!;

  OcrInstallation ocr() {
    final result = OcrInstallation(
      directory: () async => dir.path,
      build: null,
      findInstalled: () async => null,
      probe: (_) async => '5.5.3',
      retryDelays: const [],
      startDownload: record,
      downloadsAllowed: () => allowed,
    );
    addTearDown(result.dispose);
    return result;
  }

  TranscriptionModels transcription() {
    final result = TranscriptionModels(
      directory: () async => dir.path,
      phone: false,
      retryDelays: const [],
      startDownload: record,
      downloadsAllowed: () => allowed,
    );
    addTearDown(result.dispose);
    return result;
  }

  group('text recognition', () {
    test('a download is refused while ocr is off', () async {
      final installation = ocr();
      await installation.load();
      await installation.download(engFast);
      await installation.downloadAll([engFast]);
      expect(started, isEmpty);
      expect(installation.stateOf(engFast), isA<NotDownloaded>());
    });

    test('the resume of a cut-off download is refused too', () async {
      File(p.join(dir.path, '${engFast.fileName}${DownloadFiles.partSuffix}'))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);
      final installation = ocr();
      await installation.load();
      expect(installation.stateOf(engFast), isA<DownloadFailed>());

      await installation.resumeInterrupted();
      expect(started, isEmpty);
      expect(
        File(p.join(dir.path, '${engFast.fileName}${DownloadFiles.partSuffix}'))
            .existsSync(),
        isTrue,
        reason: 'off is inert: the partial file stays',
      );
    });

    test('turned on again, the same download goes', () async {
      final installation = ocr();
      await installation.load();
      await installation.download(engFast);
      expect(started, isEmpty);

      allowed = true;
      await installation.download(engFast);
      expect(started, hasLength(1));
    });
  });

  group('transcription', () {
    test('a model is not downloaded while transcription is off', () async {
      final models = transcription();
      await models.load();
      await models.download(transcriptionModels.first);
      expect(started, isEmpty);
      expect(models.stateOf(transcriptionModels.first), isA<NotDownloaded>());
    });

    test('the resume is refused, and the model goes once on', () async {
      final model = transcriptionModels.first;
      File(p.join(dir.path, '${model.fileName}${DownloadFiles.partSuffix}'))
          .writeAsBytesSync([1, 2, 3]);
      final models = transcription();
      await models.load();

      await models.resumeInterrupted();
      expect(started, isEmpty);

      allowed = true;
      await models.resumeInterrupted();
      expect(started, hasLength(1));
    });
  });

  group('the gate the providers use', () {
    late FakeLibrarySession session;
    late ProviderContainer container;

    setUp(() {
      session = FakeLibrarySession();
      container = ProviderContainer(
        overrides: [librarySessionProvider.overrideWithValue(session)],
      );
      addTearDown(container.dispose);
    });

    bool Function() gateOf(LibraryFeature feature) {
      late bool Function() gate;
      final probe = Provider<bool Function()>((ref) {
        return gate = featureDownloadGate(ref, feature);
      });
      container.read(probe);
      return gate;
    }

    test('follows the open library, read at each download', () {
      final ocrGate = gateOf(LibraryFeature.ocr);
      final transcriptionGate = gateOf(LibraryFeature.transcription);
      expect(ocrGate(), isTrue);
      expect(transcriptionGate(), isTrue);

      session.features.value = const Features().withSwitch(
        LibraryFeature.ocr,
        on: false,
      );
      expect(ocrGate(), isFalse);
      expect(transcriptionGate(), isTrue, reason: 'its own switch');

      session.features.value = const Features().withSwitch(
        LibraryFeature.kindAudio,
        on: false,
      );
      expect(ocrGate(), isTrue);
      expect(
        transcriptionGate(),
        isFalse,
        reason: 'no audio notes, no models to fetch',
      );
    });
  });
}
