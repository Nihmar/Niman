import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/transfers/direct_write.dart';
import 'package:niman/src/sync/webdav/webdav_client_config.dart';

// The messages between a sync run and its transfer worker isolate (#1107).
// Everything here is plain data — strings, numbers, dates, the
// `WebDavDownload` / `WebDavUpload` results and the `WebDavFailure`
// subtypes, which hold nothing but those — so it crosses an isolate and
// arrives as the same type it left as.

/// What the worker isolate starts from.
@immutable
final class TransferWorkerStart {
  /// A worker that builds its client from [config] and answers on [events].
  const new(this.config, this.events);

  /// The destination, to build the worker's own client from.
  final WebDavClientConfig config;

  /// Where the worker sends its command port first, then its replies.
  final SendPort events;
}

/// A request to the worker, answered by a [TransferReply] with the same
/// [id].
@immutable
sealed class TransferRequest {
  /// A request numbered [id].
  const new(this.id);

  /// Pairs the reply with the request.
  final int id;

  /// A line for the failure that says what the request was.
  String get what;
}

/// `GET` [path] into the file at [tempPath].
final class DownloadRequest extends TransferRequest {
  /// See [TransferRequest.new].
  const new(super.id, this.path, this.tempPath);

  /// The remote path.
  final String path;

  /// The file the body is written to.
  final String tempPath;

  @override
  String get what => 'GET $path';
}

/// `GET` [path] into [targetPath], a file that must not exist yet, with no
/// temp file and no rename (`downloadNewFile`).
final class DownloadNewRequest extends TransferRequest {
  /// See [TransferRequest.new].
  const new(
    super.id,
    this.path,
    this.targetPath, {
    required this.listedSize,
    required this.listedEtag,
    required this.memoryLimit,
  });

  /// The remote path.
  final String path;

  /// The file created and written, under its final name.
  final String targetPath;

  /// The size the listing gave, or null when it gave none.
  final int? listedSize;

  /// The ETag the listing gave, or null.
  final String? listedEtag;

  /// The largest body written from memory.
  final int memoryLimit;

  @override
  String get what => 'GET $path';
}

/// `GET` [path] only for its sha256.
final class HashRequest extends TransferRequest {
  /// See [TransferRequest.new].
  const new(super.id, this.path);

  /// The remote path.
  final String path;

  @override
  String get what => 'GET $path';
}

/// `PUT` the file at [filePath] to [path].
final class UploadRequest extends TransferRequest {
  /// See [TransferRequest.new].
  const new(
    super.id,
    this.path,
    this.filePath, {
    this.ifMatch,
    this.ifNoneMatch = false,
    this.modified,
  });

  /// The remote path.
  final String path;

  /// The local file sent.
  final String filePath;

  /// The `If-Match` to send.
  final String? ifMatch;

  /// Whether to send `If-None-Match: *`.
  final bool ifNoneMatch;

  /// The `X-OC-Mtime` to send.
  final DateTime? modified;

  @override
  String get what => 'PUT $path';
}

/// Abort every request in flight; later ones fail at once.
final class TransferCancel {
  /// The one cancel message.
  const new();
}

/// Finish the requests in flight, answer [TransferBye] and stop.
final class TransferShutdown {
  /// The one shutdown message.
  const new();
}

/// The answer to a [TransferRequest]: its [result], or the [failure] it
/// ended in; either way the worker's byte counters as they stood.
@immutable
final class TransferReply {
  /// The answer to request [id].
  const new(
    this.id, {
    required this.sent,
    required this.received,
    required this.hashed,
    this.result,
    this.failure,
  });

  /// The request answered.
  final int id;

  /// The `WebDavDownload`, the `NewFileDownload`, the sha256 string or the
  /// `WebDavUpload`, by the request.
  final Object? result;

  /// Why it failed: a `WebDavFailure`, a [TransferLocalFailure] or a
  /// [TransferCrash]; null when it did not.
  final Object? failure;

  /// Body bytes the worker's client has sent so far.
  final int sent;

  /// Body bytes the worker's client has received and kept so far.
  final int received;

  /// Body bytes the worker's client has downloaded only to hash, so far.
  final int hashed;
}

/// The worker is done: its final byte counters.
@immutable
final class TransferBye {
  /// The final counters.
  const new({required this.sent, required this.received, required this.hashed});

  /// Body bytes sent over the worker's life.
  final int sent;

  /// Body bytes received and kept over the worker's life.
  final int received;

  /// Body bytes downloaded only to hash, over the worker's life.
  final int hashed;
}

/// One log event of the worker, for the isolate that owns the log.
@immutable
final class TransferLog {
  /// An event of [severity] from the logger [name].
  const new(this.severity, this.name, this.message);

  /// How serious.
  final LogSeverity severity;

  /// The logger's name.
  final String name;

  /// The line.
  final String message;
}

/// A [FileSystemException] as data: the exception itself carries an
/// `OSError`, which the worker rebuilds here from its parts.
@immutable
final class TransferLocalFailure {
  /// Describes [error].
  new(FileSystemException error)
    : message = error.message,
      path = error.path,
      osMessage = error.osError?.message,
      osCode = error.osError?.errorCode,
      refused = error is DirectWriteRefused;

  /// The exception's message.
  final String message;

  /// The path it names.
  final String? path;

  /// The OS error's message, when there was one.
  final String? osMessage;

  /// The OS error's code, when there was one.
  final int? osCode;

  /// Whether it was a [DirectWriteRefused]: the file the download meant to
  /// create was somebody else's, which the run must not take for its own.
  final bool refused;

  /// The exception again, on the receiving side.
  FileSystemException toException() {
    final os = osMessage == null
        ? null
        : OSError(osMessage!, osCode ?? OSError.noErrorCode);
    return refused
        ? DirectWriteRefused(path ?? '', os)
        : FileSystemException(message, path, os);
  }
}

/// An error the worker did not expect, as text: a bug, not a failed
/// transfer.
@immutable
final class TransferCrash {
  /// Describes [text].
  const new(this.text);

  /// What was thrown, and where.
  final String text;
}
