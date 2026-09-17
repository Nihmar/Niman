// Issue #79: the trash empties itself of what has waited long enough,
// and of nothing else.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/trash_cleaner.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;

  setUp(() async {
    root = await Directory.current.createTemp('niman_trash_clean_');
    dbDir = await Directory.current.createTemp('niman_trash_clean_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    final indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  /// Deletes a note into the trash and answers its trash name.
  Future<String> trashANote(String name) async {
    await ops.createNote(parentPath: '', name: name);
    await ops.delete('$name.md');
    final item = (await ops.trashItems()).firstWhere(
      (i) => i.originalPath == '$name.md',
    );
    return item.name;
  }

  /// The clock as it will read [days] from now — the waiting is what the
  /// cleaner reads, so moving the clock beats faking the manifest.
  DateTime inDays(int days) => DateTime.now().add(Duration(days: days));

  test('deletes every item that waited longer than the setting', () async {
    final old = await trashANote('Old');
    final young = await trashANote('Young');
    final deleted = await autoEmptyTrash(ops, maxAgeDays: 30, now: inDays(31));
    expect(deleted, 2);
    expect(await ops.trashItems(), isEmpty);
    expect(File(p.join(root.path, '.trash', old)).existsSync(), isFalse);
    expect(File(p.join(root.path, '.trash', young)).existsSync(), isFalse);
  });

  test('an item that has not waited long enough stays', () async {
    final name = await trashANote('Recent');
    expect(await autoEmptyTrash(ops, maxAgeDays: 30, now: inDays(29)), 0);
    expect(await ops.trashItems(), hasLength(1));
    expect(File(p.join(root.path, '.trash', name)).existsSync(), isTrue);
  });

  test('off empties nothing, however long the wait has been', () async {
    await trashANote('Ancient');
    expect(await autoEmptyTrash(ops, maxAgeDays: 0, now: inDays(4000)), 0);
    expect(await autoEmptyTrash(ops, maxAgeDays: -30, now: inDays(4000)), 0);
    expect(await ops.trashItems(), hasLength(1));
  });

  test('a file dropped into .trash by hand is left alone', () async {
    await trashANote('Managed');
    // No manifest entry, so no deletion date: nothing says this one has
    // waited at all, and the cleaner does not guess.
    final byHand = File(p.join(root.path, '.trash', 'by-hand.md'))
      ..writeAsStringSync('mine');
    expect(await autoEmptyTrash(ops, maxAgeDays: 1, now: inDays(400)), 1);
    expect(byHand.existsSync(), isTrue);
  });

  test('a folder in the trash goes with everything under it', () async {
    await ops.createFolder(parentPath: '', name: 'Docs');
    await ops.createNote(parentPath: 'Docs', name: 'One');
    await ops.delete('Docs');
    expect(await autoEmptyTrash(ops, maxAgeDays: 7, now: inDays(8)), 1);
    expect(
      Directory(p.join(root.path, '.trash', 'Docs')).existsSync(),
      isFalse,
    );
    expect(await ops.trashItems(), isEmpty);
  });
}
