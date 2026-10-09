// #697: a full scan holds the indexer's lock a directory at a time, so a
// note made, deleted or renamed during it is written at once — and the
// scan, whose listings may be older than that write, leaves it as written.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/db/scan_touches.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ScanTouches', () {
    test('owns a touched path and what is inside it', () {
      final touches = ScanTouches()
        ..begin()
        ..add(['a/b']);
      expect(touches.owns('a/b'), isTrue);
      expect(touches.owns(p.posix.join('a', 'b', 'c.md')), isTrue);
      expect(touches.owns('a'), isFalse, reason: 'it holds one, not is one');
      expect(touches.owns('a/bc'), isFalse, reason: 'a sibling, not inside');
    });

    test('shields the folders above a touched path too', () {
      final touches = ScanTouches()
        ..begin()
        ..add(['a/b/c.md']);
      expect(touches.shields('a'), isTrue);
      expect(touches.shields('a/b'), isTrue);
      expect(touches.shields('a/b/c.md'), isTrue);
      expect(touches.shields('x'), isFalse);
    });

    test('counts nothing while no scan runs', () {
      final touches = ScanTouches()..add(['a']);
      expect(touches.owns('a'), isFalse);
      touches
        ..begin()
        ..add(['a'])
        ..end();
      expect(touches.owns('a'), isFalse);
    });
  });

  group('a write during a full scan', () {
    late Directory root;
    late IndexDatabase db;
    late Indexer indexer;

    String abs(String rel) => p.joinAll([root.path, ...rel.split('/')]);

    void write(String rel, String text) {
      File(abs(rel))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(text);
    }

    setUp(() async {
      root = await Directory.current.createTemp('niman_scan_lock_');
      db = IndexDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      indexer = Indexer(db);
      // Several folders: the scan has steps left after the first.
      for (var f = 0; f < 6; f++) {
        for (var n = 0; n < 5; n++) {
          write('f$f/n$n.md', 'note $f $n');
        }
      }
      write('keep.md', 'kept');
      await indexer.fullScan(root.path);
    });

    tearDown(() async {
      await root.delete(recursive: true);
    });

    Future<Set<String>> paths() async => {
      for (final row in await indexer.dao.allRows()) row.path,
    };

    /// Runs [during] once a scan has started, and answers whether the
    /// scan was still running when [during] was done.
    Future<bool> midScan(Future<void> Function() during) async {
      var scanned = false;
      final scan = indexer.fullScan(root.path).then((_) => scanned = true);
      await during();
      final early = !scanned;
      await scan;
      return early;
    }

    test('is written before the scan ends, not after it', () async {
      write('f5/new.md', 'made during the scan');
      final early = await midScan(
        () => indexer.applyEvents(root.path, [abs('f5/new.md')]),
      );
      expect(early, isTrue, reason: 'it waited for the whole walk');
      expect(await paths(), contains('f5/new.md'));
    });

    /// Runs [action] before the scan's [n]th step takes the lock: the
    /// first is its setup, the second the root's directory, whose listing
    /// is then already taken — what [action] writes is newer than it.
    void atStep(int n, Future<void> Function() action) {
      var calls = 0;
      indexer.beforeScanStep = () async {
        if (++calls == n) await action();
      };
      addTearDown(() => indexer.beforeScanStep = null);
    }

    test('a note made after its folder was listed survives the scan', () async {
      atStep(2, () async {
        write('made.md', 'made after the listing');
        await indexer.applyEvents(root.path, [abs('made.md')]);
      });
      await indexer.fullScan(root.path);
      expect(await paths(), containsAll(['made.md', 'keep.md']));
    });

    test('a note deleted after its folder was listed stays deleted', () async {
      atStep(2, () async {
        File(abs('keep.md')).deleteSync();
        await indexer.applyEvents(root.path, [abs('keep.md')]);
      });
      await indexer.fullScan(root.path);
      expect(await paths(), isNot(contains('keep.md')));
    });

    test('a note renamed after its folder was listed keeps its id at its '
        'new path, alone', () async {
      final id = (await indexer.dao.find('keep.md'))!.id;
      atStep(2, () async {
        File(abs('keep.md')).renameSync(abs('kept.md'));
        await indexer.applyEvents(root.path, [abs('keep.md'), abs('kept.md')]);
      });
      await indexer.fullScan(root.path);
      final after = await paths();
      expect(after, isNot(contains('keep.md')));
      expect((await indexer.dao.find('kept.md'))?.id, id);
    });

    test(
      'a folder made again after the scan saw it gone keeps its note',
      () async {
        // Gone from disk when the root is listed: the scan marks it gone.
        Directory(abs('f5')).deleteSync(recursive: true);
        atStep(3, () async {
          write('f5/back.md', 'back again');
          await indexer.applyEvents(root.path, [abs('f5/back.md')]);
        });
        await indexer.fullScan(root.path);
        expect(await paths(), containsAll(['f5', 'f5/back.md']));
      },
    );

    test("reads a folder's notes before it takes the lock", () async {
      // A first index: the tree written, every note's content owed.
      final fresh = IndexDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final first = Indexer(fresh);
      await first.indexTreeFirst(root.path);
      final read = <String>[];
      first.onProgress = (progress) => read.add(progress.file);
      var steps = 0;
      List<String>? readAtRootStep;
      first.beforeScanStep = () async {
        // The second step is the root's: its one note is read by now, so
        // a big note there no longer holds every write back (#697).
        if (++steps == 2) readAtRootStep = List.of(read);
      };
      await first.fullScan(root.path);
      expect(readAtRootStep, contains(endsWith('keep.md')));
    });
  });
}
