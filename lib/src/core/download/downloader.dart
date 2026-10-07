import 'dart:async';

import 'package:niman/src/core/download/download_files.dart';
import 'package:niman/src/core/download/download_state.dart';
import 'package:niman/src/core/download/downloadable.dart';
import 'package:niman/src/core/download/file_download.dart';
import 'package:niman/src/core/logging.dart';

/// Starts a download; [FileDownload.start] in the app, a fake in tests.
typedef DownloadStarter = Future<FileDownload> Function({
  required Uri uri,
  required String target,
  required void Function(int received) onProgress,
  String? sha256,
  void Function(int? total, int elapsedMs, int resumedFrom)? onHeaders,
});

/// Runs the downloads of a catalog of [Downloadable]s (transcription
/// models, the OCR engine and languages): one per item, retried and
/// resumed.
///
/// A download that loses its connection retries by itself after
/// [retryDelays], resuming from the bytes already on disk: Android
/// freezes an app that leaves the foreground, and the connection rarely
/// survives it. When the retries run out the item is [DownloadFailed] with
/// its partial file kept, and [resumeInterrupted] starts it again.
final class Downloader<T extends Downloadable> {
  /// A downloader writing through [files], reporting through [state] and
  /// [setState], calling [onInstalled] when an item lands; [log] tags its
  /// lines.
  new({
    required this.files,
    required this.state,
    required this.setState,
    required this.onInstalled,
    this.log = const AppLogger(name: 'download'),
    DownloadStarter? start,
    this.retryDelays = defaultRetryDelays,
  }) : _start = start ?? FileDownload.start;

  /// The waits between attempts when none are given.
  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
  ];

  /// Where the files are.
  final DownloadFiles files;

  /// An item's current state.
  final DownloadState Function(T item) state;

  /// Publishes an item's new state.
  final void Function(T item, DownloadState state) setState;

  /// Called once an item is installed.
  final Future<void> Function(T item) onInstalled;

  /// Where the download lines go.
  final AppLogger log;

  /// The waits before each retry of a download that failed transiently.
  final List<Duration> retryDelays;

  final DownloadStarter _start;
  final Map<String, FileDownload> _running = {};
  final Set<String> _cancelled = {};
  bool _closed = false;

  /// Whether [item] has a download attempt running right now.
  bool isRunning(T item) => _running.containsKey(item.id);

  /// Downloads [item], resuming a partial file, retrying on connection
  /// problems.
  Future<void> download(T item) async {
    // Downloading covers the moment the isolate is still spawning: a
    // second tap must not start a second download.
    if (state(item) case Downloading() || Downloaded()) return;
    _cancelled.remove(item.id);
    final clock = Stopwatch()..start();
    final kept = switch (state(item)) {
      DownloadFailed(:final received) => received,
      _ => 0,
    };
    setState(item, Downloading(received: kept, total: item.bytes));
    log.info('download ${item.id}: start ${item.uri}, $kept b on disk');
    for (var attempt = 0; ; attempt++) {
      final failure = await _attempt(item, clock);
      if (failure == null) return;
      if (_cancelled.remove(item.id) || _closed) {
        setState(item, const NotDownloaded());
        return;
      }
      if (!failure.transient || attempt >= retryDelays.length) {
        final received = switch (state(item)) {
          Downloading(:final received) => received,
          _ => 0,
        };
        log.warning(
          'download ${item.id}: gave up after ${attempt + 1} attempts, '
          '${clock.elapsedMilliseconds} ms (${failure.reason}), '
          '${failure.transient ? received : 0} b kept',
        );
        setState(
          item,
          DownloadFailed(
            failure.reason,
            received: failure.transient ? received : 0,
            total: item.bytes,
          ),
        );
        return;
      }
      final wait = retryDelays[attempt];
      log.info(
        'download ${item.id}: attempt ${attempt + 1} failed '
        '(${failure.reason}), retrying in ${wait.inMilliseconds} ms',
      );
      if (state(item) case Downloading(:final received, :final total)) {
        setState(
          item,
          Downloading(received: received, total: total, retrying: true),
        );
      }
      await Future<void>.delayed(wait);
      if (_cancelled.remove(item.id) || _closed) {
        if (!_closed) {
          await DownloadFiles.deletePart(await files.pathOf(item));
        }
        setState(item, const NotDownloaded());
        return;
      }
    }
  }

  /// One attempt; null once the item is installed or the download was
  /// cancelled, the failure otherwise.
  Future<DownloadException?> _attempt(T item, Stopwatch clock) async {
    var total = item.bytes;
    var resumed = 0;
    var nextLog = 10;
    final attemptClock = Stopwatch()..start();
    final FileDownload download;
    try {
      download = await _start(
        uri: item.uri,
        target: await files.pathOf(item),
        sha256: item.sha256,
        onHeaders: (announced, ms, resumedFrom) {
          if (announced != null) total = announced;
          resumed = resumedFrom;
          log.info(
            'download ${item.id}: headers after $ms ms, '
            '${announced ?? 'unknown'} b'
            '${resumedFrom > 0 ? ', resuming from $resumedFrom b' : ''}',
          );
        },
        onProgress: (received) {
          if (state(item) is! Downloading) return;
          setState(item, Downloading(received: received, total: total));
          final percent = total <= 0 ? 0 : received * 100 ~/ total;
          if (percent >= nextLog) {
            log.debug(
              'download ${item.id}: $percent% $received b '
              'at ${clock.elapsedMilliseconds} ms',
            );
            nextLog = (percent ~/ 10 + 1) * 10;
          }
        },
      );
    } on Object catch (error) {
      return DownloadException('could not start: $error');
    }
    _running[item.id] = download;
    try {
      final bytes = await download.done;
      final seconds = attemptClock.elapsedMilliseconds / 1000;
      final fetched = bytes - resumed;
      final speed = seconds == 0
          ? '-'
          : (fetched / 1048576 / seconds).toStringAsFixed(1);
      log.info(
        'download ${item.id}: done, $bytes b in '
        '${clock.elapsedMilliseconds} ms (last attempt $fetched b at '
        '$speed MB/s)',
      );
      setState(item, Downloaded(bytes));
      await onInstalled(item);
      return null;
    } on DownloadCancelled {
      log.info(
        'download ${item.id}: stopped after ${clock.elapsedMilliseconds} ms',
      );
      _cancelled.remove(item.id);
      setState(item, const NotDownloaded());
      return null;
    } on DownloadException catch (error) {
      return error;
    } finally {
      _running.remove(item.id);
    }
  }

  /// Starts again every item in [items] whose download stopped on a
  /// connection problem and kept its bytes.
  Future<void> resumeInterrupted(Iterable<T> items) async {
    final stopped = [
      for (final item in items)
        if (state(item) case DownloadFailed(resumable: true)) item,
    ];
    if (stopped.isEmpty) return;
    log.info('resuming ${stopped.map((m) => m.id).join(', ')}');
    await Future.wait(stopped.map(download));
  }

  /// Stops [item]'s download, also while it waits to retry, and discards
  /// the partial file.
  Future<void> cancel(T item) async {
    switch (state(item)) {
      case Downloading():
        _cancelled.add(item.id);
        await _running[item.id]?.cancel();
      case DownloadFailed(resumable: true):
        await DownloadFiles.deletePart(await files.pathOf(item));
        setState(item, const NotDownloaded());
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
