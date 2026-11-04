import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:niman/src/sync/webdav/webdav_transport.dart';

/// How many bytes the download gathers before the hash and the sink see
/// them: the response arrives in socket-sized pieces, and hashing and
/// handing on every one of them costs more than the bytes (#1107).
const int _downloadChunk = 64 * 1024;

/// [response]'s body (the answer to a `GET` on [path]) streamed into
/// [into], with its length and its lowercase hex sha256 computed on the
/// way; every piece that arrives is handed to [onBytes] as it comes.
///
/// A body that stops arriving for [transport]'s timeout fails as its
/// retryable kind, and so does a broken connection; on any failure [into]
/// is closed before the failure goes on.
Future<({int bytes, String sha256})> copyWebDavBody(
  HttpClientResponse response,
  StreamConsumer<List<int>> into, {
  required String path,
  required WebDavTransport transport,
  required void Function(int count) onBytes,
}) async {
  final digest = _DigestSink();
  final hasher = sha256.startChunkedConversion(digest);
  var bytes = 0;
  // The body is copied through a subscription this client owns, into a
  // stream it can end: giving up on the transfer cancels the copy and
  // closes that stream, which releases the sink for its caller to close.
  // Handing the response straight to `pipe` left the sink bound to a
  // copy that may never finish — the socket cannot always be detached —
  // and `IOSink.close()` on a bound sink throws where no caller can
  // catch it, so a `StateError` replaced the transfer's own failure
  // (#495).
  final body = StreamController<List<int>>();
  StreamSubscription<List<int>>? source;
  // The sink's own backpressure reaches the connection, so a slow disk
  // does not read the whole body into memory.
  void pause() => source?.pause();
  void resume() => source?.resume();
  body
    ..onPause = pause
    ..onResume = resume;
  // Stops the copy into [into]: once it returns, the pipe is done and
  // the sink is no longer bound.
  Future<void> endCopy() async {
    await source?.cancel();
    await body.close();
  }

  try {
    // The response arrives in socket-sized pieces (a few KB each over a
    // phone link); gathering them keeps the hash and the sink from
    // paying per piece. The stall timer still sees every piece, so a
    // silent server is caught as before (#1107).
    final gathered = BytesBuilder(copy: false);
    void flush() {
      if (gathered.isEmpty) return;
      final chunk = gathered.takeBytes();
      hasher.add(chunk);
      body.add(chunk);
    }

    await transport.unlessStalled((progress) {
      source = response.listen(
        (chunk) {
          progress();
          bytes += chunk.length;
          onBytes(chunk.length);
          gathered.add(chunk);
          if (gathered.length >= _downloadChunk) flush();
        },
        onError: body.addError,
        onDone: () {
          flush();
          unawaited(body.close());
        },
      );
      return body.stream.pipe(into);
    });
  } on TimeoutException {
    await endCopy();
    // Dropping the connection is what makes the server stop. Best
    // effort: the stall fails as the retryable kind the caller already
    // backs off on either way (#348).
    await _dropQuietly(response);
    await closeWebDavSinkQuietly(into);
    throw transport.timedOut('GET', path, 'the body stalled');
  } on IOException catch (e) {
    await endCopy();
    await closeWebDavSinkQuietly(into);
    throw transport.transportFailure('GET', path, e);
  } on Object {
    // Whatever else the sink threw: the copy is ours, so it ends here
    // too, or it keeps reading and buffering a body nobody wants.
    await endCopy();
    await closeWebDavSinkQuietly(into);
    rethrow;
  }
  hasher.close();
  return (bytes: bytes, sha256: digest.value.toString());
}

/// Closes [into], swallowing whatever closing it throws.
Future<void> closeWebDavSinkQuietly(StreamConsumer<List<int>> into) async {
  try {
    await into.close();
  } on Object catch (_) {
    // The transfer's own failure is the one to report.
  }
}

/// Ends a response that is not going to finish, so the connection is
/// not left open with a body nobody will read.
Future<void> _dropQuietly(HttpClientResponse response) async {
  try {
    (await response.detachSocket()).destroy();
  } on Object catch (_) {
    // Already gone: nothing to drop.
  }
}

final class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
