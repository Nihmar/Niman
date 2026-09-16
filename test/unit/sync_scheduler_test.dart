import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/sync/network_monitor.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_engine.dart';
import 'package:niman/src/sync/sync_scheduler.dart';

final class _Network implements NetworkMonitor {
  SyncNetwork now = SyncNetwork.unmetered;
  final StreamController<SyncNetwork> _changes =
      StreamController<SyncNetwork>.broadcast();

  void change(SyncNetwork next) {
    now = next;
    _changes.add(next);
  }

  @override
  Future<SyncNetwork> current() async => now;

  @override
  Stream<SyncNetwork> get changes => _changes.stream;
}

/// A scheduler over scripted runs, driven by fake time.
final class _Harness {
  new(this.async, {bool phone = false}) {
    scheduler = SyncScheduler(
      run: ({required quick}) async {
        runs.add('${quick ? 'quick' : 'full'} @${async.elapsed.inSeconds}');
        final wait = runTakes;
        if (wait != null) await Future<void>.delayed(wait);
        due = false; // the run settled what was queued
        return (reports.isEmpty ? SyncReport.new : reports.removeAt(0))()
          ..quick = quick;
      },
      triggers: () async => triggers,
      hasDueHints: () async => due,
      retryNow: () async => retries++,
      network: network,
      phone: phone,
      now: () => DateTime(2026, 9, 15).add(async.elapsed),
    );
  }

  final FakeAsync async;
  late final SyncScheduler scheduler;
  final network = _Network();
  SyncTriggers? triggers = const SyncTriggers();
  bool due = false;
  int retries = 0;
  Duration? runTakes;
  final List<String> runs = [];
  final List<SyncReport Function()> reports = [];

  void start() {
    unawaited(scheduler.start());
    async.flushMicrotasks();
  }

  void elapse(int seconds) => async.elapse(Duration(seconds: seconds));
}

SyncReport _aborted(SyncAbort why, {Duration? retryAfter}) => SyncReport()
  ..aborted = why
  ..abortDetail = why.name
  ..retryAfter = retryAfter;

void main() {
  test('opening the library makes a full sync', () {
    fakeAsync((async) {
      final h = _Harness(async)..start();
      expect(h.runs, ['full @0']);
      h.scheduler.dispose();
    });
  });

  test('nothing runs without a destination, automatic sync or first sync', () {
    fakeAsync((async) {
      for (final triggers in [
        null,
        const SyncTriggers(autoSync: false),
        const SyncTriggers(enabled: false),
        const SyncTriggers(everSynced: false),
      ]) {
        final h = _Harness(async)
          ..triggers = triggers
          ..due = true
          ..start();
        h.scheduler.hinted();
        h.elapse(300);
        expect(h.runs, isEmpty, reason: '$triggers');
        h.scheduler.dispose();
      }
    });
  });

  test('a quick sync goes 5 s after the last hint, 60 s at most', () {
    fakeAsync((async) {
      final h = _Harness(async)
        ..triggers = const SyncTriggers(intervalSeconds: 0)
        ..start();
      h.runs.clear();
      h.due = true;

      h.scheduler.hinted();
      h.elapse(3);
      h.scheduler.hinted();
      h.elapse(4);
      expect(h.runs, isEmpty);
      h.elapse(1);
      expect(h.runs, ['quick @8']);

      // Typing without a pause: a save every 2 s.
      h
        ..runs.clear()
        ..due = true;
      for (var i = 0; i < 40; i++) {
        h.scheduler.hinted();
        h.elapse(2);
      }
      expect(h.runs.first, 'quick @68');
      h.scheduler.dispose();
    });
  });

  test('the periodic full sync follows the interval', () {
    fakeAsync((async) {
      final h = _Harness(async)
        ..triggers = const SyncTriggers(intervalSeconds: 300)
        ..start()
        ..elapse(900);
      expect(h.runs, ['full @0', 'full @300', 'full @600', 'full @900']);

      h.triggers = const SyncTriggers(intervalSeconds: 0);
      unawaited(h.scheduler.settingsChanged());
      h.elapse(900);
      expect(h.runs, hasLength(4));
      h.scheduler.dispose();
    });
  });

  test('a server out of reach backs off, honoring Retry-After', () {
    fakeAsync((async) {
      final h = _Harness(async)
        ..triggers = const SyncTriggers(intervalSeconds: 0)
        ..reports.addAll([
          () => _aborted(SyncAbort.offline),
          () => _aborted(SyncAbort.offline),
          () => _aborted(
            SyncAbort.offline,
            retryAfter: const Duration(minutes: 2),
          ),
        ])
        ..start();
      expect(h.runs, ['full @0']);
      h.elapse(5);
      expect(h.runs, ['full @0', 'full @5']);
      h.elapse(10);
      expect(h.runs.last, 'full @15');
      h.elapse(119);
      expect(h.runs, hasLength(3));
      h.elapse(1);
      expect(h.runs.last, 'full @135');
      expect(h.scheduler.backoffUntil, isNull, reason: 'that one went fine');
      h.scheduler.dispose();
    });
  });

  test('a refused password pauses until a manual run or a new password', () {
    fakeAsync((async) {
      final h = _Harness(async)
        ..reports.add(() => _aborted(SyncAbort.authentication))
        ..start();
      expect(h.scheduler.paused, SyncPause.authentication);
      h.due = true;
      h.scheduler.hinted();
      h.elapse(600);
      expect(h.runs, ['full @0']);

      unawaited(h.scheduler.manualRunStarting());
      async.flushMicrotasks();
      expect(h.scheduler.paused, isNull);
      expect(h.retries, 1);
      h.scheduler.hinted();
      h.elapse(5);
      expect(h.runs.last, 'quick @605');
      h.scheduler.dispose();
    });
  });

  test('a mass deletion an automatic run refused pauses for a confirm', () {
    fakeAsync((async) {
      final h = _Harness(async)
        ..reports.add(
          () => _aborted(SyncAbort.notConfirmed)
            ..plan = SyncPlan([
              for (var i = 0; i < 20; i++)
                SyncDecision(
                  path: 'n$i.md',
                  kind: SyncActionKind.trashLocal,
                  why: 'gone remotely',
                ),
            ], rowCount: 25),
        )
        ..start();
      expect(h.scheduler.paused, SyncPause.confirmation);
      h.scheduler.dispose();
    });
  });

  test('on a phone, Wi-Fi only waits for Wi-Fi and resumes on it', () {
    fakeAsync((async) {
      final h = _Harness(async, phone: true)
        ..triggers = const SyncTriggers(wifiOnly: true);
      h.network.now = SyncNetwork.mobile;
      h
        ..due = true
        ..start();
      h.scheduler.hinted();
      h.elapse(120);
      expect(h.runs, isEmpty);
      expect(h.scheduler.networkAllows(h.triggers!), isFalse);

      h.network.change(SyncNetwork.unmetered);
      async.flushMicrotasks();
      expect(h.retries, 1);
      expect(h.runs, ['quick @120']);
      h.scheduler.dispose();
    });
  });

  test('the network coming back retries the interrupted full sync', () {
    fakeAsync((async) {
      final h = _Harness(async, phone: true)
        ..triggers = const SyncTriggers(intervalSeconds: 0)
        ..reports.add(() => _aborted(SyncAbort.offline))
        ..start();
      h.network.change(SyncNetwork.offline);
      async.flushMicrotasks();
      h.elapse(30);
      expect(h.runs, ['full @0'], reason: 'offline: the retry waits');

      h.network.change(SyncNetwork.unmetered);
      async.flushMicrotasks();
      expect(h.runs, ['full @0', 'full @30']);
      expect(h.scheduler.backoffUntil, isNull);
      h.scheduler.dispose();
    });
  });

  test('backgrounding sends the queue now; resuming syncs in full', () {
    fakeAsync((async) {
      final h = _Harness(async, phone: true)
        ..start()
        ..due = true;
      h.scheduler
        ..hinted()
        ..backgrounded();
      async.flushMicrotasks();
      expect(h.runs, ['full @0', 'quick @0']);

      h
        ..due = false
        ..elapse(600);
      expect(h.runs, hasLength(2), reason: 'no periodic sync in background');

      h.scheduler.resumed();
      async.flushMicrotasks();
      expect(h.runs.last, 'full @600');
      h.elapse(60);
      expect(h.runs.last, 'full @660');
      h.scheduler.dispose();
    });
  });

  test('a trigger during a run is served after it', () {
    fakeAsync((async) {
      final h = _Harness(async)
        ..triggers = const SyncTriggers(intervalSeconds: 0)
        ..runTakes = const Duration(seconds: 20)
        ..start()
        ..elapse(10);
      h.scheduler.resumed();
      h.elapse(10);
      expect(h.runs, ['full @0', 'full @20']);
      h.elapse(20);
      expect(h.runs, hasLength(2));
      h.scheduler.dispose();
    });
  });

  test('a quick sync that left work for a full one gets it', () {
    fakeAsync((async) {
      final h = _Harness(async)
        ..triggers = const SyncTriggers(intervalSeconds: 0)
        ..start();
      h.reports.add(
        () => SyncReport()
          ..deferred.add(
            const SyncDecision(
              path: 'a.md',
              kind: SyncActionKind.trashLocal,
              why: 'gone remotely',
            ),
          ),
      );
      h.due = true;
      h.scheduler.hinted();
      h.elapse(5);
      expect(h.runs, ['full @0', 'quick @5', 'full @5']);
      h.scheduler.dispose();
    });
  });
}
