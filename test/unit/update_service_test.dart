// Issue #81: the Android installer bridge hands the APK to the system.
// Issue #384: the download is verified against the release's digest.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/isolate_gauge.dart';
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

    test('reports its progress, and a verified file is not fetched again '
        '(#900)', () async {
      final bytes = List<int>.generate(200000, (i) => i % 251);
      final digest = 'sha256:${sha256.convert(bytes)}';
      var requests = 0;
      server.listen((request) async {
        requests++;
        request.response
          ..statusCode = HttpStatus.ok
          ..contentLength = bytes.length
          ..add(bytes);
        await request.response.close();
      });
      final served = ReleaseAsset(
        name: 'niman-1.0.0-windows-x64-setup.exe',
        downloadUrl: 'http://${server.address.host}:${server.port}/setup.exe',
        digest: digest,
      );
      final seen = <(int, int?)>[];
      await downloadAsset(
        served,
        into: dir,
        onProgress: (received, total) => seen.add((received, total)),
      );
      expect(seen.last, (bytes.length, bytes.length));
      expect(requests, 1);

      final again = await downloadAsset(served, into: dir);
      expect(requests, 1, reason: 'the file there passed the digest');
      expect(await again.readAsBytes(), bytes);
    });

    test('a cancel stops the transfer and leaves nothing (#900)', () async {
      final bytes = List<int>.generate(200000, (i) => i % 251);
      await expectLater(
        downloadAsset(
          asset(served: bytes, digest: 'sha256:${sha256.convert(bytes)}'),
          into: dir,
          cancel: Future<void>.value(),
        ),
        throwsA(isA<UpdateCancelled>()),
      );
      expect(dir.listSync(), isEmpty);
    });

    test('a cancel that lands while the file is hashed keeps it from '
        'becoming the download (#911)', () async {
      final bytes = List<int>.generate(200000, (i) => i % 251);
      final cancel = Completer<void>();
      Timer? watch;
      addTearDown(() => watch?.cancel());
      server.listen((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..contentLength = bytes.length
          ..add(bytes);
        await request.response.close();
      });
      final served = ReleaseAsset(
        name: 'niman-1.0.0-windows-x64-setup.exe',
        downloadUrl: 'http://${server.address.host}:${server.port}/setup.exe',
        digest: 'sha256:${sha256.convert(bytes)}',
      );
      final hashing = Completer<void>();
      await expectLater(
        downloadAsset(
          served,
          into: dir,
          cancel: cancel.future,
          onProgress: (received, total) {
            // The last chunk is in: the digest job starts once the body
            // closes, and the cancel is pressed while it runs.
            if (received != total || watch != null) return;
            watch = Timer.periodic(Duration.zero, (timer) {
              if (IsolateGauge.inFlight == 0) return;
              timer.cancel();
              hashing.complete();
              cancel.complete();
            });
          },
        ),
        throwsA(isA<UpdateCancelled>()),
      );
      expect(hashing.isCompleted, isTrue, reason: 'the cancel came mid-hash');
      expect(downloaded().existsSync(), isFalse);
      expect(dir.listSync(), isEmpty, reason: 'the partial file is gone too');
    });

    test('a cancel on a file already there stops before it is handed back '
        'and keeps the file (#911)', () async {
      final bytes = utf8.encode('the genuine installer bytes');
      final served = asset(
        served: bytes,
        digest: 'sha256:${sha256.convert(bytes)}',
      );
      await downloadAsset(served, into: dir);
      await expectLater(
        downloadAsset(served, into: dir, cancel: Future<void>.value()),
        throwsA(isA<UpdateCancelled>()),
      );
      expect(await downloaded().readAsBytes(), bytes);
    });

    test('a cancel ends a stalled transfer at once, not at the stall timeout '
        '(#911)', () async {
      final cancel = Completer<void>();
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
      // The server goes quiet; the user gives up after a moment.
      Timer(const Duration(milliseconds: 300), cancel.complete);
      final clock = Stopwatch()..start();
      await expectLater(
        downloadAsset(
          target,
          into: dir,
          cancel: cancel.future,
        ).timeout(const Duration(seconds: 10)),
        throwsA(isA<UpdateCancelled>()),
      );
      expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
      expect(dir.listSync(), isEmpty);
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

    test('the installer is hashed off the UI isolate', () async {
      final bytes = utf8.encode('the genuine installer bytes');
      final file = await downloadAsset(
        asset(served: bytes, digest: 'sha256:${sha256.convert(bytes)}'),
        into: dir,
      );
      expect(await file.readAsBytes(), bytes);
      // The digest is computed as a counted background job (IsolateGauge.run),
      // the way the index's probes are: reading and hashing a 60-100 MB
      // installer inline would freeze the UI isolate for a second or more,
      // and would leave the gauge at zero (#495).
      expect(
        IsolateGauge.peak,
        greaterThanOrEqualTo(1),
        reason: 'the digest is computed off the UI isolate',
      );
      expect(IsolateGauge.inFlight, 0, reason: 'the job is counted back out');
    });
  });
}
