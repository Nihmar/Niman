// #535: what the Home's tiles ask of the index — the notes modified last,
// one at random, and the values a frontmatter key already holds.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late NoteDao dao;

  setUp(() async {
    root = await Directory.current.createTemp('niman_home_queries_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    dao = NoteDao(db);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  /// Writes [rel] (slash-separated) modified [minutesAgo] minutes ago.
  void write(String rel, {int minutesAgo = 0, String content = 'x'}) {
    final file = File(p.joinAll([root.path, ...rel.split('/')]));
    file.parent.createSync(recursive: true);
    file
      ..writeAsStringSync(content)
      ..setLastModifiedSync(
        DateTime.now().subtract(Duration(minutes: minutesAgo)),
      );
  }

  group('recentlyModified', () {
    test('lists notes newest first, folders and the excluded folder out, '
        'at most limit', () async {
      write('old.md', minutesAgo: 30);
      write('new.md', minutesAgo: 1);
      write('mid.md', minutesAgo: 10);
      write('Templates/Meeting.md');
      write('Work/deep.md', minutesAgo: 5);
      await indexer.fullScan(root.path);

      final recent = await dao.recentlyModified(
        limit: 3,
        excludeFolder: 'Templates',
      );

      expect(recent.map((n) => n.path), ['new.md', 'Work/deep.md', 'mid.md']);
    });

    test(
      'keeps a sibling whose name only starts like the excluded folder',
      () async {
        write('Templates/t.md');
        write('Templates2.md', minutesAgo: 2);
        await indexer.fullScan(root.path);

        final recent = await dao.recentlyModified(excludeFolder: 'Templates');

        expect(recent.map((n) => n.path), ['Templates2.md']);
      },
    );

    test('walks the notes_recent index instead of sorting the table', () async {
      await indexer.fullScan(root.path);
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM notes WHERE is_dir = 0 '
            'ORDER BY modified DESC LIMIT 8',
          )
          .get();
      final detail = plan.map((r) => r.read<String>('detail')).join('\n');

      expect(detail, contains('notes_recent'));
      expect(detail, isNot(contains('TEMP B-TREE')));
    });
  });

  group('randomNote', () {
    test(
      'is null for a library with no note outside the excluded folder',
      () async {
        write('Templates/t.md');
        await indexer.fullScan(root.path);

        expect(await dao.randomNote(excludeFolder: 'Templates'), isNull);
      },
    );

    test('picks a note, never a folder nor an excluded one', () async {
      for (var i = 0; i < 20; i++) {
        write('n$i.md');
      }
      write('Templates/t.md');
      await indexer.fullScan(root.path);

      final seen = <String>{};
      for (var i = 0; i < 60; i++) {
        final note = await dao.randomNote(excludeFolder: 'Templates');
        expect(note, isNotNull);
        expect(note!.isDir, isFalse);
        expect(note.path, isNot(startsWith('Templates/')));
        seen.add(note.path);
      }
      // Random, not stuck on one row.
      expect(seen.length, greaterThan(1));
    });

    test('reaches the whole library, not only its lowest ids (#666)', () async {
      for (var i = 0; i < 200; i++) {
        write('n$i.md');
      }
      await indexer.fullScan(root.path);
      final ids = [for (var i = 0; i < 60; i++) (await dao.randomNote())!.id];
      final top = ids.reduce((a, b) => a > b ? a : b);

      // A threshold drawn per row let only the first ~√n notes win; one
      // drawn per query lands in the upper half all but 2⁻⁶⁰ of the time.
      expect(top, greaterThan(100), reason: 'ids $ids');
    });
  });

  group('topValues', () {
    test("lists a key's values, most used first, ties alphabetical", () async {
      write('a.md', content: '---\nproject: beta\nstatus: open\n---\n');
      write('b.md', content: '---\nproject: alpha\n---\n');
      write('c.md', content: '---\nproject: beta\n---\n');
      write('d.md', content: '---\nProject: gamma\n---\n');
      await indexer.fullScan(root.path);
      final repo = FieldRepo(db);

      expect(await repo.topValues('project'), ['beta', 'alpha', 'gamma']);
      expect(await repo.topValues('project', limit: 1), ['beta']);
      expect(await repo.topValues('missing'), isEmpty);
    });
  });
}
