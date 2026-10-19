import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
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
