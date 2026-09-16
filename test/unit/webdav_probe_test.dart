import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

import '../fakes/fake_webdav_server.dart';

void main() {
  late FakeWebDavServer server;
  late WebDavClient client;
  final probedAt = DateTime(2026, 9, 15, 12);

  setUp(() async {
    server = await FakeWebDavServer.start();
    client = WebDavClient(url: server.url);
  });

  tearDown(() async {
    client.close();
    await server.close();
  });

  Future<WebDavCapabilities> probe() =>
      probeWebDav(client, now: () => probedAt);

  test('a full-featured server turns every optimization on and leaves no '
      'scratch folder behind', () async {
    server
      ..fileIds = true
      ..checksums = true
      ..ocMtime = true
      ..putFile('Notes/a.md', [1]);
    final caps = await probe();
    expect(caps.fileEtags, isTrue);
    expect(caps.collectionEtags, isTrue);
    expect(caps.ifMatch, isTrue);
    expect(caps.ifNoneMatch, isTrue);
    expect(caps.move, isTrue);
    expect(caps.fileIds, isTrue);
    expect(caps.checksums, isTrue);
    expect(caps.ocMtime, isTrue);
    expect(caps.davClasses, containsAll(['1', '2']));
    expect(caps.probedAt, probedAt);
    expect(server.paths, ['Notes', 'Notes/a.md']);
  });

  test('a bare share (no ETags, no preconditions, no MOVE) is usable in '
      'compatible mode', () async {
    server
      ..etags = false
      ..collectionEtags = false
      ..preconditions = false
      ..supportMove = false;
    final caps = await probe();
    expect(caps.fileEtags, isFalse);
    expect(caps.collectionEtags, isFalse);
    expect(caps.ifMatch, isFalse);
    expect(caps.ifNoneMatch, isFalse);
    expect(caps.move, isFalse);
    expect(caps.fileIds, isFalse);
    expect(caps.checksums, isFalse);
    expect(caps.ocMtime, isFalse);
    expect(server.paths, isEmpty);
  });

  test('file ETags without subtree-aware folder ETags', () async {
    server.collectionEtags = false;
    final caps = await probe();
    expect(caps.fileEtags, isTrue);
    expect(caps.collectionEtags, isFalse);
  });

  test('OPTIONS refused or without DAV falls back to PROPFIND', () async {
    server.optionsRefused = true;
    expect((await probe()).davClasses, isEmpty);
    server
      ..optionsRefused = false
      ..davHeader = false;
    expect((await probe()).fileEtags, isTrue);
  });

  test('a folder that is not WebDAV is WebDavUnsupported', () async {
    server
      ..davHeader = false
      ..propfindRefused = true;
    await expectLater(probe(), throwsA(isA<WebDavUnsupported>()));
  });

  test('a folder that does not exist is WebDavNotFound', () async {
    final missing = WebDavClient(url: server.origin.resolve('/web/'));
    addTearDown(missing.close);
    await expectLater(probeWebDav(missing), throwsA(isA<WebDavNotFound>()));
  });

  test('wrong credentials are WebDavAuthFailure', () async {
    server.credentials = (user: 'u', password: 'p');
    await expectLater(probe(), throwsA(isA<WebDavAuthFailure>()));
  });

  test('the scratch folder is deleted when the probe fails midway', () async {
    // OPTIONS, MKCOL, MKCOL, PUT go through; the PROPFIND after them fails.
    server.failNext(418, after: 4);
    await expectLater(probe(), throwsA(isA<WebDavProtocolFailure>()));
    expect(server.requests.last.method, 'DELETE');
    expect(server.paths, isEmpty);
  });

  test('capabilities round-trip through their stored JSON', () {
    final caps = WebDavCapabilities(
      probedAt: DateTime.fromMillisecondsSinceEpoch(1789000000000),
      davClasses: const {'2', '1'},
      fileEtags: true,
      ifMatch: true,
      move: true,
    );
    expect(WebDavCapabilities.decode(caps.encode()), caps);
    expect(WebDavCapabilities.decode(''), isNull);
    expect(WebDavCapabilities.decode('{}'), isNull);
    expect(WebDavCapabilities.decode('garbage'), isNull);
    expect(caps.isStale(caps.probedAt.add(const Duration(days: 29))), isFalse);
    expect(caps.isStale(caps.probedAt.add(const Duration(days: 31))), isTrue);
    expect(caps.describe(), contains('no collection etags'));
  });
}
