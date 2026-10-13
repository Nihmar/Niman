// #842: the notes that link to a note. The reverse lookup is one indexed read
// over `note_links` (who, in path order, by which link form, never the note
// itself and never a dead link); what each one says is read when its row is
// drawn, off the UI isolate, parsed with the link parser and found by the
// resolver's own rules, once per revision of the referrer.
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/db/referrer_dao.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory data;
  late IndexDatabase db;
  late Indexer indexer;
  late List<String> reads;
  late MentionReader resolver;

  void write(String name, String text) {
    final file = File(p.join(root.path, name));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(text);
  }

  setUp(() async {
    root = await Directory.current.createTemp('niman_mentions_');
    data = await Directory.current.createTemp('niman_mentions_db_');
    write('A.md', 'Intro\n\nSee [[B]] for the story, and [the same](B.md).\n');
    write('C.md', 'Look: ![[B]]\n');
    write('D.md', '- both: ![[B]] then [[B]]\n');
    write('E.md', 'a dead one: [[B2]]\n');
    write('B.md', 'self [[B]] and [[F]]\n');
    write('F.md', 'x\n');
    write('Long.md', '${'word ' * 60}[[B]]${' more' * 60}\n');
    write('Sub/G.md', '> quoted [[B]] here\n');
    db = IndexDatabase(NativeDatabase(File(p.join(data.path, 'i.sqlite'))));
    indexer = Indexer(db);
    await indexer.fullScan(root.path);
    reads = <String>[];
    resolver = MentionReader(
      db,
      LinkResolver(db),
      readSpots: (path) async {
        reads.add(path);
        return linkSpotsOfNoteFile(p.join(root.path, path));
      },
    );
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
    await data.delete(recursive: true);
  });

  group('the reverse lookup', () {
    test('lists who links here, in path order, with the link forms', () async {
      final b = (await indexer.dao.find('B.md'))!;

      final found = await indexer.dao.referrers.page(b.id, limit: 50);

      expect(found.items.map((r) => r.path), [
        'A.md',
        'C.md',
        'D.md',
        'Long.md',
        'Sub/G.md',
      ]);
      expect(found.items.first.kinds, ['md', 'wiki'], reason: 'both forms');
      expect(found.items[1].kinds, ['wiki']);
      expect(found.next, isNull);
    });

    test(
      "the note itself is not a referrer, nor is a dead link's writer",
      () async {
        final b = (await indexer.dao.find('B.md'))!;
        final paths = (await indexer.dao.referrers.page(
          b.id,
          limit: 50,
        )).items.map((r) => r.path);

        expect(paths, isNot(contains('B.md')));
        expect(paths, isNot(contains('E.md')), reason: '[[B2]] is no edge');
      },
    );

    test('a note nobody links to has none', () async {
      final e = (await indexer.dao.find('E.md'))!;
      final none = await indexer.dao.referrers.page(e.id, limit: 5);
      expect(none.items, isEmpty);
      expect(none.next, isNull);
    });

    // A page is the edges the index walks to first, stopped at the limit,
    // and put in path order; the cursor carries the walk on, so every
    // referrer is on exactly one page, however many there are.
    test('pages through every referrer once, each page by path', () async {
      final b = (await indexer.dao.find('B.md'))!;
      final seen = <String>[];
      int? after;
      var pages = 0;
      do {
        final page = await indexer.dao.referrers.page(
          b.id,
          limit: 2,
          after: after ?? 0,
        );
        final paths = [for (final r in page.items) r.path];
        expect(paths, [...paths]..sort(), reason: 'a page is by path');
        expect(paths.length, lessThanOrEqualTo(2));
        seen.addAll(paths);
        after = page.next;
        pages++;
      } while (after != null);

      expect(pages, 3);
      expect(seen..sort(), ['A.md', 'C.md', 'D.md', 'Long.md', 'Sub/G.md']);
    });

    test('a referrer comes with its revision', () async {
      final b = (await indexer.dao.find('B.md'))!;
      final a = (await indexer.dao.find('A.md'))!;
      final row = (await indexer.dao.referrers.page(
        b.id,
        limit: 50,
      )).items.firstWhere((r) => r.path == 'A.md');

      expect(row.modified, a.modified);
      expect(row.size, a.size);
    });

    // The edges are read in the `links_to` index's own order and the walk
    // stops at the page: no sort of every edge a hub note has.
    test("is a walk of the target's own edges, never a sort of them", () async {
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN ${ReferrerDao.pageQuery}',
            variables: [
              Variable.withInt(1),
              Variable.withInt(0),
              Variable.withInt(5),
            ],
          )
          .get();
      final detail = plan.map((r) => r.read<String>('detail')).join(' | ');

      expect(detail, contains('links_to'), reason: detail);
      expect(detail, isNot(contains('SCAN l')), reason: detail);
      expect(detail, isNot(contains('TEMP B-TREE')), reason: detail);
    });

    test(
      'the resolver answers in paths, and an unknown note has none',
      () async {
        expect((await resolver.referrersOf('B.md')).items.map((r) => r.path), [
          'A.md',
          'C.md',
          'D.md',
          'Long.md',
          'Sub/G.md',
        ]);
        expect(await resolver.referrersOf('Nope.md'), same(Referrers.none));
      },
    );
  });

  group('what a referrer says', () {
    test('the line of the link, trimmed, with the link in it', () async {
      final mention = await resolver.mentionIn('A.md', 'B.md');

      expect(mention.context, 'See [[B]] for the story, and [the same](B.md).');
      expect(mention.line, 2);
      expect(mention.count, 2);
      expect(mention.embed, isFalse);
    });

    test('an embed is marked as one; a link shows ahead of an embed', () async {
      final embedded = await resolver.mentionIn('C.md', 'B.md');
      expect(embedded.embed, isTrue);
      expect(embedded.context, 'Look: ![[B]]');

      final both = await resolver.mentionIn('D.md', 'B.md');
      expect(both.embed, isFalse, reason: 'the referrer links it, too');
      expect(both.count, 2);
      expect(both.context, 'both: ![[B]] then [[B]]', reason: 'marker off');
    });

    test("a quote's mark comes off the line", () async {
      expect(
        (await resolver.mentionIn('Sub/G.md', 'B.md')).context,
        'quoted [[B]] here',
      );
    });

    test(
      'a long line is a window around the link, cut with an ellipsis',
      () async {
        final mention = await resolver.mentionIn('Long.md', 'B.md');

        expect(mention.context, contains('[[B]]'));
        expect(mention.context, startsWith('…'));
        expect(mention.context, endsWith('…'));
        expect(
          mention.context.length,
          lessThanOrEqualTo(mentionContextWidth + 2),
        );
      },
    );

    test(
      'a referrer whose text no longer names the note says nothing',
      () async {
        write('A.md', 'no link any more\n');
        // The index has not heard yet: the edge is there, the link is not.
        final b = (await indexer.dao.find('B.md'))!;
        expect(
          (await indexer.dao.referrers.page(
            b.id,
            limit: 9,
          )).items.map((r) => r.path),
          contains('A.md'),
        );

        final mention = await resolver.mentionIn('A.md', 'B.md');

        expect(mention.context, isEmpty);
        expect(mention.count, 0);
        expect(mention.line, -1);
      },
    );

    test(
      'without a way to read notes, or for a note not in the index',
      () async {
        final blind = MentionReader(db, LinkResolver(db));
        expect((await blind.mentionIn('A.md', 'B.md')).count, 0);
        expect((await resolver.mentionIn('Nope.md', 'B.md')).count, 0);
        expect((await resolver.mentionIn('A.md', 'Nope.md')).count, 0);
      },
    );

    test('is read once per revision of the referrer', () async {
      await resolver.mentionIn('A.md', 'B.md');
      await resolver.mentionIn('A.md', 'B.md');
      await resolver.mentionIn('C.md', 'B.md');
      expect(reads, ['A.md', 'C.md'], reason: "the second ask is the cache's");

      write('A.md', 'Now it says: [[B]]. And more words to change its size.\n');
      await indexer.rescanFiles(root.path, [p.join(root.path, 'A.md')]);
      final changed = await resolver.mentionIn('A.md', 'B.md');

      expect(reads, ['A.md', 'C.md', 'A.md'], reason: 'a new revision reads');
      expect(changed.context, startsWith('Now it says'));
    });

    test('keeps a bounded number of mentions', () async {
      final spots = <LinkSpot>[
        (target: 'B', markdown: false, embed: false, line: 0, context: '[[B]]'),
      ];
      final bulk = MentionReader(
        db,
        LinkResolver(db),
        readSpots: (_) async => spots,
      );
      for (var i = 0; i < MentionReader.kept + 40; i++) {
        write('bulk/n$i.md', '[[B]]\n');
      }
      await indexer.fullScan(root.path);

      for (var i = 0; i < MentionReader.kept + 40; i++) {
        await bulk.mentionIn('bulk/n$i.md', 'B.md');
      }

      expect(bulk.held, MentionReader.kept);
    });
  });

  group('the line around a link', () {
    test('a list marker, a task box and a quote mark are not the context', () {
      String ctx(String line) {
        final at = line.indexOf('[[');
        return contextAround(line, at, line.indexOf(']]') + 2);
      }

      expect(ctx('- see [[B]]'), 'see [[B]]');
      expect(ctx('1. see [[B]]'), 'see [[B]]');
      expect(ctx('- [x] done [[B]]'), 'done [[B]]');
      expect(ctx('> > deep [[B]]'), 'deep [[B]]');
      expect(ctx('   indented   [[B]]   text'), 'indented [[B]] text');
    });

    test('only the line holding the link is cut from a longer text', () {
      const text = 'before\nthe [[B]] line\nafter';
      final at = text.indexOf('[[');
      expect(contextAround(text, at, at + 5), 'the [[B]] line');
    });

    test('a link at either end of a long line keeps the whole window', () {
      final head = '[[B]] ${'x ' * 200}';
      expect(contextAround(head, 0, 5, width: 40), startsWith('[[B]]'));
      expect(contextAround(head, 0, 5, width: 40), endsWith('…'));
      final tail = '${'x ' * 200}[[B]]';
      final at = tail.length - 5;
      expect(
        contextAround(tail, at, tail.length, width: 40),
        allOf(startsWith('…'), endsWith('[[B]]')),
      );
    });
  });

  group('linkSpotsOf', () {
    test('links and embeds in order, each with its line', () {
      final spots = linkSpotsOf(
        'one [[A]]\n\ntwo ![[B]] and [c](c.md)\n[web](https://x.y) [[#h]] [[|a]]\n',
      );

      expect(spots.map((s) => (s.target, s.markdown, s.embed, s.line)), [
        ('A', false, false, 0),
        ('B', false, true, 2),
        ('c.md', true, false, 2),
      ], reason: 'a URL and a link to the note itself name no other note');
    });

    // The index finds a note's links with the engine that draws the note
    // (`noteReferencesOf`), so the list of who links here agrees with it:
    // a reference-style link is a mention, with the line it is written on.
    test('a reference-style link is a mention with its line', () {
      final spots = linkSpotsOf(
        'Intro\n\nSee [the plan][p] now.\n\n[p]: Plan.md\n',
      );

      expect(spots.map((s) => (s.target, s.markdown, s.line, s.context)), [
        ('Plan.md', true, 2, 'See [the plan][p] now.'),
      ]);
    });

    test('a note with Windows line endings has the same lines', () {
      final spots = linkSpotsOf('one\r\n\r\ntwo [[A]]\r\n');

      expect(spots.map((s) => (s.target, s.line, s.context)), [
        ('A', 2, 'two [[A]]'),
      ]);
    });

    test('a link in a fence or in code is not one', () {
      expect(
        linkSpotsOf('`[[A]]`\n\n```\n[[B]]\n```\n[[C]]\n').map((s) => s.target),
        ['C'],
      );
    });
  });

  test('NoteOps reads the spots of a note off its file', () async {
    final ops = NoteOps(
      root: root.path,
      db: db,
      indexer: indexer,
      config: LibraryConfigRepo(root.path),
    );
    final spots = await ops.noteLinkSpots('A.md');
    expect(spots.map((s) => s.target), ['B', 'B.md']);
  });
}
