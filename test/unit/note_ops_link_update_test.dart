// What a rename or a move does to the links pointing at what moved depends
// on the library's link update setting (#848): rewritten, rewritten once
// asked, or left as written. Only the rewrite is the setting's; everything
// else that names the path follows the move whichever it is.
import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkUpdate;
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;
  late LibraryConfigRepo config;

  setUp(() async {
    root = await Directory.current.createTemp('niman_link_update_');
    dbDir = await Directory.current.createTemp('niman_link_update_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    config = LibraryConfigRepo(root.path);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: Indexer(db),
      config: config,
    );
  });

  tearDown(() async {
    await ops.writer.indexed;
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  Future<void> use(LinkUpdate mode) =>
      config.update((c) => c.copyWith(linkUpdate: mode));

  /// A note `Old` cited by `Ref` (which also cites `Other`, never moved)
  /// and by `Second`.
  Future<void> seed() async {
    await ops.createNote(parentPath: '', name: 'Old');
    await ops.createNote(parentPath: '', name: 'Other');
    await ops.createNote(
      parentPath: '',
      name: 'Ref',
      content: 'See [[Old]] and [[Other]].\n',
    );
    await ops.createNote(
      parentPath: '',
      name: 'Second',
      content: '[x](Old.md)\n',
    );
  }

  group('automatic (the default)', () {
    test('rewrites the links, and asks nothing', () async {
      await seed();
      var asked = 0;
      await ops.rename(
        'Old.md',
        'New',
        confirmLinks: (_) async {
          asked++;
          return false;
        },
      );
      expect(await ops.readNote('Ref.md'), 'See [[New]] and [[Other]].\n');
      expect(await ops.readNote('Second.md'), '[x](New.md)\n');
      expect(asked, 0);
    });
  });

  group('never', () {
    test('a rename leaves the links as written', () async {
      await seed();
      await use(LinkUpdate.never);
      var asked = 0;
      final row = await ops.rename(
        'Old.md',
        'New',
        confirmLinks: (_) async {
          asked++;
          return true;
        },
      );
      expect(row.path, 'New.md');
      expect(await ops.readNote('Ref.md'), 'See [[Old]] and [[Other]].\n');
      expect(await ops.readNote('Second.md'), '[x](Old.md)\n');
      expect(asked, 0);
    });

    test('a move leaves the links as written', () async {
      await seed();
      await ops.createFolder(parentPath: '', name: 'Sub');
      await ops.createNote(
        parentPath: '',
        name: 'Path',
        content: '[[Old.md]]\n',
      );
      await use(LinkUpdate.never);
      await ops.move('Old.md', 'Sub');
      expect(await ops.readNote('Path.md'), '[[Old.md]]\n');
    });

    test('the rest of the move still follows: the history does', () async {
      await seed();
      await ops.saveNote('Old.md', 'one');
      await ops.saveNote('Old.md', 'two', editSession: 1);
      await ops.writer.indexed;
      await use(LinkUpdate.never);
      await ops.rename('Old.md', 'New');
      expect((await ops.noteHistory('Old.md')).versions, isEmpty);
      expect(await ops.readNoteVersion('New.md', 1), 'one');
    });

    test('the settings naming the moved path still follow', () async {
      await ops.createFolder(parentPath: '', name: 'Lists');
      await seed();
      await use(LinkUpdate.never);
      await config.update((c) => c.copyWith(listNoteFolder: 'Lists'));
      await ops.rename('Lists', 'Checklists');
      expect((await config.config).listNoteFolder, 'Checklists');
    });
  });

  group('ask', () {
    test('a declined prompt leaves the links, and reports the number '
        'of notes first', () async {
      await seed();
      await use(LinkUpdate.ask);
      final counts = <int>[];
      final row = await ops.rename(
        'Old.md',
        'New',
        confirmLinks: (notes) async {
          counts.add(notes);
          return false;
        },
      );
      await ops.linkQuestion;
      expect(counts, [2], reason: 'Ref and Second would change; one prompt');
      expect(row.path, 'New.md', reason: 'the move itself is not up to it');
      expect(await ops.readNote('Ref.md'), 'See [[Old]] and [[Other]].\n');
      expect(await ops.readNote('Second.md'), '[x](Old.md)\n');
    });

    test('an accepted prompt rewrites them', () async {
      await seed();
      await use(LinkUpdate.ask);
      final counts = <int>[];
      await ops.rename(
        'Old.md',
        'New',
        confirmLinks: (notes) async {
          counts.add(notes);
          return true;
        },
      );
      await ops.linkQuestion;
      expect(counts, [2]);
      expect(await ops.readNote('Ref.md'), 'See [[New]] and [[Other]].\n');
      expect(await ops.readNote('Second.md'), '[x](New.md)\n');
    });

    test('a folder rename is one prompt, not one per note', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'A');
      await ops.createNote(parentPath: 'Docs', name: 'B');
      await ops.createNote(
        parentPath: '',
        name: 'Ref',
        content: '[[Docs/A]] [[Docs/B]]\n',
      );
      await ops.createNote(parentPath: '', name: 'Ref2', content: '[[Docs/A]]');
      await use(LinkUpdate.ask);
      final counts = <int>[];
      await ops.rename(
        'Docs',
        'Books',
        confirmLinks: (notes) async {
          counts.add(notes);
          return true;
        },
      );
      await ops.linkQuestion;
      expect(counts, [2]);
      expect(await ops.readNote('Ref.md'), '[[Books/A]] [[Books/B]]\n');
      expect(await ops.readNote('Ref2.md'), '[[Books/A]]');
    });

    test('a move asks too', () async {
      await seed();
      await ops.createFolder(parentPath: '', name: 'Sub');
      await use(LinkUpdate.ask);
      final counts = <int>[];
      await ops.move(
        'Old.md',
        'Sub',
        confirmLinks: (notes) async {
          counts.add(notes);
          return true;
        },
      );
      await ops.linkQuestion;
      expect(counts, [1], reason: 'only the href changes; the bare name stays');
      expect(await ops.readNote('Second.md'), '[x](Sub/Old.md)\n');
      expect(await ops.readNote('Ref.md'), 'See [[Old]] and [[Other]].\n');
    });

    test('nothing to rewrite means no prompt', () async {
      await ops.createNote(parentPath: '', name: 'Lonely');
      await ops.createNote(
        parentPath: '',
        name: 'Ref',
        content: 'no links here\n',
      );
      await use(LinkUpdate.ask);
      var asked = 0;
      await ops.rename(
        'Lonely.md',
        'Alone',
        confirmLinks: (_) async {
          asked++;
          return true;
        },
      );
      expect(asked, 0);
    });

    test('a move that changes no link text asks nothing', () async {
      // A bare-name link survives a move to another folder untouched: the
      // referrer exists, but there is nothing to rewrite, so nothing to ask.
      await ops.createNote(parentPath: '', name: 'Old');
      await ops.createNote(parentPath: '', name: 'Ref', content: 'See [[Old]]');
      await ops.createFolder(parentPath: '', name: 'Sub');
      await use(LinkUpdate.ask);
      var asked = 0;
      await ops.move(
        'Old.md',
        'Sub',
        confirmLinks: (_) async {
          asked++;
          return true;
        },
      );
      await ops.linkQuestion;
      expect(asked, 0);
      expect(await ops.readNote('Ref.md'), 'See [[Old]]');
    });

    test('without a prompt to ask, nothing is written unasked', () async {
      await seed();
      await use(LinkUpdate.ask);
      await ops.rename('Old.md', 'New');
      expect(await ops.readNote('Ref.md'), 'See [[Old]] and [[Other]].\n');
    });

    test(
      'the question holds no lock: another op runs while it is open',
      () async {
        await seed();
        await use(LinkUpdate.ask);
        final asked = Completer<int>();
        final answer = Completer<bool>();
        final rename = ops.rename(
          'Old.md',
          'New',
          confirmLinks: (notes) {
            asked.complete(notes);
            return answer.future;
          },
        );
        expect(await asked.future.timeout(const Duration(seconds: 10)), 2);

        // A dialog left open must not stall the library: this op joins the
        // same serial chain the rename ran in.
        final created = await ops
            .createNote(parentPath: '', name: 'Free')
            .timeout(const Duration(seconds: 5));
        expect(created.path, 'Free.md');

        answer.complete(true);
        await rename;
        await ops.linkQuestion;
        expect(await ops.readNote('Ref.md'), 'See [[New]] and [[Other]].\n');
      },
    );

    test('an edit made while the question is open is kept', () async {
      await seed();
      await use(LinkUpdate.ask);
      final asked = Completer<int>();
      final answer = Completer<bool>();
      final rename = ops.rename(
        'Old.md',
        'New',
        confirmLinks: (notes) {
          asked.complete(notes);
          return answer.future;
        },
      );
      await asked.future.timeout(const Duration(seconds: 10));
      await ops.saveNote('Ref.md', 'Edited meanwhile: [[Old]].\n');
      await ops.writer.indexed;

      answer.complete(true);
      await rename;
      await ops.linkQuestion;
      expect(
        await ops.readNote('Ref.md'),
        'Edited meanwhile: [[New]].\n',
        reason: 'the rewrite reads the note again once it is agreed to',
      );
      expect(await ops.readNote('Second.md'), '[x](New.md)\n');
    });

    test('the move returns before the question is answered (#859)', () async {
      await seed();
      await use(LinkUpdate.ask);
      final asked = Completer<int>();
      final answer = Completer<bool>();
      var rewritten = 0;
      final row = await ops
          .rename(
            'Old.md',
            'New',
            confirmLinks: (notes) {
              asked.complete(notes);
              return answer.future;
            },
            onLinksRewritten: () => rewritten++,
          )
          .timeout(const Duration(seconds: 10));
      expect(row.path, 'New.md', reason: 'returned with the dialog still up');
      expect(await ops.readNote('Ref.md'), 'See [[Old]] and [[Other]].\n');

      // The note moves again while the question is open: the answer still
      // finds the links to rewrite, and nothing is thrown at the caller.
      await ops.move('New.md', '');
      await ops.createFolder(parentPath: '', name: 'Sub');
      await ops.move('New.md', 'Sub');
      expect(rewritten, 0);
      answer.complete(true);
      await ops.linkQuestion;
      expect(rewritten, 1);
      expect(await ops.readNote('Second.md'), '[x](New.md)\n');
    });

    test('a failing question is logged, not thrown into the move', () async {
      await seed();
      await use(LinkUpdate.ask);
      final row = await ops.rename(
        'Old.md',
        'New',
        confirmLinks: (_) async => throw StateError('dialog gone'),
      );
      expect(row.path, 'New.md');
      await ops.linkQuestion;
      expect(await ops.readNote('Ref.md'), 'See [[Old]] and [[Other]].\n');
    });
  });
}
