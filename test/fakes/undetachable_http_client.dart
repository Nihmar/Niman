import 'dart:async';
import 'dart:io';

/// An [HttpClient] that reaches the real network but hands back responses
/// whose connection cannot be detached.
///
/// `WebDavClient` gives up on a body that stalls by detaching the socket
/// (#348), and a connection the HTTP client no longer owns refuses that:
/// the stall then has to end the copy into the caller's sink by itself, or
/// the sink stays bound to a transfer nothing will finish (#495).
///
/// Everything the client does not use is left unimplemented.
final class UndetachableHttpClient implements HttpClient {
  /// Wraps a fresh [HttpClient].
  new() : _inner = HttpClient();

  final HttpClient _inner;

  /// How many response bodies had their subscription cancelled — a copy
  /// the client gave up on has to say so, or it keeps reading (and
  /// buffering) a body nobody wants.
  int cancelledBodies = 0;

  /// Closes the wrapped client.
  void dispose() => _inner.close(force: true);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _UndetachableRequest(
        await _inner.openUrl(method, url),
        () => cancelledBodies++,
      );

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

final class _UndetachableRequest implements HttpClientRequest {
  new(this._inner, this._onCancel);

  final HttpClientRequest _inner;
  final void Function() _onCancel;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  set contentLength(int value) => _inner.contentLength = value;

  @override
  set followRedirects(bool value) => _inner.followRedirects = value;

  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;

  @override
  Future<void> addStream(Stream<List<int>> stream) => _inner.addStream(stream);

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);

  @override
  Future<HttpClientResponse> close() async =>
      _UndetachableResponse(await _inner.close(), _onCancel);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _UndetachableResponse implements HttpClientResponse {
  new(this._inner, this._onCancel);

  final HttpClientResponse _inner;
  final void Function() _onCancel;

  @override
  int get statusCode => _inner.statusCode;

  @override
  int get contentLength => _inner.contentLength;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _CountedSubscription(
    _inner.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    ),
    _onCancel,
  );

  @override
  Stream<S> map<S>(S Function(List<int> event) convert) => _inner.map(convert);

  @override
  Future<E> drain<E>([E? futureValue]) => _inner.drain<E>(futureValue);

  @override
  Future<Socket> detachSocket() async =>
      throw UnsupportedError('this connection cannot be detached');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// A subscription that says when it is cancelled (once).
final class _CountedSubscription implements StreamSubscription<List<int>> {
  new(this._inner, this._onCancel);

  final StreamSubscription<List<int>> _inner;
  final void Function() _onCancel;
  var _cancelled = false;

  @override
  Future<void> cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _onCancel();
    }
    return _inner.cancel();
  }

  @override
  void onData(void Function(List<int> data)? handleData) =>
      _inner.onData(handleData);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();

  @override
  bool get isPaused => _inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture<E>(futureValue);
}
