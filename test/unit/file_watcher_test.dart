import 'dart:io';

import 'package:copist/src/library/file_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('copist_watch_');
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
    final batches = await runWith(
      FileWatcher(root.path, debounce: const Duration(milliseconds: 100)),
      (b) async {
        for (var i = 0; i < 5; i++) {
          File(p.join(root.path, 'f$i.md')).writeAsStringSync('x');
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
    );
    final wanted = List.of(
      List.generate(5, (i) => p.join(root.path, 'f$i.md')),
    );
    final allPaths = batches.expand((b) => b.paths).toSet();
    for (final path in wanted) {
      expect(allPaths, contains(path));
    }
    // All five writes happened within one debounce window: at least one
    // batch carries every path together.
    expect(
      batches.where(
        (b) => wanted.every((path) => b.paths.contains(path)),
      ),
      isNotEmpty,
    );
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
  });

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
