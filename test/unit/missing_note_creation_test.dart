// #847: a dead link into folders the library does not have yet makes them,
// the way Obsidian's does — `[[Projects/Three laws]]` creates `Projects/`
// along the way — through the library's own creation path, sanitized as every
// note name is.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/ui/shell_note_io.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';

void main() {
  group('the creator the shell hands the dead-link flow', () {
    late Directory root;
    late FakeLibrarySession session;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('niman_missing_');
      session = FakeLibrarySession();
      await session.open(root.path, create: false);
    });

    tearDown(() async {
      await session.dispose();
      await root.delete(recursive: true);
    });

    test('a note in folders the library lacks makes them first', () async {
      final create = missingNoteCreatorFor(session)!;

      final made = await create('Projects/Laws/Three laws.md');

      expect(made, 'Projects/Laws/Three laws.md');
      expect(await session.find('Projects'), isNotNull);
      expect((await session.find('Projects/Laws'))!.isDir, isTrue);
      expect(
        (await session.find('Projects/Laws/Three laws.md'))!.isDir,
        isFalse,
      );
    });

    test('a note in a folder it has leaves the folder alone', () async {
      await session.ensureFolder('Notes');
      final before = await session.find('Notes');
      final create = missingNoteCreatorFor(session)!;

      await create('Notes/Foo.md');

      expect((await session.find('Notes'))!.id, before!.id);
      expect(await session.find('Notes/Foo.md'), isNotNull);
    });

    test('a note at the root asks for no folder', () async {
      final create = missingNoteCreatorFor(session)!;

      await create('Foo.md');

      expect(await session.find('Foo.md'), isNotNull);
      expect(await session.folders(), isEmpty);
    });
  });

  group('on the disk, through the library', () {
    late Directory root;
    late Directory data;
    late IndexDatabase db;
    late NoteOps ops;

    setUp(() async {
      root = await Directory.current.createTemp('niman_missing_ops_');
      data = await Directory.current.createTemp('niman_missing_ops_db_');
      db = IndexDatabase(NativeDatabase(File(p.join(data.path, 'i.sqlite'))));
      ops = NoteOps(
        root: root.path,
        db: db,
        indexer: Indexer(db),
        config: LibraryConfigRepo(root.path),
      );
    });

    tearDown(() async {
      await db.close();
      await root.delete(recursive: true);
      await data.delete(recursive: true);
    });

    test('the proposed path of a link names the folders, sanitized', () async {
      const context = LinkContext(
        libraryRoot: '/lib',
        currentNote: '/lib/Notes/Current.md',
      );
      final proposed = proposedMissingNotePath(
        'Pro:jects/../Three laws',
        MissingNoteLocation.currentFolder,
        context,
      );
      expect(
        proposed,
        'Projects/Three laws.md',
        reason: 'a `..` is dropped, a `:` too',
      );
    });

    test('the folders and the note exist, and are in the index', () async {
      await ops.ensureFolder('Projects/Laws');
      final note = await ops.createNote(
        parentPath: 'Projects/Laws',
        name: 'Three laws',
      );

      expect(note.path, 'Projects/Laws/Three laws.md');
      expect(
        Directory(p.join(root.path, 'Projects', 'Laws')).existsSync(),
        isTrue,
      );
      expect(
        File(p.join(root.path, 'Projects', 'Laws', 'Three laws.md'))
            .existsSync(),
        isTrue,
      );
      final rows = await db.select(db.notes).get();
      expect(
        rows.map((n) => n.path),
        containsAll(<String>[
          'Projects',
          'Projects/Laws',
          'Projects/Laws/Three laws.md',
        ]),
        reason: 'every folder on the way is a row, so the tree shows it',
      );
    });
  });
}
