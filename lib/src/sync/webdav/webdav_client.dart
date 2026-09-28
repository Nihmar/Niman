import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';

/// What `OPTIONS` said about the destination folder.
@immutable
final class WebDavServerInfo {
  /// Describes a server advertising [davClasses] and [allowedMethods].
  const new({required this.davClasses, required this.allowedMethods});

  /// The `DAV:` header's compliance classes, lowercased (`1`, `2`, `3`,
  /// `access-control`, …); empty when the header is missing.
  final Set<String> davClasses;

  /// The `Allow:` header's methods, uppercased; empty when missing.
  final Set<String> allowedMethods;

  /// Whether the server claims WebDAV class 1.
  bool get isWebDav => davClasses.contains('1');

  /// Whether [method] is allowed — assumed when the server lists nothing.
  bool allows(String method) =>
      allowedMethods.isEmpty || allowedMethods.contains(method.toUpperCase());
}

/// What a finished `GET` delivered.
@immutable
final class WebDavDownload {
  /// A download of [bytes] bytes hashing to [sha256].
  const new({
    required this.bytes,
    required this.sha256,
    this.etag,
    this.modified,
  });

  /// Bytes received (and checked against `Content-Length` when sent).
  final int bytes;

  /// Lowercase hex sha256 of those bytes, computed while streaming.
  final String sha256;

  /// The response's `ETag`, or null.
  final String? etag;

  /// The response's `Last-Modified` (UTC), or null.
  final DateTime? modified;
}

/// What a finished `PUT` reported.
@immutable
final class WebDavUpload {
  /// An upload that [created] the item (or replaced it).
  const new({required this.created, this.etag, this.mtimeAccepted = false});

  /// 201: the item did not exist before.
  final bool created;

  /// The new `ETag` (or `OC-ETag`) when the server returned one; many
  /// servers do not, and the caller PROPFINDs instead.
  final String? etag;

  /// Whether the server kept the `X-OC-Mtime` sent with the upload.
  final bool mtimeAccepted;
}

/// A WebDAV client for one destination folder (docs/records/sync.md, "The
/// client").
///
/// Every path is relative to [baseUrl], `/`-separated, unencoded; `''` is
/// the folder itself. One call is one attempt (redirects aside): failures
/// come back as [WebDavFailure]s, and the caller decides about retries.
/// Plain `dart:io`, no Flutter, so it runs in any isolate.
final class WebDavClient {
  /// A client for the folder at [url] (`http` or `https`).
  ///
  /// [username] empty means no authentication; otherwise Basic auth is
  /// sent with every request. Credentials in the URL itself are refused,
  /// so they can never reach a log line through it. [httpClient] is for
  /// tests; the client closes only the one it created.
  ///
  /// [trustedCertificateFingerprint] is the SHA-256 fingerprint of the one
  /// server certificate this destination may present when the device
  /// cannot verify it (#454): the certificate the user confirmed. It is
  /// the only thing accepted — every other certificate is refused, as it
  /// is with no fingerprint at all — and it is per client, so nothing is
  /// trusted app-wide. Null trusts nothing beyond the device's own
  /// certificate store.
  new({
    required Uri url,
    String username = '',
    String password = '',
    String? trustedCertificateFingerprint,
    HttpClient? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : baseUrl = _normalizeBase(url),
       _authorization = username.isEmpty
           ? null
           : 'Basic ${base64.encode(utf8.encode('$username:$password'))}',
       _trustedFingerprint = _fingerprintKey(trustedCertificateFingerprint),
       _ownsHttp = httpClient == null,
       _http = httpClient ?? HttpClient() {
    _http
      ..connectionTimeout = timeout
      ..idleTimeout = const Duration(seconds: 15)
      ..autoUncompress = false
      ..userAgent = 'Niman';
    // The device refused the server's certificate: the user may have
    // confirmed this exact one for this destination (#454). Accepting
    // anything else — any other certificate, whatever host — is not what
    // this does: the callback answers true only for the confirmed
    // fingerprint, for the destination's own host, and false for
    // everything else, which leaves the failure #366 already described.
    _http.badCertificateCallback = _onBadCertificate;
    _baseSegments = [
      for (final segment in baseUrl.pathSegments)
        if (segment.isNotEmpty) segment,
    ];
  }

  /// The destination folder, always ending with `/`, with no query,
  /// fragment or user info.
  final Uri baseUrl;

  /// How long to wait for a connection, for a response to start, and for
  /// a body to arrive.
  ///
  /// The last one is what stops a server that sent its headers and then
  /// went quiet from holding a sync run open for the rest of the session
  /// (#348).
  final Duration timeout;

  final String? _authorization;
  final bool _ownsHttp;
  final HttpClient _http;

  /// The only certificate fingerprint this client accepts when the device
  /// cannot verify it (hex digits only, uppercased), or null when it
  /// accepts none (#454).
  final String? _trustedFingerprint;

  /// The fingerprint of the last certificate the callback refused, so the
  /// failure can name what it refused even where the exception does not.
  String? _refusedFingerprint;

  late final List<String> _baseSegments;
  DateTime? _serverDate;

  /// The server's clock (`Date` header, UTC) on the latest response, or
  /// null before one carried it. The sync compares remote mtimes with it,
  /// never with this device's clock, which can be minutes off.
  DateTime? get serverDate => _serverDate;

  static const _maxRedirects = 5;
  static const _log = AppLogger(name: 'webdav');

  static Uri _normalizeBase(Uri url) {
    if (url.scheme != 'http' && url.scheme != 'https') {
      throw ArgumentError.value(
        url.scheme,
        'url',
        'WebDAV needs an http or https URL',
      );
    }
    if (url.userInfo.isNotEmpty) {
      throw ArgumentError(
        'Credentials belong in username/password, not in the URL',
      );
    }
    if (url.host.isEmpty) {
      throw ArgumentError('The URL has no host');
    }
    final path = url.path.endsWith('/') ? url.path : '${url.path}/';
    return Uri(
      scheme: url.scheme,
      host: url.host,
      port: url.hasPort ? url.port : null,
      path: path,
    );
  }

  /// Whether the device may proceed with a certificate it could not verify:
  /// true only for the one fingerprint the user confirmed for this
  /// destination, presented by the destination's own host, and false for
  /// everything else (#454), which leaves the failure [WebDavFailure] #366
  /// already described. Called by `dart:io` only when verification failed.
  bool _onBadCertificate(X509Certificate certificate, String host, int port) {
    final fingerprint = sha256Fingerprint(certificate.der);
    final trusted = _trustedFingerprint;
    if (trusted != null &&
        host.toLowerCase() == baseUrl.host.toLowerCase() &&
        _fingerprintKey(fingerprint) == trusted) {
      return true;
    }
    _refusedFingerprint = fingerprint;
    return false;
  }

  /// The absolute URL of [path]; [collection] adds the trailing slash
  /// folders need on most servers.
  Uri urlFor(String path, {bool collection = false}) {
    final segments = [..._baseSegments];
    for (final segment in path.split('/')) {
      if (segment.isEmpty) continue;
      if (segment == '.' || segment == '..') {
        throw ArgumentError.value(path, 'path', 'no . or .. segments');
      }
      segments.add(segment);
    }
    final folder = collection || segments.length == _baseSegments.length;
    return baseUrl.replace(pathSegments: [...segments, if (folder) '']);
  }

  /// Closes the connections (only those of a client this one created).
  void close() {
    if (_ownsHttp) _http.close(force: true);
  }

  /// `OPTIONS` on the destination folder.
  Future<WebDavServerInfo> options() async {
    final clock = Stopwatch()..start();
    final response = await _send('OPTIONS', '', collection: true);
    if (response.statusCode >= 300) {
      throw await _fail('OPTIONS', '', response, clock);
    }
    await response.drain<void>();
    final dav = {
      for (final token in _headerTokens(response, 'dav')) token.toLowerCase(),
    };
    final allow = _headerTokens(response, 'allow');
    _done(
      'OPTIONS',
      '',
      response.statusCode,
      clock,
      extra: ', DAV ${dav.isEmpty ? 'none' : dav.join(' ')}',
    );
    return WebDavServerInfo(
      davClasses: dav,
      allowedMethods: {for (final m in allow) m.toUpperCase()},
    );
  }

  /// `PROPFIND` on [path] with `Depth: 0` or `1`: the item itself first
  /// when the server lists it (all do), then its children.
  Future<List<WebDavResource>> propfind(
    String path, {
    required int depth,
    bool collection = false,
  }) async {
    if (depth != 0 && depth != 1) {
      throw ArgumentError.value(depth, 'depth', 'must be 0 or 1');
    }
    final clock = Stopwatch()..start();
    final body = utf8.encode(propfindBody);
    final response = await _send(
      'PROPFIND',
      path,
      collection: collection,
      headers: {
        'Depth': '$depth',
        HttpHeaders.contentTypeHeader: 'application/xml; charset=utf-8',
      },
      body: () => Stream.value(body),
      length: body.length,
      compressed: true,
    );
    if (response.statusCode != 207) {
      throw await _fail('PROPFIND', path, response, clock);
    }
    final String text;
    try {
      final encoding = response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      final raw = encoding == 'gzip' ? gzip.decoder.bind(response) : response;
      text = await const Utf8Decoder(allowMalformed: true).bind(raw).join();
    } on IOException catch (e) {
      throw _transportFailure('PROPFIND', path, e);
    } on FormatException catch (e) {
      throw WebDavProtocolFailure('PROPFIND ${_show(path)}: ${e.message}');
    }
    final resources = parseMultistatus(
      text,
      baseUrl,
      onSkipped: (href) => _log.warning(
        'PROPFIND ${_show(path)}: skipped an item outside the destination '
        '($href)',
      ),
    );
    _done(
      'PROPFIND',
      path,
      207,
      clock,
      extra: ', depth $depth, ${resources.length} items, ${text.length} chars',
    );
    return resources;
  }

  /// The children of [folder] (`PROPFIND Depth: 1`, the folder itself
  /// left out).
  Future<List<WebDavResource>> list(String folder) async {
    final self = _clean(folder);
    final items = await propfind(folder, depth: 1, collection: true);
    return [
      for (final item in items)
        if (item.path != self) item,
    ];
  }

  /// The item at [path] (`PROPFIND Depth: 0`), or null when it does not
  /// exist.
  ///
  /// A server may spell the href its own way (another percent-encoding,
  /// a trailing slash), so a lone item that is not the path asked for
  /// still counts — but only when it is the kind asked for. A folder
  /// answering for a file is the server describing the parent of a file
  /// that is not there, not the file (#163).
  Future<WebDavResource?> stat(String path, {bool collection = false}) async {
    try {
      final items = await propfind(path, depth: 0, collection: collection);
      final self = _clean(path);
      final exact = items.where((item) => item.path == self).firstOrNull;
      if (exact != null) return exact;
      final only = items.length == 1 ? items.single : null;
      return only != null && only.isCollection == collection ? only : null;
    } on WebDavNotFound {
      return null;
    }
  }

  /// `GET` [path] streamed into [into], which is closed at the end (also
  /// on failure). The sha256 is computed on the way; a body shorter or
  /// longer than its `Content-Length` fails as [WebDavRetryable], and so
  /// does one that stops arriving for [timeout].
  Future<WebDavDownload> download(
    String path,
    StreamConsumer<List<int>> into,
  ) async {
    final clock = Stopwatch()..start();
    final HttpClientResponse response;
    try {
      response = await _send('GET', path);
    } on Object {
      await _closeQuietly(into);
      rethrow;
    }
    if (response.statusCode != 200) {
      await _closeQuietly(into);
      throw await _fail('GET', path, response, clock);
    }
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    var bytes = 0;
    try {
      await response
          .map((chunk) {
            hasher.add(chunk);
            bytes += chunk.length;
            return chunk;
          })
          .pipe(into)
          .timeout(timeout);
    } on TimeoutException {
      // Headers and no body: dropping the connection is what makes the
      // server stop, and the failure is the retryable kind the caller
      // already backs off on (#348).
      await _dropQuietly(response);
      await _closeQuietly(into);
      throw _timedOut('GET', path, 'the body stalled');
    } on IOException catch (e) {
      await _closeQuietly(into);
      throw _transportFailure('GET', path, e);
    }
    hasher.close();
    final expected = response.contentLength;
    if (expected >= 0 && bytes != expected) {
      _log.warning(
        'GET ${_show(path)}: received $bytes of $expected bytes, '
        '${clock.elapsedMilliseconds} ms',
      );
      throw WebDavRetryable(
        'GET ${_show(path)}: received $bytes of $expected bytes',
        status: 200,
      );
    }
    final etag = response.headers.value(HttpHeaders.etagHeader);
    final modified = _httpDate(
      response.headers.value(HttpHeaders.lastModifiedHeader),
    );
    final sha = digest.value.toString();
    _done(
      'GET',
      path,
      200,
      clock,
      etag: etag,
      bytes: bytes,
      extra: ', sha ${sha.substring(0, 8)}',
    );
    return WebDavDownload(
      bytes: bytes,
      sha256: sha,
      etag: etag,
      modified: modified,
    );
  }

  /// The whole body of [path] in memory. For small things only (the
  /// probe, tests): transfers use [download].
  Future<Uint8List> readBytes(String path) async {
    final sink = _BytesConsumer();
    await download(path, sink);
    return sink.builder.takeBytes();
  }

  /// `PUT` [length] bytes from [open] to [path].
  ///
  /// [open] is called once per attempt at sending the body (a 307/308
  /// redirect sends it again), so it must return a fresh stream each
  /// time. [ifMatch] sends `If-Match` (a changed remote fails as
  /// [WebDavPrecondition]); [ifNoneMatch] sends `If-None-Match: *` (an
  /// existing remote fails the same way). [modified] goes out as
  /// `X-OC-Mtime`, which servers that do not know it ignore.
  Future<WebDavUpload> upload(
    String path, {
    required Stream<List<int>> Function() open,
    required int length,
    String? ifMatch,
    bool ifNoneMatch = false,
    DateTime? modified,
  }) async {
    final clock = Stopwatch()..start();
    // A weak ETag cannot guard anything (a caller that plans with
    // [WebDavResource.guardEtag] never hands one over); dropped rather than
    // sent, it would fail every write with 412.
    final guard = ifMatchGuard(ifMatch);
    final response = await _send(
      'PUT',
      path,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/octet-stream',
        'If-Match': ?guard,
        if (ifNoneMatch) 'If-None-Match': '*',
        if (modified != null)
          'X-OC-Mtime': '${modified.millisecondsSinceEpoch ~/ 1000}',
      },
      body: open,
      length: length,
    );
    final status = response.statusCode;
    if (status != 200 && status != 201 && status != 204) {
      throw await _fail('PUT', path, response, clock);
    }
    await response.drain<void>();
    final etag =
        response.headers.value(HttpHeaders.etagHeader) ??
        response.headers.value('oc-etag');
    final mtimeAccepted =
        response.headers.value('x-oc-mtime')?.toLowerCase() == 'accepted';
    _done(
      'PUT',
      path,
      status,
      clock,
      etag: etag,
      bytes: length,
      extra:
          '${guard == null ? '' : ', if-match'}'
          '${ifNoneMatch ? ', if-none-match' : ''}'
          '${mtimeAccepted ? ', mtime kept' : ''}',
    );
    return WebDavUpload(
      created: status == 201,
      etag: etag,
      mtimeAccepted: mtimeAccepted,
    );
  }

  /// [upload] with the contents of [file], streamed.
  Future<WebDavUpload> uploadFile(
    String path,
    File file, {
    String? ifMatch,
    bool ifNoneMatch = false,
    DateTime? modified,
  }) async {
    final length = await file.length();
    return await upload(
      path,
      open: file.openRead,
      length: length,
      ifMatch: ifMatch,
      ifNoneMatch: ifNoneMatch,
      modified: modified,
    );
  }

  /// `MKCOL` [folder]: true when it was created, false when it already
  /// existed (405). A missing parent fails as [WebDavNotFound].
  Future<bool> createFolder(String folder) async {
    final clock = Stopwatch()..start();
    final response = await _send('MKCOL', folder, collection: true);
    final status = response.statusCode;
    if (status == 405) {
      await response.drain<void>();
      _done('MKCOL', folder, status, clock, extra: ', already there');
      return false;
    }
    if (status != 201 && status != 200 && status != 204) {
      throw await _fail('MKCOL', folder, response, clock);
    }
    await response.drain<void>();
    _done('MKCOL', folder, status, clock);
    return true;
  }

  /// Creates [folder] and whatever parents it lacks: tries the folder
  /// first and walks up only on a missing parent, so the common case
  /// (parents exist) is one request.
  Future<void> createFolders(String folder) async {
    final clean = _clean(folder);
    if (clean.isEmpty) return;
    try {
      await createFolder(clean);
    } on WebDavNotFound {
      final slash = clean.lastIndexOf('/');
      if (slash < 0) rethrow; // the destination folder itself is gone
      await createFolders(clean.substring(0, slash));
      await createFolder(clean);
    }
  }

  /// `DELETE` [path] (a folder with [collection], recursively): true
  /// when something was deleted, false when nothing was there.
  ///
  /// [ifMatch] sends `If-Match`: a remote changed since fails as
  /// [WebDavPrecondition] and stays.
  Future<bool> delete(
    String path, {
    bool collection = false,
    String? ifMatch,
  }) async {
    final clock = Stopwatch()..start();
    final guard = ifMatchGuard(ifMatch);
    final response = await _send(
      'DELETE',
      path,
      collection: collection,
      headers: {'If-Match': ?guard},
    );
    final status = response.statusCode;
    if (status == 404) {
      await response.drain<void>();
      _done('DELETE', path, status, clock, extra: ', already gone');
      return false;
    }
    // 207 means part of a folder could not be deleted.
    if (status != 200 && status != 202 && status != 204) {
      throw await _fail('DELETE', path, response, clock);
    }
    await response.drain<void>();
    _done('DELETE', path, status, clock);
    return true;
  }

  /// `MOVE` [from] to [to]. Without [overwrite] an existing target fails
  /// as [WebDavPrecondition]; a server without `MOVE` fails as
  /// [WebDavUnsupported].
  Future<void> move(
    String from,
    String to, {
    bool overwrite = false,
    bool collection = false,
  }) async {
    final clock = Stopwatch()..start();
    final response = await _send(
      'MOVE',
      from,
      collection: collection,
      headers: {
        'Destination': urlFor(to, collection: collection).toString(),
        'Overwrite': overwrite ? 'T' : 'F',
      },
    );
    final status = response.statusCode;
    if (status != 201 && status != 204) {
      throw await _fail('MOVE', from, response, clock);
    }
    await response.drain<void>();
    _done('MOVE', from, status, clock, extra: ' to ${_show(to)}');
  }

  // --- transport -----------------------------------------------------------

  Future<HttpClientResponse> _send(
    String method,
    String path, {
    bool collection = false,
    Map<String, String> headers = const {},
    Stream<List<int>> Function()? body,
    int length = 0,
    bool compressed = false,
  }) async {
    var uri = urlFor(path, collection: collection);
    var verb = method;
    var sendBody = body;
    var sendAuth = true;
    for (var hop = 0; ; hop++) {
      final HttpClientResponse response;
      try {
        // One attempt, one certificate: the callback may have caught a
        // refusal on an earlier hop, and that fingerprint is not this one.
        _refusedFingerprint = null;
        final request = await _http.openUrl(verb, uri).timeout(timeout);
        request
          ..followRedirects = false
          ..persistentConnection = true;
        if (!compressed) {
          request.headers.removeAll(HttpHeaders.acceptEncodingHeader);
        }
        final authorization = _authorization;
        if (sendAuth && authorization != null) {
          request.headers.set(HttpHeaders.authorizationHeader, authorization);
        }
        headers.forEach(request.headers.set);
        final bodyNow = sendBody;
        if (bodyNow == null) {
          request.contentLength = 0;
        } else {
          request.contentLength = length;
          try {
            await request.addStream(bodyNow()).timeout(timeout);
          } on TimeoutException {
            // A server that takes the headers and reads nothing leaves
            // the write waiting forever; abort it rather than hang the
            // run that owns the lock (#348).
            request.abort();
            throw _timedOut(method, path, 'sending the body stalled');
          }
        }
        response = await request.close().timeout(timeout);
      } on TimeoutException {
        throw _timedOut(method, path, 'no answer');
      } on IOException catch (e) {
        throw _transportFailure(method, path, e);
      }
      final status = response.statusCode;
      final date = response.headers.date;
      if (date != null) _serverDate = date.toUtc();
      if (!const {301, 302, 303, 307, 308}.contains(status)) return response;
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>().catchError((Object _) {});
      if (location == null) {
        throw WebDavProtocolFailure(
          '$method ${_show(path)}: redirect without a Location',
          status: status,
        );
      }
      if (hop >= _maxRedirects) {
        _log.warning(
          '$method ${_show(path)}: more than $_maxRedirects redirects',
        );
        throw WebDavProtocolFailure(
          '$method ${_show(path)}: more than $_maxRedirects redirects',
          status: status,
        );
      }
      final Uri next;
      try {
        next = uri.resolve(location);
      } on FormatException {
        throw WebDavProtocolFailure(
          '$method ${_show(path)}: unparsable redirect',
          status: status,
        );
      }
      if (next.scheme != 'http' && next.scheme != 'https') {
        throw WebDavProtocolFailure(
          '$method ${_show(path)}: redirect to a ${next.scheme} URL',
          status: status,
        );
      }
      // Credentials follow a redirect only while the origin stays the
      // same: the same host and the same port a URL spells (a port
      // neither spells is the scheme's default, so an `http://nas/dav`
      // -> `https://nas/dav` upgrade keeps it, which is the setup the
      // docs invite). A downgrade to plain http is another origin — the
      // credentials would travel in the clear — and another host or port
      // is too; once dropped they stay dropped.
      final sameOrigin =
          next.host == uri.host &&
          _spelledPort(next) == _spelledPort(uri) &&
          !(uri.scheme == 'https' && next.scheme == 'http');
      if (!sameOrigin) sendAuth = false;
      if (status == 303) {
        verb = 'GET';
        sendBody = null;
      }
      _log.info(
        '$method ${_show(path)} -> $status redirect'
        '${sameOrigin ? '' : ' to another origin, credentials not sent'}',
      );
      uri = next;
    }
  }

  WebDavFailure _transportFailure(String method, String path, IOException e) {
    final detail = switch (e) {
      TlsException(:final message) => 'TLS: $message',
      SocketException(:final osError, :final message) =>
        osError?.message ?? message,
      HttpException(:final message) => message,
      FileSystemException(:final message) => 'local file: $message',
      _ => e.runtimeType.toString(),
    };
    _log.warning('$method ${_show(path)}: $detail');
    final text = '$method ${_show(path)}: $detail';
    if (e is TlsException) {
      // A certificate the device refuses is its own outcome, with a
      // message that names the destination so the user can act on it
      // (#366). Any other TLS trouble stays a protocol failure, as it
      // was.
      return _certificateFailure(method, path, e) ??
          WebDavProtocolFailure(text);
    }
    return WebDavRetryable(text);
  }

  /// The failure for a refused certificate, or null when [e] is TLS
  /// trouble of another kind (a version mismatch, a dropped handshake).
  ///
  /// A fingerprint the callback caught is the certificate itself and is
  /// preferred over one guessed out of the exception's text; when the
  /// callback never ran (an injected client in tests), the text is all
  /// there is.
  WebDavCertificateFailure? _certificateFailure(
    String method,
    String path,
    TlsException e,
  ) {
    final caught = _refusedFingerprint;
    if (caught == null && !_certificateRefused(e)) return null;
    final fingerprint = caught ?? _fingerprintIn(e);
    final host = baseUrl.host;
    final authority = baseUrl.hasPort ? '$host:${baseUrl.port}' : host;
    final digest = fingerprint == null ? '' : ', fingerprint $fingerprint';
    return WebDavCertificateFailure(
      '$method ${_show(path)}: the certificate for $authority is not '
      'trusted$digest',
      host: host,
      fingerprint: fingerprint,
    );
  }

  /// Whether [e] is the device refusing the server's certificate, rather
  /// than any other TLS failure.
  ///
  /// The Dart VM raises [HandshakeException] from BoringSSL, whose text
  /// carries `CERTIFICATE_VERIFY_FAILED`; the named cases below cover a
  /// platform that words it differently.
  static bool _certificateRefused(TlsException e) {
    final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
    return text.contains('certificate_verify_failed') ||
        (text.contains('certificate') &&
            (text.contains('self signed') ||
                text.contains('self-signed') ||
                text.contains('selfsigned') ||
                text.contains('untrusted') ||
                text.contains('not trusted') ||
                text.contains('verify failed')));
  }

  /// The certificate's fingerprint, when [e]'s text carries a digest.
  ///
  /// [TlsException] has no certificate field: the Dart VM's does not
  /// expose one, so this is null unless the platform put a digest in the
  /// message. A fingerprint is a long chain of hex bytes, which is what
  /// the pattern looks for.
  static String? _fingerprintIn(TlsException e) {
    final text = '${e.message} ${e.osError?.message ?? ''}';
    final match = RegExp(
      // A digest starts at a boundary: the `56` of a `SHA256:` label is
      // hex too, and must not be taken for the first byte.
      '(?<![0-9a-f])[0-9a-f]{2}(?::[0-9a-f]{2}){15,}'
      '|(?<![0-9a-f])[0-9a-f]{40,}',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(0)?.toUpperCase();
  }

  Future<WebDavFailure> _fail(
    String method,
    String path,
    HttpClientResponse response,
    Stopwatch clock,
  ) async {
    await response.drain<void>().catchError((Object _) {});
    final status = response.statusCode;
    final text = '$method ${_show(path)}: $status ${response.reasonPhrase}';
    _log.warning('$text, ${clock.elapsedMilliseconds} ms');
    return switch (status) {
      401 || 403 => WebDavAuthFailure(text, status: status),
      404 || 409 || 410 => WebDavNotFound(text, status: status),
      412 => WebDavPrecondition(text, status: status),
      408 || 423 || 425 || 429 || 500 || 502 || 503 || 504 => WebDavRetryable(
        text,
        status: status,
        retryAfter: _retryAfter(response),
      ),
      405 || 501 => WebDavUnsupported(text, status: status),
      _ => WebDavProtocolFailure(text, status: status),
    };
  }

  void _done(
    String method,
    String path,
    int status,
    Stopwatch clock, {
    String? etag,
    int? bytes,
    String extra = '',
  }) {
    _log.info(
      '$method ${_show(path)} -> $status'
      '${etag == null ? '' : ', etag ${_shortEtag(etag)}'}'
      '${bytes == null ? '' : ', $bytes b'}'
      '$extra, ${clock.elapsedMilliseconds} ms',
    );
  }

  /// The retryable failure of an attempt that outlived [timeout], with
  /// [what] saying what never came through — the answer, the body.
  ///
  /// One failure for every wait: a slow connection, a response that never
  /// starts and a body that never arrives are all the same kind of bad
  /// luck to the caller, and all worth retrying (#348).
  WebDavRetryable _timedOut(String method, String path, String what) {
    final text = '$method ${_show(path)}: $what in ${_describe(timeout)}';
    _log.warning(text);
    return WebDavRetryable(text);
  }

  /// [duration] the way a log line wants it: whole seconds, or the
  /// milliseconds a shorter timeout really is.
  static String _describe(Duration duration) => duration.inSeconds >= 1
      ? '${duration.inSeconds} s'
      : '${duration.inMilliseconds} ms';

  static Future<void> _closeQuietly(StreamConsumer<List<int>> into) async {
    try {
      await into.close();
    } on Object catch (_) {
      // The transfer's own failure is the one to report.
    }
  }

  /// Ends a response that is not going to finish, so the connection is
  /// not left open with a body nobody will read.
  static Future<void> _dropQuietly(HttpClientResponse response) async {
    try {
      (await response.detachSocket()).destroy();
    } on Object catch (_) {
      // Already gone: nothing to drop.
    }
  }

  /// The comma-separated tokens of every [name] header, trimmed.
  static Iterable<String> _headerTokens(
    HttpClientResponse response,
    String name,
  ) => (response.headers[name] ?? const <String>[])
      .expand((value) => value.split(','))
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty);

  static Duration? _retryAfter(HttpClientResponse response) {
    final value = response.headers.value(HttpHeaders.retryAfterHeader);
    if (value == null) return null;
    final seconds = int.tryParse(value.trim());
    if (seconds != null) return Duration(seconds: seconds < 0 ? 0 : seconds);
    final date = _httpDate(value);
    if (date == null) return null;
    final wait = date.difference(DateTime.now().toUtc());
    return wait.isNegative ? Duration.zero : wait;
  }

  static DateTime? _httpDate(String? value) {
    if (value == null) return null;
    try {
      return HttpDate.parse(value);
    } on HttpException {
      return null;
    }
  }

  static String _clean(String path) =>
      path.split('/').where((s) => s.isNotEmpty).join('/');

  static String _show(String path) {
    final clean = _clean(path);
    return clean.isEmpty ? '/' : clean;
  }

  static String _shortEtag(String etag) {
    final bare = etag.replaceFirst('W/', '').replaceAll('"', '');
    return bare.length <= 12 ? bare : bare.substring(0, 12);
  }

  /// The comparison form of a certificate fingerprint: the hex digits
  /// alone, uppercased, so a stored `AB:CD:…` matches one written without
  /// the separators. An empty or separator-only string is no fingerprint.
  static String? _fingerprintKey(String? fingerprint) {
    if (fingerprint == null) return null;
    final digits = fingerprint.replaceAll(RegExp('[^0-9A-Fa-f]'), '');
    return digits.isEmpty ? null : digits.toUpperCase();
  }

  /// The port [uri] spells, or null when it leaves it to the scheme's
  /// default (`80`/`443`): `http://nas/dav` and `https://nas/dav` then
  /// have the same spelled port, as a scheme upgrade must keep its
  /// credentials.
  static int? _spelledPort(Uri uri) =>
      uri.port == (uri.scheme == 'https' ? 443 : 80) ? null : uri.port;
}

/// The SHA-256 fingerprint of a DER-encoded certificate: uppercase hex
/// bytes joined with `:`, the way `openssl x509 -fingerprint -sha256`
/// prints it. This is the value a destination stores and compares against
/// (#454), so it is computed from the certificate's own bytes rather than
/// from anything a message says.
String sha256Fingerprint(List<int> der) =>
    _formatFingerprint(sha256.convert(der).bytes);

/// [digest] as uppercase hex bytes joined with `:`.
String _formatFingerprint(List<int> digest) => [
  for (final byte in digest)
    byte.toRadixString(16).padLeft(2, '0').toUpperCase(),
].join(':');

final class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

final class _BytesConsumer implements StreamConsumer<List<int>> {
  final builder = BytesBuilder(copy: false);

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(builder.add);

  @override
  Future<void> close() async {}
}
