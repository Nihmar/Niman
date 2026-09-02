import 'dart:io';

import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/db/database.dart';
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

  /// A factory over one shared on-disk database, so a "fresh" controller
  /// (simulating an app restart) sees the same index and settings.
  Future<CopistDatabase> Function() sharedDb() {
    return () async => CopistDatabase(
      NativeDatabase(File(p.join(tmp.path, 'copist.db'))),
    );
  }

  /// A controller with a long periodic rescan and the given
  /// reconciliation delay.
  LibraryController makeController({
    Duration reconcileDelay = const Duration(seconds: 1),
  }) {
    return LibraryController(
      sharedDb(),
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

  test('a non-blocking open is ready from the last index, then reconciles',
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
    await expectConverged(
      () async => (await names(second)).contains('b.md'),
    );
    await second.close();
    await second.dispose();
  });

  test('resume becomes ready from the last index, then reconciles',
      () async {
    // A previous session indexed the library...
    final first = makeController();
    await first.open(root.path, create: false);
    await first.close();
    await first.dispose();

    // ...and its process died, leaving the persisted last-library path.
    final settingsDb = CopistDatabase(
      NativeDatabase(File(p.join(tmp.path, 'copist.db'))),
    );
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
    await expectConverged(
      () async => (await names(second)).contains('b.md'),
    );
    await second.close();
    await second.dispose();
  });
}
