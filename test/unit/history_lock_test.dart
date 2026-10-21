import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

/// The history lock (#1148 review): taken across real isolates, broken
/// when stale by one waiter alone, released only when still ours, and
/// failing at once where it cannot be had.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.current.createTemp('niman_history_lock_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  File note(String rel) => File(p.join(root.path, rel));

  void write(String rel, String text) {
    final file = note(rel);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(text);
  }

  SnapshotRequest forced() => SnapshotRequest(
    limit: 1000,
    interval: const Duration(minutes: 5),
    now: DateTime(2026, 9, 15, 10),
    forced: HistoryReason.restore,
  );

  test(
    'two isolates snapshotting one note lose no line and no number',
    () async {
      write('a.md', 'start');
      final path = root.path;
      final runs = await Future.wait([
        Isolate.run(() => _snapshotMany(path, 'a.md', 'left', 40)),
        Isolate.run(() => _snapshotMany(path, 'a.md', 'right', 40)),
      ]);
      final numbers = [for (final run in runs) ...run];
      expect(numbers.toSet().length, numbers.length, reason: 'a number twice');
      final kept = readHistoryManifest(path, 'a.md').versions;
      expect(
        kept.map((v) => v.number).toSet(),
        numbers.toSet(),
        reason: 'a version taken is a version listed',
      );
    },
  );

  test('the lock is not in the note folder, so a release lists nothing', () {
    write('dir/a.md', 'one');
    withHistoryLock(root.path, ['dir/a.md'], () {
      // Inside the note's own folder of .history there is nothing of the
      // lock's: it lives flat, apart (a release that had to tidy the
      // folder would list it, thousands of logs on a big one).
      expect(
        Directory(p.join(root.path, '.history', 'dir')).existsSync(),
        false,
      );
      expect(File(historyLockPath(root.path, 'dir/a.md')).existsSync(), true);
    });
    expect(File(historyLockPath(root.path, 'dir/a.md')).existsSync(), false);
    expect(
      p.isWithin(historyLocksPath(root.path), historyLockPath(root.path, 'x')),
      true,
    );
  });

  test('names that differ by case alone ask for one lock', () {
    expect(
      historyLockPath(root.path, 'Dir/Note.md'),
      historyLockPath(root.path, 'dir/note.md'),
    );
    // Two names of one lock, asked for together, are taken once: the
    // second would otherwise wait the whole patience for the first.
    final clock = Stopwatch()..start();
    withHistoryLock(root.path, ['Note.md', 'note.md'], () {});
    expect(clock.elapsedMilliseconds, lessThan(2000));
  });

  test('a case-only rename keeps the history under the new name', () {
    write('Note.md', 'one');
    snapshotBeforeWrite(root.path, 'Note.md', forced());
    write('Note.md', 'two');
    snapshotBeforeWrite(root.path, 'Note.md', forced());
    final clock = Stopwatch()..start();
    final moved = moveNoteHistory(root.path, 'Note.md', 'note.md');
    expect(clock.elapsedMilliseconds, lessThan(5000), reason: 'a deadlock');
    expect(moved, 2);
    expect(readHistoryManifest(root.path, 'note.md').versions, hasLength(2));
  });

  test('a case-only folder rename keeps the notes history', () {
    write('Dir/a.md', 'one');
    snapshotBeforeWrite(root.path, 'Dir/a.md', forced());
    write('Dir/a.md', 'two');
    snapshotBeforeWrite(root.path, 'Dir/a.md', forced());
    final clock = Stopwatch()..start();
    moveFolderHistory(root.path, 'Dir', 'dir');
    expect(clock.elapsedMilliseconds, lessThan(5000), reason: 'a deadlock');
    expect(readHistoryManifest(root.path, 'dir/a.md').versions, hasLength(2));
  });

  test('a release leaves the lock of the writer that broke ours', () {
    final lock = File(historyLockPath(root.path, 'a.md'));
    withHistoryLock(root.path, ['a.md'], () {
      // Ours was taken for stale and broken; another writer holds it now.
      lock.writeAsStringSync('another writer');
    });
    expect(lock.existsSync(), true);
    expect(lock.readAsStringSync(), 'another writer');
  });

  // 25 rounds of eight isolates, each round starting 300 ms out: 14 s on an
  // idle Mac, past the default 30 s on a shared three-core runner.
  test(
    'two waiters that find a lock stale never both take it',
    timeout: const Timeout(Duration(minutes: 2)),
    () async {
      final path = root.path;
      var overlaps = 0;
      for (var round = 0; round < 25; round++) {
        File(historyLockPath(path, 'a.md'))
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('a writer that crashed')
          ..setLastModifiedSync(
            DateTime.now().subtract(const Duration(minutes: 5)),
          );
        final start = DateTime.now().millisecondsSinceEpoch + 300;
        final runs = await Future.wait([
          for (var i = 0; i < 8; i++)
            Isolate.run(() => _holdWhenStart(path, 'a.md', start)),
        ]);
        overlaps += runs.fold(0, (sum, n) => sum + n);
      }
      expect(overlaps, 0);
    },
  );

  test('a store that cannot hold a lock fails at once, not after 10 s', () {
    // A file where the locks folder should be: nothing can be created in it.
    Directory(p.join(root.path, '.history')).createSync();
    File(p.join(root.path, '.history', '.locks')).writeAsStringSync('');
    write('a.md', 'one');
    final clock = Stopwatch()..start();
    expect(
      () => snapshotBeforeWrite(root.path, 'a.md', forced()),
      throwsA(isA<FileSystemException>()),
    );
    expect(clock.elapsedMilliseconds, lessThan(3000));
  });

  test('a store that cannot write a note log fails at once too', () {
    // A file where the note's history folder should be.
    Directory(p.join(root.path, '.history')).createSync();
    File(p.join(root.path, '.history', 'dir')).writeAsStringSync('');
    write('dir/a.md', 'one');
    final clock = Stopwatch()..start();
    expect(
      () => snapshotBeforeWrite(root.path, 'dir/a.md', forced()),
      throwsA(isA<FileSystemException>()),
    );
    expect(clock.elapsedMilliseconds, lessThan(3000));
  });

  test('reading a note with no history takes no lock', () {
    // The store cannot hold a lock, and a read of nothing does not need one.
    Directory(p.join(root.path, '.history')).createSync();
    File(p.join(root.path, '.history', '.locks')).writeAsStringSync('');
    write('a.md', 'one');
    final clock = Stopwatch()..start();
    expect(readHistoryManifest(root.path, 'a.md').versions, isEmpty);
    expect(clock.elapsedMilliseconds, lessThan(3000));
  });
}

/// Takes [count] snapshots of [rel], writing a text of its own before each,
/// and answers the numbers of the versions it took.
List<int> _snapshotMany(String root, String rel, String tag, int count) {
  final numbers = <int>[];
  for (var i = 0; i < count; i++) {
    File(p.join(root, rel)).writeAsStringSync('$tag $i');
    final outcome = snapshotBeforeWrite(
      root,
      rel,
      SnapshotRequest(
        limit: 1000,
        interval: const Duration(minutes: 5),
        now: DateTime(2026, 9, 15, 10),
        forced: HistoryReason.restore,
      ),
    );
    final version = outcome.version;
    if (version != null) numbers.add(version.number);
  }
  return numbers;
}

/// Waits for [startAtMs], takes the lock of [rel] and answers 1 when
/// another holder was inside at the same time, 0 otherwise.
int _holdWhenStart(String root, String rel, int startAtMs) {
  final wait = startAtMs - DateTime.now().millisecondsSinceEpoch;
  if (wait > 0) sleep(Duration(milliseconds: wait));
  return withHistoryLock(root, [rel], () {
    final marker = File(p.join(root, 'inside'));
    try {
      marker.createSync(exclusive: true);
    } on FileSystemException {
      return 1;
    }
    sleep(const Duration(milliseconds: 15));
    marker.deleteSync();
    return 0;
  });
}
