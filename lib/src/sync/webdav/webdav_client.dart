import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/webdav/webdav_body_copy.dart';
import 'package:niman/src/sync/webdav/webdav_client_config.dart';
import 'package:niman/src/sync/webdav/webdav_download.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_file_body.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_paths.dart';
import 'package:niman/src/sync/webdav/webdav_response_failure.dart';
import 'package:niman/src/sync/webdav/webdav_server_info.dart';
import 'package:niman/src/sync/webdav/webdav_transport.dart';
import 'package:niman/src/sync/webdav/webdav_upload.dart';

export 'package:niman/src/sync/webdav/webdav_download.dart';
export 'package:niman/src/sync/webdav/webdav_fingerprint.dart';
export 'package:niman/src/sync/webdav/webdav_server_info.dart';
export 'package:niman/src/sync/webdav/webdav_upload.dart';

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
    Duration timeout = const Duration(seconds: 30),
  }) : _transport = WebDavTransport(
         url: url,
         username: username,
         password: password,
         trustedCertificateFingerprint: trustedCertificateFingerprint,
         httpClient: httpClient,
         timeout: timeout,
       ),
       config = httpClient != null
           ? null
           : WebDavClientConfig(
               url: url.toString(),
               username: username,
               password: password,
               trustedCertificateFingerprint: trustedCertificateFingerprint,
               timeoutMs: timeout.inMilliseconds,
             );

  /// How the requests reach the destination: the connection, the
  /// credentials, the redirects, the timeouts and the certificate trust.
  final WebDavTransport _transport;

  /// The destination folder, always ending with `/`, with no query,
  /// fragment or user info.
  Uri get baseUrl => _transport.baseUrl;

  /// What builds this client again in another isolate (#1107), or null for
  /// a client over an injected `HttpClient`: a transport that cannot cross
  /// an isolate, which only a test injects.
  final WebDavClientConfig? config;

  /// How long to wait for a connection, for a response to start, and for
  /// the next chunk of a body, either way.
  ///
  /// The last one is what stops a server that sent its headers and then
  /// went quiet from holding a sync run open for the rest of the session
  /// (#348). It bounds a silence, not a whole transfer
  /// ([WebDavTransport.unlessStalled]).
  Duration get timeout => _transport.timeout;

  /// The server's clock (`Date` header, UTC) on the latest response, or
  /// null before one carried it. The sync compares remote mtimes with it,
  /// never with this device's clock, which can be minutes off.
  DateTime? get serverDate => _transport.serverDate;

  int _bytesSent = 0;
  int _bytesReceived = 0;
  int _bytesHashed = 0;

  /// Body bytes this client has handed to the connection for an upload,
  /// counted as they leave: a transfer that fails half way counts what it
  /// sent, and a redirect hop that sends the body again counts it again.
  int get bytesSent => _bytesSent;

  /// Body bytes this client has received from downloads that kept them,
  /// counted as they arrive (a failed or short download counts what came).
  int get bytesReceived => _bytesReceived;

  /// Body bytes received from downloads made only to hash them
  /// ([download]'s `hashOnly`): the cost of a file whose listing cannot say
  /// whether it changed, apart from the notes the run really fetched.
  int get bytesHashed => _bytesHashed;

  static const _log = AppLogger(name: 'webdav');

  /// The absolute URL of [path]; [collection] adds the trailing slash
  /// folders need on most servers.
  Uri urlFor(String path, {bool collection = false}) =>
      _transport.urlFor(path, collection: collection);

  /// Closes the connections (only those of a client this one created).
  void close() => _transport.close();

  /// `OPTIONS` on the destination folder.
  Future<WebDavServerInfo> options() async {
    final clock = Stopwatch()..start();
    final response = await _transport.send('OPTIONS', '', collection: true);
    if (response.statusCode >= 300) {
      throw await webDavResponseFailure('OPTIONS', '', response, clock);
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
    final response = await _transport.send(
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
      throw await webDavResponseFailure('PROPFIND', path, response, clock);
    }
    final String text;
    try {
      final encoding = response.headers.value(
        HttpHeaders.contentEncodingHeader,
      );
      final raw = encoding == 'gzip' ? gzip.decoder.bind(response) : response;
      text = await const Utf8Decoder(allowMalformed: true).bind(raw).join();
    } on IOException catch (e) {
      throw _transport.transportFailure('PROPFIND', path, e);
    } on FormatException catch (e) {
      throw WebDavProtocolFailure(
        'PROPFIND ${webDavShowPath(path)}: ${e.message}',
      );
    }
    final resources = parseMultistatus(
      text,
      baseUrl,
      onSkipped: (href) => _log.warning(
        'PROPFIND ${webDavShowPath(path)}: skipped an item outside the '
        'destination ($href)',
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
    final self = webDavCleanPath(folder);
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
      final self = webDavCleanPath(path);
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
  ///
  /// The bytes that arrive add to [bytesReceived], or to [bytesHashed] when
  /// [hashOnly] says [into] throws them away and the download is made only
  /// for the sha256.
  Future<WebDavDownload> download(
    String path,
    StreamConsumer<List<int>> into, {
    bool hashOnly = false,
  }) async {
    final clock = Stopwatch()..start();
    final HttpClientResponse response;
    try {
      response = await _transport.send('GET', path);
    } on Object {
      await closeWebDavSinkQuietly(into);
      rethrow;
    }
    if (response.statusCode != 200) {
      await closeWebDavSinkQuietly(into);
      throw await webDavResponseFailure('GET', path, response, clock);
    }
    final (:bytes, sha256: sha) = await copyWebDavBody(
      response,
      into,
      path: path,
      transport: _transport,
      onBytes: (count) {
        if (hashOnly) {
          _bytesHashed += count;
        } else {
          _bytesReceived += count;
        }
      },
    );
    final expected = response.contentLength;
    if (expected >= 0 && bytes != expected) {
      _log.warning(
        'GET ${webDavShowPath(path)}: received $bytes of $expected bytes, '
        '${clock.elapsedMilliseconds} ms',
      );
      throw WebDavRetryable(
        'GET ${webDavShowPath(path)}: received $bytes of $expected bytes',
        status: 200,
      );
    }
    final etag = response.headers.value(HttpHeaders.etagHeader);
    final modified = webDavHttpDate(
      response.headers.value(HttpHeaders.lastModifiedHeader),
    );
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
    final response = await _transport.send(
      'PUT',
      path,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/octet-stream',
        'If-Match': ?guard,
        if (ifNoneMatch) 'If-None-Match': '*',
        if (modified != null)
          'X-OC-Mtime': '${modified.millisecondsSinceEpoch ~/ 1000}',
      },
      body: () => open().map((chunk) {
        _bytesSent += chunk.length;
        return chunk;
      }),
      length: length,
    );
    final status = response.statusCode;
    if (status != 200 && status != 201 && status != 204) {
      throw await webDavResponseFailure('PUT', path, response, clock);
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

  /// `PUT`s [file]'s bytes to [path], as one file, streamed.
  ///
  /// The length and the bytes come from **one open handle** (#723): taking
  /// the length from one read and the body from another sent a new save's
  /// first bytes under the old length — half a note on the server. A
  /// redirect hop that sends the body again reads the same handle from its
  /// start.
  ///
  /// What a save during the upload does depends on the platform. On
  /// Android and Linux its rename lands, and the handle goes on reading the
  /// file it opened, whole. On Windows `File.open` does not share delete
  /// access, so the save's rename over the path fails (access denied) for
  /// as long as the handle is open — through the server's response and any
  /// redirect — and the editor keeps the note unsaved until its next save
  /// (#763). Either way the bytes sent are one version of the file.
  ///
  /// [WebDavUpload.sha256] is the digest of the bytes actually sent: what a
  /// caller with a plan compares its own hash against.
  Future<WebDavUpload> uploadFile(
    String path,
    File file, {
    String? ifMatch,
    bool ifNoneMatch = false,
    DateTime? modified,
  }) async {
    final handle = await file.open();
    try {
      final length = await handle.length();
      String? sent;
      final result = await upload(
        path,
        open: () => webDavFileBody(handle, (sha) => sent = sha),
        length: length,
        ifMatch: ifMatch,
        ifNoneMatch: ifNoneMatch,
        modified: modified,
      );
      return WebDavUpload(
        created: result.created,
        etag: result.etag,
        mtimeAccepted: result.mtimeAccepted,
        sha256: sent,
      );
    } finally {
      await handle.close();
    }
  }

  /// `MKCOL` [folder]: true when it was created, false when it already
  /// existed (405). A missing parent fails as [WebDavNotFound].
  Future<bool> createFolder(String folder) async {
    final clock = Stopwatch()..start();
    final response = await _transport.send('MKCOL', folder, collection: true);
    final status = response.statusCode;
    if (status == 405) {
      await response.drain<void>();
      _done('MKCOL', folder, status, clock, extra: ', already there');
      return false;
    }
    if (status != 201 && status != 200 && status != 204) {
      throw await webDavResponseFailure('MKCOL', folder, response, clock);
    }
    await response.drain<void>();
    _done('MKCOL', folder, status, clock);
    return true;
  }

  /// Creates [folder] and whatever parents it lacks: tries the folder
  /// first and walks up only on a missing parent, so the common case
  /// (parents exist) is one request.
  Future<void> createFolders(String folder) async {
    final clean = webDavCleanPath(folder);
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
    final response = await _transport.send(
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
      throw await webDavResponseFailure('DELETE', path, response, clock);
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
    final response = await _transport.send(
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
      throw await webDavResponseFailure('MOVE', from, response, clock);
    }
    await response.drain<void>();
    _done('MOVE', from, status, clock, extra: ' to ${webDavShowPath(to)}');
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
      '$method ${webDavShowPath(path)} -> $status'
      '${etag == null ? '' : ', etag ${_shortEtag(etag)}'}'
      '${bytes == null ? '' : ', $bytes b'}'
      '$extra, ${clock.elapsedMilliseconds} ms',
    );
  }

  /// The comma-separated tokens of every [name] header, trimmed.
  static Iterable<String> _headerTokens(
    HttpClientResponse response,
    String name,
  ) => (response.headers[name] ?? const <String>[])
      .expand((value) => value.split(','))
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty);

  static String _shortEtag(String etag) {
    final bare = etag.replaceFirst('W/', '').replaceAll('"', '');
    return bare.length <= 12 ? bare : bare.substring(0, 12);
  }
}

final class _BytesConsumer implements StreamConsumer<List<int>> {
  final builder = BytesBuilder(copy: false);

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(builder.add);

  @override
  Future<void> close() async {}
}
