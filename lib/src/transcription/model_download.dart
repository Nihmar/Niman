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
/// when the byte count matches the announced size: a finished name is
/// always a whole model ([ModelFiles] relies on it). A failure keeps the
/// partial file, and the next download of the same target resumes it
/// with an HTTP `Range` request: Android freezes an app that leaves the
/// foreground, which drops the connection, and starting a 466 MB model
/// over each time would never finish.
final class ModelDownload {
  new _(this._isolate, this._port, this._exit, this.target);

  /// Starts downloading [uri] into [target], resuming a partial file.
  ///
  /// [onHeaders] gets the model's full size (null when the server sends
  /// none), the time to the first response and the byte offset it
  /// resumed from; [onProgress] the bytes on disk so far, throttled to
  /// about [progressInterval].
  static Future<ModelDownload> start({
    required Uri uri,
    required String target,
    required void Function(int received) onProgress,
    void Function(int? total, int elapsedMs, int resumedFrom)? onHeaders,
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
        case ('headers', final int? total, final int ms, final int from):
          onHeaders?.call(total, ms, from);
        case ('progress', final int received):
          onProgress(received);
        case ('done', final int bytes):
          download._finish(bytes: bytes);
        case ('error', final String reason, final bool transient):
          download._finish(
            error: ModelDownloadException(reason, transient: transient),
          );
      }
    });
    exit.listen((_) {
      // The isolate ended without reporting: killed, or crashed hard.
      download._finish(
        error: download._cancelled
            ? const ModelDownloadCancelled()
            : const ModelDownloadException(
                'download stopped unexpectedly',
                transient: true,
              ),
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

  /// Completes with the model's size once it is in place; fails with
  /// [ModelDownloadException], or [ModelDownloadCancelled] after [cancel].
  Future<int> get done => _done.future;

  /// Stops the download and removes its partial file: unlike a failure, a
  /// cancel means the bytes are not wanted.
  Future<void> cancel() async {
    if (_done.isCompleted) return;
    stop();
    await ModelFiles.deletePart(target);
  }

  /// Stops the download and keeps its partial file for a later resume
  /// (the app shutting down).
  void stop() {
    if (_done.isCompleted) return;
    _cancelled = true;
    _isolate.kill(priority: Isolate.immediate);
    _finish(error: const ModelDownloadCancelled());
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
  const new(this.reason, {this.transient = false});

  /// What went wrong.
  final String reason;

  /// Whether trying again may work: the network, a timeout, a server
  /// error, a connection cut short. The partial file is kept for it.
  final bool transient;

  @override
  String toString() =>
      'ModelDownloadException: $reason${transient ? ' (transient)' : ''}';
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
  final stall = Duration(milliseconds: request.stallMs);
  final clock = Stopwatch()..start();
  final client = HttpClient()..connectionTimeout = stall;
  final part = File('${request.target}${ModelFiles.partSuffix}');
  IOSink? sink;
  try {
    final existing = part.existsSync() ? part.lengthSync() : 0;
    final httpRequest = await client.getUrl(Uri.parse(request.uri));
    if (existing > 0) {
      httpRequest.headers.set(HttpHeaders.rangeHeader, 'bytes=$existing-');
    }
    final response = await httpRequest.close().timeout(stall);
    final status = response.statusCode;
    final int from;
    final int? total;
    if (existing > 0 && status == HttpStatus.partialContent) {
      from = existing;
      total =
          _totalOf(response.headers.value(HttpHeaders.contentRangeHeader)) ??
          (response.contentLength < 0
              ? null
              : existing + response.contentLength);
    } else if (status == HttpStatus.ok) {
      // No range support, or nothing to resume: start over.
      from = 0;
      total = response.contentLength < 0 ? null : response.contentLength;
    } else {
      if (status == HttpStatus.requestedRangeNotSatisfiable) {
        // The partial file does not fit the model any more.
        await part.delete();
      }
      await response.drain<void>();
      port.send((
        'error',
        'HTTP $status',
        status >= 500 ||
            status == HttpStatus.requestTimeout ||
            status == HttpStatus.tooManyRequests ||
            status == HttpStatus.requestedRangeNotSatisfiable,
      ));
      return;
    }
    port.send(('headers', total, clock.elapsedMilliseconds, from));
    await part.parent.create(recursive: true);
    sink = part.openWrite(mode: from > 0 ? FileMode.append : FileMode.write);
    var received = from;
    var lastReport = 0;
    await sink.addStream(
      response
          .timeout(
            stall,
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
    if (total != null && received < total) {
      port.send(('error', 'incomplete: $received of $total bytes', true));
      return;
    }
    if (total != null && received > total) {
      await part.delete();
      port.send(('error', 'too long: $received of $total bytes', true));
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
    // The partial file stays: the next attempt resumes from it. Progress
    // is throttled, so report what actually reached the disk.
    try {
      if (part.existsSync()) port.send(('progress', part.lengthSync()));
    } on FileSystemException {
      // The size is only for the page; the resume reads it again.
    }
    port.send((
      'error',
      _short(error),
      error is SocketException ||
          error is HttpException ||
          error is TimeoutException,
    ));
  } finally {
    client.close(force: true);
  }
}

/// The full size from a `Content-Range: bytes 100-199/1234` header.
int? _totalOf(String? contentRange) {
  if (contentRange == null) return null;
  final slash = contentRange.lastIndexOf('/');
  if (slash < 0) return null;
  return int.tryParse(contentRange.substring(slash + 1).trim());
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
