// Issue #81: the Android installer bridge hands the APK to the system.
// Issue #384: the download is verified against the release's digest.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/update/release_asset.dart';
import 'package:niman/src/update/update_service.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('installApk', () {
    test('passes the apk path to the system installer', () async {
      String? installed;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const channel = MethodChannel('niman/update');
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'installApk');
        installed = (call.arguments as Map)['path'] as String?;
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      expect(await installApk(File('niman-1.0.0-android.apk')), true);
      expect(installed, 'niman-1.0.0-android.apk');
    });

    test(
      'an unreachable bridge keeps the download without launching',
      () async {
        expect(await installApk(File('niman-1.0.0-android.apk')), false);
      },
    );
  });

  group('downloadAsset verifies the published digest', () {
    // A throwaway local server stands in for GitHub: the download path is
    // the real `HttpClient` one, and the fixtures are the bytes it answers.
    late HttpServer server;
    late Directory dir;
    HttpOverrides? savedOverrides;

    setUp(() async {
      // flutter_test's binding answers every HttpClient request with 400;
      // drop that override so the loopback server is really reached.
      savedOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      dir = await Directory.systemTemp.createTemp('niman-update');
    });

    tearDown(() async {
      HttpOverrides.global = savedOverrides;
      await server.close(force: true);
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    /// Serves [bytes] at every path until the server closes.
    void serve(List<int> bytes) {
      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..add(bytes);
        await request.response.close();
      });
    }

    ReleaseAsset asset({required List<int> served, required String? digest}) {
      serve(served);
      return ReleaseAsset(
        name: 'niman-1.0.0-windows-x64-setup.exe',
        downloadUrl: 'http://${server.address.host}:${server.port}/setup.exe',
        digest: digest,
      );
    }

    File downloaded() =>
        File(p.join(dir.path, 'niman-1.0.0-windows-x64-setup.exe'));

    test('keeps bytes that match the published digest', () async {
      final bytes = utf8.encode('the genuine installer bytes');
      final file = await downloadAsset(
        asset(served: bytes, digest: 'sha256:${sha256.convert(bytes)}'),
        into: dir,
      );
      expect(file.existsSync(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });

    test('refuses and removes bytes that do not match', () async {
      await expectLater(
        downloadAsset(
          asset(
            served: utf8.encode('the tampered bytes'),
            digest: 'sha256:${sha256.convert(utf8.encode('the genuine ones'))}',
          ),
          into: dir,
        ),
        throwsA(isA<UpdateIntegrityException>()),
      );
      expect(downloaded().existsSync(), isFalse);
    });

    test('refuses an asset that published no digest', () async {
      await expectLater(
        downloadAsset(
          asset(served: utf8.encode('unverifiable bytes'), digest: null),
          into: dir,
        ),
        throwsA(isA<UpdateIntegrityException>()),
      );
      expect(downloaded().existsSync(), isFalse);
    });

    test(
      'a download cut off mid-body leaves nothing under the asset name',
      () async {
        // Headers promise a whole installer, then the connection is dropped
        // after the first bytes: the transfer fails mid-body.
        final partial = utf8.encode('the first half of the installer');
        server.listen((request) async {
          request.response
            ..statusCode = HttpStatus.ok
            ..contentLength = 1000000
            ..add(partial);
          try {
            await request.response.flush();
            await request.response.close();
          } on HttpException {
            // The client hung up on the short body; the server says so.
          }
        });
        final target = ReleaseAsset(
          name: 'niman-1.0.0-windows-x64-setup.exe',
          downloadUrl: 'http://${server.address.host}:${server.port}/setup.exe',
          digest: 'sha256:${sha256.convert(partial)}',
        );
        await expectLater(
          downloadAsset(target, into: dir),
          throwsA(anything),
          reason: 'the cut-off transfer must fail',
        );
        expect(
          downloaded().existsSync(),
          isFalse,
          reason: 'a truncated file must not keep the installer name',
        );
        expect(
          File('${downloaded().path}.part').existsSync(),
          isFalse,
          reason: 'the partial file must be removed too',
        );
      },
    );

    test('a body that stops arriving times out', () async {
      const stall = Duration(milliseconds: 600);
      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..contentLength = 1000000
          ..add(utf8.encode('the first bytes'));
        // Headers and a first chunk, then silence with the socket open.
        await request.response.flush();
      });
      final target = ReleaseAsset(
        name: 'niman-1.0.0-windows-x64-setup.exe',
        downloadUrl: 'http://${server.address.host}:${server.port}/setup.exe',
        digest: 'sha256:${sha256.convert(utf8.encode('the whole installer'))}',
      );
      final clock = Stopwatch()..start();
      await expectLater(
        downloadAsset(
          target,
          into: dir,
          stallTimeout: stall,
        ).timeout(const Duration(seconds: 10)),
        throwsA(isA<TimeoutException>()),
        reason: 'a silent server must fail, not hold the check open',
      );
      expect(
        clock.elapsed,
        lessThan(stall * 4),
        reason: 'the body gives up on the stall timeout',
      );
      expect(downloaded().existsSync(), isFalse);
      expect(File('${downloaded().path}.part').existsSync(), isFalse);
    });
  });
}
