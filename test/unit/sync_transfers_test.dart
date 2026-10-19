import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/sync/transfers/inline_sync_transfers.dart';
import 'package:niman/src/sync/transfers/sync_transfers.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_webdav_server.dart';

/// How a transfer implementation is built over a client for the server.
typedef _Build = SyncTransfers Function(WebDavClient client);

void main() {
  group('inline transfers', () => _contract(InlineSyncTransfers.new));
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
