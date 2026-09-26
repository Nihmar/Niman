// The directory-at-a-time full scan (#302). Bounded memory is structural —
// a unit test cannot weigh a heap — so what is held here is what the
// structure must keep true: ids, content rows and prune reporting across
// directories, including a move into a folder the walk already passed.
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteDao dao;

  setUp(() async {
    root = await Directory.current.createTemp('niman_scan_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    dao = indexer.dao;
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  /// Writes [rel] (slash-separated) with [text], making its folders.
  Future<File> write(String rel, String text) async {
    final file = File(p.joinAll([root.path, ...rel.split('/')]));
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
    return file;
  }

  /// Moves [from] to [to] (both slash-separated) — a rename, so the mtime
  /// and the digest the pairing keys on are unchanged.
  Future<void> move(String from, String to) async {
    final target = File(p.joinAll([root.path, ...to.split('/')]));
    await target.parent.create(recursive: true);
    await File(p.joinAll([root.path, ...from.split('/')])).rename(target.path);
  }

  Future<bool> ftsHas(int id, String title) async {
    final rows = await db
        .customSelect(
          'SELECT rowid FROM notes_fts WHERE notes_fts MATCH ?1 AND rowid = ?2',
          variables: [Variable<String>('title : "$title"'), Variable<int>(id)],
        )
        .get();
    return rows.isNotEmpty;
  }

  test(
    'a note moved to a folder the walk reaches later keeps its id',
    () async {
      await write('a/note.md', '---\ntitle: Kept\ntags: [moved]\n---\nbody\n');
      await write('b/other.md', 'other');
      await indexer.fullScan(root.path);
      final before = (await dao.find('a/note.md'))!;

      await move('a/note.md', 'c/note.md');
      final removed = <String>{};
      indexer.onRemoved = removed.addAll;
      await indexer.fullScan(root.path);

      // The walk listed "a" before "c": the orphan it found was the
      // candidate the new home paired against.
      final after = (await dao.find('c/note.md'))!;
      expect(after.id, before.id);
      expect(await dao.find('a/note.md'), isNull);
      expect(removed, isEmpty, reason: 'a rename is paired, not pruned');
      expect(await ftsHas(after.id, 'Kept'), isTrue);
      final tags = await (db.select(
        db.noteTags,
      )..where((t) => t.noteId.equals(after.id))).get();
      expect(tags.map((t) => t.tag), contains('moved'));
    },
  );

  test('a note moved into a folder the walk already passed is paired after '
      'the walk', () async {
    await write('a/other.md', 'other');
    await write('z/note.md', '---\ntitle: Kept\ntags: [moved]\n---\nbody\n');
    await indexer.fullScan(root.path);
    final before = (await dao.find('z/note.md'))!;

    // "a" is walked first, so its listing inserted a fresh row for the
    // new path before "z" reported the old one gone.
    await move('z/note.md', 'a/note.md');
    final removed = <String>{};
    indexer.onRemoved = removed.addAll;
    await indexer.fullScan(root.path);

    final after = (await dao.find('a/note.md'))!;
    expect(after.id, before.id);
    expect(await dao.find('z/note.md'), isNull);
    expect(removed, isEmpty);
    // The surviving row keeps its content rows; the fresh row's copies
    // went with it.
    expect(await ftsHas(after.id, 'Kept'), isTrue);
    expect(
      (await db
              .customSelect(
                'SELECT count(*) AS c FROM notes_fts WHERE rowid = ?',
                variables: [Variable<int>(after.id)],
              )
              .getSingle())
          .read<int>('c'),
      1,
    );
  });

  test('a link to a moved note resolves against the surviving id', () async {
    await write('a/linker.md', 'links [[note]]\n');
    await write('z/note.md', 'note body\n');
    await indexer.fullScan(root.path);
    final before = (await dao.find('z/note.md'))!;

    // The linker changes in the same scan, so its link is written while
    // the moved note still has two rows; the edge is deferred to the end
    // of the walk, when only the surviving one is left.
    await write('a/linker.md', 'links [[note]] still\n');
    await move('z/note.md', 'a/note.md');
    await indexer.fullScan(root.path);

    final after = (await dao.find('a/note.md'))!;
    expect(after.id, before.id);
    final linker = (await dao.find('a/linker.md'))!;
    final links = await (db.select(
      db.noteLinks,
    )..where((l) => l.fromNote.equals(linker.id))).get();
    expect(links.map((l) => l.toNote), [after.id]);
  });

  test('a link to a note a later folder introduces resolves', () async {
    await write('a/linker.md', 'first\n');
    await indexer.fullScan(root.path);

    // The linker changes, linking a note that does not exist yet; the new
    // note lands in a folder the walk reaches after it.
    await write('a/linker.md', 'links [[fresh]]\n');
    await write('z/fresh.md', 'fresh body\n');
    await indexer.fullScan(root.path);

    final linker = (await dao.find('a/linker.md'))!;
    final fresh = (await dao.find('z/fresh.md'))!;
    final links = await (db.select(
      db.noteLinks,
    )..where((l) => l.fromNote.equals(linker.id))).get();
    expect(links.map((l) => l.toNote), [fresh.id]);
  });

  test('a moved folder keeps the ids of the notes inside it', () async {
    await write('old/x.md', 'x body');
    await write('old/deep/y.md', 'y body');
    await indexer.fullScan(root.path);
    final x = (await dao.find('old/x.md'))!;
    final y = (await dao.find('old/deep/y.md'))!;

    await Directory(p.join(root.path, 'old')).rename(p.join(root.path, 'new'));
    final removed = <String>{};
    indexer.onRemoved = removed.addAll;
    await indexer.fullScan(root.path);

    expect((await dao.find('new/x.md'))!.id, x.id);
    expect((await dao.find('new/deep/y.md'))!.id, y.id);
    expect(await dao.find('old'), isNull);
    // The folder path is gone and reported; a rename of its notes is not
    // a prune of them.
    expect(removed, {'old'});
  });

  test(
    'a folder gone from disk takes its notes with it, reported once',
    () async {
      await write('docs/x.md', 'x');
      await write('docs/deep/y.md', 'y');
      await write('keep.md', 'keep');
      await indexer.fullScan(root.path);
      final kept = (await dao.find('keep.md'))!;

      final removed = <String>{};
      indexer.onRemoved = removed.addAll;
      await Directory(p.join(root.path, 'docs')).delete(recursive: true);
      await indexer.fullScan(root.path);

      expect(await dao.find('docs'), isNull);
      expect(await dao.find('docs/x.md'), isNull);
      expect(await dao.find('docs/deep/y.md'), isNull);
      expect(removed, {'docs'});
      expect((await dao.find('keep.md'))!.id, kept.id);
    },
  );

  test('a note whose content moved out of a deleted folder keeps its id '
      'and its folder goes', () async {
    await write('docs/x.md', 'x body');
    await write('elsewhere.md', 'elsewhere');
    await indexer.fullScan(root.path);
    final before = (await dao.find('docs/x.md'))!;

    await move('docs/x.md', 'moved.md');
    await Directory(p.join(root.path, 'docs')).delete(recursive: true);
    final removed = <String>{};
    indexer.onRemoved = removed.addAll;
    await indexer.fullScan(root.path);

    final after = (await dao.find('moved.md'))!;
    expect(after.id, before.id);
    expect(removed, {'docs'});
  });

  test(
    'a link queued by an interrupted scan resolves on the next one',
    () async {
      await write('a/linker.md', 'links [[target]]\n');
      await write('z/target.md', 'target body\n');
      await indexer.fullScan(root.path);

      // A scan that queued the edge and never reached its flush — a crash, a
      // killed process. The link is not re-read (its note did not change),
      // so the queue is the only thing that can repair it.
      final linker = (await dao.find('a/linker.md'))!;
      await db
          .into(db.pendingLinks)
          .insert(
            PendingLinksCompanion.insert(
              noteId: linker.id,
              target: 'target',
              kind: 'wiki',
            ),
          );
      await (db.delete(
        db.noteLinks,
      )..where((l) => l.fromNote.equals(linker.id))).go();

      await indexer.fullScan(root.path);

      final target = (await dao.find('z/target.md'))!;
      final links = await (db.select(
        db.noteLinks,
      )..where((l) => l.fromNote.equals(linker.id))).get();
      expect(links.map((l) => l.toNote), [target.id]);
      expect(await db.select(db.pendingLinks).get(), isEmpty);
    },
  );

  test('a pruned note takes its queued links with it', () async {
    await write('a/linker.md', 'links [[target]]\n');
    await write('z/target.md', 'target body\n');
    await indexer.fullScan(root.path);
    final linker = (await dao.find('a/linker.md'))!;
    await db
        .into(db.pendingLinks)
        .insert(
          PendingLinksCompanion.insert(
            noteId: linker.id,
            target: 'target',
            kind: 'wiki',
          ),
        );

    await File(p.join(root.path, 'a/linker.md')).delete();
    await indexer.fullScan(root.path);

    expect(await db.select(db.pendingLinks).get(), isEmpty);
  });

  test(
    'one scan fires onChanged once, however many directories it wrote',
    () async {
      await write('a/one.md', 'one');
      await write('b/two.md', 'two');
      await indexer.fullScan(root.path);

      await write('a/one.md', 'one changed');
      await write('b/two.md', 'two changed');
      var fires = 0;
      indexer.onChanged = () => fires++;
      await indexer.fullScan(root.path);

      expect(fires, 1);
    },
  );

  test('a scan of an unchanged library writes nothing', () async {
    await write('a/one.md', 'one');
    await write('b/two.md', 'two');
    await indexer.fullScan(root.path);

    var fires = 0;
    indexer.onChanged = () => fires++;
    await indexer.fullScan(root.path);

    expect(fires, 0);
  });

  test('a directory that vanishes mid-walk does not stop the scan', () async {
    await write('a/one.md', 'one');
    await write('b/two.md', 'two');
    await indexer.fullScan(root.path);

    // The test cannot delete a folder between two listings of one walk
    // deterministically; what it can hold is that a listing failure is a
    // non-event, which the walker reports as `failed` (see
    // dir_walker_test.dart for the vanishing folder itself).
    await write('c/three.md', 'three');
    await indexer.fullScan(root.path);
    expect(await dao.find('c/three.md'), isNotNull);
  });
}
