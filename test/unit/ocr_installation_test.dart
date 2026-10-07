import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/core/download/file_download.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/ocr/ocr_engine_build.dart';
import 'package:niman/src/ocr/ocr_engine_locator.dart';
import 'package:niman/src/ocr/ocr_installation.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_settings.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory dir;
  late HttpServer server;
  final payload = Uint8List.fromList(List<int>.generate(5000, (i) => i % 7));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_ocr_');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) async {
        request.response.contentLength = payload.length;
        request.response.add(payload);
        await request.response.close();
      });
  });

  tearDown(() async {
    await server.close(force: true);
    for (var i = 0; i < 20 && dir.existsSync(); i++) {
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  final ita = ocrLanguageByCode('ita')!;
  final eng = ocrLanguageByCode('eng')!;
  final itaFast = ita.file(OcrQuality.fast)!;
  final engFast = eng.file(OcrQuality.fast)!;
  final build = OcrEngineBuild(
    'linux-x64',
    bytes: payload.length,
    sha256: sha256.convert(payload).toString(),
  );

  OcrInstallation installation({
    OcrEngineBuild? engineBuild,
    OcrEngineLibrary? installed,
    Future<String?> Function(String path)? probe,
  }) {
    final result = OcrInstallation(
      directory: () async => dir.path,
      build: engineBuild,
      findInstalled: () async => installed,
      probe: probe ?? (_) async => '5.5.3',
      retryDelays: const [],
      // Every file comes from the local server, whatever its catalog URL.
      startDownload:
          ({
            required uri,
            required target,
            required onProgress,
            sha256,
            onHeaders,
          }) => FileDownload.start(
            uri: Uri.parse('http://127.0.0.1:${server.port}/f'),
            target: target,
            onProgress: onProgress,
            sha256: sha256,
            onHeaders: onHeaders,
          ),
    );
    addTearDown(result.dispose);
    return result;
  }

  void put(String relative, {String suffix = ''}) {
    File(p.join(dir.path, '$relative$suffix'))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
  }

  test('disk says what is installed and what was cut off', () async {
    put(itaFast.fileName);
    put(engFast.fileName, suffix: '.part');
    final ocr = installation();
    await ocr.load();
    expect(ocr.stateOf(itaFast), isA<Downloaded>());
    expect(
      ocr.stateOf(engFast),
      isA<DownloadFailed>()
          .having((s) => s.resumable, 'resumable', isTrue)
          .having((s) => s.total, 'total', engFast.bytes),
    );
    expect(ocr.installed(OcrQuality.fast), [itaFast]);
    expect(ocr.installed(OcrQuality.best), isEmpty);
    expect(ocr.installedBytes(OcrQuality.fast), 3);
    expect(ocr.datapath(OcrQuality.best), p.join(dir.path, 'best'));
  });

  test('the engine: on the device, downloaded, to download, or none', () async {
    const system = (
      name: 'libtesseract.so.5',
      source: OcrEngineSource.system,
      version: '5.5.3',
    );
    final onDevice = installation(engineBuild: build, installed: system);
    await onDevice.load();
    expect(onDevice.engine, system);
    expect(onDevice.missingFor([ita]), [itaFast]);

    final toDownload = installation(engineBuild: build);
    await toDownload.load();
    expect(toDownload.engine, isNull);
    expect(toDownload.missingFor([ita, eng]), [build, itaFast, engFast]);
    expect(toDownload.unavailable, isFalse);

    put(build.fileName);
    final downloaded = installation(engineBuild: build);
    await downloaded.load();
    expect(downloaded.engine, (
      name: p.join(dir.path, build.fileName),
      source: OcrEngineSource.downloaded,
      version: OcrEngineBuild.version,
    ));

    final none = installation();
    await none.load();
    expect(none.unavailable, isTrue);
  });

  test('a download lands when it matches its pinned SHA-256', () async {
    final ocr = installation(engineBuild: build);
    await ocr.load();
    await ocr.download(build);
    expect(ocr.stateOf(build), isA<Downloaded>());
    expect(File(p.join(dir.path, build.fileName)).readAsBytesSync(), payload);
    expect(ocr.engine?.source, OcrEngineSource.downloaded);

    await ocr.delete(build);
    expect(ocr.stateOf(build), isA<NotDownloaded>());
    expect(File(p.join(dir.path, build.fileName)).existsSync(), isFalse);
  });

  test('a download already running is waited for, not skipped', () async {
    final ocr = installation(engineBuild: build);
    await ocr.load();
    final first = ocr.download(build);
    expect(ocr.stateOf(build), isA<Downloading>());
    await ocr.downloadAll([build]);
    expect(ocr.stateOf(build), isA<Downloaded>());
    await first;
  });

  test('an engine this device will not load is thrown away', () async {
    String? probed;
    final ocr = installation(
      engineBuild: build,
      probe: (path) async {
        probed = path;
        return null;
      },
    );
    await ocr.load();
    await ocr.download(build);
    expect(probed, p.join(dir.path, build.fileName));
    expect(
      ocr.stateOf(build),
      isA<DownloadFailed>().having((s) => s.resumable, 'resumable', isFalse),
    );
    expect(File(p.join(dir.path, build.fileName)).existsSync(), isFalse);
    expect(ocr.engine, isNull);
  });

  test('a download that does not match its SHA-256 fails for good', () async {
    final ocr = installation();
    await ocr.load();
    await ocr.download(itaFast);
    expect(
      ocr.stateOf(itaFast),
      isA<DownloadFailed>().having((s) => s.resumable, 'resumable', isFalse),
    );
    expect(File(p.join(dir.path, itaFast.fileName)).existsSync(), isFalse);
  });

  test('settings are saved next to the data and read back', () async {
    final ocr = installation();
    await ocr.load();
    expect(ocr.defaultLanguage(AppLanguage.italian), ita);
    await ocr.setQuality(OcrQuality.best);
    await ocr.setLanguage(eng);
    await ocr.setAlso(ita);
    final again = installation();
    await again.load();
    expect(
      again.settings,
      const OcrSettings(quality: OcrQuality.best, language: 'eng', also: 'ita'),
    );
    expect(again.alsoLanguage(AppLanguage.italian), ita);
  });
}
