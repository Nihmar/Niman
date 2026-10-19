import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/transfers/direct_write.dart';
import 'package:niman/src/sync/transfers/sync_transfers.dart';
import 'package:niman/src/sync/transfers/transfer_messages.dart';
import 'package:niman/src/sync/transfers/transfer_worker.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_client_config.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';

/// Transfers that run on a worker isolate of their own (#1107): the socket
/// reads, the hash and the file writes of a download, and the file reads of
/// an upload, happen there, so the isolate that renders the app and indexes
/// the library only hears about a transfer when it has finished.
///
/// One worker per sync run, started at the first transfer — a run with
/// nothing to move never spawns it — and shut down by [close]. The worker
/// builds its client from the [WebDavClientConfig], so the certificate the
/// user confirmed (#454) is the only one it accepts, as on the run's own
/// client. A failure crosses as the same `WebDavFailure` subtype, a local
/// one as a [FileSystemException].
final class IsolateSyncTransfers implements SyncTransfers {
  /// Transfers to the destination [_config] describes.
  new(this._config);

  final WebDavClientConfig _config;

  Future<SendPort>? _commands;
  Isolate? _isolate;
  ReceivePort? _events;
  Completer<SendPort>? _ready;
  Completer<void>? _bye;

  final Map<int, Completer<Object?>> _pending = {};
  int _ids = 0;
  bool _cancelled = false;
  bool _closed = false;

  int _sent = 0;
  int _received = 0;
  int _hashed = 0;

  @override
  int get bytesSent => _sent;

  @override
  int get bytesReceived => _received;

  @override
  int get bytesHashed => _hashed;

  @override
  Future<WebDavDownload> download(String path, String tempPath) async =>
      await _call<WebDavDownload>(
        'GET $path',
        (id) => DownloadRequest(id, path, tempPath),
      );

  @override
  Future<NewFileDownload> downloadNew(
    String path,
    String targetPath, {
    required int? listedSize,
    required String? listedEtag,
    int memoryLimit = kSyncDirectWriteMaxBytes,
  }) async => await _call<NewFileDownload>(
    'GET $path',
    (id) => DownloadNewRequest(
      id,
      path,
      targetPath,
      listedSize: listedSize,
      listedEtag: listedEtag,
      memoryLimit: memoryLimit,
    ),
  );

  @override
  Future<String> hashRemote(String path) async =>
      await _call<String>('GET $path', (id) => HashRequest(id, path));

  @override
  Future<WebDavUpload> upload(
    String path,
    String filePath, {
    String? ifMatch,
    bool ifNoneMatch = false,
    DateTime? modified,
  }) async => await _call<WebDavUpload>(
    'PUT $path',
    (id) => UploadRequest(
      id,
      path,
      filePath,
      ifMatch: ifMatch,
      ifNoneMatch: ifNoneMatch,
      modified: modified,
    ),
  );

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    // The worker aborts what it is serving; a transfer waiting for the
    // worker to start is refused as soon as it does.
    final commands = _commands;
    if (commands == null) return;
    unawaited(
      commands
          .then((port) => port.send(const TransferCancel()))
          .catchError((Object _) {}),
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final starting = _commands;
    if (starting == null) return;
    final SendPort commands;
    try {
      commands = await starting;
    } on Object {
      _release();
      return;
    }
    final bye = _bye = Completer<void>();
    commands.send(const TransferShutdown());
    // The worker answers what it was serving first, then says goodbye with
    // its counters; one that never does is killed.
    await bye.future.timeout(const Duration(seconds: 10), onTimeout: () {});
    _release();
  }

  Future<T> _call<T>(
    String what,
    TransferRequest Function(int id) request,
  ) async {
    if (_cancelled || _closed) {
      throw WebDavRetryable('$what: the run stopped');
    }
    final SendPort commands;
    try {
      commands = await (_commands ??= _spawn());
    } on Object catch (e) {
      throw WebDavRetryable('$what: the transfer worker did not start ($e)');
    }
    if (_cancelled || _closed) {
      throw WebDavRetryable('$what: the run stopped');
    }
    final id = ++_ids;
    final answer = _pending[id] = Completer<Object?>();
    commands.send(request(id));
    return await answer.future as T;
  }

  Future<SendPort> _spawn() async {
    final events = _events = ReceivePort();
    final ready = _ready = Completer<SendPort>();
    // Failed with nobody waiting on it yet (a spawn that did not work) is
    // not an uncaught error; whoever does wait still hears it.
    ready.future.ignore();
    events.listen(_onMessage);
    try {
      _isolate = await Isolate.spawn(
        transferWorkerMain,
        TransferWorkerStart(_config, events.sendPort),
        onExit: events.sendPort,
        onError: events.sendPort,
        debugName: 'sync-transfers',
      );
    } on Object {
      _release();
      rethrow;
    }
    return await ready.future;
  }

  void _onMessage(Object? message) {
    switch (message) {
      case SendPort():
        final ready = _ready;
        if (ready != null && !ready.isCompleted) ready.complete(message);
      case TransferReply():
        _count(message.sent, message.received, message.hashed);
        final answer = _pending.remove(message.id);
        final failure = message.failure;
        if (answer == null) return;
        if (failure == null) {
          answer.complete(message.result);
        } else {
          answer.completeError(_failureOf(failure));
        }
      case TransferLog():
        AppLog.record(message.severity, message.name, message.message);
      case TransferBye():
        _count(message.sent, message.received, message.hashed);
        final bye = _bye;
        if (bye != null && !bye.isCompleted) bye.complete();
      case null:
        // The worker's isolate ended: whatever it still owed is lost.
        _failPending(const WebDavRetryable('the transfer worker stopped'));
        final bye = _bye;
        if (bye != null && !bye.isCompleted) bye.complete();
      case List():
        // An error nothing caught in the worker: it ends there, and the
        // exit that follows settles the requests.
        AppLog.record(
          LogSeverity.error,
          'sync',
          'transfer worker failed: ${message.first}',
        );
    }
  }

  /// The counters only grow; the latest message carries the most.
  void _count(int sent, int received, int hashed) {
    if (sent > _sent) _sent = sent;
    if (received > _received) _received = received;
    if (hashed > _hashed) _hashed = hashed;
  }

  /// The exception the worker's [failure] stands for.
  static Object _failureOf(Object failure) => switch (failure) {
    WebDavFailure() => failure,
    TransferLocalFailure() => failure.toException(),
    TransferCrash() => StateError('transfer worker: ${failure.text}'),
    _ => StateError('transfer worker: $failure'),
  };

  void _failPending(Object error) {
    final waiting = _pending.values.toList();
    _pending.clear();
    for (final answer in waiting) {
      answer.completeError(error);
    }
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.completeError(error);
  }

  /// Ends the worker, however it is doing, and the port that listens to it.
  void _release() {
    _failPending(const WebDavRetryable('the transfer worker stopped'));
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _events?.close();
    _events = null;
  }
}
