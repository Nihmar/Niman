import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/webdav/webdav_certificate_trust.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_paths.dart';

/// How a WebDAV client's requests reach the destination folder: one
/// request at a time over one `HttpClient`, with its credentials, its
/// redirects, its timeouts and the certificate it may trust, failing as
/// [WebDavFailure]s (docs/records/sync.md, "The client").
final class WebDavTransport {
  /// The transport for the folder at [url] (`http` or `https`), as
  /// `WebDavClient.new` describes its arguments.
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
       _ownsHttp = httpClient == null,
       _http = httpClient ?? HttpClient() {
    _trust = WebDavCertificateTrust(
      baseUrl: baseUrl,
      trustedCertificateFingerprint: trustedCertificateFingerprint,
    );
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
    _http.badCertificateCallback = _trust.onBadCertificate;
    _baseSegments = [
      for (final segment in baseUrl.pathSegments)
        if (segment.isNotEmpty) segment,
    ];
  }

  /// The destination folder, always ending with `/`, with no query,
  /// fragment or user info.
  final Uri baseUrl;

  /// How long to wait for a connection, for a response to start, and for
  /// the next chunk of a body, either way ([unlessStalled]).
  final Duration timeout;

  final String? _authorization;
  final bool _ownsHttp;
  final HttpClient _http;
  late final WebDavCertificateTrust _trust;

  late final List<String> _baseSegments;
  DateTime? _serverDate;

  /// The server's clock (`Date` header, UTC) on the latest response, or
  /// null before one carried it.
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

  /// Closes the connections (only those of a transport this one created).
  void close() {
    if (_ownsHttp) _http.close(force: true);
  }

  /// Sends [method] on [path] and returns the response that is not a
  /// redirect, following up to [_maxRedirects] of them.
  ///
  /// [body] is called once per hop that sends it, for [length] bytes;
  /// [compressed] lets the server gzip the response.
  Future<HttpClientResponse> send(
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
        _trust.forgetRefused();
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
            await unlessStalled(
              (progress) => request.addStream(
                bodyNow().map((chunk) {
                  progress();
                  return chunk;
                }),
              ),
            );
          } on TimeoutException {
            // A server that takes the headers and reads nothing leaves
            // the write waiting forever; abort it rather than hang the
            // run that owns the lock (#348).
            request.abort();
            throw timedOut(method, path, 'sending the body stalled');
          }
        }
        response = await request.close().timeout(timeout);
      } on TimeoutException {
        throw timedOut(method, path, 'no answer');
      } on IOException catch (e) {
        throw transportFailure(method, path, e, at: uri);
      }
      final status = response.statusCode;
      final date = response.headers.date;
      if (date != null) _serverDate = date.toUtc();
      if (!const {301, 302, 303, 307, 308}.contains(status)) return response;
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>().catchError((Object _) {});
      if (location == null) {
        throw WebDavProtocolFailure(
          '$method ${webDavShowPath(path)}: redirect without a Location',
          status: status,
        );
      }
      if (hop >= _maxRedirects) {
        _log.warning(
          '$method ${webDavShowPath(path)}: more than $_maxRedirects '
          'redirects',
        );
        throw WebDavProtocolFailure(
          '$method ${webDavShowPath(path)}: more than $_maxRedirects '
          'redirects',
          status: status,
        );
      }
      final Uri next;
      try {
        next = uri.resolve(location);
      } on FormatException {
        throw WebDavProtocolFailure(
          '$method ${webDavShowPath(path)}: unparsable redirect',
          status: status,
        );
      }
      if (next.scheme != 'http' && next.scheme != 'https') {
        throw WebDavProtocolFailure(
          '$method ${webDavShowPath(path)}: redirect to a ${next.scheme} URL',
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
        '$method ${webDavShowPath(path)} -> $status redirect'
        '${sameOrigin ? '' : ' to another origin, credentials not sent'}',
      );
      uri = next;
    }
  }

  /// The failure of [method] on [path] that [e] broke off.
  ///
  /// [at] is the URL the request went to, when a redirect may have taken
  /// it off the destination.
  WebDavFailure transportFailure(
    String method,
    String path,
    IOException e, {
    Uri? at,
  }) {
    final detail = switch (e) {
      TlsException(:final message) => 'TLS: $message',
      SocketException(:final osError, :final message) =>
        osError?.message ?? message,
      HttpException(:final message) => message,
      FileSystemException(:final message) => 'local file: $message',
      _ => e.runtimeType.toString(),
    };
    _log.warning('$method ${webDavShowPath(path)}: $detail');
    final text = '$method ${webDavShowPath(path)}: $detail';
    if (e is TlsException) {
      // A certificate the device refuses is its own outcome, with a
      // message that names the destination so the user can act on it
      // (#366). Any other TLS trouble stays a protocol failure, as it
      // was.
      return _trust.certificateFailure(method, path, e, at: at) ??
          WebDavProtocolFailure(text);
    }
    return WebDavRetryable(text);
  }

  /// [transfer] run to its end, or a [TimeoutException] once [timeout]
  /// passes with no chunk moving.
  ///
  /// [transfer] calls the `progress` it is handed for every chunk that
  /// goes through, and each call starts the wait over. The bound is on the
  /// silence, not on the whole transfer: a body that stops arriving (or a
  /// server that stops reading one) fails within [timeout] (#348), while a
  /// large file on a slow link, which keeps moving, takes as long as it
  /// takes — a limit on the whole transfer failed every run for a file
  /// that needs longer than [timeout] to cross, so it never synced.
  Future<void> unlessStalled(
    Future<void> Function(void Function() progress) transfer,
  ) async {
    final stalled = Completer<void>();
    Timer? wait;
    void progress() {
      wait?.cancel();
      wait = Timer(timeout, () {
        if (!stalled.isCompleted) {
          stalled.completeError(TimeoutException('no data moved', timeout));
        }
      });
    }

    progress();
    try {
      await Future.any([transfer(progress), stalled.future]);
    } finally {
      wait?.cancel();
    }
  }

  /// The retryable failure of an attempt that outlived [timeout], with
  /// [what] saying what never came through — the answer, the body.
  ///
  /// One failure for every wait: a slow connection, a response that never
  /// starts and a body that never arrives are all the same kind of bad
  /// luck to the caller, and all worth retrying (#348).
  WebDavRetryable timedOut(String method, String path, String what) {
    final text =
        '$method ${webDavShowPath(path)}: $what in ${_describe(timeout)}';
    _log.warning(text);
    return WebDavRetryable(text);
  }

  /// [duration] the way a log line wants it: whole seconds, or the
  /// milliseconds a shorter timeout really is.
  static String _describe(Duration duration) => duration.inSeconds >= 1
      ? '${duration.inSeconds} s'
      : '${duration.inMilliseconds} ms';

  /// The port [uri] spells, or null when it leaves it to the scheme's
  /// default (`80`/`443`): `http://nas/dav` and `https://nas/dav` then
  /// have the same spelled port, as a scheme upgrade must keep its
  /// credentials.
  static int? _spelledPort(Uri uri) =>
      uri.port == (uri.scheme == 'https' ? 443 : 80) ? null : uri.port;
}
