// #919 reads the referrers of a move before it, to tell which of their links
// named what moves. That read is on the op chain, so it is only made when it
// can change the answer: when another file shares a moved file's name. With
// names that are unique, the text of a link says what it named, and a hub
// note's thousand referrers are read after the move, off the chain (#859).
import 'dart:io';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkUpdate;
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/library/note_relocation.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late _QueryCounter counter;
  late IndexDatabase db;
  late Indexer indexer;
  late LibraryConfigRepo config;
  late NoteOps ops;

  setUp(() async {
    root = await Directory.current.createTemp('niman_reloc_reads_');
    counter = _QueryCounter();
    db = IndexDatabase(NativeDatabase.memory().interceptWith(counter));
    addTearDown(db.close);
    config = LibraryConfigRepo(root.path);
    indexer = Indexer(db);
    ops = NoteOps(root: root.path, db: db, indexer: indexer, config: config);
  });

  tearDown(() async {
    await ops.writer.indexed;
    await root.delete(recursive: true);
  });

  /// Renames [path] to [newRel] through a relocator that counts the notes it
  /// reads while the old path is still on disk.
  Future<List<String>> readsBeforeTheMove(String path, String newRel) async {
    final before = <String>[];
    final relocator = NoteRelocator(
      root: root.path,
      dao: indexer.dao,
      resolver: LinkResolver(db),
      indexer: indexer,
      history: ops.history,
      config: config,
      writer: ops.writer,
      hint: (_, _, {fromPath}) {},
      find: (rel) async => (await ops.find(rel))!,
      readNote: (rel) {
        if (File(p.join(root.path, path)).existsSync()) before.add(rel);
        return ops.readNote(rel);
      },
    );
    final done = await relocator.relocate(
      (await ops.find(path))!,
      path,
      newRel,
    );
    // The automatic rewrite is a job of its own after the move (#1041).
    await done.pending?.apply(<T>(fn) => fn());
    await ops.writer.indexed;
    return before;
  }

  Future<void> hub() async {
    await ops.createNote(parentPath: '', name: 'Old');
    for (var i = 0; i < 30; i++) {
      await ops.createNote(
        parentPath: '',
        name: 'Ref$i',
        content: 'See [[Old]] and [x](Old.md).\n',
      );
    }
  }

  test('a note whose name is unique is renamed without reading its referrers '
      'first', () async {
    await hub();

    final before = await readsBeforeTheMove('Old.md', 'New.md');

    expect(before, isEmpty);
    for (var i = 0; i < 30; i++) {
      expect(
        await ops.readNote('Ref$i.md'),
        'See [[New]] and [x](New.md).\n',
        reason: 'the links follow all the same',
      );
    }
  });

  test('nothing is read before the move when the question is to be asked '
      'later', () async {
    await hub();
    await config.update((c) => c.copyWith(linkUpdate: LinkUpdate.ask));

    final before = await readsBeforeTheMove('Old.md', 'New.md');

    expect(before, isEmpty);
  });

  test('a name another file shares is the case that reads the referrers '
      '(#919)', () async {
    await ops.createFolder(parentPath: '', name: 'a');
    await ops.createFolder(parentPath: '', name: 'z');
    await ops.createNote(parentPath: 'a', name: 'b');
    await ops.createNote(parentPath: 'z', name: 'b');
    await ops.createNote(
      parentPath: '',
      name: 'N',
      content: '[[a/b]] and [[b]]\n',
    );

    final before = await readsBeforeTheMove('a/b.md', 'a/c.md');

    expect(before, ['N.md']);
    expect(await ops.readNote('N.md'), '[[a/c]] and [[b]]\n');
  });

  test('a folder move asks the index in chunks, not once per file', () async {
    await ops.createNote(parentPath: '', name: 'One');
    counter.selects.clear();

    final shared = await indexer.dao.stemsHeldBeyond({
      for (var i = 0; i < 1200; i++) 'file$i',
    }, <int>{});

    expect(shared, isFalse);
    expect(counter.selects, hasLength(3), reason: '1200 stems, 500 a chunk');
  });

  test('a stem held by a note outside the moved ones is found', () async {
    final one = await ops.createNote(parentPath: '', name: 'One');
    await ops.createFolder(parentPath: '', name: 'Sub');
    await ops.createNote(parentPath: 'Sub', name: 'One');
    final sub = (await ops.find('Sub/One.md'))!;

    expect(await indexer.dao.stemsHeldBeyond({'one'}, {sub.id}), isTrue);
    expect(
      await indexer.dao.stemsHeldBeyond({'one'}, {sub.id, one.id}),
      isFalse,
    );
    expect(await indexer.dao.stemsHeldBeyond({'ONE'}, {sub.id}), isTrue);
  });
}

/// Counts the selects the index runs.
final class _QueryCounter extends QueryInterceptor {
  final selects = <String>[];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    selects.add(statement);
    return executor.runSelect(statement, args);
  }
}
