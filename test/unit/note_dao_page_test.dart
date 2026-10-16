// #1064: a folder's children come in pages by keyset, in the tree's order.
import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';

void main() {
  late IndexDatabase db;
  late NoteDao dao;

  setUp(() async {
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    dao = NoteDao(db);
    // Folders and notes, names that differ in case, numbers, and times and
    // sizes that repeat: every tie a cursor has to break.
    final names = [
      'Alpha',
      'alpha2',
      'alpha10',
      'Beta',
      'beta',
      'Émile',
      'zed',
      'Zed',
      for (var i = 0; i < 20; i++) 'n$i',
    ];
    for (var i = 0; i < names.length; i++) {
      await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              path: names[i],
              parent: 0,
              name: names[i],
              nameKey: nameSortKey(names[i]),
              isDir: i % 5 == 0,
              size: i % 3,
              modified: DateTime(2026, 1, 1 + i % 4),
              created: DateTime(2026, 2, 1 + i % 2),
            ),
          );
    }
    // Rows of another folder must not leak into a page.
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            path: 'other/x',
            parent: 99,
            name: 'x',
            nameKey: 'x',
            isDir: false,
            size: 0,
            modified: DateTime(2026),
            created: DateTime(2026),
            pinned: const Value(false),
          ),
        );
  });

  for (final sort in TreeSort.values) {
    test(
      'pages of 4 in ${sort.name} are the whole folder in its order',
      () async {
        final whole = await dao.children(0, sort: sort);
        final paged = <String>[];
        var pages = 0;
        for (
          var page = await dao.childrenPage(0, limit: 4, sort: sort);
          page.isNotEmpty;
          page = await dao.childrenPage(
            0,
            limit: 4,
            sort: sort,
            after: page.last,
          )
        ) {
          paged.addAll(page.map((n) => n.path));
          pages++;
          expect(page.length, lessThanOrEqualTo(4));
        }

        expect(paged, whole.map((n) => n.path).toList());
        expect(pages, (whole.length / 4).ceil());
      },
    );
  }

  test('a name page reads the notes_tree index, sorting nothing', () async {
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM notes WHERE parent = ? '
          'AND ((is_dir < ?) OR (is_dir = ? AND name_key > ?)) '
          'ORDER BY is_dir DESC, name_key ASC, name ASC LIMIT ?',
          variables: [
            const Variable<int>(0),
            const Variable<bool>(true),
            const Variable<bool>(true),
            const Variable<String>('a'),
            const Variable<int>(4),
          ],
        )
        .get();
    final detail = plan.map((r) => r.read<String>('detail')).join('\n');

    expect(detail, contains('notes_tree'));
    expect(detail, isNot(contains('TEMP B-TREE')));
  });
}
