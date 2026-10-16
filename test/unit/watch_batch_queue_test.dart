// #1062: the watcher's batches run one at a time, and the ones that arrive
// while one runs are folded into a single pending batch.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/file_watcher.dart';
import 'package:niman/src/library/watch_batch_queue.dart';

void main() {
  WatchBatch batch(
    List<String> paths, {
    List<String> dirs = const [],
    bool missed = false,
  }) => WatchBatch(paths: paths, resyncDirs: dirs, missedChanges: missed);

  test('a batch merged with a later one holds each path once', () {
    final merged = batch(
      ['a', 'b'],
      dirs: ['d'],
    ).mergedWith(batch(['b', 'c'], dirs: ['d', 'e'], missed: true));

    expect(merged.paths, ['a', 'b', 'c']);
    expect(merged.resyncDirs, ['d', 'e']);
    expect(merged.missedChanges, isTrue);
  });

  test('batches arriving during a slow batch merge into one', () {
    fakeAsync((async) {
      final seen = <WatchBatch>[];
      var inFlight = 0;
      var peak = 0;
      final queue = WatchBatchQueue((b) async {
        seen.add(b);
        inFlight++;
        if (inFlight > peak) peak = inFlight;
        await Future<void>.delayed(const Duration(seconds: 10));
        inFlight--;
      });

      var done = 0;
      unawaited(queue.add(batch(['first'])).then((_) => done++));
      // Twenty more arrive, 250 ms apart, while the first one runs.
      for (var i = 0; i < 20; i++) {
        async.elapse(const Duration(milliseconds: 250));
        unawaited(queue.add(batch(['p$i', 'shared'])).then((_) => done++));
      }
      expect(queue.processed, 1, reason: 'the others wait behind the first');

      async.elapse(const Duration(seconds: 30));
      expect(queue.processed, 2, reason: 'one merged batch, not twenty');
      expect(seen.last.paths, hasLength(21)); // p0..p19 and shared, once
      expect(peak, 1);
      expect(done, 21);
      expect(queue.running, isFalse);
    });
  });

  test('a batch that fails does not stop the one behind it', () {
    fakeAsync((async) {
      var calls = 0;
      final queue = WatchBatchQueue((b) async {
        calls++;
        await Future<void>.delayed(const Duration(seconds: 1));
        if (calls == 1) throw StateError('transient');
      });

      unawaited(queue.add(batch(['one'])));
      unawaited(queue.add(batch(['two'])));
      async.elapse(const Duration(seconds: 5));

      expect(calls, 2);
    });
  });

  test('closing drops the waiting batch', () {
    fakeAsync((async) {
      final seen = <WatchBatch>[];
      final queue = WatchBatchQueue((b) async {
        seen.add(b);
        await Future<void>.delayed(const Duration(seconds: 1));
      });

      unawaited(queue.add(batch(['one'])));
      unawaited(queue.add(batch(['two'])));
      queue.close();
      async.elapse(const Duration(seconds: 5));

      expect(seen, hasLength(1));
    });
  });
}
