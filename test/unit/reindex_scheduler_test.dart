// The reindex half of `NoteWriter` (#1137): when a saved note is read back
// into the index, with the save chain and the read replaced by fakes so the
// order of events is the test's and time is fake time.
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/read_cancel.dart';
import 'package:niman/src/library/reindex_scheduler.dart';

/// A scheduler over fake reads, and the save chain they are checked against.
final class _Harness {
  new({Duration Function(int bytes)? quiet}) {
    scheduler = ReindexScheduler(
      chainOf: (path) => chains[path]?.future,
      read: (path, {required created, required cancel}) {
        reads.add((path: path, created: created, cancel: cancel));
        return onRead(cancel);
      },
      quietBeforeReindex: quiet ?? (_) => Duration.zero,
    );
  }

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
        final h = _Harness();
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
        final h = _Harness();
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
}
