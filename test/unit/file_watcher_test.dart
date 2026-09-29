import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/file_watcher.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_watch_');
  });

  tearDown(() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  /// Starts the watcher, runs [fn] with the collected batches, stops the
  /// watcher, and returns the batches.
  Future<List<WatchBatch>> runWith(
    FileWatcher watcher,
    Future<void> Function(List<WatchBatch> batches) fn,
  ) async {
    final batches = <WatchBatch>[];
    final sub = watcher.events.listen(batches.add);
    await watcher.start();
    try {
      await fn(batches);
    } finally {
      await watcher.stop();
      await sub.cancel();
    }
    return batches;
  }

  test('emits a batch containing external creates', () async {
    final batches = await runWith(
      FileWatcher(root.path, debounce: const Duration(milliseconds: 50)),
      (b) async {
        File(p.join(root.path, 'a.md')).writeAsStringSync('x');
        File(p.join(root.path, 'b.md')).writeAsStringSync('y');
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
    );
    expect(batches, isNotEmpty);
    final allPaths = batches.expand((b) => b.paths);
    expect(
      allPaths,
      containsAll([p.join(root.path, 'a.md'), p.join(root.path, 'b.md')]),
    );
  });

  test('coalesces rapid events into a single batch', () async {
    // Driven from a stream this test owns, not from real filesystem
    // notifications: those open the window when the OS delivers the
    // first one, and under full-suite load the last change of the burst
    // used to land after the window had closed, splitting the batch.
    final changes = StreamController<WatchChange>();
    final watcher = FileWatcher(
      root.path,
      debounce: const Duration(milliseconds: 20),
      source: (_) => changes.stream,
    );
    final wanted = List.generate(5, (i) => p.join(root.path, 'f$i.md'));
    final latePath = p.join(root.path, 'late.md');
    final batches = await runWith(watcher, (b) async {
      final first = watcher.events.first;
      // Fed synchronously: a Timer cannot run before the microtasks
      // carrying these to the watcher have drained, so all five are
      // inside one window whatever else the machine is doing.
      for (final path in wanted) {
        changes.add(WatchChange(path));
      }
      await first;
      // The window has closed; what arrives now belongs to the next.
      final second = watcher.events.first;
      changes.add(WatchChange(latePath));
      await second;
    });
    await changes.close();
    expect(batches, hasLength(2));
    expect(batches.first.paths, unorderedEquals(wanted));
    expect(batches.last.paths, <String>[latePath]);
  });

  test('rename batches carry the parent directory for resync', () async {
    final batches = await runWith(
      FileWatcher(root.path, debounce: const Duration(milliseconds: 50)),
      (b) async {
        final bPath = p.join(root.path, 'b.md');
        File(bPath).writeAsStringSync('x');
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await File(bPath).rename(p.join(root.path, 'c.md'));
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
    );
    final parent = p.dirname(p.join(root.path, 'b.md'));
    expect(batches.any((b) => b.resyncDirs.contains(parent)), isTrue);
  });

  test(
    'directory create events cover the child, directly or via the parent',
    () async {
      final batches = await runWith(
        FileWatcher(root.path, debounce: const Duration(milliseconds: 50)),
        (b) async {
          Directory(p.join(root.path, 'newdir')).createSync();
          // Let the recursive watch register on the new directory before the
          // child appears (a write that wins this race is still covered, via
          // the parent event's subtree resync).
          await Future<void>.delayed(const Duration(milliseconds: 200));
          File(p.join(root.path, 'newdir/inner.md')).writeAsStringSync('x');
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
      );
      final allPaths = batches.expand((b) => b.paths).toSet();
      expect(
        allPaths.contains(p.join(root.path, 'newdir/inner.md')) ||
            allPaths.contains(p.join(root.path, 'newdir')),
        isTrue,
      );
    },
  );

  test('stop closes the events stream', () async {
    final watcher = FileWatcher(root.path);
    var done = false;
    final sub = watcher.events.listen(
      null,
      onDone: () {
        done = true;
      },
    );
    await watcher.start();
    await watcher.stop();
    await sub.cancel();
    expect(done, isTrue);
  });

  test('restarting a stopped watcher throws', () async {
    final watcher = FileWatcher(root.path);
    await watcher.start();
    await watcher.stop();
    expect(watcher.start, throwsStateError);
  });

  test('resubscribes when the source stream ends (#389)', () async {
    final first = StreamController<WatchChange>();
    final second = StreamController<WatchChange>();
    var opened = 0;
    final watcher = FileWatcher(
      root.path,
      debounce: const Duration(milliseconds: 20),
      restartBackoff: const Duration(milliseconds: 5),
      source: (_) => opened++ == 0 ? first.stream : second.stream,
    );
    final before = p.join(root.path, 'before.md');
    final after = p.join(root.path, 'after.md');
    final batches = await runWith(watcher, (b) async {
      final firstBatch = watcher.events.first;
      first.add(WatchChange(before));
      expect((await firstBatch).paths, contains(before));
      // The OS stream ends on its own (an inotify limit, a FUSE hiccup,
      // the directory going away): the watch has to come back by itself,
      // or nothing is ever noticed again for the rest of the session.
      await first.close();
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (opened < 2 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(opened, 2, reason: 'the watcher resubscribes after an end');
      final next = watcher.events.first;
      second.add(WatchChange(after));
      expect((await next).paths, contains(after));
    });
    await second.close();
    expect(batches, hasLength(3));
    expect(batches.map((b) => b.missedChanges), [false, true, false]);
  });

  test('a resubscribe reports that changes may have gone unseen', () async {
    // Between the end of one stream and the start of the next nothing is
    // watching: a note saved then leaves no event, and without a word from
    // the watcher it waits for the periodic rescan, minutes away.
    final first = StreamController<WatchChange>();
    final second = StreamController<WatchChange>();
    var opened = 0;
    final watcher = FileWatcher(
      root.path,
      debounce: const Duration(milliseconds: 20),
      restartBackoff: const Duration(milliseconds: 5),
      source: (_) => opened++ == 0 ? first.stream : second.stream,
    );
    final batches = await runWith(watcher, (b) async {
      final reported = watcher.events.first;
      await first.close();
      final batch = await reported;
      expect(opened, 2, reason: 'reported once the new watch is in place');
      expect(batch.missedChanges, isTrue);
    });
    await second.close();
    expect(batches, hasLength(1));
  });

  test('a batch of plain changes asks for no full walk', () async {
    final changes = StreamController<WatchChange>();
    final watcher = FileWatcher(
      root.path,
      debounce: const Duration(milliseconds: 20),
      source: (_) => changes.stream,
    );
    final batches = await runWith(watcher, (b) async {
      final first = watcher.events.first;
      changes.add(WatchChange(p.join(root.path, 'a.md')));
      await first;
    });
    await changes.close();
    expect(batches.single.missedChanges, isFalse);
  });

  test('a burst past the path cap ships in bounded batches (#389)', () async {
    const cap = FileWatcher.maxPendingPaths;
    final changes = StreamController<WatchChange>();
    final watcher = FileWatcher(
      root.path,
      debounce: const Duration(milliseconds: 20),
      source: (_) => changes.stream,
    );
    final burst = List.generate(
      cap * 2 + 17,
      (i) => p.join(root.path, 'f$i.md'),
    );
    final batches = await runWith(watcher, (b) async {
      for (final path in burst) {
        changes.add(WatchChange(path));
      }
      // A window well past the last event: without a cap the whole burst
      // would sit in one pending set and ship as one batch.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await changes.close();
    for (final batch in batches) {
      expect(batch.paths.length, lessThanOrEqualTo(cap));
    }
    expect(batches.length, greaterThan(1), reason: 'the burst ships in pieces');
    // Bounded, but nothing is lost: every path of the burst still ships.
    expect(batches.expand((b) => b.paths).toSet(), burst.toSet());
  });

  test('a burst past the resync cap ships in bounded batches (#389)', () async {
    const cap = FileWatcher.maxPendingResyncDirs;
    final changes = StreamController<WatchChange>();
    final watcher = FileWatcher(
      root.path,
      debounce: const Duration(milliseconds: 20),
      source: (_) => changes.stream,
    );
    final batches = await runWith(watcher, (b) async {
      for (var i = 0; i < cap + 5; i++) {
        final dir = p.join(root.path, 'd$i');
        changes.add(WatchChange.move(p.join(dir, 'note.md')));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await changes.close();
    for (final batch in batches) {
      expect(batch.resyncDirs.length, lessThanOrEqualTo(cap));
    }
    expect(batches.length, greaterThan(1), reason: 'the burst ships in pieces');
  });

  test(
    'stopping during a pending resubscribe reopens nothing (#389)',
    () async {
      final changes = StreamController<WatchChange>();
      var opened = 0;
      final watcher = FileWatcher(
        root.path,
        restartBackoff: const Duration(milliseconds: 5),
        source: (_) {
          opened++;
          return changes.stream;
        },
      );
      await watcher.start();
      await changes.close();
      await watcher.stop();
      // Long past the resubscribe the end had scheduled: a stopped watcher
      // must not install a new OS watch behind the caller's back.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(opened, 1);
    },
  );
}
