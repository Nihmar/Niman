import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/transfers/direct_write.dart';
import 'package:niman/src/sync/transfers/inline_sync_transfers.dart';
import 'package:niman/src/sync/transfers/isolate_sync_transfers.dart';
import 'package:niman/src/sync/transfers/sync_transfers.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_webdav_server.dart';

/// How a transfer implementation is built over a client for the server.
typedef _Build = SyncTransfers Function(WebDavClient client);

void main() {
  group('inline transfers', () => _contract(InlineSyncTransfers.new));
  group('isolate transfers', () {
    _contract((client) => IsolateSyncTransfers(client.config!));
    _isolateOnly();
  });
}

String _sha(List<int> bytes) => sha256.convert(bytes).toString();

/// What every [SyncTransfers] does the same, whichever isolate it runs on.
void _contract(_Build build) {
  late FakeWebDavServer server;
  late Directory dir;
  late WebDavClient client;
  late SyncTransfers transfers;

  setUp(() async {
    server = await FakeWebDavServer.start();
    dir = await Directory.systemTemp.createTemp('niman_transfers');
    client = WebDavClient(
      url: server.url,
      timeout: const Duration(milliseconds: 600),
    );
    transfers = build(client);
  });

  tearDown(() async {
    await transfers.close();
    client.close();
    await server.close();
    await dir.delete(recursive: true);
  });

  String temp(String name) => p.join(dir.path, name);

  bool leftover() => dir.listSync().isNotEmpty;

  /// Bytes the two sides together counted.
  int received() => client.bytesReceived + transfers.bytesReceived;
  int sent() => client.bytesSent + transfers.bytesSent;
  int hashed() => client.bytesHashed + transfers.bytesHashed;

  test('a download writes the file, closed, and says what arrived', () async {
    final body = utf8.encode('the server copy' * 5000);
    server.putFile('a/b.md', body);

    final download = await transfers.download('a/b.md', temp('out'));

    expect(download.bytes, body.length);
    expect(download.sha256, _sha(body));
    expect(download.etag, isNotNull);
    expect(download.modified, isNotNull);
    // Closed before the answer: a rename over it goes through at once, as
    // it must on Windows, where an open handle refuses it (#103).
    final renamed = await File(temp('out')).rename(temp('renamed'));
    expect(await renamed.readAsBytes(), body);
    expect(received(), body.length);
    expect(hashed(), 0);
  });

  test('a hash by download keeps nothing and counts as hashed', () async {
    final body = List<int>.generate(70000, (i) => i % 251);
    server.putFile('big.bin', body);

    expect(await transfers.hashRemote('big.bin'), _sha(body));

    expect(hashed(), body.length);
    expect(received(), 0);
    expect(leftover(), isFalse);
  });

  test('an upload sends the file and answers the digest it sent', () async {
    final body = utf8.encode('local words ' * 3000);
    File(temp('local.md')).writeAsBytesSync(body);
    server.putFile('.keep', const []);

    final upload = await transfers.upload(
      'new.md',
      temp('local.md'),
      ifNoneMatch: true,
      modified: DateTime.utc(2026, 3, 4, 5, 6, 7),
    );

    expect(upload.created, isTrue);
    expect(upload.sha256, _sha(body));
    expect(upload.etag, isNotNull);
    expect(server.file('new.md'), body);
    expect(sent(), body.length);
  });

  test('a failed If-None-Match is the precondition failure', () async {
    File(temp('local.md')).writeAsStringSync('mine');
    server.putFile('there.md', utf8.encode('theirs'));

    await expectLater(
      transfers.upload('there.md', temp('local.md'), ifNoneMatch: true),
      throwsA(isA<WebDavPrecondition>().having((e) => e.status, 'status', 412)),
    );
    expect(utf8.decode(server.file('there.md')!), 'theirs');
  });

  test('a stale If-Match is the precondition failure', () async {
    File(temp('local.md')).writeAsStringSync('mine');
    server.putFile('there.md', utf8.encode('theirs'));

    await expectLater(
      transfers.upload('there.md', temp('local.md'), ifMatch: '"nope"'),
      throwsA(isA<WebDavPrecondition>()),
    );
  });

  test('a missing file is not found and leaves no temp', () async {
    await expectLater(
      transfers.download('gone.md', temp('out')),
      throwsA(isA<WebDavNotFound>().having((e) => e.status, 'status', 404)),
    );
    expect(leftover(), isFalse);
  });

  test('refused credentials are the auth failure', () async {
    server
      ..credentials = (user: 'u', password: 'right')
      ..putFile('a.md', utf8.encode('a'));

    await expectLater(
      transfers.download('a.md', temp('out')),
      throwsA(isA<WebDavAuthFailure>().having((e) => e.status, 'status', 401)),
    );
    expect(leftover(), isFalse);
  });

  test('a busy server is retryable, with the wait it asked for', () async {
    server
      ..putFile('a.md', utf8.encode('a'))
      ..failNext(503, retryAfter: '7');

    await expectLater(
      transfers.download('a.md', temp('out')),
      throwsA(
        isA<WebDavRetryable>()
            .having((e) => e.status, 'status', 503)
            .having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 7),
            ),
      ),
    );
    expect(leftover(), isFalse);
  });

  test('a body cut short is retryable and leaves no temp', () async {
    server
      ..putFile('a.bin', List<int>.filled(100000, 7))
      ..dropNextGet();

    await expectLater(
      transfers.download('a.bin', temp('out')),
      throwsA(isA<WebDavRetryable>()),
    );
    expect(leftover(), isFalse);
    // What came before the break still counts.
    expect(received(), greaterThan(0));
  });

  test('a body that stalls is retryable and leaves no temp', () async {
    server
      ..putFile('a.bin', List<int>.filled(100000, 7))
      ..stallNextGet();

    await expectLater(
      transfers.download('a.bin', temp('out')),
      throwsA(isA<WebDavRetryable>()),
    );
    expect(leftover(), isFalse);
  });

  test('an upload of a file that is not there is a local failure', () async {
    await expectLater(
      transfers.upload('x.md', temp('missing.md')),
      throwsA(isA<FileSystemException>()),
    );
    expect(server.requests.where((r) => r.method == 'PUT'), isEmpty);
  });

  group('a new file, written to its final name', () {
    /// Every name the folder holds at any moment while [action] runs, and
    /// every rename the file system reports: a temp that lived for a
    /// millisecond, or a move onto the final name, shows up here.
    Future<({Set<String> names, List<FileSystemEvent> moves})> watched(
      Future<void> Function() action,
    ) async {
      final names = <String>{};
      final moves = <FileSystemEvent>[];
      final events = dir.watch().listen((event) {
        if (event is FileSystemMoveEvent) moves.add(event);
        names.add(p.basename(event.path));
      });
      final poll = Timer.periodic(const Duration(milliseconds: 1), (_) {
        if (!dir.existsSync()) return;
        for (final entry in dir.listSync()) {
          names.add(p.basename(entry.path));
        }
      });
      try {
        await action();
        // The notifications arrive a little behind the calls.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      } finally {
        poll.cancel();
        await events.cancel();
      }
      return (names: names, moves: moves);
    }

    test('under the limit it is held in memory, with no temp', () async {
      final body = utf8.encode('a new note ' * 4000);
      server.putFile('a/new.md', body);

      late NewFileDownload got;
      final seen = await watched(() async {
        got = await transfers.downloadNew(
          'a/new.md',
          temp('out'),
          listedSize: body.length,
          listedEtag: null,
        );
      });

      expect(got.mode, SyncWriteMode.directMemory);
      expect(got.download.bytes, body.length);
      expect(got.download.sha256, _sha(body));
      expect(File(temp('out')).readAsBytesSync(), body);
      // Nothing but the final name ever appeared, and nothing was renamed.
      expect(seen.names, {'out'});
      expect(seen.moves, isEmpty);
      expect(received(), body.length);
      expect(hashed(), 0);
    });

    test('over the limit it streams into the final name', () async {
      final body = List<int>.generate(300000, (i) => i % 253);
      server.putFile('big.bin', body);

      late NewFileDownload got;
      final seen = await watched(() async {
        got = await transfers.downloadNew(
          'big.bin',
          temp('out'),
          listedSize: body.length,
          listedEtag: null,
          memoryLimit: 1000,
        );
      });

      expect(got.mode, SyncWriteMode.directStream);
      expect(got.download.sha256, _sha(body));
      expect(File(temp('out')).readAsBytesSync(), body);
      expect(seen.names, {'out'});
      expect(seen.moves, isEmpty);
      expect(received(), body.length);
    });

    test('a listing without a size streams too', () async {
      final body = utf8.encode('no size ' * 100);
      server.putFile('n.md', body);

      final got = await transfers.downloadNew(
        'n.md',
        temp('out'),
        listedSize: null,
        listedEtag: null,
      );

      expect(got.mode, SyncWriteMode.directStream);
      expect(File(temp('out')).readAsBytesSync(), body);
    });

    test('an empty file is created, empty', () async {
      server.putFile('empty.md', const []);

      final got = await transfers.downloadNew(
        'empty.md',
        temp('out'),
        listedSize: 0,
        listedEtag: null,
      );

      expect(got.download.bytes, 0);
      expect(File(temp('out')).readAsBytesSync(), isEmpty);
    });

    // The same failures, once for each way of writing.
    for (final streamed in [false, true]) {
      final how = streamed ? 'streamed' : 'held in memory';
      final limit = streamed ? 100 : kSyncDirectWriteMaxBytes;

      test('a file that appears first is not overwritten ($how)', () async {
        server.putFile('a.md', utf8.encode('from the server'));
        File(temp('out')).writeAsStringSync('the user wrote this');

        await expectLater(
          transfers.downloadNew(
            'a.md',
            temp('out'),
            listedSize: 'from the server'.length,
            listedEtag: null,
            memoryLimit: limit,
          ),
          throwsA(isA<DirectWriteRefused>()),
        );

        expect(File(temp('out')).readAsStringSync(), 'the user wrote this');
        expect(dir.listSync().length, 1);
      });

      test('a body cut short leaves nothing ($how)', () async {
        server
          ..putFile('a.bin', List<int>.filled(100000, 7))
          ..dropNextGet();

        await expectLater(
          transfers.downloadNew(
            'a.bin',
            temp('out'),
            listedSize: 100000,
            listedEtag: null,
            memoryLimit: streamed ? 100 : 200000,
          ),
          throwsA(isA<WebDavRetryable>()),
        );

        expect(leftover(), isFalse);
      });

      test(
        'a body that disagrees with the listing leaves nothing ($how)',
        () async {
          server.putFile('a.bin', List<int>.filled(5000, 7));
          // The listing's ETag is the file's own, so the size cannot be
          // explained as a rewrite since.
          final etag = (await client.stat('a.bin'))!.etag;

          await expectLater(
            transfers.downloadNew(
              'a.bin',
              temp('out'),
              listedSize: 4000,
              listedEtag: etag,
              memoryLimit: streamed ? 100 : 200000,
            ),
            throwsA(isA<WebDavProtocolFailure>()),
          );

          expect(leftover(), isFalse);
        },
      );

      test('a missing file leaves nothing ($how)', () async {
        await expectLater(
          transfers.downloadNew(
            'gone.md',
            temp('out'),
            listedSize: 10,
            listedEtag: null,
            memoryLimit: limit,
          ),
          throwsA(isA<WebDavNotFound>()),
        );

        expect(leftover(), isFalse);
      });
    }

    test(
      'a body that outgrows the memory held for it fails, leaving nothing',
      () async {
        server.putFile('grown.bin', List<int>.filled(5000, 9));

        await expectLater(
          transfers.downloadNew(
            'grown.bin',
            temp('out'),
            listedSize: 50,
            listedEtag: null,
            memoryLimit: 100,
          ),
          throwsA(
            isA<WebDavRetryable>().having((e) => e.status, 'status', 200),
          ),
        );

        expect(leftover(), isFalse);
      },
    );

    test('a folder that is not there is a local failure', () async {
      server.putFile('a.md', utf8.encode('a'));

      await expectLater(
        transfers.downloadNew(
          'a.md',
          p.join(dir.path, 'no', 'such', 'out'),
          listedSize: 1,
          listedEtag: null,
        ),
        throwsA(
          isA<FileSystemException>().having(
            (e) => e is DirectWriteRefused,
            'refused',
            isFalse,
          ),
        ),
      );
    });
  });

  test('a download that cannot open its file is a local failure', () async {
    server.putFile('a.md', utf8.encode('a'));

    await expectLater(
      transfers.download('a.md', p.join(dir.path, 'no', 'such', 'dir', 'out')),
      throwsA(isA<FileSystemException>()),
    );
  });
}

/// What only the worker isolate does: cancel, the log, the certificate rule.
void _isolateOnly() {
  late FakeWebDavServer server;
  late Directory dir;

  setUp(() async {
    server = await FakeWebDavServer.start();
    dir = await Directory.systemTemp.createTemp('niman_transfers');
  });

  tearDown(() async {
    await server.close();
    await dir.delete(recursive: true);
  });

  WebDavClient clientFor(Uri url, {String? fingerprint}) => WebDavClient(
    url: url,
    timeout: const Duration(seconds: 5),
    trustedCertificateFingerprint: fingerprint,
  );

  test('a cancel stops a download in flight and removes its temp', () async {
    server
      ..putFile('slow.bin', List<int>.filled(600000, 1))
      ..trickleNextGet = const Duration(milliseconds: 400);
    final client = clientFor(server.url);
    addTearDown(client.close);
    final transfers = IsolateSyncTransfers(client.config!);
    addTearDown(transfers.close);

    final failure = expectLater(
      transfers.download('slow.bin', p.join(dir.path, 'out')),
      throwsA(isA<WebDavRetryable>()),
    );
    // The body has started coming: the temp exists and the GET was seen.
    while (!server.requests.any((r) => r.method == 'GET')) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(dir.listSync(), isNotEmpty);

    transfers.cancel();
    await failure;

    expect(dir.listSync(), isEmpty);
    // Nothing more is asked of a worker that was told to stop.
    await expectLater(
      transfers.hashRemote('slow.bin'),
      throwsA(isA<WebDavRetryable>()),
    );
  });

  test('a close with nothing in flight reports the whole count', () async {
    final body = List<int>.filled(300000, 3);
    server.putFile('a.bin', body);
    final client = clientFor(server.url);
    addTearDown(client.close);
    final transfers = IsolateSyncTransfers(client.config!);

    await Future.wait([
      transfers.download('a.bin', p.join(dir.path, 'one')),
      transfers.download('a.bin', p.join(dir.path, 'two')),
      transfers.download('a.bin', p.join(dir.path, 'three')),
      transfers.hashRemote('a.bin'),
    ]);
    await transfers.close();

    expect(transfers.bytesReceived, 3 * body.length);
    expect(transfers.bytesHashed, body.length);
    expect(transfers.bytesSent, 0);
    // The run's own client moved none of it.
    expect(client.bytesReceived, 0);
    await expectLater(
      transfers.download('a.bin', p.join(dir.path, 'late')),
      throwsA(isA<WebDavRetryable>()),
    );
  });

  test('a cancel stops a new file streaming in and removes it', () async {
    server
      ..putFile('slow.bin', List<int>.filled(600000, 1))
      ..trickleNextGet = const Duration(milliseconds: 400);
    final client = clientFor(server.url);
    addTearDown(client.close);
    final transfers = IsolateSyncTransfers(client.config!);
    addTearDown(transfers.close);

    final failure = expectLater(
      transfers.downloadNew(
        'slow.bin',
        p.join(dir.path, 'out'),
        listedSize: 600000,
        listedEtag: null,
        memoryLimit: 1000,
      ),
      throwsA(isA<WebDavRetryable>()),
    );
    while (!server.requests.any((r) => r.method == 'GET')) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // Part way, under its final name.
    expect(File(p.join(dir.path, 'out')).existsSync(), isTrue);

    transfers.cancel();
    await failure;

    expect(dir.listSync(), isEmpty);
  });

  test('a cancel while a new file is held in memory writes nothing', () async {
    server
      ..putFile('slow.bin', List<int>.filled(600000, 1))
      ..trickleNextGet = const Duration(milliseconds: 400);
    final client = clientFor(server.url);
    addTearDown(client.close);
    final transfers = IsolateSyncTransfers(client.config!);
    addTearDown(transfers.close);

    final failure = expectLater(
      transfers.downloadNew(
        'slow.bin',
        p.join(dir.path, 'out'),
        listedSize: 600000,
        listedEtag: null,
      ),
      throwsA(isA<WebDavRetryable>()),
    );
    while (!server.requests.any((r) => r.method == 'GET')) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // Nothing on the disk while the body is still arriving.
    expect(dir.listSync(), isEmpty);

    transfers.cancel();
    await failure;

    expect(dir.listSync(), isEmpty);
  });

  test('a close reports every byte of the new files it wrote', () async {
    final body = List<int>.filled(300000, 3);
    server.putFile('a.bin', body);
    final client = clientFor(server.url);
    addTearDown(client.close);
    final transfers = IsolateSyncTransfers(client.config!);

    await Future.wait([
      transfers.downloadNew(
        'a.bin',
        p.join(dir.path, 'one'),
        listedSize: body.length,
        listedEtag: null,
      ),
      transfers.downloadNew(
        'a.bin',
        p.join(dir.path, 'two'),
        listedSize: body.length,
        listedEtag: null,
        memoryLimit: 10,
      ),
    ]);
    await transfers.close();

    expect(transfers.bytesReceived, 2 * body.length);
    expect(client.bytesReceived, 0);
  });

  test('a close that never needed the worker spawns none', () async {
    final client = clientFor(server.url);
    addTearDown(client.close);
    final transfers = IsolateSyncTransfers(client.config!);

    await transfers.close();
    await transfers.close();

    expect(server.requests, isEmpty);
    expect(transfers.bytesReceived, 0);
  });

  test("the worker's request lines reach the app log", () async {
    server.putFile('logged.md', utf8.encode('x'));
    final client = clientFor(server.url);
    addTearDown(client.close);
    final transfers = IsolateSyncTransfers(client.config!);

    await transfers.download('logged.md', p.join(dir.path, 'out'));
    await transfers.close();

    expect(
      AppLog.lines().any((l) => l.contains('[webdav] GET logged.md -> 200')),
      isTrue,
    );
  });

  group('trusted certificate (#454)', () {
    late FakeWebDavServer secure;
    late String fingerprint;

    setUp(() async {
      secure = await FakeWebDavServer.startSecure(
        SecurityContext()
          ..useCertificateChainBytes(
            File('test/fakes/self_signed_cert.pem').readAsBytesSync(),
          )
          ..usePrivateKeyBytes(
            File('test/fakes/self_signed_key.pem').readAsBytesSync(),
          ),
      );
      final pem = File('test/fakes/self_signed_cert.pem')
          .readAsStringSync()
          .replaceAll(RegExp('-----[^-]+-----'), '')
          .replaceAll(RegExp(r'\s'), '');
      fingerprint = sha256Fingerprint(base64.decode(pem));
      secure.putFile('a.md', utf8.encode('over tls'));
    });

    tearDown(() => secure.close());

    test('the confirmed certificate is accepted in the worker', () async {
      final client = clientFor(secure.url, fingerprint: fingerprint);
      addTearDown(client.close);
      final transfers = IsolateSyncTransfers(client.config!);
      addTearDown(transfers.close);

      final download = await transfers.download('a.md', p.join(dir.path, 'o'));

      expect(download.bytes, 'over tls'.length);
    });

    test('any other certificate is refused, naming what it refused', () async {
      final client = clientFor(secure.url, fingerprint: 'AB' * 32);
      addTearDown(client.close);
      final transfers = IsolateSyncTransfers(client.config!);
      addTearDown(transfers.close);

      await expectLater(
        transfers.download('a.md', p.join(dir.path, 'o')),
        throwsA(
          isA<WebDavCertificateFailure>()
              .having((f) => f.host, 'host', '127.0.0.1')
              .having((f) => f.fingerprint, 'fingerprint', fingerprint),
        ),
      );
    });

    test('no fingerprint at all refuses the self-signed server', () async {
      final client = clientFor(secure.url);
      addTearDown(client.close);
      final transfers = IsolateSyncTransfers(client.config!);
      addTearDown(transfers.close);

      await expectLater(
        transfers.hashRemote('a.md'),
        throwsA(isA<WebDavCertificateFailure>()),
      );
    });
  });
}
