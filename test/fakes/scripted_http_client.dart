import 'dart:async';
import 'dart:io';

/// An [HttpClient] whose one answer is a `200` with a body the test hands
/// over piece by piece: the socket-sized pieces a response arrives in, at
/// the sizes the test chooses, which a real connection never promises.
///
/// Everything `WebDavClient` does not use is left unimplemented.
final class ScriptedHttpClient implements HttpClient {
  /// A client answering every request with a `200` whose body is [body],
  /// announced as [contentLength] bytes long.
  new({required this.body, required this.contentLength});

  /// The pieces of the body, as the connection delivers them.
  final Stream<List<int>> body;

  /// The `Content-Length` the answer announces.
  final int contentLength;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _Request(body, contentLength);

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

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? value,
  ) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _Request implements HttpClientRequest {
  new(this._body, this._contentLength);

  final Stream<List<int>> _body;
  final int _contentLength;

  @override
  final HttpHeaders headers = _Headers();

  @override
  set contentLength(int value) {}

  @override
  set followRedirects(bool value) {}

  @override
  set persistentConnection(bool value) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> close() async => _Response(_body, _contentLength);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _Response implements HttpClientResponse {
  new(this._body, this.contentLength);

  final Stream<List<int>> _body;

  @override
  final int contentLength;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  String get reasonPhrase => 'OK';

  @override
  final HttpHeaders headers = _Headers();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _body.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  Future<E> drain<E>([E? futureValue]) => _body.drain<E>(futureValue);

  @override
  Future<Socket> detachSocket() async =>
      throw UnsupportedError('there is no socket');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

final class _Headers implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _values[name.toLowerCase()] = ['$value'];

  @override
  void removeAll(String name) => _values.remove(name.toLowerCase());

  @override
  String? value(String name) => _values[name.toLowerCase()]?.single;

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  DateTime? get date => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}
