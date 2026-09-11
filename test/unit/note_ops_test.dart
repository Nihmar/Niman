import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteOps ops;
  late NoteDao dao;

  setUp(() async {
    root = await Directory.current.createTemp('niman_ops_');
    dbDir = await Directory.current.createTemp('niman_ops_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    indexer = Indexer(db);
    dao = indexer.dao;
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
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

  // T-TPL-02: what a template's `folder:` and `append:` directives need
  // from the ops layer.
  group('ensureFolder', () {
    test('creates the whole chain, and indexes every folder in it', () async {
      final row = await ops.ensureFolder('Journal/2026/03');
      expect(row.path, 'Journal/2026/03');
      expect(
        Directory(p.join(root.path, 'Journal/2026/03')).existsSync(),
        true,
      );
      expect(await dao.find('Journal'), isNotNull);
      expect(await dao.find('Journal/2026'), isNotNull);
      expect(await dao.find('Journal/2026/03'), isNotNull);
    });

    test('an existing folder is returned, never uniquified', () async {
      final first = await ops.ensureFolder('Journal');
      final second = await ops.ensureFolder('Journal');
      expect(second.path, first.path);
      expect(await dao.find('Journal_1'), isNull);
    });

    test('a path out of a settings file is sanitized', () async {
      final row = await ops.ensureFolder('/../World//Places/');
      expect(row.path, 'World/Places');
    });

    test('the root is not a folder anyone can ask for', () async {
      await expectLater(ops.ensureFolder(''), throwsArgumentError);
    });
  });

  group('appendToNote', () {
    test('a missing note is created with the content', () async {
      final row = await ops.appendToNote('Log.md', '- one\n');
      expect(row.path, 'Log.md');
      expect(File(p.join(root.path, 'Log.md')).readAsStringSync(), '- one\n');
    });

    test('a second append goes under the first, one blank line down', () async {
      await ops.appendToNote('Log.md', '- one\n');
      await ops.appendToNote('Log.md', '- two\n');
      expect(
        File(p.join(root.path, 'Log.md')).readAsStringSync(),
        '- one\n\n- two\n',
      );
    });

    test('trailing blank lines do not pile up', () async {
      await ops.appendToNote('Log.md', '- one\n\n\n\n');
      await ops.appendToNote('Log.md', '- two\n');
      expect(
        File(p.join(root.path, 'Log.md')).readAsStringSync(),
        '- one\n\n- two\n',
      );
    });

    test('a CRLF note keeps its line endings at the join', () async {
      final file = File(p.join(root.path, 'Log.md'));
      await file.writeAsString('- one\r\n');
      await indexer.fullScan(root.path);
      await ops.appendToNote('Log.md', '- two\n');
      expect(file.readAsStringSync(), '- one\r\n\r\n- two\n');
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

    test(
      'moving a folder into itself or its own subtree is rejected',
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
        expect(Directory(p.join(root.path, 'Docs/Inner')).existsSync(), isTrue);
      },
    );
  });

  group('pin (T-M4-04)', () {
    test('pinning writes the key into the note and the index', () async {
      await ops.createNote(parentPath: '', name: 'Note', content: 'body\n');

      final row = await ops.setPinned('Note.md', pinned: true);

      expect(row.pinned, isTrue);
      expect(
        File(p.join(root.path, 'Note.md')).readAsStringSync(),
        '---\npinned: true\n---\n\nbody\n',
      );
      expect((await dao.find('Note.md'))!.pinned, isTrue);
    });

    test('pinning keeps the rest of an existing block', () async {
      await ops.createNote(
        parentPath: '',
        name: 'Note',
        content: '---\ntitle: Real\ntags: [a]\n---\nbody\n',
      );

      await ops.setPinned('Note.md', pinned: true);

      expect(
        File(p.join(root.path, 'Note.md')).readAsStringSync(),
        '---\ntitle: Real\ntags: [a]\npinned: true\n---\nbody\n',
      );
    });

    test('unpinning takes the key back out, block and all', () async {
      await ops.createNote(parentPath: '', name: 'Note', content: 'body\n');
      await ops.setPinned('Note.md', pinned: true);

      final row = await ops.setPinned('Note.md', pinned: false);

      expect(row.pinned, isFalse);
      expect(File(p.join(root.path, 'Note.md')).readAsStringSync(), 'body\n');
      expect((await dao.find('Note.md'))!.pinned, isFalse);
    });

    test('pinning an already pinned note rewrites nothing', () async {
      await ops.createNote(
        parentPath: '',
        name: 'Note',
        content: '---\npinned: true\n---\nbody\n',
      );
      final before = File(p.join(root.path, 'Note.md')).lastModifiedSync();

      await ops.setPinned('Note.md', pinned: true);

      expect(
        File(p.join(root.path, 'Note.md')).lastModifiedSync(),
        before,
        reason: 'the file was already in the wanted state',
      );
    });

    test('only Markdown notes can be pinned', () async {
      // The pin is a frontmatter key. Pinning a `todo.txt` wrote a YAML
      // block into a file that has no such thing, and the Todo tab then
      // read its three lines as tasks (user, 2026-09-09).
      File(p.join(root.path, 'todo.txt')).writeAsStringSync('task\n');
      await indexer.fullScan(root.path);

      await expectLater(
        () => ops.setPinned('todo.txt', pinned: true),
        throwsArgumentError,
      );
      expect(File(p.join(root.path, 'todo.txt')).readAsStringSync(), 'task\n');
    });

    test('unpinning is allowed on any file, so a stray block can go', () async {
      // A pin written before that rule existed has to be removable.
      File(p.join(root.path, 'todo.txt'))
          .writeAsStringSync('---\npinned: true\n---\n\ntask\n');
      await indexer.fullScan(root.path);

      await ops.setPinned('todo.txt', pinned: false);

      expect(File(p.join(root.path, 'todo.txt')).readAsStringSync(), 'task\n');
    });

    test('a folder cannot be pinned', () async {
      await ops.createFolder(parentPath: '', name: 'Folder');
      expect(() => ops.setPinned('Folder', pinned: true), throwsArgumentError);
    });
  });

  group('delete (trash on by default)', () {
    test('moves the note into .trash with a manifest entry', () async {
      await ops.createNote(parentPath: '', name: 'Gone');
      await ops.delete('Gone.md');
      expect(File(p.join(root.path, 'Gone.md')).existsSync(), isFalse);
      expect(File(p.join(root.path, '.trash/Gone.md')).existsSync(), isTrue);
      final items = await ops.trashItems();
      expect(items, hasLength(1));
      expect(items.first.name, 'Gone.md');
      expect(items.first.originalPath, 'Gone.md');
    });

    test('moves a folder subtree into .trash as a directory', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'One');
      await ops.delete('Docs');
      expect(Directory(p.join(root.path, '.trash/Docs')).existsSync(), isTrue);
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
      final item = (await ops.trashItems()).firstWhere(
        (i) => i.name == 'One.md',
      );
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
      expect(File(p.join(root.path, '.trash/Gone.md')).existsSync(), isFalse);
    });

    test('emptyTrash removes every item', () async {
      await ops.createNote(parentPath: '', name: 'A');
      await ops.createNote(parentPath: '', name: 'B');
      await ops.delete('A.md');
      await ops.delete('B.md');
      await ops.emptyTrash();
      expect(await ops.trashItems(), isEmpty);
      expect(File(p.join(root.path, '.trash/A.md')).existsSync(), isFalse);
      expect(File(p.join(root.path, '.trash/B.md')).existsSync(), isFalse);
    });

    test(
      'a corrupt manifest entry is skipped, the rest still listed',
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
      },
    );

    test('a non-JSON manifest file yields an empty listing', () async {
      await ops.createNote(parentPath: '', name: 'A');
      await ops.delete('A.md');
      File(p.join(root.path, '.trash/${NoteOps.manifestFileName}'))
          .writeAsStringSync('{not json');

      expect(await ops.trashItems(), isEmpty);
    });

    test('writing the manifest prunes items that left the trash', () async {
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

    test('emptyTrash removes items Niman never put there', () async {
      await ops.createNote(parentPath: '', name: 'A');
      await ops.delete('A.md');
      // A user moved these into .trash/ by hand: none is in the manifest.
      final foreign = File(p.join(root.path, '.trash/foreign.txt'))
        ..writeAsStringSync('mine');
      Directory(p.join(root.path, '.trash/foreign_folder/inner'))
          .createSync(recursive: true);

      await ops.emptyTrash();

      expect(await ops.trashItems(), isEmpty);
      expect(foreign.existsSync(), isFalse);
      expect(
        Directory(p.join(root.path, '.trash/foreign_folder')).existsSync(),
        isFalse,
      );
      expect(
        jsonDecode(
          File(p.join(root.path, '.trash/${NoteOps.manifestFileName}'))
              .readAsStringSync(),
        ),
        isEmpty,
      );
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

    test('the toggle persists in the library folder', () async {
      await ops.setTrashEnabled(enabled: false);
      final fresh = NoteOps(
        root: root.path,
        db: db,
        indexer: indexer,
        config: LibraryConfigRepo(root.path),
      );
      expect(await fresh.trashEnabled, isFalse);
      // It is the library's own settings file that holds it, not a row
      // in the app database (T-ML-02).
      final config = await LibraryConfigStore(root.path).read();
      expect(config.trashEnabled, isFalse);
    });
  });

  group('quick note', () {
    test('defaults to null, the built-in Quick note.md at the root', () async {
      expect(await ops.quickNotePath, isNull);
    });

    test('the chosen path persists across ops instances', () async {
      await ops.setQuickNotePath(path: 'Inbox/Scratch.md');
      final fresh = NoteOps(
        root: root.path,
        db: db,
        indexer: indexer,
        config: LibraryConfigRepo(root.path),
      );
      expect(await fresh.quickNotePath, 'Inbox/Scratch.md');
    });

    test('clearing restores the default', () async {
      await ops.setQuickNotePath(path: 'Inbox/Scratch.md');
      await ops.setQuickNotePath(path: null);
      expect(await ops.quickNotePath, isNull);
    });
  });
}
