import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/transcription/model_files.dart';

/// A model download running in its own isolate.
///
/// The weights are 75 MB to 3 GB. Streaming them on the UI isolate would
/// push every chunk through the heap the frames are built from, so the
/// HTTP read and the file write both happen in a spawned isolate, which
/// reports progress back a few times a second.
///
/// The file is written as `<target>.part` and renamed to [target] only
/// when the byte count matches the response's `Content-Length`: a
/// finished name is always a whole model ([ModelFiles] relies on it).
final class ModelDownload {
  new _(this._isolate, this._port, this._exit, this.target);

  /// Starts downloading [uri] into [target].
  ///
  /// [onHeaders] gets the announced size (null when the server sends
  /// none) once the response starts; [onProgress] the bytes received so
  /// far, throttled to about [progressInterval].
  static Future<ModelDownload> start({
    required Uri uri,
    required String target,
    required void Function(int received) onProgress,
    void Function(int? total, int elapsedMs)? onHeaders,
    Duration progressInterval = const Duration(milliseconds: 250),
    Duration stallTimeout = const Duration(seconds: 30),
  }) async {
    final port = ReceivePort();
    final exit = ReceivePort();
    final isolate = await Isolate.spawn(
      _run,
      _Request(
        port.sendPort,
        uri.toString(),
        target,
        progressInterval.inMilliseconds,
        stallTimeout.inMilliseconds,
      ),
      onExit: exit.sendPort,
      debugName: 'model-download',
    );
    final download = ModelDownload._(isolate, port, exit, target);
    // A cancel before anyone awaits [done] must not surface as an
    // unhandled error; later listeners still receive it.
    download._done.future.ignore();
    port.listen((message) {
      switch (message) {
        case ('headers', final int? total, final int ms):
          onHeaders?.call(total, ms);
        case ('progress', final int received):
          onProgress(received);
        case ('done', final int bytes):
          download._finish(bytes: bytes);
        case ('error', final String reason):
          download._finish(error: ModelDownloadException(reason));
      }
    });
    exit.listen((_) {
      // The isolate ended without reporting: killed, or crashed hard.
      download._finish(
        error: download._cancelled
            ? const ModelDownloadCancelled()
            : const ModelDownloadException('download stopped unexpectedly'),
      );
    });
    return download;
  }

  final Isolate _isolate;
  final ReceivePort _port;
  final ReceivePort _exit;

  /// Where the finished model lands.
  final String target;

  final Completer<int> _done = Completer<int>();
  bool _cancelled = false;

  /// Completes with the bytes written once the model is in place; fails
  /// with [ModelDownloadException], or [ModelDownloadCancelled] after
  /// [cancel].
  Future<int> get done => _done.future;

  /// Stops the download and removes its partial file.
  Future<void> cancel() async {
    if (_done.isCompleted) return;
    _cancelled = true;
    _isolate.kill(priority: Isolate.immediate);
    _finish(error: const ModelDownloadCancelled());
    final part = '$target${ModelFiles.partSuffix}';
    await Isolate.run(() {
      // The killed isolate may still hold the handle for a moment on
      // Windows; the next scan removes whatever this cannot.
      try {
        final file = File(part);
        if (file.existsSync()) file.deleteSync();
      } on FileSystemException {
        // Left for ModelFiles.installed.
      }
    });
  }

  void _finish({int? bytes, Object? error}) {
    if (_done.isCompleted) return;
    _port.close();
    _exit.close();
    if (error != null) {
      _done.completeError(error);
    } else {
      _done.complete(bytes);
    }
  }
}

/// A download that failed; [reason] is short and safe to log.
final class ModelDownloadException implements Exception {
  /// Creates the failure with [reason].
  const new(this.reason);

  /// What went wrong.
  final String reason;

  @override
  String toString() => 'ModelDownloadException: $reason';
}

/// A download stopped by [ModelDownload.cancel].
final class ModelDownloadCancelled implements Exception {
  /// Creates the cancellation.
  const new();

  @override
  String toString() => 'ModelDownloadCancelled';
}

final class _Request {
  const new(this.port, this.uri, this.target, this.progressMs, this.stallMs);

  final SendPort port;
  final String uri;
  final String target;
  final int progressMs;
  final int stallMs;
}

Future<void> _run(_Request request) async {
  final port = request.port;
  final clock = Stopwatch()..start();
  final client = HttpClient()
    ..connectionTimeout = Duration(milliseconds: request.stallMs);
  final part = File('${request.target}${ModelFiles.partSuffix}');
  IOSink? sink;
  try {
    final response = await (await client.getUrl(Uri.parse(request.uri)))
        .close()
        .timeout(Duration(milliseconds: request.stallMs));
    if (response.statusCode != HttpStatus.ok) {
      port.send(('error', 'HTTP ${response.statusCode}'));
      return;
    }
    final total = response.contentLength < 0 ? null : response.contentLength;
    port.send(('headers', total, clock.elapsedMilliseconds));
    await part.parent.create(recursive: true);
    sink = part.openWrite();
    var received = 0;
    var lastReport = 0;
    await sink.addStream(
      response
          .timeout(
            Duration(milliseconds: request.stallMs),
            onTimeout: (events) => events.addError(
              TimeoutException('no data for ${request.stallMs} ms'),
            ),
          )
          .map((chunk) {
            received += chunk.length;
            final now = clock.elapsedMilliseconds;
            if (now - lastReport >= request.progressMs) {
              lastReport = now;
              port.send(('progress', received));
            }
            return chunk;
          }),
    );
    await sink.close();
    sink = null;
    port.send(('progress', received));
    if (total != null && received != total) {
      await part.delete();
      port.send(('error', 'incomplete: $received of $total bytes'));
      return;
    }
    await part.rename(request.target);
    port.send(('done', received));
  } on Object catch (error) {
    try {
      await sink?.close();
    } on Object {
      // The write already failed; the reason below is what matters.
    }
    try {
      if (part.existsSync()) await part.delete();
    } on FileSystemException {
      // ModelFiles.installed removes it on the next scan.
    }
    port.send(('error', _short(error)));
  } finally {
    client.close(force: true);
  }
}

/// The failure without stack or URL noise, for the page and the log.
String _short(Object error) => switch (error) {
  SocketException(:final message, :final osError) =>
    'network: ${osError?.message ?? message}',
  HttpException(:final message) => 'http: $message',
  TimeoutException(:final message) => 'timeout: ${message ?? ''}',
  FileSystemException(:final message, :final osError) =>
    'disk: ${osError?.message ?? message}',
  _ => error.toString(),
};
