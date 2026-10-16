import 'dart:async';

import 'package:niman/src/library/file_watcher.dart';

/// Runs the watcher's batches one at a time, folding the ones that arrive
/// meanwhile into a single pending batch (#1062).
///
/// The watcher ships a batch every 250 ms while changes keep coming, and a
/// batch is index work that can outlast that by far (a probe, a read, a
/// write per path). Handed straight to the index each would queue behind
/// the last one holding the lock, each repeating the work the others
/// already asked for. Here at most one is running and one is waiting, and
/// the waiting one is the union of everything that arrived: a path changed
/// three times is applied once.
final class WatchBatchQueue {
  /// A queue running its batches through the given processor.
  new(this._process);

  final Future<void> Function(WatchBatch batch) _process;

  WatchBatch? _pending;
  bool _running = false;
  bool _closed = false;

  /// How many batches the processor has been called with.
  int processed = 0;

  /// Whether a batch is being processed now.
  bool get running => _running;

  /// Hands [batch] over. Completes when the batch it ends up in has been
  /// processed — this one, or the merged one it joined.
  Future<void> add(WatchBatch batch) {
    if (_closed) return Future<void>.value();
    final waiting = _pending;
    _pending = waiting == null ? batch : waiting.mergedWith(batch);
    if (_running) return _idle().future;
    return _drain();
  }

  /// Drops what is waiting and takes no more. A batch already running
  /// finishes.
  void close() {
    _closed = true;
    _pending = null;
    _complete();
  }

  final List<Completer<void>> _waiters = [];

  Completer<void> _idle() {
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter;
  }

  void _complete() {
    final waiters = List.of(_waiters);
    _waiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  Future<void> _drain() async {
    _running = true;
    try {
      while (!_closed) {
        final next = _pending;
        if (next == null) break;
        _pending = null;
        processed++;
        // A batch that fails is the next rescan's to repair; the queue
        // goes on with the one behind it.
        try {
          await _process(next);
        } on Object {
          // The processor logs its own failures.
        }
      }
    } finally {
      _running = false;
      _complete();
    }
  }
}
