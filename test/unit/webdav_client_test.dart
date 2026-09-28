import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';

import '../fakes/fake_webdav_server.dart';

void main() {
  late FakeWebDavServer server;
  late WebDavClient client;

  setUp(() async {
    server = await FakeWebDavServer.start();
    client = WebDavClient(url: server.url);
  });

  tearDown(() async {
    client.close();
    await server.close();
  });

  Stream<List<int>> Function() bytesOf(String text) {
    final bytes = utf8.encode(text);
    return () => Stream.value(bytes);
  }

  Future<WebDavUpload> put(
    String path,
    String text, {
    String? ifMatch,
    bool ifNoneMatch = false,
  }) => client.upload(
    path,
    open: bytesOf(text),
    length: utf8.encode(text).length,
    ifMatch: ifMatch,
    ifNoneMatch: ifNoneMatch,
  );

  group('URLs', () {
    test('the base gains a trailing slash and paths are encoded per '
        'segment', () {
      final c = WebDavClient(url: Uri.parse('http://nas/webdav/Notes'));
      addTearDown(c.close);
      expect(c.baseUrl.toString(), 'http://nas/webdav/Notes/');
      expect(
        c.urlFor('Folder A/Nota è #1?.md').toString(),
        'http://nas/webdav/Notes/Folder%20A/Nota%20%C3%A8%20%231%3F.md',
      );
      expect(c.urlFor('Inbox', collection: true).path, '/webdav/Notes/Inbox/');
      expect(c.urlFor('').path, '/webdav/Notes/');
    });

    test('credentials in the URL, other schemes and dot segments are '
        'refused', () {
      expect(
        () => WebDavClient(url: Uri.parse('http://u:secret@nas/dav/')),
        throwsArgumentError,
      );
      expect(
        () => WebDavClient(url: Uri.parse('ftp://nas/dav/')),
        throwsArgumentError,
      );
      expect(() => client.urlFor('a/../b'), throwsArgumentError);
    });
  });

  group('verbs', () {
    test('OPTIONS reads the DAV classes and allowed methods', () async {
      final info = await client.options();
      expect(info.isWebDav, isTrue);
      expect(info.davClasses, containsAll(['1', '2']));
      expect(info.allows('MOVE'), isTrue);
      server.supportMove = false;
      expect((await client.options()).allows('MOVE'), isFalse);
    });

    test('PUT creates, replaces and returns the ETag', () async {
      final created = await put('a.md', 'one');
      expect(created.created, isTrue);
      expect(created.etag, isNotNull);
      final replaced = await put('a.md', 'two!');
      expect(replaced.created, isFalse);
      expect(replaced.etag, isNot(created.etag));
      expect(utf8.decode(server.file('a.md')!), 'two!');
    });

    test('PUT into a missing folder is WebDavNotFound', () async {
      await expectLater(put('No/a.md', 'x'), throwsA(isA<WebDavNotFound>()));
    });

    test('uploadFile streams a file from disk', () async {
      final dir = await Directory.systemTemp.createTemp('niman_webdav_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/big.bin');
      final bytes = List<int>.generate(300000, (i) => i % 251);
      await file.writeAsBytes(bytes);
      await client.uploadFile('big.bin', file);
      expect(server.file('big.bin'), bytes);
    });

    test('If-Match with a stale ETag and If-None-Match on an existing file '
        'are WebDavPrecondition and leave the file alone', () async {
      final first = await put('a.md', 'one');
      await put('a.md', 'two');
      await expectLater(
        put('a.md', 'three', ifMatch: first.etag),
        throwsA(isA<WebDavPrecondition>()),
      );
      await expectLater(
        put('a.md', 'three', ifNoneMatch: true),
        throwsA(isA<WebDavPrecondition>()),
      );
      expect(utf8.decode(server.file('a.md')!), 'two');
      final current = await client.stat('a.md');
      await put('a.md', 'three', ifMatch: current!.etag);
      expect(utf8.decode(server.file('a.md')!), 'three');
    });

    test('a weak ETag is never sent as If-Match', () async {
      server.weakEtags = true;
      await put('a.md', 'one');
      final listed = (await client.stat('a.md'))!;
      expect(listed.etag, startsWith('W/'));
      final before = server.requests.length;
      await put('a.md', 'two', ifMatch: listed.etag);
      final guarded = server.requests.skip(before).single;
      expect(guarded.method, 'PUT');
      expect(
        guarded.headers['if-match'],
        isNull,
        reason:
            'strong comparison could never match a weak validator, so '
            'the guard is dropped',
      );
      expect(utf8.decode(server.file('a.md')!), 'two');
    });

    test('PROPFIND lists children with decoded paths and properties', () async {
      server
        ..putFile('Folder A/Nota è.md', utf8.encode('hello'))
        ..putFile('Folder A/Sub/x.md', utf8.encode('x'));
      final items = await client.list('Folder A');
      expect(
        items.map((i) => i.path),
        unorderedEquals(['Folder A/Nota è.md', 'Folder A/Sub']),
      );
      final note = items.firstWhere((i) => !i.isCollection);
      expect(note.size, 5);
      expect(note.etag, isNotNull);
      expect(note.modified, isNotNull);
      expect(items.firstWhere((i) => i.isCollection).name, 'Sub');
    });

    test('PROPFIND copes with other prefixes and absolute hrefs', () async {
      server
        ..prefix = ''
        ..absoluteHrefs = true
        ..putFile('a b/c.md', utf8.encode('c'));
      expect((await client.list('a b')).single.path, 'a b/c.md');
      server.prefix = 'lp1';
      expect((await client.list('')).single.path, 'a b');
    });

    test('stat returns null for a missing item', () async {
      expect(await client.stat('nope.md'), isNull);
      server.putFile('yes.md', [1]);
      expect((await client.stat('yes.md'))!.size, 1);
    });

    test('stat returns null for a missing item a server answers with a '
        '207 holding a 404 (#163)', () async {
      server.missingAsMultistatus = true;
      expect(await client.stat('nope.md'), isNull);
      expect(await client.stat('Folder', collection: true), isNull);
    });

    test(
      'GET streams into a sink with the sha256 computed on the way',
      () async {
        final bytes = List<int>.generate(100000, (i) => (i * 7) % 256);
        server.putFile('Inbox/blob.bin', bytes);
        final dir = await Directory.systemTemp.createTemp('niman_webdav_');
        addTearDown(() => dir.delete(recursive: true));
        final target = File('${dir.path}/blob.tmp');
        final result = await client.download(
          'Inbox/blob.bin',
          target.openWrite(),
        );
        expect(result.bytes, bytes.length);
        expect(result.sha256, sha256.convert(bytes).toString());
        expect(result.etag, isNotNull);
        expect(result.modified, isNotNull);
        expect(await target.readAsBytes(), bytes);
      },
    );

    test(
      'GET of a missing file is WebDavNotFound and closes the sink',
      () async {
        final dir = await Directory.systemTemp.createTemp('niman_webdav_');
        final target = File('${dir.path}/x.tmp');
        await expectLater(
          client.download('missing.md', target.openWrite()),
          throwsA(isA<WebDavNotFound>()),
        );
        // The sink is closed: the temp folder can be deleted on Windows too.
        await dir.delete(recursive: true);
      },
    );

    test('a connection dropped mid-body is WebDavRetryable', () async {
      server
        ..putFile('a.bin', List<int>.filled(50000, 1))
        ..dropNextGet();
      await expectLater(
        client.readBytes('a.bin'),
        throwsA(isA<WebDavRetryable>()),
      );
      expect(await client.readBytes('a.bin'), hasLength(50000));
    });

    test('a body that never arrives is WebDavRetryable within twice the '
        'timeout (#348)', () async {
      const timeout = Duration(milliseconds: 600);
      server
        ..putFile('a.bin', List<int>.filled(50000, 1))
        ..stallNextGet();
      final stalled = WebDavClient(url: server.url, timeout: timeout);
      addTearDown(stalled.close);
      // The wait is bounded here too: on a client that never times the
      // body out this fails as a test instead of hanging the suite.
      final clock = Stopwatch()..start();
      await expectLater(
        stalled.readBytes('a.bin').timeout(const Duration(seconds: 10)),
        throwsA(
          isA<WebDavRetryable>().having(
            (failure) => failure.message,
            'message',
            contains('body stalled'),
          ),
        ),
        reason: 'headers and no body must fail, not wait for the session',
      );
      expect(
        clock.elapsed,
        lessThan(timeout * 2),
        reason: 'the body must give up on the client timeout',
      );
      expect(await stalled.readBytes('a.bin'), hasLength(50000));
    });

    // The timeout bounds a silence, not the transfer: a body that keeps
    // arriving on a slow link is not cut off because the whole of it takes
    // longer than the timeout, or a large file would never sync.
    test('a body that keeps arriving outlives the timeout', () async {
      const timeout = Duration(milliseconds: 600);
      final bytes = List<int>.generate(60000, (i) => i % 251);
      server
        ..putFile('a.bin', bytes)
        ..trickleNextGet = const Duration(milliseconds: 250);
      final slow = WebDavClient(url: server.url, timeout: timeout);
      addTearDown(slow.close);
      final clock = Stopwatch()..start();
      expect(await slow.readBytes('a.bin'), bytes);
      expect(
        clock.elapsed,
        greaterThan(timeout),
        reason: 'the transfer as a whole outlasted the timeout',
      );
    });

    test('an upload that keeps moving outlives the timeout; one that '
        'stops fails as WebDavRetryable', () async {
      const timeout = Duration(milliseconds: 600);
      final client = WebDavClient(url: server.url, timeout: timeout);
      addTearDown(client.close);
      Stream<List<int>> pieces({required bool stops}) async* {
        for (var i = 0; i < 6; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          yield List<int>.filled(1000, i);
          if (stops && i == 1) await Completer<void>().future;
        }
      }

      final clock = Stopwatch()..start();
      await client.upload(
        'slow.bin',
        open: () => pieces(stops: false),
        length: 6000,
      );
      expect(clock.elapsed, greaterThan(timeout));
      expect(server.file('slow.bin'), hasLength(6000));

      await expectLater(
        client
            .upload('stuck.bin', open: () => pieces(stops: true), length: 6000)
            .timeout(const Duration(seconds: 10)),
        throwsA(
          isA<WebDavRetryable>().having(
            (failure) => failure.message,
            'message',
            contains('sending the body stalled'),
          ),
        ),
      );
      expect(server.exists('stuck.bin'), isFalse);
    });

    test(
      'MKCOL creates, reports existing folders and missing parents',
      () async {
        expect(await client.createFolder('A'), isTrue);
        expect(await client.createFolder('A'), isFalse);
        await expectLater(
          client.createFolder('X/Y'),
          throwsA(isA<WebDavNotFound>()),
        );
        await client.createFolders('B/C/D');
        expect(server.isFolder('B/C/D'), isTrue);
        final before = server.requests.length;
        await client.createFolders('B/C/E');
        expect(server.requests.length - before, 1, reason: 'parents exist');
      },
    );

    test('DELETE removes files and folders; a missing item is false', () async {
      server
        ..putFile('A/a.md', [1])
        ..putFile('b.md', [2]);
      expect(await client.delete('b.md'), isTrue);
      expect(await client.delete('A', collection: true), isTrue);
      expect(server.paths, isEmpty);
      expect(await client.delete('b.md'), isFalse);
    });

    test('MOVE renames; an existing target without overwrite is a '
        'precondition failure; no MOVE support is WebDavUnsupported', () async {
      server
        ..putFile('a.md', [1])
        ..putFile('Sub/b.md', [2]);
      await client.move('a.md', 'Sub/a 2.md');
      expect(server.exists('a.md'), isFalse);
      expect(server.file('Sub/a 2.md'), [1]);
      await expectLater(
        client.move('Sub/a 2.md', 'Sub/b.md'),
        throwsA(isA<WebDavPrecondition>()),
      );
      await client.move('Sub/a 2.md', 'Sub/b.md', overwrite: true);
      expect(server.file('Sub/b.md'), [1]);
      server.supportMove = false;
      await expectLater(
        client.move('Sub/b.md', 'c.md'),
        throwsA(isA<WebDavUnsupported>()),
      );
    });
  });

  group('auth', () {
    test(
      'Basic auth is sent; wrong credentials are WebDavAuthFailure',
      () async {
        server.credentials = (user: 'ale', password: 's3cret-pw');
        await expectLater(client.options(), throwsA(isA<WebDavAuthFailure>()));
        final wrong = WebDavClient(
          url: server.url,
          username: 'ale',
          password: 'nope',
        );
        addTearDown(wrong.close);
        await expectLater(wrong.options(), throwsA(isA<WebDavAuthFailure>()));
        final right = WebDavClient(
          url: server.url,
          username: 'ale',
          password: 's3cret-pw',
        );
        addTearDown(right.close);
        expect((await right.options()).isWebDav, isTrue);
      },
    );

    test('logs never carry the password or the Authorization header', () async {
      AppLog.clear();
      server.credentials = (user: 'ale', password: 's3cret-pw');
      final right = WebDavClient(
        url: server.url,
        username: 'ale',
        password: 's3cret-pw',
      );
      addTearDown(right.close);
      await right.upload('a.md', open: bytesOf('x'), length: 1);
      await right.readBytes('a.md');
      await expectLater(right.readBytes('b.md'), throwsA(anything));
      final log = AppLog.dump();
      expect(log, contains('[webdav] PUT a.md -> 201'));
      expect(log, isNot(contains('s3cret-pw')));
      expect(log, isNot(contains('Basic')));
      expect(log, isNot(contains(base64.encode(utf8.encode('ale:s3cret-pw')))));
    });
  });

  group('redirects', () {
    test('a 308 keeps the method, the body and the credentials on the same '
        'origin', () async {
      server
        ..credentials = (user: 'u', password: 'p')
        ..redirects['/old/'] = (status: 308, target: server.url);
      final moved = WebDavClient(
        url: server.origin.resolve('/old/'),
        username: 'u',
        password: 'p',
      );
      addTearDown(moved.close);
      await moved.upload('a.md', open: bytesOf('body'), length: 4);
      expect(utf8.decode(server.file('a.md')!), 'body');
      final methods = server.requests.map((r) => '$r').toList();
      expect(methods, ['PUT /old/a.md', 'PUT /dav/a.md']);
    });

    test('credentials are not sent to another origin', () async {
      final other = await FakeWebDavServer.start();
      addTearDown(other.close);
      server.redirects['/dav/'] = (status: 307, target: other.url);
      final c = WebDavClient(url: server.url, username: 'u', password: 'p');
      addTearDown(c.close);
      await c.options();
      expect(server.requests.single.headers['authorization'], isNotNull);
      expect(other.requests.single.headers['authorization'], isNull);
    });

    test('a same-host http -> https upgrade keeps the credentials', () async {
      // The fake speaks plain http; the point here is the client's origin
      // rule, so `_PlainHttp` carries the https hop to it unchanged.
      server
        ..credentials = (user: 'u', password: 'p')
        ..redirects['/old/'] = (
          status: 308,
          target: server.origin.replace(scheme: 'https').resolve('/dav/'),
        );
      final http = HttpClient();
      addTearDown(() => http.close(force: true));
      final moved = WebDavClient(
        url: server.origin.resolve('/old/'),
        username: 'u',
        password: 'p',
        httpClient: _PlainHttp(http),
      );
      addTearDown(moved.close);
      await moved.upload('a.md', open: bytesOf('body'), length: 4);
      expect(utf8.decode(server.file('a.md')!), 'body');
      expect(server.requests.map((r) => '$r').toList(), [
        'PUT /old/a.md',
        'PUT /dav/a.md',
      ]);
      expect(
        server.requests.last.headers['authorization'],
        isNotNull,
        reason:
            'a scheme upgrade on the same host and port is the same '
            'origin',
      );
    });

    test('a redirect loop stops after five hops', () async {
      server.redirects['/dav/'] = (status: 302, target: server.url);
      await expectLater(
        client.options(),
        throwsA(isA<WebDavProtocolFailure>()),
      );
      expect(server.requests, hasLength(6));
    });
  });

  group('failures', () {
    test('busy and locked servers are retryable with Retry-After', () async {
      server.failNext(503, retryAfter: '7');
      await expectLater(
        client.options(),
        throwsA(
          isA<WebDavRetryable>()
              .having((f) => f.status, 'status', 503)
              .having(
                (f) => f.retryAfter,
                'retryAfter',
                const Duration(seconds: 7),
              ),
        ),
      );
      server.failNext(423);
      await expectLater(client.options(), throwsA(isA<WebDavRetryable>()));
      server.failNext(418);
      await expectLater(
        client.options(),
        throwsA(isA<WebDavProtocolFailure>()),
      );
      expect((await client.options()).isWebDav, isTrue);
    });

    test('a server that is not there is WebDavRetryable', () async {
      final url = server.url;
      await server.close();
      final gone = WebDavClient(url: url, timeout: const Duration(seconds: 5));
      addTearDown(gone.close);
      await expectLater(gone.options(), throwsA(isA<WebDavRetryable>()));
      server = await FakeWebDavServer.start(); // for tearDown
    });

    test(
      'a refused certificate is its own failure naming the host (#366)',
      () async {
        final refused = WebDavClient(
          url: Uri.parse('https://nas.example:8443/dav/'),
          httpClient: _TlsRefusingHttp(
            const HandshakeException(
              'Handshake error in client (OS Error: '
              'CERTIFICATE_VERIFY_FAILED: self signed certificate)',
            ),
          ),
        );
        addTearDown(refused.close);
        await expectLater(
          refused.options(),
          throwsA(
            isA<WebDavCertificateFailure>()
                .having((f) => f.host, 'host', 'nas.example')
                .having((f) => f.message, 'message', contains('nas.example'))
                .having((f) => f.message, 'message', contains('not trusted'))
                .having((f) => f.message, 'message', contains('8443'))
                .having((f) => f.fingerprint, 'fingerprint', isNull),
          ),
        );
      },
    );

    test('a certificate failure carries the fingerprint the error exposes '
        '(#366)', () async {
      const fingerprint =
          'AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23:45:67:89:'
          'AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23:45:67:89';
      final refused = WebDavClient(
        url: Uri.parse('https://nas.example/dav/'),
        httpClient: _TlsRefusingHttp(
          const HandshakeException(
            'CERTIFICATE_VERIFY_FAILED: self signed certificate, '
            'SHA256:$fingerprint',
          ),
        ),
      );
      addTearDown(refused.close);
      await expectLater(
        refused.options(),
        throwsA(
          isA<WebDavCertificateFailure>()
              .having((f) => f.fingerprint, 'fingerprint', fingerprint)
              .having((f) => f.message, 'message', contains(fingerprint)),
        ),
      );
    });

    test('a TLS failure that is not the certificate stays a protocol '
        'failure (#366)', () async {
      final other = WebDavClient(
        url: Uri.parse('https://nas.example/dav/'),
        httpClient: _TlsRefusingHttp(
          const TlsException('TLS protocol version not supported'),
        ),
      );
      addTearDown(other.close);
      await expectLater(other.options(), throwsA(isA<WebDavProtocolFailure>()));
    });
  });

  // #454: a self-signed destination can be trusted once, by fingerprint.
  // The client is given exactly one fingerprint and accepts exactly that
  // certificate — never another, and never by a switch.
  group('trusted certificate', () {
    late FakeWebDavServer secure;
    late String fingerprint;

    /// A security context presenting the checked-in self-signed pair.
    SecurityContext context() => SecurityContext()
      ..useCertificateChainBytes(
        File('test/fakes/self_signed_cert.pem').readAsBytesSync(),
      )
      ..usePrivateKeyBytes(
        File('test/fakes/self_signed_key.pem').readAsBytesSync(),
      );

    /// The certificate's own Sha-256 fingerprint, from its PEM: the value
    /// the user confirms and the destination stores.
    String fingerprintOfPem(String path) {
      // The armor, and the line breaks the armor is written with: base64
      // takes neither.
      final body = File(path)
          .readAsStringSync()
          .replaceAll(RegExp('-----[^-]+-----'), '')
          .replaceAll(RegExp(r'\s'), '');
      return sha256Fingerprint(base64.decode(body));
    }

    setUp(() async {
      secure = await FakeWebDavServer.startSecure(context());
      fingerprint = fingerprintOfPem('test/fakes/self_signed_cert.pem');
    });

    tearDown(() => secure.close());

    test('the confirmed fingerprint is accepted', () async {
      final trusted = WebDavClient(
        url: secure.url,
        trustedCertificateFingerprint: fingerprint,
      );
      addTearDown(trusted.close);
      expect((await trusted.options()).isWebDav, isTrue);
      expect(secure.requests, isNotEmpty);
    });

    test('a certificate the fingerprint does not match is still refused '
        '(#366)', () async {
      final other = WebDavClient(
        url: secure.url,
        trustedCertificateFingerprint: 'AB' * 32,
      );
      addTearDown(other.close);
      await expectLater(
        other.options(),
        throwsA(
          isA<WebDavCertificateFailure>()
              .having((f) => f.host, 'host', '127.0.0.1')
              .having((f) => f.fingerprint, 'fingerprint', fingerprint)
              .having((f) => f.message, 'message', contains('not trusted')),
        ),
      );
    });

    test('with no fingerprint at all the self-signed server is refused '
        '(#366)', () async {
      final refused = WebDavClient(url: secure.url);
      addTearDown(refused.close);
      await expectLater(
        refused.options(),
        throwsA(
          isA<WebDavCertificateFailure>().having(
            (f) => f.fingerprint,
            'fingerprint',
            fingerprint,
          ),
        ),
      );
    });

    test(
      'a fingerprint written without the separators still matches',
      () async {
        final compact = WebDavClient(
          url: secure.url,
          trustedCertificateFingerprint: fingerprint.replaceAll(':', ''),
        );
        addTearDown(compact.close);
        expect((await compact.options()).isWebDav, isTrue);
      },
    );
  });
}

/// An [HttpClient] that reaches the loopback fake over plain http even when
/// the URL says `https`: the fake has no certificate, and the redirect test
/// is about the client's credential rule, not TLS. Every other member the
/// client does not use is left unimplemented.
final class _PlainHttp implements HttpClient {
  new(this._inner);

  final HttpClient _inner;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _inner.openUrl(method, url.replace(scheme: 'http'));

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? value,
  ) => _inner.badCertificateCallback = value;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// An [HttpClient] that fails every request with a TLS [IOException], standing
/// in for a handshake the device stopped. The fake server speaks plain http,
/// so a certificate can only be raised through the client's own error mapping
/// — which is what these tests are about. Every other member the client does
/// not use is left unimplemented.
final class _TlsRefusingHttp implements HttpClient {
  new(this._error);

  final IOException _error;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      throw _error;

  @override
  void close({bool force = false}) {}

  @override
  set connectionTimeout(Duration? value) {}

  @override
  set idleTimeout(Duration value) {}

  @override
  set autoUncompress(bool value) {}

  @override
  set userAgent(String? value) {}

  // The client installs its callback on every `HttpClient`, including this
  // fake; the failure it raises never reaches one, so it is dropped.
  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? value,
  ) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
