import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/transfers/transfer_messages.dart';
import 'package:niman/src/sync/transfers/transfer_ops.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';

/// The entry point of a sync run's transfer worker isolate (#1107): builds
/// the worker's own [WebDavClient], hands the run its command port, and
/// serves [TransferRequest]s until told to shut down.
///
/// Top-level so `Isolate.spawn` can take it.
void transferWorkerMain(TransferWorkerStart start) {
  final commands = ReceivePort();
  AppLog.forwardTo = (severity, name, message) =>
      start.events.send(TransferLog(severity, name, message));
  final worker = _TransferWorker(start.config.build(), start.events, commands);
  commands.listen(worker.handle);
  start.events.send(commands.sendPort);
}

/// One worker's state: its client and the requests it is serving.
final class _TransferWorker {
  new(this._client, this._events, this._commands);

  final WebDavClient _client;
  final SendPort _events;
  final ReceivePort _commands;

  final Set<Future<void>> _serving = {};
  bool _stopped = false;

  void handle(Object? message) {
    switch (message) {
      case TransferRequest():
        final serving = _serve(message);
        _serving.add(serving);
        unawaited(serving.whenComplete(() => _serving.remove(serving)));
      case TransferCancel():
        _stop();
      case TransferShutdown():
        unawaited(_shutDown());
    }
  }

  /// Aborts what is in flight, the connections included: a request that
  /// meets a closed client fails as a retryable transfer, and the download
  /// that was writing a temp removes it.
  void _stop() {
    if (_stopped) return;
    _stopped = true;
    _client.close();
  }

  Future<void> _shutDown() async {
    _stop();
    // Every answer goes out before the last word, so the counters in it are
    // the whole of what this worker moved.
    await Future.wait(_serving.toList());
    _events.send(
      TransferBye(
        sent: _client.bytesSent,
        received: _client.bytesReceived,
        hashed: _client.bytesHashed,
      ),
    );
    _commands.close();
  }

  Future<void> _serve(TransferRequest request) async {
    Object? result;
    Object? failure;
    if (_stopped) {
      failure = WebDavRetryable('${request.what}: the run stopped');
    } else {
      try {
        result = switch (request) {
          DownloadRequest() => await downloadToFile(
            _client,
            request.path,
            request.tempPath,
          ),
          HashRequest() => await hashRemoteFile(_client, request.path),
          UploadRequest() => await uploadFromFile(
            _client,
            request.path,
            request.filePath,
            ifMatch: request.ifMatch,
            ifNoneMatch: request.ifNoneMatch,
            modified: request.modified,
          ),
        };
      } on WebDavFailure catch (e) {
        failure = e;
      } on FileSystemException catch (e) {
        failure = TransferLocalFailure(e);
      } on Object catch (e, stack) {
        failure = TransferCrash('${request.what}: $e\n$stack');
      }
    }
    _events.send(
      TransferReply(
        request.id,
        result: result,
        failure: failure,
        sent: _client.bytesSent,
        received: _client.bytesReceived,
        hashed: _client.bytesHashed,
      ),
    );
  }
}
