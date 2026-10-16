// The tree reads (T-M6-01 rewrote two of them to seek rather than scan).
//
// The trap the range predicate has to survive: a folder's descendants are
// the paths starting `folder/`, and a sibling whose name merely starts
// with the folder's name is not one of them. `a`, `a.md`, `a0` and `ab`
// all sort next to each other, and only one of them is inside `a`.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';

void main() {
  late IndexDatabase db;
  late NoteDao dao;

  /// Inserts a row and returns its id.
  Future<int> add(
    String path, {
    required bool isDir,
    int parent = 0,
    int? id,
  }) async {
    return await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            id: id == null ? const Value.absent() : Value(id),
            path: path,
            parent: parent,
            name: path.split('/').last,
            nameKey: nameSortKey(path.split('/').last),
            isDir: isDir,
            size: isDir ? 0 : 10,
            modified: DateTime(2026),
            created: DateTime(2026),
          ),
        );
  }

  setUp(() async {
    db = IndexDatabase(NativeDatabase.memory());
    dao = NoteDao(db);
    final a = await add('a', isDir: true);
    await add('a/x.md', isDir: false, parent: a);
    await add('a.md', isDir: false);
    final a0 = await add('a0', isDir: true);
    await add('a0/y.md', isDir: false, parent: a0);
    final ab = await add('ab', isDir: true);
    await add('ab/z.md', isDir: false, parent: ab);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<String>> paths() async =>
      (await dao.allRows()).map((n) => n.path).toList()..sort();

  test('a subtree is the folder and what is under it, nothing adjacent', () {
    expect(
      dao.subtreeRows('a').then((rows) => rows.map((n) => n.path).toList()),
      completion(unorderedEquals(['a', 'a/x.md'])),
    );
  });

  test('deleting a subtree leaves the neighbours standing', () async {
    final gone = await dao.deleteSubtree('a');

    expect(gone, 2);
    expect(await paths(), ['a.md', 'a0', 'a0/y.md', 'ab', 'ab/z.md']);
  });

  test('an empty path means every row', () async {
    expect(await dao.subtreeRows(''), hasLength(7));
  });

  test('the folder list is the directories, by path', () async {
    expect((await dao.folders()).map((n) => n.path), ['a', 'a0', 'ab']);
  });

  test('children and the top level read the materialized rows', () async {
    final top = await dao.topLevel();
    // Directories first, then by name.
    expect(top.map((n) => n.path), ['a', 'a0', 'ab', 'a.md']);
    final a = await dao.find('a');
    expect((await dao.children(a!.id)).map((n) => n.path), ['a/x.md']);
  });

  // #726: the orders the tree offers, folders first in every one of them.
  test(
    'the name order ignores case and marks, and counts numbers (#1070)',
    () async {
      final names = [
        'Zebra.md',
        'apple.md',
        '\u00c9mile.md',
        'zed.md',
        'note 10.md',
        'note 2.md',
        'Note 1.md',
        'note 02a.md',
        'Archive',
      ];
      for (final name in names) {
        await add(name, isDir: name == 'Archive');
      }

      final order = await dao.children(0);
      final listed = order.map((n) => n.name).where(names.contains).toList();

      expect(listed, [
        'Archive',
        'apple.md',
        '\u00c9mile.md',
        'Note 1.md',
        'note 2.md',
        'note 02a.md',
        'note 10.md',
        'Zebra.md',
        'zed.md',
      ]);
    },
  );

  test('the tree query reads the name order from its index (#1070)', () async {
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM notes WHERE parent = 0 '
          'ORDER BY is_dir DESC, name_key, name',
        )
        .get();
    final detail = plan.map((r) => r.read<String>('detail')).join('\n');

    expect(detail, contains('notes_tree'));
    expect(detail, isNot(contains('TEMP B-TREE')));
  });

  group('the tree orders', () {
    late IndexDatabase orderDb;
    late NoteDao orderDao;

    Future<int> row(
      String path, {
      required bool isDir,
      required DateTime modified,
      required DateTime created,
      int parent = 0,
      int size = 0,
    }) {
      return orderDb
          .into(orderDb.notes)
          .insert(
            NotesCompanion.insert(
              path: path,
              parent: parent,
              name: path.split('/').last,
              nameKey: nameSortKey(path.split('/').last),
              isDir: isDir,
              size: size,
              modified: modified,
              created: created,
            ),
          );
    }

    setUp(() async {
      orderDb = IndexDatabase(NativeDatabase.memory());
      orderDao = NoteDao(orderDb);
      await row(
        'zed',
        isDir: true,
        modified: DateTime(2026, 3),
        created: DateTime(2026),
      );
      await row(
        'alba',
        isDir: true,
        modified: DateTime(2026),
        created: DateTime(2026, 3),
      );
      await row(
        'beta.md',
        isDir: false,
        size: 300,
        modified: DateTime(2026, 2),
        created: DateTime(2026, 4),
      );
      await row(
        'alpha.md',
        isDir: false,
        size: 100,
        modified: DateTime(2026, 4),
        created: DateTime(2026, 2),
      );
      await row(
        'gamma.md',
        isDir: false,
        size: 200,
        modified: DateTime(2026),
        created: DateTime(2026, 3),
      );
    });

    tearDown(() async {
      await orderDb.close();
    });

    Future<List<String>> names(TreeSort sort) async =>
        (await orderDao.children(0, sort: sort)).map((n) => n.name).toList();

    test('folders first in every order, then the field and the way', () async {
      // Folders lead whatever the field is, and the field orders both
      // groups; equal fields break by name.
      expect(await names(TreeSort.nameAsc), [
        'alba',
        'zed',
        'alpha.md',
        'beta.md',
        'gamma.md',
      ]);
      expect(await names(TreeSort.nameDesc), [
        'zed',
        'alba',
        'gamma.md',
        'beta.md',
        'alpha.md',
      ]);
      expect(await names(TreeSort.modifiedDesc), [
        'zed',
        'alba',
        'alpha.md',
        'beta.md',
        'gamma.md',
      ]);
      expect(await names(TreeSort.createdDesc), [
        'alba',
        'zed',
        'beta.md',
        'gamma.md',
        'alpha.md',
      ]);
      expect(await names(TreeSort.sizeAsc), [
        'alba',
        'zed',
        'alpha.md',
        'gamma.md',
        'beta.md',
      ]);
      expect(await names(TreeSort.sizeDesc), [
        'alba',
        'zed',
        'beta.md',
        'gamma.md',
        'alpha.md',
      ]);
    });
  });
}
