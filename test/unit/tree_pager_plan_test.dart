// #1229: a name order reads a folder's first rows, and rows from an offset,
// as seeks on `notes_tree`, in either direction. The index is `(parent,
// is_dir DESC, name_key, name)`, so a descending name order is not a scan of
// it unless the read is split at `is_dir`; unsplit, SQLite sorted the whole
// folder for the first page and for every jump.
import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';

/// Every SELECT over `notes` a database ran, with the plan SQLite gave it.
final class _PlanLog extends QueryInterceptor {
  final plans = <({String sql, String detail})>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (statement.startsWith('SELECT * FROM notes')) {
      final plan = await executor.runSelect(
        'EXPLAIN QUERY PLAN $statement',
        args,
      );
      plans.add((
        sql: statement,
        detail: [for (final row in plan) row['detail']].join('\n'),
      ));
    }
    return await executor.runSelect(statement, args);
  }
}

void main() {
  late _PlanLog log;
  late IndexDatabase db;
  late NoteDao dao;

  setUp(() async {
    log = _PlanLog();
    db = IndexDatabase(NativeDatabase.memory().interceptWith(log));
    addTearDown(db.close);
    dao = NoteDao(db);
    for (var i = 0; i < 40; i++) {
      final name = 'n$i';
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              path: name,
              parent: 0,
              name: name,
              nameKey: nameSortKey(name),
              isDir: i % 4 == 0,
              size: 0,
              modified: DateTime(2026),
              created: DateTime(2026),
              pinned: const Value(false),
            ),
          );
    }
  });

  for (final sort in [TreeSort.nameAsc, TreeSort.nameDesc]) {
    test('the first rows and an offset read in ${sort.name} sort nothing '
        '(#1229)', () async {
      // Inside the folders, across their end, and past it into the files.
      final reads = <Future<List<Note>> Function()>[
        () => dao.childrenAt(0, offset: 0, limit: 6, sort: sort),
        () => dao.childrenAt(0, offset: 7, limit: 6, sort: sort),
        () => dao.childrenAt(0, offset: 25, limit: 6, sort: sort),
        () => dao.childrenAt(0, offset: 99, limit: 6, sort: sort),
        () => dao.childrenPage(0, limit: 6, sort: sort),
      ];
      for (final read in reads) {
        await read();
      }

      expect(log.plans, isNotEmpty);
      for (final plan in log.plans) {
        expect(plan.detail, contains('notes_tree'), reason: plan.sql);
        expect(plan.detail, isNot(contains('TEMP B-TREE')), reason: plan.sql);
      }
    });

    test('the split reads give the folder in ${sort.name} order', () async {
      final whole = [for (final n in await dao.children(0, sort: sort)) n.path];
      for (var offset = 0; offset <= whole.length; offset++) {
        for (final limit in [1, 6, 100]) {
          final read = await dao.childrenAt(
            0,
            offset: offset,
            limit: limit,
            sort: sort,
          );
          expect(
            [for (final n in read) n.path],
            whole.skip(offset).take(limit).toList(),
            reason: 'limit $limit from $offset',
          );
        }
      }
      final first = await dao.childrenPage(0, limit: 100, sort: sort);
      expect([for (final n in first) n.path], whole);
    });
  }

  test(
    'the warm-up prepares the statements the first page runs (#1230)',
    () async {
      for (final sort in TreeSort.values) {
        log.plans.clear();
        await dao.warmUpTree(sort: sort);
        final warmed = [for (final plan in log.plans) plan.sql];
        log.plans.clear();
        await dao.childrenAt(0, offset: 0, limit: 2000, sort: sort);
        final first = {for (final plan in log.plans) plan.sql};

        expect(warmed, isNotEmpty, reason: sort.name);
        expect(first.containsAll(warmed), isTrue, reason: sort.name);
      }
    },
  );
}
