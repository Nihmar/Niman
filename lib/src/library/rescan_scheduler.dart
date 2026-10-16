import 'dart:async';

import 'package:meta/meta.dart';

/// When the open library is walked whole, and never twice at once (#1067).
///
/// The watcher carries the live changes; the full walk is the net under it
/// (a missed event, a network mount, a background isolate that wrote a
/// file). A net that costs a stat per file has to be paid for in time the
/// library can spare, so:
///
/// - **One scan in flight.** A request that arrives while one runs does not
///   queue a scan behind each caller: the requests share one follow-up,
///   started when the running scan ends.
/// - **Scheduled after the last scan ended, not on a fixed beat.** The next
///   periodic scan waits [durationFactor] times the last one's duration (a
///   scan that takes six minutes on a phone is not started again after
///   five), and at least [minInterval] — stretched by [healthyStretch] while
///   [watcherHealthy] says the watch is up and has said nothing was missed.
/// - **Not while nobody is looking.** The timer is off while the app is in
///   the background or its window hidden; coming back runs the scan that
///   fell due meanwhile.
///
/// Explicit triggers — the watcher's `missedChanges`, the manual rescan, the
/// first index's content pass — go through [run] and do not wait for the
/// timer.
final class RescanScheduler {
  /// A scheduler around [scan], the walk itself.
  ///
  /// [onPeriodicError] receives a failure of a scan the timer started (a
  /// caller of [run] gets its own); [now] is injected in tests that run on a
  /// fake clock.
  new({
    required this.scan,
    required this.minInterval,
    this.watcherHealthy,
    this.onPeriodicError,
    this.healthyStretch = defaultHealthyStretch,
    this.durationFactor = defaultDurationFactor,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Times [minInterval] the wait grows to while the watcher is healthy.
  static const defaultHealthyStretch = 3;

  /// How many times a scan's own duration the next one waits.
  static const defaultDurationFactor = 10;

  /// The walk.
  final Future<void> Function() scan;

  /// The shortest wait between two periodic scans.
  final Duration minInterval;

  /// Whether the watch is up and has reported no gap since the last scan;
  /// null counts as never.
  final bool Function()? watcherHealthy;

  /// Called with the failure of a scan the timer started.
  final void Function(Object error, StackTrace stack)? onPeriodicError;

  /// See [defaultHealthyStretch].
  final int healthyStretch;

  /// See [defaultDurationFactor].
  final int durationFactor;

  final DateTime Function() _now;

  Timer? _timer;
  bool _running = false;
  bool _closed = false;
  bool _foreground = true;
  Completer<void>? _followUp;
  DateTime? _lastEnd;
  Duration _lastDuration = Duration.zero;
  int _scans = 0;

  /// How many scans have run, periodic and requested together.
  @visibleForTesting
  int get scans => _scans;

  /// Whether a scan is running now.
  bool get running => _running;

  /// How long after the last scan the next periodic one is due.
  Duration get interval {
    final floor = (watcherHealthy?.call() ?? false)
        ? minInterval * healthyStretch
        : minInterval;
    final byDuration = _lastDuration * durationFactor;
    return byDuration > floor ? byDuration : floor;
  }

  /// Starts the periodic scans, the first one [interval] from now.
  void start() {
    _lastEnd = _now();
    _arm(interval);
  }

  /// Stops the timer. A scan already running finishes; no other starts.
  void stop() {
    _closed = true;
    _timer?.cancel();
    _timer = null;
    final waiting = _followUp;
    _followUp = null;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }

  /// The app went to the background (or its window was hidden), or came
  /// back.
  void setForeground({required bool foreground}) {
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (_closed) return;
    if (!foreground) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_running) return;
    final last = _lastEnd;
    final due = last == null
        ? Duration.zero
        : interval - _now().difference(last);
    _arm(due.isNegative ? Duration.zero : due);
  }

  /// Walks the library now, or — when a walk is already running — once more
  /// when it ends, the same walk for every caller waiting. Completes when
  /// that walk has; a failure of it is thrown to the callers.
  Future<void> run() {
    if (_closed) return Future<void>.value();
    if (_running) return (_followUp ??= Completer<void>()).future;
    return _once();
  }

  void _arm(Duration after) {
    _timer?.cancel();
    _timer = null;
    if (_closed || !_foreground || _running) return;
    _timer = Timer(after, _tick);
  }

  void _tick() {
    _timer = null;
    if (_closed || !_foreground || _running) return;
    unawaited(
      _once().then<void>(
        (_) {},
        onError: (Object error, StackTrace stack) =>
            onPeriodicError?.call(error, stack),
      ),
    );
  }

  Future<void> _once() async {
    _running = true;
    _scans++;
    _timer?.cancel();
    _timer = null;
    final started = _now();
    try {
      await scan();
    } finally {
      _lastEnd = _now();
      _lastDuration = _lastEnd!.difference(started);
      _running = false;
      final waiting = _followUp;
      _followUp = null;
      if (waiting != null && !_closed) {
        unawaited(
          _once().then<void>(waiting.complete, onError: waiting.completeError),
        );
      } else {
        if (waiting != null) waiting.complete();
        _arm(interval);
      }
    }
  }
}
