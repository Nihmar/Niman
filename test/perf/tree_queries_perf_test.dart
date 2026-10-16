// What the tree's index queries cost on a big table (#1065, #1064, #1063).
//
// The rows are written straight into the index with one recursive INSERT, so
// the table is 200 000 rows in a second and the numbers are SQLite's, not the
// filesystem's. Every run prints its numbers and asserts a backstop three
// times as wide as the design's ceiling; `NIMAN_PERF=1` holds the ceiling
// itself (AGENTS.md).

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/frontmatter/fields.dart';

final bool _referenceHost = Platform.environment['NIMAN_PERF'] == '1';

/// The bar [ceiling] is held to, per [_referenceHost].
double _bar(double ceiling) => _referenceHost ? ceiling : ceiling * 3;

const int _rows = 200000;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late IndexDatabase db;

  setUp(() async {
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      'WITH RECURSIVE s(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM s '
      'WHERE i < $_rows) '
      'INSERT INTO notes (path, parent, name, is_dir, size, modified, '
      'created, pinned, name_key) '
      "SELECT 'Inbox/n' || i || '.md', 0, 'n' || i || '.md', 0, 0, 0, 0, "
      'i IN (5, 90000, 199999), '
      "'n' || printf('%07d', i) || '.md' FROM s",
    );
  });

  test('the pinned notes come from the partial index, not a scan', () async {
    final repo = FieldRepo(db);
    await repo.pinnedNotes(); // opens the connection and prepares the statement
    final clock = Stopwatch()..start();
    final pinned = await repo.pinnedNotes();
    final ms = clock.elapsedMicroseconds / 1000;
    _say('pinnedNotes over $_rows rows: ${ms.toStringAsFixed(2)} ms');

    expect(pinned, hasLength(3));
    expect(ms, lessThan(_bar(20)));
  });

  test('a page of a big root costs the page, not the folder (#1064)', () async {
    final dao = NoteDao(db);
    await dao.childrenPage(0, limit: 2001); // opens the connection
    final clock = Stopwatch()..start();
    final first = await dao.childrenPage(0, limit: 2001);
    final firstMs = clock.elapsedMicroseconds / 1000;
    clock
      ..reset()
      ..start();
    final deep = await dao.childrenPage(0, limit: 2001, after: first.last);
    final deepMs = clock.elapsedMicroseconds / 1000;
    _say(
      'page of 2001 in a $_rows-row root: first ${firstMs.toStringAsFixed(1)} '
      'ms, next ${deepMs.toStringAsFixed(1)} ms',
    );

    expect(first, hasLength(2001));
    expect(deep.first.path, isNot(first.first.path));
    expect(firstMs, lessThan(_bar(200)));
    expect(deepMs, lessThan(_bar(200)));
  });

  test(
    'the tree of a 200k-note root reads its index in order (#1064)',
    () async {
      final dao = NoteDao(db);
      await dao.tree(
        const [],
      ); // opens the connection and prepares the statement
      final clock = Stopwatch()..start();
      final rows = await dao.tree(const []);
      final ms = clock.elapsedMicroseconds / 1000;
      _say('tree of $_rows rows in the root: ${ms.toStringAsFixed(1)} ms');
      expect(rows, hasLength(_rows));

      final generated = dao.treeQuery(const []).constructQuery();
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN ${generated.sql}',
            variables: generated.introducedVariables,
          )
          .get();
      final detail = plan.map((r) => r.read<String>('detail')).join('\n');
      expect(detail, contains('notes_tree'));
      expect(detail, isNot(contains('TEMP B-TREE')));
    },
  );
}

/// Prints a measurement. The numbers are the point of this file, so they
/// go to the console rather than into an assertion message nobody sees.
// ignore: avoid_print
void _say(String line) => print(line);
