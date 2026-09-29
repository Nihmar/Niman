import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/library_registry.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory root;

  setUp(() async {
    tmp = await Directory.current.createTemp('niman_rebuild_');
    root = Directory(p.join(tmp.path, 'library'))..createSync();
    File(p.join(root.path, 'a.md')).writeAsStringSync('a');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<AppDatabase> appDb() async =>
      AppDatabase(NativeDatabase(File(p.join(tmp.path, 'niman.db'))));

  Future<IndexDatabase> indexDb(String libraryPath) async => IndexDatabase(
    NativeDatabase(File(p.join(tmp.path, '${p.basename(libraryPath)}.db'))),
  );

  LibraryController makeController() => LibraryController(
    appDb,
    indexDbFactory: indexDb,
    indexFileOf: (libraryPath) async =>
        File(p.join(tmp.path, '${p.basename(libraryPath)}.db')),
    rescanInterval: const Duration(hours: 1),
  );

  test('rebuilding the index re-reads disk and keeps the library', () async {
    // #368: the maintenance action deletes the index and re-indexes from
    // disk — the documented repair — without forgetting the library: the
    // registry row and the workspace a forget would have taken stay.
    final controller = makeController();
    await controller.open(root.path, create: false);
    await controller.saveWorkspace(Workspace.empty.open('a.md'));

    // A note that reached the disk while the library was open.
    File(p.join(root.path, 'b.md')).writeAsStringSync('b');
    await controller.rebuildIndex();

    expect(controller.phase, LibraryPhase.ready);
    expect(controller.lastError, isNull);
    expect((await controller.children(0)).map((note) => note.name).toList(), [
      'a.md',
      'b.md',
    ]);
    final db = await controller.appDatabase;
    expect((await LibraryRegistry(db).all()).single.path, root.path);
    expect((await controller.savedWorkspace).activePath, 'a.md');
    await controller.close();
    await controller.dispose();
  });

  test('rebuilding with no library open is refused', () async {
    final controller = makeController();
    await expectLater(controller.rebuildIndex(), throwsStateError);
    await controller.dispose();
  });

  test('two rebuilds in a row coalesce into one', () async {
    // #493: rebuildIndex tears the session down and deletes the index. A
    // second call while the first runs must not do that again over the file
    // the first is opening or scanning.
    var deletes = 0;
    final controller = LibraryController(
      appDb,
      indexDbFactory: indexDb,
      indexFileOf: (libraryPath) async {
        deletes++;
        return File(p.join(tmp.path, '${p.basename(libraryPath)}.db'));
      },
      rescanInterval: const Duration(hours: 1),
    );
    await controller.open(root.path, create: false);

    final first = controller.rebuildIndex();
    final second = controller.rebuildIndex();
    expect(
      identical(first, second),
      isTrue,
      reason: 'the second call joined the one already running',
    );
    await first;
    await second;

    expect(deletes, 1, reason: 'the index was deleted exactly once');
    expect(controller.phase, LibraryPhase.ready);
    expect((await controller.children(0)).map((note) => note.name).toList(), [
      'a.md',
    ]);
    await controller.close();
    await controller.dispose();
  });
}
