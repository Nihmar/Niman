// #974: a dead link is an edge once its target is made. The edge is what
// "Links to this note" lists and what a rename or a move finds the notes to
// rewrite by, and it was written only when the linking note itself was
// indexed — so a note made later (from the dead link, by hand, restored from
// the trash, synced in) had no referrers until the note that linked to it
// happened to be saved again.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
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

  setUp(() async {
    root = await Directory.current.createTemp('niman_dangling_');
    dbDir = await Directory.current.createTemp('niman_dangling_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    indexer = Indexer(db);
    ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
  });

  tearDown(() async {
    await ops.writer.indexed;
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  /// The paths "Links to this note" lists for the note at [path].
  Future<List<String>> referrersOf(String path) async {
    final row = (await ops.find(path))!;
    final page = await indexer.dao.referrers.page(row.id, limit: 50);
    return [for (final item in page.items) item.path];
  }

  void write(String rel, String text) {
    final file = File(p.join(root.path, rel));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(text);
  }

  group('a note made after the links to it', () {
    test(
      'lists the note that linked to it, and a rename rewrites the link',
      () async {
        await ops.createNote(
          parentPath: '',
          name: 'A',
          content: 'Later: [[New idea]] and [again](New%20idea.md).\n',
        );
        await ops.createNote(parentPath: '', name: 'New idea');

        expect(await referrersOf('New idea.md'), ['A.md']);

        await ops.rename('New idea.md', 'Better idea');

        expect(
          await ops.readNote('A.md'),
          'Later: [[Better idea]] and [again](Better%20idea.md).\n',
        );
        expect(await referrersOf('Better idea.md'), ['A.md']);
      },
    );

    test('is found by a note written by hand and seen by a scan', () async {
      write('A.md', 'See [[Made by hand]].\n');
      await indexer.fullScan(root.path);
      expect(await ops.find('A.md'), isNotNull);

      write('Made by hand.md', 'x\n');
      await indexer.fullScan(root.path);

      expect(await referrersOf('Made by hand.md'), ['A.md']);
    });

    test('is found when the scan that saw both ran first', () async {
      write('A.md', 'See [[Later]].\n');
      write('Later.md', 'x\n');
      await indexer.fullScan(root.path);

      expect(await referrersOf('Later.md'), ['A.md']);
    });

    test('is found by a note that answers to an alias', () async {
      write('A.md', 'See [[Nickname]].\n');
      await indexer.fullScan(root.path);

      await ops.createNote(
        parentPath: '',
        name: 'Real name',
        content: '---\naliases: [Nickname]\n---\nbody\n',
      );

      expect(await referrersOf('Real name.md'), ['A.md']);
    });

    test('is found under the folder the link names', () async {
      write('A.md', 'See [[Projects/Plan]].\n');
      await indexer.fullScan(root.path);

      write('Other/Plan.md', 'x\n');
      await indexer.applyEvents(root.path, [p.join(root.path, 'Other')]);
      expect(await ops.find('Other/Plan.md'), isNotNull);
      // The wrong folder: the link still waits.
      final other = (await ops.find('Other/Plan.md'))!;
      expect(
        (await indexer.dao.referrers.page(other.id, limit: 50)).items,
        isEmpty,
      );

      write('Projects/Plan.md', 'x\n');
      await indexer.applyEvents(root.path, [p.join(root.path, 'Projects')]);
      expect(await referrersOf('Projects/Plan.md'), ['A.md']);
    });

    test('is found again when the note comes back from the trash', () async {
      write('A.md', 'See [[Gone]].\n');
      await indexer.fullScan(root.path);
      await ops.createNote(parentPath: '', name: 'Gone');
      expect(await referrersOf('Gone.md'), ['A.md']);

      await ops.delete('Gone.md');
      expect(await ops.find('Gone.md'), isNull);
      final item = (await ops.trashItems()).single;
      await ops.restoreTrash(item.name);

      expect(await referrersOf('Gone.md'), ['A.md']);
    });

    test(
      'is not kept once the linking note no longer holds the link',
      () async {
        write('A.md', 'See [[Soon]].\n');
        await indexer.fullScan(root.path);
        write('A.md', 'Nothing here now.\n');
        await indexer.applyEvents(root.path, [p.join(root.path, 'A.md')]);

        await ops.createNote(parentPath: '', name: 'Soon');

        expect(await referrersOf('Soon.md'), isEmpty);
      },
    );

    test('is not kept for a note that was deleted', () async {
      write('A.md', 'See [[Soon]].\n');
      await indexer.fullScan(root.path);
      await ops.delete('A.md');

      final rows = await db
          .customSelect('SELECT count(*) AS c FROM dangling_links')
          .getSingle();
      expect(rows.read<int>('c'), 0);
    });
  });

  group('at the scale of a library', () {
    test('a stem finds its waiting links by the index, not a scan', () async {
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN '
            'SELECT d.rowid, d.note_id, d.target, d.kind, n.path '
            'FROM dangling_links d JOIN notes n ON n.id = d.note_id '
            "WHERE d.stem = 'x' AND d.rowid > 0 ORDER BY d.rowid LIMIT 500",
          )
          .get();
      final detail = plan.map((r) => r.read<String>('detail')).join('\n');
      expect(detail, contains('dangling_stem'));
      expect(detail, isNot(contains('SCAN d')));
      expect(detail, isNot(contains('USE TEMP B-TREE')));
    });

    test('more new stems than are kept settle in one pass', () async {
      write('A.md', 'See [[n0]] and [[n300]].\n');
      await indexer.fullScan(root.path);
      // One batch brings more stems than the store holds apart.
      final paths = <String>[];
      for (var i = 0; i < 400; i++) {
        write('n$i.md', 'x\n');
        paths.add(p.join(root.path, 'n$i.md'));
      }
      await indexer.applyEvents(root.path, paths);

      expect(await referrersOf('n0.md'), ['A.md']);
      expect(await referrersOf('n300.md'), ['A.md']);
    });
  });
}
