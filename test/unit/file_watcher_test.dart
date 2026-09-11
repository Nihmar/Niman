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
}
