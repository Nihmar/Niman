// T-M4-02/03: the frontmatter fields index — what the pinned section and
// the `key = value` filter read — and the index file's upgrade rule.
import 'dart:io';

import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/frontmatter/fields.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  // The upgrade test opens the same file twice on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late FieldRepo repo;

  setUp(() async {
    root = await Directory.current.createTemp('copist_fields_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    repo = FieldRepo(db);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  void write(String name, String content) {
    File(p.join(root.path, name)).writeAsStringSync(content);
  }

  group('pinnedNotes', () {
    test('lists the pinned notes in path order, folders excluded', () async {
      write('b.md', '---\npinned: true\n---\nb');
      write('a.md', '---\npinned: true\n---\na');
      write('c.md', '---\npinned: false\n---\nc');
      write('d.md', 'no frontmatter');
      Directory(p.join(root.path, 'folder')).createSync();
      await indexer.fullScan(root.path);

      expect((await repo.pinnedNotes()).map((n) => n.path), ['a.md', 'b.md']);
    });

    test('unpinning a note drops it from the list', () async {
      write('a.md', '---\npinned: true\n---\na');
      await indexer.fullScan(root.path);
      expect(await repo.pinnedNotes(), hasLength(1));

      write('a.md', '---\npinned: false\n---\na');
      await indexer.applyEvents(root.path, [p.join(root.path, 'a.md')]);

      expect(await repo.pinnedNotes(), isEmpty);
    });
  });

  group('notesWithField', () {
    setUp(() async {
      write('draft.md', '---\nstatus: Draft\nprojects: [alpha, beta]\n---\nx');
      write('done.md', '---\nstatus: done\n---\nx');
      write('other.md', '---\nprojects: [beta]\n---\nx');
      write('plain.md', 'nothing here');
      await indexer.fullScan(root.path);
    });

    test('filters by an invented key, case-insensitively', () async {
      expect(
        (await repo.notesWithField('status', 'draft')).map((n) => n.path),
        ['draft.md'],
      );
      expect(
        (await repo.notesWithField('STATUS', 'DRAFT')).map((n) => n.path),
        ['draft.md'],
      );
    });

    test('a list value matches any of its items', () async {
      expect(
        (await repo.notesWithField('projects', 'beta')).map((n) => n.path),
        ['draft.md', 'other.md'],
      );
      expect(
        (await repo.notesWithField('projects', 'alpha')).map((n) => n.path),
        ['draft.md'],
      );
    });

    test('an empty value asks for every note declaring the key', () async {
      expect((await repo.notesWithField('status', '')).map((n) => n.path), [
        'done.md',
        'draft.md',
      ]);
    });

    test('an unknown key or value matches nothing', () async {
      expect(await repo.notesWithField('nope', 'x'), isEmpty);
      expect(await repo.notesWithField('status', 'archived'), isEmpty);
    });
  });

  group('fieldKeys', () {
    test('counts the notes per key, most used first', () async {
      write('a.md', '---\nstatus: draft\nweight: 1\n---\nx');
      write('b.md', '---\nstatus: done\n---\nx');
      await indexer.fullScan(root.path);

      final keys = await repo.fieldKeys();
      expect(keys.map((k) => k.key), ['status', 'weight']);
      expect(keys.first.count, 2);
      expect(keys.last.count, 1);
    });
  });

  group('the index file upgrade', () {
    test('an older index is wiped and rebuilt, not migrated', () async {
      final file = File(p.join(root.path, 'index.db'));
      write('a.md', '---\nstatus: draft\n---\nx');

      final first = IndexDatabase(NativeDatabase(file));
      await Indexer(first).fullScan(root.path);
      expect(
        await FieldRepo(first).notesWithField('status', 'draft'),
        hasLength(1),
      );
      // Back-date the file so the next open takes the upgrade path.
      await first.customStatement('PRAGMA user_version = 1');
      await first.close();

      final second = IndexDatabase(NativeDatabase(file));
      addTearDown(second.close);
      // The rows are gone; the shape is current and usable.
      expect(await second.select(second.notes).get(), isEmpty);
      expect(await FieldRepo(second).fieldKeys(), isEmpty);

      // And one scan puts everything back.
      await Indexer(second).fullScan(root.path);
      expect(
        (await FieldRepo(second).notesWithField('status', 'draft')).single.path,
        'a.md',
      );
    });
  });
}
