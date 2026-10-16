// #1063: a folder renamed or moved by the app is a rewrite of the paths of
// its rows, not a re-index of its notes.
import 'dart:io';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

/// Counts every statement the index runs.
final class _Statements extends QueryInterceptor {
  int count = 0;

  @override
  Future<int> runInsert(QueryExecutor e, String statement, List<Object?> args) {
    count++;
    return super.runInsert(e, statement, args);
  }

  @override
  Future<int> runUpdate(QueryExecutor e, String statement, List<Object?> args) {
    count++;
    return super.runUpdate(e, statement, args);
  }

  @override
  Future<int> runDelete(QueryExecutor e, String statement, List<Object?> args) {
    count++;
    return super.runDelete(e, statement, args);
  }

  @override
  Future<void> runCustom(
    QueryExecutor e,
    String statement,
    List<Object?> args,
  ) {
    count++;
    return super.runCustom(e, statement, args);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor e,
    String statement,
    List<Object?> args,
  ) {
    count++;
    return super.runSelect(e, statement, args);
  }
}

void main() {
  const notes = 40;
  late Directory root;
  late _Statements statements;
  late IndexDatabase db;
  late Indexer indexer;

  void write(String rel, String text) {
    File(p.join(root.path, rel))
      ..createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  Future<void> move(String from, String to) async {
    Directory(p.dirname(p.join(root.path, to))).createSync(recursive: true);
    await Directory(p.join(root.path, from)).rename(p.join(root.path, to));
  }

  Future<Set<int>> ftsRows(String word) async {
    final rows = await db
        .customSelect(
          'SELECT rowid AS id FROM notes_fts WHERE notes_fts MATCH ?',
          variables: [Variable<String>(word)],
        )
        .get();
    return {for (final row in rows) row.read<int>('id')};
  }

  setUp(() async {
    root = await Directory.current.createTemp('niman_move_');
    statements = _Statements();
    db = IndexDatabase(NativeDatabase.memory().interceptWith(statements));
    addTearDown(db.close);
    indexer = Indexer(db);
    for (var i = 0; i < notes; i++) {
      write(p.join('Big', 'n$i.md'), 'zebra $i');
    }
    write(p.join('Big', 'sub', 'deep.md'), 'zebra deep');
    write('Outside.md', 'outside');
    await indexer.fullScan(root.path);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('renaming a folder reads no note and keeps every id (#1063)', () async {
    // The folder of the issue: two thousand notes.
    for (var i = notes; i < 2000; i++) {
      write(p.join('Big', 'n$i.md'), 'zebra $i');
    }
    await indexer.fullScan(root.path);
    final idsBefore = {
      for (final row in await indexer.dao.subtreeRows('Big')) row.path: row.id,
    };
    final before = await ftsRows('zebra');
    var reads = 0;
    indexer.onProgress = (_) => reads++;
    await move('Big', 'Renamed');
    statements.count = 0;

    final moved = await indexer.relocateFolder(
      root.path,
      p.join(root.path, 'Big'),
      p.join(root.path, 'Renamed'),
    );

    _say(
      'folder rename, ${idsBefore.length} rows: ${statements.count} '
      'statements, $reads note reads',
    );
    expect(moved, isTrue);
    expect(reads, 0, reason: 'no note is read');
    expect(statements.count, lessThan(40), reason: 'not a statement per note');
    expect(await indexer.dao.find('Big'), isNull);
    expect(await indexer.dao.subtreeRows('Big'), isEmpty);
    final after = {
      for (final row in await indexer.dao.subtreeRows('Renamed'))
        row.path: row.id,
    };
    expect(after.length, idsBefore.length);
    for (final MapEntry(:key, :value) in idsBefore.entries) {
      final moved = key == 'Big' ? 'Renamed' : 'Renamed${key.substring(3)}';
      expect(after[moved], value, reason: '$key keeps its id');
    }
    expect(await ftsRows('zebra'), before, reason: 'the word index is intact');
    final sub = (await indexer.dao.find('Renamed/sub/deep.md'))!;
    expect(sub.parent, (await indexer.dao.find('Renamed/sub'))!.id);
    expect(
      (await indexer.dao.find('Renamed'))!.name,
      'Renamed',
      reason: 'the folder row follows its name',
    );
  });

  test('NoteOps renames and moves a folder without reading it', () async {
    final ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    final id = (await indexer.dao.find('Big/n7.md'))!.id;
    var reads = 0;
    indexer.onProgress = (_) => reads++;

    final renamed = await ops.rename('Big', 'Renamed');
    expect(reads, 0, reason: 'the rename read no note');
    expect(renamed.path, 'Renamed');
    write(p.join('Archive', 'keep.md'), 'k');
    await indexer.fullScan(root.path);
    reads = 0;
    final moved = await ops.move('Renamed', 'Archive');

    expect(moved.path, 'Archive/Renamed');
    expect(reads, 0, reason: 'no note was read');
    expect((await indexer.dao.find('Archive/Renamed/n7.md'))!.id, id);
    expect(await indexer.dao.find('Big/n7.md'), isNull);
  });

  test('moving a folder under another repoints its parent', () async {
    write(p.join('Archive', 'keep.md'), 'k');
    await indexer.fullScan(root.path);
    await move('Big', p.join('Archive', 'Big'));

    final moved = await indexer.relocateFolder(
      root.path,
      p.join(root.path, 'Big'),
      p.join(root.path, 'Archive', 'Big'),
    );

    expect(moved, isTrue);
    final archive = (await indexer.dao.find('Archive'))!;
    final big = (await indexer.dao.find('Archive/Big'))!;
    expect(big.parent, archive.id);
    expect(big.name, 'Big');
    expect((await indexer.dao.find('Archive/Big/n7.md'))!.parent, big.id);
  });

  test('the watcher echo of a move walks no subtree (#1063)', () async {
    for (var i = notes; i < 400; i++) {
      write(p.join('Big', 'n$i.md'), 'zebra $i');
    }
    await indexer.fullScan(root.path);
    await move('Big', 'Renamed');
    await indexer.relocateFolder(
      root.path,
      p.join(root.path, 'Big'),
      p.join(root.path, 'Renamed'),
    );
    var reads = 0;
    indexer.onProgress = (_) => reads++;
    statements.count = 0;

    // What the watcher reports for the app's own move.
    await indexer.applyEvents(root.path, [
      p.join(root.path, 'Big'),
      p.join(root.path, 'Renamed'),
    ]);

    expect(reads, 0);
    expect(
      statements.count,
      lessThan(100),
      reason: 'statements: ${statements.count}',
    );
  });

  test('a move the disk does not show is left to the event path', () async {
    final moved = await indexer.relocateFolder(
      root.path,
      p.join(root.path, 'Big'),
      p.join(root.path, 'Nowhere'),
    );

    expect(moved, isFalse);
    expect(await indexer.dao.find('Big/n7.md'), isNotNull);
  });

  test('notes whose links read from their folder are linked again', () async {
    write(p.join('Docs', 'near.md'), 'near');
    write(p.join('Docs', 'rel.md'), 'see [out](../Outside.md) and [[near]]');
    await indexer.fullScan(root.path);
    final rel = (await indexer.dao.find('Docs/rel.md'))!;
    Future<int> edgesOf(int id) async =>
        (await db
                .customSelect(
                  'SELECT count(*) AS c FROM note_links WHERE from_note = ?',
                  variables: [Variable<int>(id)],
                )
                .getSingle())
            .read<int>('c');
    expect(await edgesOf(rel.id), 2);

    // Docs moves a level down: ../Outside.md no longer names the note it did.
    await move('Docs', p.join('Deeper', 'Docs'));
    var reads = 0;
    indexer.onProgress = (_) => reads++;
    await indexer.relocateFolder(
      root.path,
      p.join(root.path, 'Docs'),
      p.join(root.path, 'Deeper', 'Docs'),
    );

    final moved = (await indexer.dao.find('Deeper/Docs/rel.md'))!;
    expect(moved.id, rel.id);
    expect(reads, 1, reason: 'only the note that links out is read');
    expect(await edgesOf(moved.id), 1, reason: 'the wiki link stays');
  });
}

/// Prints a measurement. The numbers are the point of this test, so they go
/// to the console rather than into an assertion message nobody sees.
// ignore: avoid_print
void _say(String line) => print(line);
