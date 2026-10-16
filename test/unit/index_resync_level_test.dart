// #1062: a resync of a directory reconciles that directory's own entries, and
// does not walk or load the subtree below it.
import 'dart:io';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:path/path.dart' as p;

/// Counts the rows every SELECT hands back.
final class _RowCounter extends QueryInterceptor {
  int rows = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final result = await super.runSelect(executor, statement, args);
    rows += result.length;
    return result;
  }
}

void main() {
  late Directory root;
  late _RowCounter counter;
  late IndexDatabase db;
  late Indexer indexer;

  setUp(() async {
    root = await Directory.current.createTemp('niman_level_');
    counter = _RowCounter();
    db = IndexDatabase(NativeDatabase.memory().interceptWith(counter));
    addTearDown(db.close);
    indexer = Indexer(db);
    // Archive holds three notes and a deep folder of 300.
    File(p.join(root.path, 'Archive', 'a.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('a');
    File(p.join(root.path, 'Archive', 'keep.md')).writeAsStringSync('k');
    File(p.join(root.path, 'Archive', 'x.md')).writeAsStringSync('x');
    for (var i = 0; i < 300; i++) {
      File(p.join(root.path, 'Archive', 'deep', 'n$i.md'))
        ..createSync(recursive: true)
        ..writeAsStringSync('note $i');
    }
    await indexer.fullScan(root.path);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test(
    'a resync after a rename loads the directory, not its subtree',
    () async {
      await File(p.join(root.path, 'Archive', 'a.md'))
          .rename(p.join(root.path, 'Archive', 'b.md'));
      counter.rows = 0;

      await indexer.resync(root.path, p.join(root.path, 'Archive'));

      expect(await indexer.dao.find('Archive/b.md'), isNotNull);
      expect(await indexer.dao.find('Archive/a.md'), isNull);
      // The folder's rows: its children plus the lookups of the write. The
      // 300 notes below Archive/deep were 300 more.
      expect(counter.rows, lessThan(50), reason: 'rows read: ${counter.rows}');
    },
  );

  test('a new subfolder is synced whole, an indexed one left alone', () async {
    final fresh = p.join(root.path, 'Archive', 'fresh');
    File(p.join(fresh, 'inside.md'))
      ..createSync(recursive: true)
      ..writeAsStringSync('inside');
    // Behind the index's back, a note appears in an indexed subfolder: it
    // is that folder's event to report, not this level's.
    File(p.join(root.path, 'Archive', 'deep', 'late.md'))
        .writeAsStringSync('l');

    await indexer.resync(root.path, p.join(root.path, 'Archive'));

    expect(await indexer.dao.find('Archive/fresh/inside.md'), isNotNull);
    expect(await indexer.dao.find('Archive/deep/late.md'), isNull);
  });

  test('a note and a folder gone from the level are pruned', () async {
    File(p.join(root.path, 'Archive', 'x.md')).deleteSync();
    Directory(p.join(root.path, 'Archive', 'deep')).deleteSync(recursive: true);
    final removed = <String>{};
    indexer.onRemoved = removed.addAll;

    await indexer.resync(root.path, p.join(root.path, 'Archive'));

    expect(await indexer.dao.find('Archive/x.md'), isNull);
    expect(await indexer.dao.find('Archive/deep'), isNull);
    expect(await indexer.dao.find('Archive/deep/n7.md'), isNull);
    expect(removed, {'Archive/x.md', 'Archive/deep'});
  });
}
