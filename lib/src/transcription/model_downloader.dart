import 'dart:async';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/transcription/model_download.dart';
import 'package:niman/src/transcription/model_files.dart';
import 'package:niman/src/transcription/model_state.dart';
import 'package:niman/src/transcription/transcription_model.dart';

/// Starts a download; [ModelDownload.start] in the app, a fake in tests.
typedef ModelDownloadStarter = Future<ModelDownload> Function({
  required Uri uri,
  required String target,
  required void Function(int received) onProgress,
  void Function(int? total, int elapsedMs, int resumedFrom)? onHeaders,
});

/// Runs the model downloads of `TranscriptionModels`: one per model,
/// retried and resumed.
///
/// A download that loses its connection retries by itself after
/// [retryDelays], resuming from the bytes already on disk: Android
/// freezes an app that leaves the foreground, and the connection rarely
/// survives it. When the retries run out the model is [ModelFailed] with
/// its partial file kept, and [resumeInterrupted] starts it again.
final class ModelDownloader {
  /// A downloader writing through [files], reporting through [state] and
  /// [setState], calling [onInstalled] when a model lands.
  new({
    required this.files,
    required this.state,
    required this.setState,
    required this.onInstalled,
    ModelDownloadStarter? start,
    this.retryDelays = defaultRetryDelays,
  }) : _start = start ?? ModelDownload.start;

  /// The waits between attempts when none are given.
  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
  ];

  /// Where the model files are.
  final ModelFiles files;

  /// A model's current state.
  final ModelState Function(TranscriptionModel model) state;

  /// Publishes a model's new state.
  final void Function(TranscriptionModel model, ModelState state) setState;

  /// Called once a model is installed.
  final Future<void> Function(TranscriptionModel model) onInstalled;

  /// The waits before each retry of a download that failed transiently.
  final List<Duration> retryDelays;

  final ModelDownloadStarter _start;
  final Map<String, ModelDownload> _running = {};
  final Set<String> _cancelled = {};
  bool _closed = false;

  /// Whether [model] has a download attempt running right now.
  bool isRunning(TranscriptionModel model) => _running.containsKey(model.id);

  /// Downloads [model], resuming a partial file, retrying on connection
  /// problems.
  Future<void> download(TranscriptionModel model) async {
    // Downloading covers the moment the isolate is still spawning: a
    // second tap must not start a second download.
    if (state(model) case ModelDownloading() || ModelInstalled()) return;
    _cancelled.remove(model.id);
    final clock = Stopwatch()..start();
    final kept = switch (state(model)) {
      ModelFailed(:final received) => received,
      _ => 0,
    };
    setState(model, ModelDownloading(received: kept, total: model.bytes));
    _log.info('download ${model.id}: start ${model.uri}, $kept b on disk');
    for (var attempt = 0; ; attempt++) {
      final failure = await _attempt(model, clock);
      if (failure == null) return;
      if (_cancelled.remove(model.id) || _closed) {
        setState(model, const ModelAbsent());
        return;
      }
      if (!failure.transient || attempt >= retryDelays.length) {
        final received = switch (state(model)) {
          ModelDownloading(:final received) => received,
          _ => 0,
        };
        _log.warning(
          'download ${model.id}: gave up after ${attempt + 1} attempts, '
          '${clock.elapsedMilliseconds} ms (${failure.reason}), '
          '${failure.transient ? received : 0} b kept',
        );
        setState(
          model,
          ModelFailed(
            failure.reason,
            received: failure.transient ? received : 0,
            total: model.bytes,
          ),
        );
        return;
      }
      final wait = retryDelays[attempt];
      _log.info(
        'download ${model.id}: attempt ${attempt + 1} failed '
        '(${failure.reason}), retrying in ${wait.inMilliseconds} ms',
      );
      if (state(model) case ModelDownloading(:final received, :final total)) {
        setState(
          model,
          ModelDownloading(received: received, total: total, retrying: true),
        );
      }
      await Future<void>.delayed(wait);
      if (_cancelled.remove(model.id) || _closed) {
        if (!_closed) {
          await ModelFiles.deletePart(await files.pathOf(model));
        }
        setState(model, const ModelAbsent());
        return;
      }
    }
  }

  /// One attempt; null once the model is installed or the download was
  /// cancelled, the failure otherwise.
  Future<ModelDownloadException?> _attempt(
    TranscriptionModel model,
    Stopwatch clock,
  ) async {
    var total = model.bytes;
    var resumed = 0;
    var nextLog = 10;
    final attemptClock = Stopwatch()..start();
    final ModelDownload download;
    try {
      download = await _start(
        uri: model.uri,
        target: await files.pathOf(model),
        onHeaders: (announced, ms, resumedFrom) {
          if (announced != null) total = announced;
          resumed = resumedFrom;
          _log.info(
            'download ${model.id}: headers after $ms ms, '
            '${announced ?? 'unknown'} b'
            '${resumedFrom > 0 ? ', resuming from $resumedFrom b' : ''}',
          );
        },
        onProgress: (received) {
          if (state(model) is! ModelDownloading) return;
          setState(model, ModelDownloading(received: received, total: total));
          final percent = total <= 0 ? 0 : received * 100 ~/ total;
          if (percent >= nextLog) {
            _log.debug(
              'download ${model.id}: $percent% $received b '
              'at ${clock.elapsedMilliseconds} ms',
            );
            nextLog = (percent ~/ 10 + 1) * 10;
          }
        },
      );
    } on Object catch (error) {
      return ModelDownloadException('could not start: $error');
    }
    _running[model.id] = download;
    try {
      final bytes = await download.done;
      final seconds = attemptClock.elapsedMilliseconds / 1000;
      final fetched = bytes - resumed;
      final speed = seconds == 0
          ? '-'
          : (fetched / 1048576 / seconds).toStringAsFixed(1);
      _log.info(
        'download ${model.id}: done, $bytes b in '
        '${clock.elapsedMilliseconds} ms (last attempt $fetched b at '
        '$speed MB/s)',
      );
      setState(model, ModelInstalled(bytes));
      await onInstalled(model);
      return null;
    } on ModelDownloadCancelled {
      _log.info(
        'download ${model.id}: stopped after ${clock.elapsedMilliseconds} ms',
      );
      _cancelled.remove(model.id);
      setState(model, const ModelAbsent());
      return null;
    } on ModelDownloadException catch (error) {
      return error;
    } finally {
      _running.remove(model.id);
    }
  }

  /// Starts again every model in [models] whose download stopped on a
  /// connection problem and kept its bytes.
  Future<void> resumeInterrupted(Iterable<TranscriptionModel> models) async {
    final stopped = [
      for (final model in models)
        if (state(model) case ModelFailed(resumable: true)) model,
    ];
    if (stopped.isEmpty) return;
    _log.info('resuming ${stopped.map((m) => m.id).join(', ')}');
    await Future.wait(stopped.map(download));
  }

  /// Stops [model]'s download, also while it waits to retry, and discards
  /// the partial file.
  Future<void> cancel(TranscriptionModel model) async {
    switch (state(model)) {
      case ModelDownloading():
        _cancelled.add(model.id);
        await _running[model.id]?.cancel();
      case ModelFailed(resumable: true):
        await ModelFiles.deletePart(await files.pathOf(model));
        setState(model, const ModelAbsent());
      case _:
        break;
    }
  }

  /// Stops every download and keeps the partial files for the next
  /// launch.
  void close() {
    _closed = true;
    for (final download in _running.values) {
      download.stop();
    }
    _running.clear();
  }
}

const _log = AppLogger(name: 'transcription');
