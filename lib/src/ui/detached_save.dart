import 'dart:async';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// A save whose note has left the editor — switched away from, or its tab
/// closed — and that the app still owes the disk (#1061, #1054).
///
/// The note's own registration with the [UnsavedTracker] ends with its view,
/// and a note read as clean the moment another one loads over its buffer. The
/// write that is still running (seconds, for a very long note) is held here
/// instead, so the close guard waits for it, and a write that **failed** keeps
/// the text: it stays registered as unsaved, with its text, until a retry
/// lands — the outgoing note's text is never dropped for a disk that was full
/// for a moment.
final class DetachedSave implements UnsavedNote {
  /// Owes the disk [text] for the note at [path], written by [write]; [text]
  /// is the note as the editor held it. [onWritten] hears of the write that
  /// landed, after which the save is no longer owed.
  new({
    required this.path,
    required this.textOf,
    required this.write,
    this.onWritten,
    this.retryDelays = defaultRetryDelays,
  });

  static const AppLogger _log = AppLogger(name: 'unsaved');

  /// How long a failed write waits before it is tried again, then again.
  static const List<Duration> defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
  ];

  @override
  final String path;

  /// Called once the write has landed.
  final void Function(DetachedSave save)? onWritten;

  /// The waits between a failed write and its automatic retries.
  final List<Duration> retryDelays;

  /// The note's text as the editor held it.
  final String Function() textOf;

  /// Writes the note; called again for each retry.
  final Future<void> Function() write;

  Future<void>? _running;
  Timer? _retry;
  int _failures = 0;
  bool _written = false;

  /// Whether the write has failed since it last landed — what is left of the
  /// note is in memory only.
  bool get failed => _failures > 0 && _running == null && !_written;

  @override
  bool get unsaved => !_written;

  @override
  String get text => textOf();

  /// Starts the write; completes when it lands, or with its error.
  Future<void> start() => _attempt();

  /// The write running, or one more attempt when none is: what the close
  /// guard awaits.
  @override
  Future<void> save() => _running ?? _attempt();

  Future<void> _attempt() {
    _retry?.cancel();
    final run = write().then<void>(
      (_) {
        _written = true;
        _log.info('outgoing save landed: $path');
        onWritten?.call(this);
      },
      onError: (Object error, StackTrace stack) {
        _failures++;
        _log.warning('outgoing save failed: $path ($error)');
        if (_failures <= retryDelays.length) {
          _retry = Timer(retryDelays[_failures - 1], () {
            if (!_written && _running == null) unawaited(_quiet(_attempt()));
          });
        }
        Error.throwWithStackTrace(error, stack);
      },
    );
    final tracked = _running = run;
    unawaited(
      _quiet(run).whenComplete(() {
        if (identical(_running, tracked)) _running = null;
      }),
    );
    return run;
  }

  /// [run] with its error taken: the one who asked has theirs, and the retry
  /// timer has nobody to tell.
  Future<void> _quiet(Future<void> run) =>
      run.then<void>((_) {}, onError: (_) {});

  /// Stops the retries; the save stays owed.
  void cancelRetries() => _retry?.cancel();
}
