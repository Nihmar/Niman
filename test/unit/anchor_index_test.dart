// #844 / #845: the headings and the block ids of every note are indexed on
// the content pass, and searched across the library through their word index
// — a bounded lookup, never a scan of the notes.
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/anchor_index.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory data;
  late IndexDatabase db;
  late Indexer indexer;

  const alpha =
      '---\ntitle: Alpha\n---\n'
      '# Alpha\n\nA paragraph with an id ^para-1\n\n'
      '## Team notes\n\n- one ^item-1\n- two\n\n'
      '```\n# not a heading ^nor-an-id\n```\n\n'
      '### Details\n\n> a quote\n\n^quote-1\n';
  const beta = '# Beta\n\n## Team planning\n\n## Details\n\nplain ^beta-id\n';

  void write(String name, String text) {
    final file = File(p.join(root.path, name));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(text);
  }

  IndexDatabase open() =>
      IndexDatabase(NativeDatabase(File(p.join(data.path, 'index.sqlite'))));

  Future<List<(String, int, int, String)>> headingRows() async {
    final rows = await db
        .customSelect(
          'SELECT n.path AS path, h.line AS line, h.level AS level, '
          'h.heading AS heading FROM note_headings AS h '
          'JOIN notes AS n ON n.id = h.note_id ORDER BY n.path, h.line',
        )
        .get();
    return [
      for (final r in rows)
        (
          r.read<String>('path'),
          r.read<int>('line'),
          r.read<int>('level'),
          r.read<String>('heading'),
        ),
    ];
  }

  Future<List<(String, String, int)>> blockRows() async {
    final rows = await db
        .customSelect(
          'SELECT n.path AS path, b.block_id AS id, b.line AS line '
          'FROM note_blocks AS b JOIN notes AS n ON n.id = b.note_id '
          'ORDER BY n.path, b.line',
        )
        .get();
    return [
      for (final r in rows)
        (r.read<String>('path'), r.read<String>('id'), r.read<int>('line')),
    ];
  }

  setUp(() async {
    root = await Directory.current.createTemp('niman_anchors_');
    data = await Directory.current.createTemp('niman_anchors_db_');
    write('Alpha.md', alpha);
    write('docs/Beta.md', beta);
    write('Plain.md', 'no headings and no ids\n');
    db = open();
    indexer = Indexer(db);
    await indexer.fullScan(root.path);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
    await data.delete(recursive: true);
  });

  test('the heading rows of a scanned library match each outline', () async {
    final expected = <(String, int, int, String)>[];
    for (final (name, text) in [('Alpha.md', alpha), ('docs/Beta.md', beta)]) {
      for (final h in outlineOfText(text)) {
        expected.add((name, h.line, h.level, h.text));
      }
    }
    expected.sort((a, b) {
      final byPath = a.$1.compareTo(b.$1);
      return byPath != 0 ? byPath : a.$2.compareTo(b.$2);
    });

    expect(await headingRows(), expected);
    expect(
      expected.map((e) => e.$4),
      isNot(contains('not a heading ^nor-an-id')),
      reason: 'the oracle itself skips a fence',
    );
  });

  test('the block rows match the anchors each note has', () async {
    final expected =
        [
          for (final (name, text) in [
            ('Alpha.md', alpha),
            ('docs/Beta.md', beta),
          ])
            for (final a in blockAnchorsOfText(text)) (name, a.id, a.line),
        ]..sort(
          (a, b) => a.$1 == b.$1 ? a.$3.compareTo(b.$3) : a.$1.compareTo(b.$1),
        );

    expect(await blockRows(), expected);
    expect(
      expected.map((e) => e.$2),
      containsAll(['para-1', 'item-1', 'quote-1', 'beta-id']),
    );
    expect(expected.map((e) => e.$2), isNot(contains('nor-an-id')));
  });

  test(
    'a rewritten note replaces its rows, a deleted one drops them',
    () async {
      write('docs/Beta.md', '# Gamma\n\nnew ^gamma-id\n');
      await indexer.rescanFiles(root.path, [
        p.join(root.path, 'docs', 'Beta.md'),
      ]);

      expect((await headingRows()).where((r) => r.$1 == 'docs/Beta.md'), [
        ('docs/Beta.md', 0, 1, 'Gamma'),
      ]);
      expect((await blockRows()).where((r) => r.$1 == 'docs/Beta.md'), [
        ('docs/Beta.md', 'gamma-id', 2),
      ]);
      final anchors = AnchorIndex(db);
      expect(await anchors.headings('planning', limit: 10), isEmpty);
      expect(
        (await anchors.headings('gamma', limit: 10)).single.heading,
        'Gamma',
      );

      File(p.join(root.path, 'docs', 'Beta.md')).deleteSync();
      await indexer.dao.deleteSubtree('docs/Beta.md');
      expect(
        (await headingRows()).map((r) => r.$1),
        isNot(contains('docs/Beta.md')),
      );
      expect(await anchors.headings('gamma', limit: 10), isEmpty);
      expect(await anchors.blocks('gamma', limit: 10), isEmpty);
    },
  );

  test('a deleted index file rebuilds the rows on the next scan', () async {
    final before = await headingRows();
    final blocksBefore = await blockRows();
    await db.close();
    for (final f in data.listSync()) {
      f.deleteSync();
    }

    db = open();
    indexer = Indexer(db);
    expect(await headingRows(), isEmpty, reason: 'a fresh file has none');
    await indexer.fullScan(root.path);

    expect(await headingRows(), before);
    expect(await blockRows(), blocksBefore);
    expect((await AnchorIndex(db).headings('details', limit: 10)).length, 2);
  });

  group('AnchorIndex', () {
    late AnchorIndex index;
    setUp(() => index = AnchorIndex(db));

    test(
      'headings: every note that holds the typed word, with its path',
      () async {
        final hits = await index.headings('team', limit: 10);

        expect(hits.map((h) => (h.path, h.heading)), [
          ('Alpha.md', 'Team notes'),
          ('docs/Beta.md', 'Team planning'),
        ]);
      },
    );

    test(
      'headings: the last word is a prefix, earlier ones are whole',
      () async {
        expect(
          (await index.headings('team pla', limit: 10)).map((h) => h.heading),
          ['Team planning'],
        );
        expect((await index.headings('tea', limit: 10)).map((h) => h.heading), [
          'Team notes',
          'Team planning',
        ], reason: 'a prefix of the word');
        expect(await index.headings('eam', limit: 10), isEmpty);
      },
    );

    test('headings: a heading that starts with the text comes first', () async {
      write('Zed.md', '# Notes about the team\n');
      await indexer.fullScan(root.path);

      final hits = await index.headings('team', limit: 10);

      expect(hits.map((h) => h.heading), [
        'Team notes',
        'Team planning',
        'Notes about the team',
      ]);
    });

    test('headings: an empty query lists the first ones, bounded', () async {
      final hits = await index.headings('', limit: 3);
      expect(hits, hasLength(3));
      expect(await index.headings('', limit: 100), hasLength(6));
    });

    test('headings: punctuation alone matches nothing', () async {
      expect(await index.headings('?!', limit: 10), isEmpty);
    });

    test('blocks: by id or by the first words, with the path', () async {
      expect((await index.blocks('item', limit: 10)).map((b) => b.blockId), [
        'item-1',
      ]);
      expect(
        (await index.blocks('paragraph', limit: 10)).map((b) => b.blockId),
        ['para-1'],
        reason: 'the first words of the block are searched too',
      );
      expect(
        (await index.blocks('beta', limit: 10)).map((b) => (b.path, b.blockId)),
        [('docs/Beta.md', 'beta-id')],
      );
      expect(await index.blocks('nor', limit: 10), isEmpty);
    });

    test('blocks: an id with a dash is found by either side of it', () async {
      expect(
        (await index.blocks('quote', limit: 10)).single.blockId,
        'quote-1',
      );
      expect(
        (await index.blocks('quote-1', limit: 10)).single.blockId,
        'quote-1',
      );
    });

    test("blocks: a note's lines come back with the block start", () async {
      final hit = (await index.blocks('quote', limit: 10)).single;
      expect(hit.path, 'Alpha.md');
      expect(
        hit.line,
        blockAnchorsOfText(alpha).firstWhere((a) => a.id == 'quote-1').line,
      );
    });
  });

  group('at the size of a library', () {
    test('a search reads a bounded number of notes, and rows by key', () async {
      // 6,000 notes that all hold "team" in a heading: the word index names
      // the first AnchorIndex.candidateNotes of them, and the rows read are
      // those notes' own.
      await db.batch((batch) {
        for (var i = 0; i < 6000; i++) {
          final id = 1000 + i;
          batch
            ..customStatement(
              'INSERT INTO notes (id, path, parent, name, is_dir, size, '
              'modified, created) '
              "VALUES ($id, 'bulk/n$i.md', 0, 'n$i.md', 0, 1, 0, 0)",
            )
            ..customStatement(
              'INSERT INTO note_headings (note_id, line, level, heading) '
              "VALUES ($id, 0, 1, 'Team $i')",
            )
            ..customStatement(
              'INSERT INTO note_anchors_fts (rowid, headings, blocks) '
              "VALUES ($id, 'Team $i', '')",
            );
        }
      });
      final index = AnchorIndex(db);

      final watch = Stopwatch()..start();
      final hits = await index.headings('team', limit: 50);
      watch.stop();

      expect(hits, hasLength(50), reason: 'cut to what was asked for');
      // A figure for the log, not a gate (the suite prints wall-clock; it
      // does not hold a shared runner to it).
      // ignore: avoid_print
      print('anchor search over 6,000 notes: ${watch.elapsedMilliseconds} ms');

      // The lookup is by the word index and the key, not a scan of the
      // table: SQLite says so in its own plan.
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT rowid FROM note_anchors_fts '
            'WHERE note_anchors_fts MATCH ? ORDER BY rowid LIMIT ?',
            variables: [
              const Variable<String>('headings : ("team" *)'),
              const Variable<int>(AnchorIndex.candidateNotes),
            ],
          )
          .get();
      expect(
        plan.map((r) => r.read<String>('detail')).join(' ').toUpperCase(),
        contains('VIRTUAL TABLE INDEX'),
      );
      final rowsPlan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT h.heading FROM note_headings AS h '
            'JOIN notes AS n ON n.id = h.note_id WHERE h.note_id IN (1, 2, 3)',
          )
          .get();
      expect(
        rowsPlan.map((r) => r.read<String>('detail')).join(' '),
        contains('SEARCH h USING'),
        reason: 'the headings of the named notes are read by their key',
      );
    });
  });
}
