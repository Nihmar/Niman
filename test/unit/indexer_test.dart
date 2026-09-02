import 'dart:io';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late CopistDatabase db;
  late Indexer indexer;
  late NoteDao dao;

  setUp(() async {
    root = await Directory.current.createTemp('copist_index_');
    db = CopistDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    dao = indexer.dao;

    File(p.join(root.path, 'note1.md')).writeAsStringSync('hello');
    File(p.join(root.path, 'note2.md')).writeAsStringSync('world');
    final docs = Directory(p.join(root.path, 'docs'));
    await docs.create();
    File(p.join(docs.path, 'doc1.md')).writeAsStringSync('deep note');
    Directory(p.join(root.path, 'empty_folder')).createSync();

    // Hidden content: must never be indexed.
    Directory(p.join(root.path, '.trash')).createSync();
    File(p.join(root.path, '.trash/secret.md')).writeAsStringSync('x');
    File(p.join(root.path, '.hidden.md')).writeAsStringSync('x');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('full scan mirrors the disk tree exactly', () async {
    await indexer.fullScan(root.path);
    final rows = await dao.allRows();
    expect(rows, hasLength(5));

    final paths = rows.map((n) => n.path).toSet();
    expect(
      paths,
      {
        'note1.md',
        'note2.md',
        'docs',
        'docs/doc1.md',
        'empty_folder',
      },
    );

    final note1 = rows.firstWhere((n) => n.path == 'note1.md');
    expect(note1.name, 'note1.md');
    expect(note1.isDir, false);
    expect(note1.parent, 0);
    expect(note1.size, 5);
    expect(note1.sha256, isNotNull);
    expect(note1.modified, toStoredSecond(
      File(p.join(root.path, 'note1.md')).statSync().modified,
    ));

    final docs = rows.firstWhere((n) => n.path == 'docs');
    expect(docs.isDir, true);
    expect(docs.sha256, isNull);
    expect(docs.size, 0);

    final doc1 = rows.firstWhere((n) => n.path == 'docs/doc1.md');
    expect(doc1.parent, docs.id);
    expect(doc1.name, 'doc1.md');

    final empty = rows.firstWhere((n) => n.path == 'empty_folder');
    expect(empty.isDir, true);
    expect(empty.parent, 0);
  });

  test('a fresh index reproduces the identical tree (rebuildable)', () async {
    await indexer.fullScan(root.path);
    final first = await dao.allRows();

    final db2 = CopistDatabase(NativeDatabase.memory());
    addTearDown(db2.close);
    await Indexer(db2).fullScan(root.path);
    final second = await NoteDao(db2).allRows();

    String norm(Note n) =>
        '${n.path}|${n.name}|${n.isDir}|${n.size}|${n.sha256}';
    expect(second.map(norm).toSet(), first.map(norm).toSet());
  });

  test('a rescan without changes does not rewrite the index', () async {
    await indexer.fullScan(root.path);
    var fired = false;
    indexer.onChanged = () {
      fired = true;
    };
    await indexer.fullScan(root.path);
    expect(fired, isFalse);
  });

  test('applyEvents picks up external create and delete', () async {
    await indexer.fullScan(root.path);

    final newAbs = p.join(root.path, 'note3.md');
    File(newAbs).writeAsStringSync('new');
    await indexer.applyEvents(root.path, [newAbs]);
    final added = await dao.find('note3.md');
    expect(added, isNotNull);
    expect(added!.name, 'note3.md');
    expect(added.size, 3);

    final oldAbs = p.join(root.path, 'note2.md');
    File(oldAbs).deleteSync();
    await indexer.applyEvents(root.path, [oldAbs]);
    expect(await dao.find('note2.md'), isNull);
  });

  test('applyEvents reconciles a rename by old and new path', () async {
    await indexer.fullScan(root.path);
    final oldAbs = p.join(root.path, 'note1.md');
    final newAbs = p.join(root.path, 'renamed.md');
    await File(oldAbs).rename(newAbs);

    await indexer.applyEvents(root.path, [oldAbs, newAbs]);
    expect(await dao.find('note1.md'), isNull);
    final renamed = await dao.find('renamed.md');
    expect(renamed, isNotNull);
    expect(renamed!.name, 'renamed.md');
  });

  test(
    'a renamed directory is pruned via the stale path; '
    'the full rescan recovers the destination',
    () async {
    await indexer.fullScan(root.path);
    await Directory(p.join(root.path, 'docs')).rename(
      p.join(root.path, 'books'),
    );

    // Mimic the watcher batch when the OS did not report the destination:
    // parent resync + the stale path.
    await indexer.resync(root.path, root.path);
    await indexer.applyEvents(root.path, [p.join(root.path, 'docs')]);

    expect(await dao.find('docs'), isNull);
    expect(await dao.find('books'), isNull);

    // The periodic full rescan is the documented safety net.
    await indexer.fullScan(root.path);
    final books = await dao.find('books');
    expect(books, isNotNull);
    expect(await dao.find('books/doc1.md'), isNotNull);
  });

  test(
    'applyEvents ignores paths outside the library and dot components',
    () async {
    await indexer.fullScan(root.path);
    final outside = await Directory.current.createTemp('copist_outside_');
    addTearDown(() => outside.delete(recursive: true));
    File(p.join(outside.path, 'x.md')).writeAsStringSync('x');

    await indexer.applyEvents(root.path, [
      p.join(outside.path, 'x.md'),
      p.join(root.path, '.trash/secret.md'),
      p.join(root.path, '.hidden.md'),
    ]);
    // Nothing changed: the index still holds exactly the seeded rows.
    expect(await dao.allRows(), hasLength(5));
  });

  test('content change updates size and digest', () async {
    await indexer.fullScan(root.path);
    final initial = (await dao.find('note1.md'))!;
    expect(initial.sha256, isNotNull);

    File(p.join(root.path, 'note1.md')).writeAsStringSync('changed');
    await indexer.applyEvents(root.path, [p.join(root.path, 'note1.md')]);
    final updated = (await dao.find('note1.md'))!;
    expect(updated.size, 7);
    expect(updated.sha256, isNot(initial.sha256));
  });
}
