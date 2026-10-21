// The reindex half of `NoteWriter` (#1137): when a saved note is read back
// into the index, with the save chain and the read replaced by fakes so the
// order of events is the test's and time is fake time.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/read_cancel.dart';
import 'package:niman/src/library/reindex_scheduler.dart';

final DateTime epoch = DateTime(2026);

/// A scheduler over fake reads, and the save chain they are checked against.
final class _Harness {
  new({required this.async, Duration Function(int bytes)? quiet}) {
    scheduler = ReindexScheduler(
      now: () => epoch.add(async.elapsed),
      chainOf: (path) => chains[path]?.future,
      read: (path, {required created, required cancel}) {
        reads.add((path: path, created: created, cancel: cancel));
        return onRead(cancel);
      },
      quietBeforeReindex: quiet ?? (_) => Duration.zero,
    );
  }

  /// The fake time the scheduler's clock reads.
  final FakeAsync async;

  late final ReindexScheduler scheduler;

  /// The save chains running, by path.
  final Map<String, Completer<void>> chains = {};

  /// Every read started.
  final List<({String path, bool created, ReadCancel cancel})> reads = [];

  /// What a read does: finishes at once by default.
  Future<bool> Function(ReadCancel cancel) onRead = (_) async => true;

  /// A save of [path] begins: its chain is busy, and a read is cancelled.
  Future<void> beginSave(String path) {
    final released = scheduler.cancelRead(path);
    chains[path] = Completer<void>();
    return released;
  }

  /// The save of [path] ends: its chain is idle.
  void endSave(String path) {
    chains.remove(path)!.complete();
    scheduler.settled(path);
  }
}

void main() {
  group('a save waits for the read it cancelled to let go of the file', () {
    test('and only for that, never for the rest of the read', () {
      fakeAsync((async) {
        final h = _Harness(async: async);
        final gate = Completer<void>();
        final parsed = Completer<void>();
        h.onRead = (cancel) async {
          final release = cancel.holdFiles();
          await gate.future; // reading: the file is open
          release();
          await parsed.future; // parsing: nothing is held
          return !cancel.isCancelled;
        };
        h.scheduler.reindex('a.md', created: false);
        async.flushMicrotasks();

        var released = false;
        unawaited(h.beginSave('a.md').then((_) => released = true));
        async.flushMicrotasks();
        expect(h.reads.single.cancel.isCancelled, isTrue);
        expect(released, isFalse, reason: 'the read still holds the file');

        gate.complete();
        async.flushMicrotasks();
        expect(
          released,
          isTrue,
          reason: 'the file is closed; the parse is not awaited',
        );
        expect(parsed.isCompleted, isFalse);
      });
    });

    test('at once when no read holds a file, or none runs', () {
      fakeAsync((async) {
        final h = _Harness(async: async);
        var released = 0;
        unawaited(h.beginSave('none.md').then((_) => released++));
        h.endSave('none.md');

        final gate = Completer<void>();
        h.onRead = (_) async {
          await gate.future; // not reading a file: probing, or parsing
          return true;
        };
        h.scheduler.reindex('a.md', created: false);
        async.flushMicrotasks();
        unawaited(h.beginSave('a.md').then((_) => released++));
        async.flushMicrotasks();
        expect(released, 2);
      });
    });
  });

  group('a replace is not part of a burst of typing', () {
    test('it does not wait for the quiet timer of an earlier save', () {
      fakeAsync((async) {
        final h = _Harness(
          async: async,
          quiet: (_) => const Duration(seconds: 30),
        );
        h.scheduler.whenQuiet('a.md', created: false, bytes: 3 << 20);
        expect(h.scheduler.awaits('a.md'), isTrue);

        // A sync download replaces the note: its turn, then its reindex.
        unawaited(h.beginSave('a.md'));
        h.scheduler.reindexNow('a.md', created: false);
        h.endSave('a.md');
        async.flushMicrotasks();
        expect(h.reads, hasLength(1), reason: 'read at once, not in 30 s');

        // The timer it replaced does not read the note a second time.
        async.elapse(const Duration(minutes: 1));
        expect(h.reads, hasLength(1));
        expect(h.scheduler.awaits('a.md'), isFalse);
      });
    });

    test('a save of the burst still waits for its own quiet', () {
      fakeAsync((async) {
        final h = _Harness(
          async: async,
          quiet: (_) => const Duration(seconds: 30),
        );
        unawaited(h.beginSave('a.md'));
        h.scheduler.whenQuiet('a.md', created: false, bytes: 3 << 20);
        h.endSave('a.md');
        async.flushMicrotasks();
        expect(h.reads, isEmpty);
        async.elapse(const Duration(seconds: 30));
        expect(h.reads, hasLength(1));
      });
    });
  });

  group('the quiet time follows what the reads of the note took', () {
    Duration ms(int n) => Duration(milliseconds: n);
    Duration sec(int n) => Duration(seconds: n);

    /// The reads a.md makes, one after another: each takes the fake time
    /// and answers whether it finished (false: a save cancelled it). A read
    /// dropped is followed by another, as the scheduler owes the note one,
    /// and once the script is out that one never ends.
    void script(_Harness h, List<(Duration, bool)> steps) {
      final queue = [...steps];
      h.onRead = (_) async {
        if (queue.isEmpty) await Completer<void>().future;
        final (ran, done) = queue.removeAt(0);
        await Future<void>.delayed(ran);
        return done;
      };
    }

    /// Reads a.md once, taking [ran] of fake time and answering [done].
    void readFor(_Harness h, Duration ran, {bool done = true}) {
      script(h, [(ran, done)]);
      h.scheduler.reindex('a.md', created: false);
      h.async.elapse(ran);
    }

    test('twice the last read, for a read the saves keep cancelling', () {
      fakeAsync((async) {
        final h = _Harness(async: async);
        // 0.6 MB on a tablet: 600 ms against a save every 500.
        readFor(h, ms(600));
        expect(h.scheduler.quietFor('a.md', 600 << 10), ms(1200));

        h.scheduler.whenQuiet('a.md', created: false, bytes: 600 << 10);
        async.elapse(ms(1100));
        expect(h.reads, hasLength(1), reason: 'still quiet');
        async.elapse(ms(100));
        expect(h.reads, hasLength(2));
      });
    });

    test('a read cancelled midway counts for as long as it ran', () {
      fakeAsync((async) {
        final h = _Harness(async: async);
        script(h, [(ms(400), false), (ms(300), false), (ms(500), true)]);
        h.scheduler.reindex('a.md', created: false);
        async.elapse(ms(400));
        expect(h.scheduler.quietFor('a.md', 600 << 10), ms(800));
        // Cancelled earlier the next time: the longer run is the estimate.
        async.elapse(ms(300));
        expect(h.scheduler.quietFor('a.md', 600 << 10), ms(800));
        // Read through at last: its own time.
        async.elapse(ms(500));
        expect(h.scheduler.quietFor('a.md', 600 << 10), sec(1));
      });
    });

    test('a note read quickly is read at once again', () {
      fakeAsync((async) {
        final h = _Harness(async: async);
        readFor(h, ms(600));
        expect(h.scheduler.quietFor('a.md', 600 << 10), isNot(Duration.zero));
        readFor(h, ms(100));
        expect(h.scheduler.quietFor('a.md', 600 << 10), Duration.zero);
        // Nor does a quick read that was cancelled say anything.
        readFor(h, ms(600));
        readFor(h, ms(100), done: false);
        expect(h.scheduler.quietFor('a.md', 600 << 10), ms(1200));
      });
    });

    test('never less than the size asks for, never more than 30 s', () {
      fakeAsync((async) {
        final h = _Harness(
          async: async,
          quiet: (bytes) => bytes > 1 << 20 ? sec(5) : Duration.zero,
        );
        readFor(h, ms(300));
        expect(h.scheduler.quietFor('a.md', 2 << 20), sec(5));
        expect(h.scheduler.quietFor('a.md', 1 << 10), ms(600));
        readFor(h, sec(20));
        expect(
          h.scheduler.quietFor('a.md', 1 << 10),
          ReindexScheduler.longestMeasuredWait,
        );
      });
    });

    test('a note is timed by its own reads', () {
      fakeAsync((async) {
        final h = _Harness(async: async);
        readFor(h, ms(600));
        expect(h.scheduler.quietFor('b.md', 600 << 10), Duration.zero);
      });
    });
  });
}
