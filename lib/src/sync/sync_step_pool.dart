import 'dart:async';

/// How many transfer steps of a sync run go on at once (#1107): enough to
/// hide the round trips between a run's many small files, few enough that a
/// slow link is not asked for more than it has and the connections the
/// client opens stay within what a server tolerates.
const int kSyncTransferConcurrency = 4;

/// Runs the steps of a sync run, a bounded number of the parallel ones at a
/// time (#1107).
///
/// A step is either **parallel** — a transfer of one path, which touches
/// nothing but that path — or not. A parallel step starts as soon as fewer
/// than [concurrency] are running and none of them holds the same
/// [keyOf]; any other step is a **barrier**: it waits until everything in
/// flight has finished, then runs alone, and nothing after it starts before
/// it is done. So the plan's order holds between a transfer and anything
/// else (a delete after uploads runs after all of them), and only transfers
/// reorder among themselves.
///
/// A step that throws is **fatal** for the run: no further step starts,
/// [onFatal] is called once so the others in flight can be cancelled, those
/// finish (or fail), and then [run] throws the first error. A step that
/// handles its own failures — the engine's records a failed path and goes
/// on — never throws.
final class SyncStepPool<T> {
  /// A pool of [concurrency] parallel steps at most. [isParallel] says which
  /// steps may overlap; [keyOf] names what a parallel step works on, and two
  /// steps of one key never overlap; [onFatal] hears the first fatal error
  /// the moment it happens.
  new({
    required this.concurrency,
    required this.isParallel,
    required this.keyOf,
    this.onFatal,
  }) : assert(concurrency >= 1, 'a pool needs at least one slot');

  /// The most parallel steps in flight.
  final int concurrency;

  /// Whether a step may overlap the others.
  final bool Function(T step) isParallel;

  /// What a parallel step works on.
  final Object Function(T step) keyOf;

  /// Called once, with the first fatal error, before the steps in flight are
  /// waited for.
  final void Function(Object error)? onFatal;

  ({Object error, StackTrace stack})? _fatal;

  /// Whether a step has thrown: what is still running is being wound up, and
  /// whatever it fails with is the consequence, not news.
  bool get aborted => _fatal != null;

  /// The most steps that were ever in flight at once, for a test.
  int get peak => _peak;
  int _peak = 0;

  /// Runs every step of [steps] in order with [body]; throws the first fatal
  /// error once everything started has settled.
  Future<void> run(
    Iterable<T> steps,
    Future<void> Function(T step) body,
  ) async {
    final running = <Future<void>>{};
    final keys = <Object>{};

    Future<void> start(T step, Object? key) {
      final task = _guarded(step, body);
      running.add(task);
      if (key != null) keys.add(key);
      if (running.length > _peak) _peak = running.length;
      unawaited(
        task.whenComplete(() {
          running.remove(task);
          if (key != null) keys.remove(key);
        }),
      );
      return task;
    }

    Future<void> settle() async {
      while (running.isNotEmpty) {
        await Future.wait(running.toList());
      }
    }

    for (final step in steps) {
      if (aborted) break;
      if (isParallel(step)) {
        final key = keyOf(step);
        while (!aborted &&
            (running.length >= concurrency || keys.contains(key))) {
          await Future.any(running.toList());
        }
        if (aborted) break;
        unawaited(start(step, key));
      } else {
        await settle();
        if (aborted) break;
        await start(step, null);
      }
    }
    await settle();
    final fatal = _fatal;
    if (fatal != null) Error.throwWithStackTrace(fatal.error, fatal.stack);
  }

  /// [body] on [step], its error kept rather than thrown: the pool stops
  /// starting steps and winds the others up before it reports.
  Future<void> _guarded(T step, Future<void> Function(T step) body) async {
    try {
      await body(step);
    } on Object catch (error, stack) {
      if (_fatal != null) return;
      _fatal = (error: error, stack: stack);
      onFatal?.call(error);
    }
  }
}
