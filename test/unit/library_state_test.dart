import 'dart:io';

import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/session.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  // The tests deliberately open the shared on-disk database several times
  // (simulating an app restart); each open is a distinct executor.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory root;

  setUp(() async {
    tmp = await Directory.current.createTemp('copist_state_');
    root = Directory(p.join(tmp.path, 'library'))..createSync();
    File(p.join(root.path, 'a.md')).writeAsStringSync('a');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  /// The app settings file, shared across controllers so a "fresh" one
  /// (simulating an app restart) sees the same settings.
  Future<AppDatabase> appDb() async =>
      AppDatabase(NativeDatabase(File(p.join(tmp.path, 'copist.db'))));

  /// One index file per library, named after its folder — the same rule
  /// the app applies with a digest (T-ML-03), spelled readably here.
  Future<IndexDatabase> indexDb(String libraryPath) async => IndexDatabase(
    NativeDatabase(File(p.join(tmp.path, '${p.basename(libraryPath)}.db'))),
  );

  /// A controller with a long periodic rescan and the given
  /// reconciliation delay.
  LibraryController makeController({
    Duration reconcileDelay = const Duration(seconds: 1),
  }) {
    return LibraryController(
      appDb,
      indexDbFactory: indexDb,
      rescanInterval: const Duration(hours: 1),
      resumeReconcileDelay: reconcileDelay,
    );
  }

  Future<List<String>> names(LibrarySession session) async {
    final kids = await session.children(0);
    return kids.map((n) => n.name).toList();
  }

  /// Polls [probe] until it returns true or ~5 s elapse.
  Future<void> expectConverged(Future<bool> Function() probe) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!(await probe())) {
      if (DateTime.now().isAfter(deadline)) {
        fail('index did not converge in time');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  test('a blocking open is ready only after the index mirrors disk', () async {
    final controller = makeController();
    await controller.open(root.path, create: false);
    expect(controller.phase, LibraryPhase.ready);
    expect(await names(controller), ['a.md']);
    await controller.close();
    await controller.dispose();
  });

  test(
    'a non-blocking open is ready from the last index, then reconciles',
    () async {
      // A previous session indexed the library and closed cleanly.
      final first = makeController();
      await first.open(root.path, create: false);
      await first.close();
      await first.dispose();

      // While it was closed, a note appeared on disk.
      File(p.join(root.path, 'b.md')).writeAsStringSync('b');

      // A non-blocking open becomes ready from the (stale) index without
      // waiting for the scan.
      final second = makeController();
      await second.open(root.path, create: false, blockingScan: false);
      expect(second.phase, LibraryPhase.ready);
      expect(await names(second), ['a.md']);

      // The background reconciliation converges the index with the disk.
      await expectConverged(() async => (await names(second)).contains('b.md'));
      await second.close();
      await second.dispose();
    },
  );

  test('resume becomes ready from the last index, then reconciles', () async {
    // A previous session indexed the library...
    final first = makeController();
    await first.open(root.path, create: false);
    await first.close();
    await first.dispose();

    // ...and its process died, leaving the persisted last-library path.
    final settingsDb = await appDb();
    await AppSettingsRepo(settingsDb).setLastLibraryPath(root.path);
    await settingsDb.close();

    // While the app was closed, a note appeared on disk.
    File(p.join(root.path, 'b.md')).writeAsStringSync('b');

    // A fresh controller (a restart) resumes non-blockingly...
    final second = makeController();
    await second.resume();
    expect(second.phase, LibraryPhase.ready);
    expect(await names(second), ['a.md']);

    // ...and the background reconciliation converges.
    await expectConverged(() async => (await names(second)).contains('b.md'));
    await second.close();
    await second.dispose();
  });

  test('each library keeps its own index across a switch', () async {
    // T-ML-03: with one shared index, opening the second library scanned
    // over the first one's rows and coming back re-scanned from scratch.
    final other = Directory(p.join(tmp.path, 'other'))..createSync();
    File(p.join(other.path, 'z.md')).writeAsStringSync('z');

    final first = makeController();
    await first.open(root.path, create: false);
    expect(await names(first), ['a.md']);
    await first.close();
    await first.dispose();

    final second = makeController();
    await second.open(other.path, create: false);
    expect(await names(second), ['z.md']);
    await second.close();
    await second.dispose();

    // Back to the first library, without waiting for a scan: what comes
    // up is its own index, not the one the second library left behind.
    final third = makeController();
    await third.open(root.path, create: false, blockingScan: false);
    expect(await names(third), ['a.md']);
    await third.close();
    await third.dispose();
  });

  test('a closed session reads no tree at all', () async {
    // The index belongs to the open library, so there is nothing to read
    // before the first open — and the tree UI asks anyway.
    final controller = makeController();
    expect(await controller.children(0), isEmpty);
    expect(await controller.tree(const []), isEmpty);
    expect(await controller.folders(), isEmpty);
    expect(await controller.searchSource, isNull);
    expect(await controller.tagSource, isNull);
    expect(await controller.linkSource, isNull);
    await controller.dispose();
  });

  test('a disk-originated change moves the revision', () async {
    final controller = makeController();
    await controller.open(root.path, create: false);
    final before = controller.revision;

    File(p.join(root.path, 'b.md')).writeAsStringSync('b');
    await controller.rescanNow();

    expect(controller.revision, greaterThan(before));
    expect(await names(controller), containsAll(<String>['a.md', 'b.md']));

    // A rescan that changes nothing does not move the revision again.
    final quiet = controller.revision;
    await controller.rescanNow();
    expect(controller.revision, quiet);

    await controller.close();
    await controller.dispose();
  });

  test('treeSort persists and flips the children order', () async {
    final first = makeController();
    await first.open(root.path, create: false);
    File(p.join(root.path, 'b.md')).writeAsStringSync('b');
    File(p.join(root.path, 'c.md')).writeAsStringSync('c');
    await first.rescanNow();

    // Default: directories first, then ascending names.
    expect((await first.children(0)).map((note) => note.name).toList(), [
      'a.md',
      'b.md',
      'c.md',
    ]);

    // Descending flips the name sort (dirs stay first).
    await first.setTreeSort(TreeSort.nameDesc);
    expect(
      (await first.children(0, nameDesc: true)).map((n) => n.name).toList(),
      ['c.md', 'b.md', 'a.md'],
    );
    await first.close();
    await first.dispose();

    // A fresh controller (an app restart) sees the persisted choice.
    final second = makeController();
    await second.open(root.path, create: false);
    expect(await second.treeSort, TreeSort.nameDesc);
    await second.close();
    await second.dispose();
  });
}
