import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/library/note_ops.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late CopistDatabase db;
  late Indexer indexer;
  late NoteOps ops;
  late NoteDao dao;

  setUp(() async {
    root = await Directory.current.createTemp('copist_ops_');
    dbDir = await Directory.current.createTemp('copist_ops_db_');
    db = CopistDatabase(
      NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))),
    );
    addTearDown(db.close);
    indexer = Indexer(db);
    dao = indexer.dao;
    ops = NoteOps(root: root.path, db: db, indexer: indexer);
  });

  tearDown(() async {
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  group('create', () {
    test('creates an empty note file and index row', () async {
      final row = await ops.createNote(parentPath: '', name: 'My Note');
      expect(File(p.join(root.path, 'My Note.md')).existsSync(), isTrue);
      expect(File(p.join(root.path, 'My Note.md')).readAsStringSync(), '');
      expect(row.path, 'My Note.md');
      expect(row.name, 'My Note.md');
      expect(await dao.find('My Note.md'), isNotNull);
    });

    test('uniquifies colliding names', () async {
      final a = await ops.createNote(parentPath: '', name: 'Same');
      final b = await ops.createNote(parentPath: '', name: 'Same');
      expect(a.path, 'Same.md');
      expect(b.path, 'Same_1.md');
    });

    test('sanitizes illegal characters in names', () async {
      final row = await ops.createNote(parentPath: '', name: 'a/b?c');
      expect(row.path, 'abc.md');
      expect(File(p.join(root.path, 'abc.md')).existsSync(), isTrue);
    });

    test('creates folders and nested notes', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      final note = await ops.createNote(parentPath: 'Docs', name: 'One');
      expect(note.path, 'Docs/One.md');
      expect(File(p.join(root.path, 'Docs/One.md')).existsSync(), isTrue);
      expect(await dao.find('Docs/One.md'), isNotNull);
    });
  });

  group('rename', () {
    test('renames a note', () async {
      await ops.createNote(parentPath: '', name: 'Old');
      await ops.rename('Old.md', 'New');
      expect(File(p.join(root.path, 'New.md')).existsSync(), isTrue);
      expect(await dao.find('New.md'), isNotNull);
      expect(await dao.find('Old.md'), isNull);
    });

    test('treats a trailing .md in the new name as redundant', () async {
      await ops.createNote(parentPath: '', name: 'Old');
      await ops.rename('Old.md', 'New.md');
      expect(await dao.find('New.md'), isNotNull);
      expect(File(p.join(root.path, 'New.md')).existsSync(), isTrue);
    });

    test('renaming a folder reindexes its subtree', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'One');
      await ops.rename('Docs', 'Books');
      final books = (await dao.find('Books'))!;
      expect(books.isDir, true);
      final one = (await dao.find('Books/One.md'))!;
      expect(one.parent, books.id);
    });

    test('renames onto its own name are a no-op', () async {
      final row = await ops.createNote(parentPath: '', name: 'Same');
      final renamed = await ops.rename('Same.md', 'Same');
      expect(renamed.id, row.id);
    });
  });

  group('move', () {
    test('moves a note into a folder', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: '', name: 'Loose');
      await ops.move('Loose.md', 'Docs');
      expect(await dao.find('Docs/Loose.md'), isNotNull);
      expect(File(p.join(root.path, 'Docs/Loose.md')).existsSync(), isTrue);
      expect(await dao.find('Loose.md'), isNull);
    });

    test('uniquifies when the target already holds the name', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'X');
      await ops.createNote(parentPath: '', name: 'X');
      await ops.move('X.md', 'Docs');
      expect(await dao.find('Docs/X.md'), isNotNull);
      expect(await dao.find('Docs/X_1.md'), isNotNull);
    });

    test('moving a folder into itself or its own subtree is rejected',
        () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createFolder(parentPath: 'Docs', name: 'Inner');

      await expectLater(
        () => ops.move('Docs', 'Docs'),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        () => ops.move('Docs', 'Docs/Inner'),
        throwsA(isA<ArgumentError>()),
      );
      // The move was never attempted: nothing moved, nothing renamed.
      expect(await dao.find('Docs'), isNotNull);
      expect(await dao.find('Docs/Inner'), isNotNull);
      expect(
        Directory(p.join(root.path, 'Docs/Inner')).existsSync(),
        isTrue,
      );
    });
  });

  group('delete (trash on by default)', () {
    test('moves the note into .trash with a manifest entry', () async {
      await ops.createNote(parentPath: '', name: 'Gone');
      await ops.delete('Gone.md');
      expect(File(p.join(root.path, 'Gone.md')).existsSync(), isFalse);
      expect(
        File(p.join(root.path, '.trash/Gone.md')).existsSync(),
        isTrue,
      );
      final items = await ops.trashItems();
      expect(items, hasLength(1));
      expect(items.first.name, 'Gone.md');
      expect(items.first.originalPath, 'Gone.md');
    });

    test('moves a folder subtree into .trash as a directory', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'One');
      await ops.delete('Docs');
      expect(
        Directory(p.join(root.path, '.trash/Docs')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(root.path, '.trash/Docs/One.md')).existsSync(),
        isTrue,
      );
      expect(await dao.find('Docs'), isNull);
    });

    test('trash name collisions are timestamped', () async {
      await ops.createNote(parentPath: '', name: 'Dup');
      await ops.delete('Dup.md');
      await ops.createNote(parentPath: '', name: 'Dup');
      await ops.delete('Dup.md');
      final items = await ops.trashItems();
      expect(items, hasLength(2));
      final names = items.map((i) => i.name).toSet();
      expect(names, isNot({'Dup.md'}));
    });
  });

  group('restore', () {
    test('restores a note to its original location', () async {
      await ops.createNote(parentPath: '', name: 'Gone');
      await ops.delete('Gone.md');
      final item = (await ops.trashItems()).single;
      final restored = await ops.restoreTrash(item.name);
      expect(restored.path, 'Gone.md');
      expect(File(p.join(root.path, 'Gone.md')).existsSync(), isTrue);
      expect(await ops.trashItems(), isEmpty);
    });

    test('restores a folder with its contents reindexed', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'One');
      await ops.delete('Docs');
      final item = (await ops.trashItems()).single;
      final restored = await ops.restoreTrash(item.name);
      expect(restored.path, 'Docs');
      expect(File(p.join(root.path, 'Docs/One.md')).existsSync(), isTrue);
      expect(await dao.find('Docs/One.md'), isNotNull);
    });

    test('falls back to the root when the original parent is gone', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'One');
      await ops.delete('Docs/One.md'); // → .trash/One.md
      await ops.delete('Docs'); // its original parent → .trash/Docs
      final item = (await ops.trashItems())
          .firstWhere((i) => i.name == 'One.md');
      final restored = await ops.restoreTrash(item.name);
      expect(restored.path, 'One.md');
      expect(await dao.find('One.md'), isNotNull);
      expect(File(p.join(root.path, 'One.md')).existsSync(), isTrue);
    });

    test('throws for unmanaged trash names', () async {
      await expectLater(
        () => ops.restoreTrash('not-managed.md'),
        throwsStateError,
      );
    });

    test('restores a timestamped note under its original name', () async {
      await ops.createNote(parentPath: '', name: 'Dup');
      await ops.delete('Dup.md');
      await ops.createNote(parentPath: '', name: 'Dup');
      await ops.delete('Dup.md');
      final items = await ops.trashItems();
      final plain = items.firstWhere((i) => i.name == 'Dup.md');
      final timestamped = items.firstWhere((i) => i.name != 'Dup.md');

      await ops.restoreTrash(plain.name);
      await ops.restoreTrash(timestamped.name);

      // Both come back under the original name, the second uniquified.
      expect(await dao.find('Dup.md'), isNotNull);
      expect(await dao.find('Dup_1.md'), isNotNull);
    });

    test('restores a dotted folder name whole', () async {
      await ops.createFolder(parentPath: '', name: 'v1.2 notes');
      await ops.createNote(parentPath: 'v1.2 notes', name: 'One');
      await ops.delete('v1.2 notes');
      final item = (await ops.trashItems()).single;

      final restored = await ops.restoreTrash(item.name);

      expect(restored.path, 'v1.2 notes');
      expect(await dao.find('v1.2 notes'), isNotNull);
      expect(await dao.find('v1.2 notes/One.md'), isNotNull);
    });
  });

  group('trash management', () {
    test('deleteTrashPermanently removes the manifest item and disk', () async {
      await ops.createNote(parentPath: '', name: 'Gone');
      await ops.delete('Gone.md');
      final item = (await ops.trashItems()).single;
      await ops.deleteTrashPermanently(item.name);
      expect(await ops.trashItems(), isEmpty);
      expect(
        File(p.join(root.path, '.trash/Gone.md')).existsSync(),
        isFalse,
      );
    });

    test('emptyTrash removes every item', () async {
      await ops.createNote(parentPath: '', name: 'A');
      await ops.createNote(parentPath: '', name: 'B');
      await ops.delete('A.md');
      await ops.delete('B.md');
      await ops.emptyTrash();
      expect(await ops.trashItems(), isEmpty);
      expect(
        File(p.join(root.path, '.trash/A.md')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(root.path, '.trash/B.md')).existsSync(),
        isFalse,
      );
    });

    test('a corrupt manifest entry is skipped, the rest still listed',
        () async {
      await ops.createNote(parentPath: '', name: 'A');
      await ops.createNote(parentPath: '', name: 'B');
      await ops.delete('A.md');
      await ops.delete('B.md');
      final manifestFile = File(
        p.join(root.path, '.trash/${NoteOps.manifestFileName}'),
      );
      final raw =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      raw['A.md'] = <String, dynamic>{'originalPath': 'A.md'};
      manifestFile.writeAsStringSync(jsonEncode(raw));

      final items = await ops.trashItems();

      expect(items.map((i) => i.name).toList(), ['B.md']);
    });

    test('a non-JSON manifest file yields an empty listing', () async {
      await ops.createNote(parentPath: '', name: 'A');
      await ops.delete('A.md');
      File(p.join(root.path, '.trash/${NoteOps.manifestFileName}'))
          .writeAsStringSync('{not json');

      expect(await ops.trashItems(), isEmpty);
    });

    test('writing the manifest prunes items that left the trash',
        () async {
      await ops.createNote(parentPath: '', name: 'A');
      await ops.createNote(parentPath: '', name: 'B');
      await ops.delete('A.md');
      await ops.delete('B.md');
      // Something removes an item without going through the ops.
      File(p.join(root.path, '.trash/A.md')).deleteSync();

      // The next manifest write (another delete) drops the stale entry.
      await ops.createNote(parentPath: '', name: 'C');
      await ops.delete('C.md');

      final manifestFile = File(
        p.join(root.path, '.trash/${NoteOps.manifestFileName}'),
      );
      final raw =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(raw.keys, {'B.md', 'C.md'});
    });
  });

  group('trash toggle', () {
    test('delete hard-deletes when the toggle is off', () async {
      await ops.createNote(parentPath: '', name: 'Gone');
      await ops.setTrashEnabled(enabled: false);
      await ops.delete('Gone.md');
      expect(File(p.join(root.path, 'Gone.md')).existsSync(), isFalse);
      expect(Directory(p.join(root.path, '.trash')).existsSync(), isFalse);
    });

    test('the toggle persists on the database', () async {
      await ops.setTrashEnabled(enabled: false);
      final fresh = NoteOps(root: root.path, db: db, indexer: indexer);
      expect(await fresh.trashEnabled, isFalse);
      // The repo agrees too.
      final repo = LibrarySettingsRepo(db);
      expect(await repo.isTrashEnabled(root.path), isFalse);
    });
  });
}
