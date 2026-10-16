// #1067: the full rescan runs one at a time, paced by how long the last took,
// stretched while the watch is healthy, and not while nobody looks.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/rescan_scheduler.dart';

void main() {
  final epoch = DateTime(2026);
  const five = Duration(minutes: 5);

  /// A scheduler over a scan that takes [length] of fake time and counts
  /// its starts and how many were ever in flight together.
  ({RescanScheduler scheduler, List<int> peak, List<int> starts}) build(
    FakeAsync async, {
    required Duration length,
    bool Function()? healthy,
    void Function(Object, StackTrace)? onError,
    Error? failWith,
  }) {
    final starts = [0];
    final peak = [0];
    var inFlight = 0;
    final scheduler = RescanScheduler(
      scan: () async {
        starts[0]++;
        inFlight++;
        if (inFlight > peak[0]) peak[0] = inFlight;
        await Future<void>.delayed(length);
        inFlight--;
        if (failWith != null) throw failWith;
      },
      minInterval: five,
      watcherHealthy: healthy,
      onPeriodicError: onError,
      now: () => epoch.add(async.elapsed),
    );
    return (scheduler: scheduler, peak: peak, starts: starts);
  }

  test('ticks during a slow scan leave one in flight and none queued', () {
    fakeAsync((async) {
      final t = build(async, length: const Duration(minutes: 60));
      t.scheduler.start();

      async.elapse(five); // the first periodic scan starts
      expect(t.starts[0], 1);
      // Ten more minutes' worth of beats, as the old fixed timer saw them.
      async.elapse(const Duration(minutes: 50));
      expect(t.starts[0], 1);
      expect(t.scheduler.running, isTrue);

      async.elapse(const Duration(minutes: 10)); // it ends
      expect(t.scheduler.running, isFalse);
      // The next one waits ten times the last one's length, not five minutes.
      async.elapse(const Duration(minutes: 599));
      expect(t.starts[0], 1);
      async.elapse(const Duration(minutes: 2));
      expect(t.starts[0], 2);
      expect(t.peak[0], 1);
      t.scheduler.stop();
    });
  });

  test('the wait follows the last scan, with the minimum as its floor', () {
    fakeAsync((async) {
      final t = build(async, length: const Duration(seconds: 10));
      t.scheduler.start();
      expect(t.scheduler.interval, five);

      async.elapse(five + const Duration(seconds: 10));
      expect(t.starts[0], 1);
      // Ten seconds' scan: ten times is a minute and a half, under the floor.
      expect(t.scheduler.interval, five);
      async.elapse(five);
      expect(t.starts[0], 2);
      t.scheduler.stop();
    });
  });

  test('a healthy watch stretches the wait', () {
    fakeAsync((async) {
      var healthy = true;
      final t = build(
        async,
        length: const Duration(seconds: 1),
        healthy: () => healthy,
      );
      t.scheduler.start();
      expect(t.scheduler.interval, five * 3);

      async.elapse(five * 3 - const Duration(seconds: 1));
      expect(t.starts[0], 0, reason: 'not at the minimum interval');
      async.elapse(const Duration(seconds: 2));
      expect(t.starts[0], 1);

      healthy = false;
      expect(t.scheduler.interval, five);
      t.scheduler.stop();
    });
  });

  test('no periodic scan runs while the app is in the background', () {
    fakeAsync((async) {
      final t = build(async, length: const Duration(seconds: 1));
      t.scheduler.start();

      t.scheduler.setForeground(foreground: false);
      async.elapse(const Duration(hours: 3));
      expect(t.starts[0], 0);

      // Back after the scan fell due: it runs at once.
      t.scheduler.setForeground(foreground: true);
      async.elapse(const Duration(milliseconds: 1));
      expect(t.starts[0], 1);
      t.scheduler.stop();
    });
  });

  test('coming back before the scan is due waits for the rest', () {
    fakeAsync((async) {
      final t = build(async, length: const Duration(seconds: 1));
      t.scheduler.start();
      async.elapse(const Duration(minutes: 2));
      t.scheduler.setForeground(foreground: false);
      async.elapse(const Duration(minutes: 1));
      t.scheduler.setForeground(foreground: true);

      async.elapse(const Duration(minutes: 1, seconds: 59));
      expect(t.starts[0], 0);
      async.elapse(const Duration(seconds: 2));
      expect(t.starts[0], 1);
      t.scheduler.stop();
    });
  });

  test('requests during a scan share one follow-up', () {
    fakeAsync((async) {
      final t = build(async, length: const Duration(minutes: 1));
      t.scheduler.start();

      final all = [for (var i = 0; i < 10; i++) t.scheduler.run()];
      var done = 0;
      for (final future in all) {
        unawaited(future.then((_) => done++));
      }
      async.elapse(const Duration(minutes: 1));
      expect(done, 1, reason: 'only the caller of the first scan is done');
      async.elapse(const Duration(minutes: 1));
      expect(done, 10);
      expect(t.starts[0], 2);
      expect(t.peak[0], 1);
      t.scheduler.stop();
    });
  });

  test('a failed periodic scan is reported and the next one still comes', () {
    fakeAsync((async) {
      final errors = <Object>[];
      final t = build(
        async,
        length: const Duration(seconds: 1),
        onError: (e, _) => errors.add(e),
        failWith: StateError('gone'),
      );
      t.scheduler.start();

      async.elapse(five + const Duration(seconds: 1));
      expect(errors, hasLength(1));
      async.elapse(five + const Duration(seconds: 1));
      expect(t.starts[0], 2);
      t.scheduler.stop();
    });
  });

  test('a requested scan hands its failure to the caller', () {
    fakeAsync((async) {
      final t = build(
        async,
        length: const Duration(seconds: 1),
        failWith: StateError('gone'),
      );
      Object? caught;
      unawaited(
        t.scheduler.run().then((_) {}, onError: (Object e) => caught = e),
      );
      async.elapse(const Duration(seconds: 2));
      expect(caught, isA<StateError>());
      t.scheduler.stop();
    });
  });

  test('stop ends the timer', () {
    fakeAsync((async) {
      final t = build(async, length: const Duration(seconds: 1));
      t.scheduler.start();
      t.scheduler.stop();
      async.elapse(const Duration(hours: 5));
      expect(t.starts[0], 0);
    });
  });
}
