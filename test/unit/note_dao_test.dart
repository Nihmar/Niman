// The tree reads (T-M6-01 rewrote two of them to seek rather than scan).
//
// The trap the range predicate has to survive: a folder's descendants are
// the paths starting `folder/`, and a sibling whose name merely starts
// with the folder's name is not one of them. `a`, `a.md`, `a0` and `ab`
// all sort next to each other, and only one of them is inside `a`.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
            isDir: isDir,
            size: isDir ? 0 : 10,
            modified: DateTime(2026),
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
}
