import 'dart:async';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';

const _log = AppLogger(name: 'isolate');

/// Counts the short-lived isolates in flight (issue #103).
///
/// A sync that stalls mid-run leaves no trace of its own: the step that
/// never finishes logs nothing, and a hung `Isolate.run` looks exactly
/// like one that was never reached. Routing those spawns through here
/// gives a stalled app three things it otherwise has none of — which job
/// was outstanding, how many were running beside it, and (through the
/// overdue warnings) proof that the process was still alive and waiting
/// rather than dead.
///
/// Debug-level while a job behaves; a job that outlives [_firstWarning]
/// warns, so a stall shows up in an exported log without the user having
/// to catch it live.
final class IsolateGauge {
  /// Counters only; no instances.
  const new _();

  /// How many jobs are running right now.
  static int get inFlight => _inFlight;

  /// The most that ever ran at once this session.
  static int get peak => _peak;

  static int _inFlight = 0;
  static int _peak = 0;
  static int _nextId = 0;

  static const Duration _firstWarning = Duration(seconds: 10);
  static const Duration _secondWarning = Duration(seconds: 30);

  /// The long-running jobs in flight, by the ticket [begin] answered.
  static final Map<int, ({String what, Stopwatch clock, List<Timer> overdue})>
  _jobs = <int, ({String what, Stopwatch clock, List<Timer> overdue})>{};

  /// Counts a long-running job in, and answers the ticket that counts it
  /// out ([finishJob]).
  ///
  /// The twin of [run] for work whose conversation with its isolate is more
  /// than one call — a streamed save, so far. The caller spawns and owns
  /// the isolate; this only keeps the count and the overdue warnings
  /// honest, so a job that never finishes still says so in an exported log.
  static int begin(String what) {
    final id = _begin(what);
    _jobs[id] = (
      what: what,
      clock: Stopwatch()..start(),
      overdue: _overdue(id, what),
    );
    return id;
  }

  /// Counts the job [begin] started out, and cancels its warnings.
  static void finishJob(int id, {Object? error}) {
    final job = _jobs.remove(id);
    if (job == null) return;
    _finish(id, job.what, job.clock, job.overdue, error: error);
  }

  /// Runs [job] on a short-lived isolate, counted and logged as [what].
  ///
  /// [what] names the work and its subject (`'replace "Notes/a.md"'`), so
  /// a line that never gets its `done` says which file it was on.
  static Future<T> run<T>(FutureOr<T> Function() job, String what) {
    final id = _begin(what);
    final clock = Stopwatch()..start();
    final overdue = _overdue(id, what);
    return Isolate.run(job).then(
      (value) {
        _finish(id, what, clock, overdue);
        return value;
      },
      onError: (Object error, StackTrace stack) {
        _finish(id, what, clock, overdue, error: error);
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  static int _begin(String what) {
    final id = ++_nextId;
    _inFlight++;
    if (_inFlight > _peak) _peak = _inFlight;
    _log.debug('#$id start: $what (in flight $_inFlight, peak $_peak)');
    return id;
  }

  /// The overdue warnings for a job, cancelled when it finishes.
  static List<Timer> _overdue(int id, String what) => [
    Timer(
      _firstWarning,
      () => _log.warning(
        '#$id still running after ${_firstWarning.inSeconds}s: $what '
        '(in flight $_inFlight)',
      ),
    ),
    Timer(
      _secondWarning,
      () => _log.warning(
        '#$id still running after ${_secondWarning.inSeconds}s: $what '
        '(in flight $_inFlight) — whatever awaits it is still waiting. '
        'A full scan of a large library can legitimately take this long; '
        'a single write or probe cannot.',
      ),
    ),
  ];

  static void _finish(
    int id,
    String what,
    Stopwatch clock,
    List<Timer> overdue, {
    Object? error,
  }) {
    for (final timer in overdue) {
      timer.cancel();
    }
    _inFlight--;
    final ms = clock.elapsedMilliseconds;
    if (error != null) {
      _log.debug('#$id failed: $what ($ms ms, in flight $_inFlight): $error');
      return;
    }
    _log.debug('#$id done: $what ($ms ms, in flight $_inFlight)');
  }
}
