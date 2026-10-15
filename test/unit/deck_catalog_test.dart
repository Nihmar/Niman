// Where the decks come from (#533): the notes typed `flashcard` found in the
// index, read off the UI isolate with `review.json`, kept by modification
// time, counted for the study day, and followed by a controller.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/flashcards/deck_catalog.dart';
import 'package:niman/src/flashcards/deck_catalog_controller.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:path/path.dart' as p;

final DateTime today = DateTime(2026, 10, 14);

ReviewState state({DateTime? due, DateTime? first, DateTime? at}) =>
    ReviewState(
      ef: 2.5,
      interval: 1,
      reps: 1,
      due: due ?? DateTime(2026, 10, 20),
      at: at ?? DateTime.utc(2026, 10, 14, 9),
      first: first,
    );

String deck(
  List<String> questions, {
  String front = '',
  String category = '',
  String tags = '',
}) =>
    '---\ntype: flashcard\n${category.isEmpty ? '' : 'deck: $category\n'}'
    '${tags.isEmpty ? '' : 'tags: [$tags]\n'}---\n\n'
    '| Q | A |\n|---|---|\n'
    '${[for (final q in questions) '| $q | answer |\n'].join()}';

void main() {
  late Directory root;
  late IndexDatabase db;
  late Indexer indexer;
  late DeckCatalog catalog;
  late ReviewStore store;

  setUp(() async {
    root = await Directory.current.createTemp('niman_decks_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    indexer = Indexer(db);
    store = ReviewStore(root.path);
    catalog = DeckCatalog(
      root: root.path,
      find: () => findDeckPaths(FieldRepo(db)),
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  void write(String name, String content) {
    File(p.join(root.path, name))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  Future<void> scan() => indexer.fullScan(root.path);

  group('finding the decks', () {
    test('lists the notes typed flashcard, in path order', () async {
      write('b.md', deck(['x']));
      write('Lingue/a.md', deck(['x']));
      write('plain.md', '| Q | A |\n|---|---|\n| x | y |\n');
      write('other.md', '---\ntype: audio\n---\nx');
      write('loud.md', '---\ntype: Flashcard\n---\n');
      Directory(p.join(root.path, 'folder')).createSync();
      await scan();
      expect(await findDeckPaths(FieldRepo(db)), [
        'Lingue/a.md',
        'b.md',
        'loud.md',
      ]);
    });

    test(
      'finds a deck made after the first scan, and loses a retyped one',
      () async {
        write('a.md', deck(['x']));
        await scan();
        write('b.md', deck(['x']));
        await indexer.applyEvents(root.path, [p.join(root.path, 'b.md')]);
        expect(await findDeckPaths(FieldRepo(db)), ['a.md', 'b.md']);
        write('a.md', '---\ntype: slides\n---\nx');
        await indexer.applyEvents(root.path, [p.join(root.path, 'a.md')]);
        expect(await findDeckPaths(FieldRepo(db)), ['b.md']);
      },
    );
  });

  group('the summaries', () {
    test('give a deck its name, place, tags and counts', () async {
      write(
        'Lingue/verbs.md',
        deck(
          ['a', 'b', 'c', 'd'],
          category: 'Lingue/Inglese',
          tags: 'esame, uni',
        ),
      );
      write(
        'titled.md',
        '---\ntype: flashcard\ntitle: Nice name\n---\n\n'
            '| Q | A |\n|---|---|\n| x | y |\n',
      );
      await scan();
      await store.write(
        'Lingue/verbs.md',
        'a',
        state(due: DateTime(2026, 10, 13)),
      );
      await store.write('Lingue/verbs.md', 'b', state(due: today));
      await store.write(
        'Lingue/verbs.md',
        'c',
        state(due: DateTime(2026, 10, 15)),
      );
      // A key no card has any more is not counted.
      await store.write(
        'Lingue/verbs.md',
        'gone',
        state(due: DateTime(2026, 10)),
      );

      final snapshot = await catalog.load();
      final summaries = snapshot.summaries(today, 20);
      expect(summaries.map((s) => s.path), ['Lingue/verbs.md', 'titled.md']);
      final titled = summaries.last;
      expect(titled.name, 'Nice name');
      expect(titled.category, isEmpty);
      expect(titled.fresh, 1);
      final verbs = summaries.first;
      expect(verbs.name, 'verbs');
      expect(verbs.category, ['Lingue', 'Inglese']);
      expect(verbs.tags, ['esame', 'uni']);
      expect(verbs.total, 4);
      expect(verbs.due, 2);
      expect(verbs.fresh, 1);
      expect(verbs.newAvailable, 1);
      expect(verbs.toStudy, 3);
    });

    test('a deck that cannot be read is left out', () async {
      write('a.md', deck(['x']));
      write('b.md', deck(['x']));
      await scan();
      File(p.join(root.path, 'b.md')).deleteSync();
      final snapshot = await catalog.load();
      expect(snapshot.decks.map((d) => d.path), ['a.md']);
    });

    test('a note in another encoding still reads', () async {
      write('a.md', deck(['x']));
      File(p.join(root.path, 'a.md')).writeAsBytesSync([
        ...File(p.join(root.path, 'a.md')).readAsBytesSync(),
        0xE9,
      ]);
      await scan();
      expect((await catalog.load()).decks, hasLength(1));
    });
  });

  group('new cards per day', () {
    setUp(() async {
      write('a.md', deck(['1', '2', '3', '4', '5', '6']));
      await scan();
    });

    Future<int> available(int perDay) async =>
        (await catalog.load()).summaries(today, perDay).single.newAvailable;

    test('is the limit when no card was shown today', () async {
      expect(await available(4), 4);
      expect(await available(20), 6);
      expect(await available(0), 0);
    });

    test('loses the cards first graded today', () async {
      await store.write('a.md', '1', state(first: today));
      await store.write('a.md', '2', state(first: today));
      expect(await available(5), 3);
      expect(await available(2), 0);
      expect(await available(1), 0);
      expect((await catalog.load()).summaries(today, 5).single.fresh, 4);
    });

    test(
      'does not count a card first graded another day, or without one',
      () async {
        await store.write('a.md', '1', state(first: DateTime(2026, 10, 13)));
        await store.write('a.md', '2', state());
        expect(await available(3), 3);
      },
    );

    test('is a fresh limit on the next day', () async {
      await store.write('a.md', '1', state(first: today));
      final snapshot = await catalog.load();
      expect(snapshot.summaries(today, 1).single.newAvailable, 0);
      expect(
        snapshot.summaries(DateTime(2026, 10, 15), 1).single.newAvailable,
        1,
      );
    });
  });

  group('the cache', () {
    test('reads only the decks that changed', () async {
      write('a.md', deck(['1']));
      write('b.md', deck(['1', '2']));
      await scan();
      await catalog.load();
      expect(catalog.notesRead, 2);

      await catalog.load();
      expect(catalog.notesRead, 0);

      File(p.join(root.path, 'b.md'))
        ..writeAsStringSync(deck(['1', '2', '3']))
        ..setLastModifiedSync(DateTime.now().add(const Duration(seconds: 5)));
      final snapshot = await catalog.load();
      expect(catalog.notesRead, 1);
      expect(snapshot.decks.last.keys, ['1', '2', '3']);
      expect(snapshot.decks.first.keys, ['1']);
    });

    test('counts again from review.json without reading a note', () async {
      write('a.md', deck(['1', '2']));
      await scan();
      await catalog.load();
      await store.write('a.md', '1', state(due: today));
      final snapshot = await catalog.reloadStates();
      expect(snapshot.summaries(today, 20).single.due, 1);
      expect(catalog.notesRead, 0);
      expect(catalog.snapshot, same(snapshot));
    });

    test('drops a deck gone from the index', () async {
      write('a.md', deck(['1']));
      await scan();
      await catalog.load();
      File(p.join(root.path, 'a.md')).deleteSync();
      await indexer.applyEvents(root.path, [p.join(root.path, 'a.md')]);
      expect((await catalog.load()).decks, isEmpty);
    });
  });

  group('the controller', () {
    late StreamController<int> index;
    late StreamController<Set<String>> synced;
    late DeckCatalogController controller;
    var perDay = 20;
    var dayStart = 0;
    var clock = DateTime(2026, 10, 14, 12);

    setUp(() {
      perDay = 20;
      dayStart = 0;
      clock = DateTime(2026, 10, 14, 12);
      index = StreamController<int>.broadcast();
      synced = StreamController<Set<String>>.broadcast();
      controller = DeckCatalogController(
        catalog: catalog,
        settings: () async => (newPerDay: perDay, dayStartHour: dayStart),
        indexEvents: index.stream,
        syncChanges: synced.stream,
        now: () => clock,
        settle: const Duration(milliseconds: 10),
      );
      addTearDown(() async {
        controller.dispose();
        await index.close();
        await synced.close();
      });
    });

    Future<void> changed() {
      final done = Completer<void>();
      void listener() {
        controller.removeListener(listener);
        done.complete();
      }

      controller.addListener(listener);
      return done.future.timeout(const Duration(seconds: 10));
    }

    test('loads, counts for today and builds the tree', () async {
      write('Lingue/a.md', deck(['1', '2'], category: 'Lingue', tags: 'uni'));
      write('b.md', deck(['1']));
      await scan();
      expect(controller.loaded, isFalse);
      await controller.refresh();
      expect(controller.loaded, isTrue);
      expect(controller.today, today);
      expect(controller.summaries, hasLength(2));
      expect(controller.tags, ['uni']);
      expect(controller.tree.counts.total, 3);
      expect(controller.tree.counts.newAvailable, 3);
    });

    test('takes today from the journal day start', () async {
      write('a.md', deck(['1']));
      await scan();
      clock = DateTime(2026, 10, 14, 2);
      dayStart = 4;
      await controller.refresh();
      expect(controller.today, DateTime(2026, 10, 13));
    });

    test('filters the tree by tags, all of them', () async {
      write('a.md', deck(['1'], tags: 'x, y'));
      write('b.md', deck(['1', '2'], tags: 'x'));
      write('c.md', deck(['1', '2', '3']));
      await scan();
      await controller.refresh();
      expect(controller.tags, ['x', 'y']);
      controller.toggleTag('x');
      expect(controller.tree.counts.decks, 2);
      controller.toggleTag('y');
      expect(controller.selectedTags, {'x', 'y'});
      expect(controller.tree.counts.total, 1);
      controller
        ..toggleTag('x')
        ..toggleTag('y');
      expect(controller.tree.counts.decks, 3);
      controller.selectTags({'nope'});
      expect(controller.selectedTags, isEmpty);
    });

    test('follows the index, then reads only what changed', () async {
      write('a.md', deck(['1']));
      await scan();
      await controller.refresh();
      write('b.md', deck(['1', '2']));
      await indexer.applyEvents(root.path, [p.join(root.path, 'b.md')]);
      final next = changed();
      index
        ..add(1)
        ..add(2);
      await next;
      expect(controller.summaries.map((s) => s.path), ['a.md', 'b.md']);
      expect(catalog.notesRead, 1);
    });

    test('follows a grade of this app without reading a note', () async {
      write('a.md', deck(['1', '2']));
      await scan();
      await controller.refresh();
      expect(controller.summaries.single.due, 0);
      final next = changed();
      await store.write('a.md', '1', state(due: today));
      await next;
      expect(controller.summaries.single.due, 1);
      expect(catalog.notesRead, 0);
    });

    test('follows a review.json the sync brought', () async {
      write('a.md', deck(['1', '2']));
      await scan();
      await controller.refresh();
      // Another process writes the file: no ReviewStore call here.
      Directory(p.join(root.path, '.niman')).createSync();
      File(p.join(root.path, ReviewStore.filePath))
          .writeAsStringSync('{"a.md": {"2": ${_json(state(due: today))}}}');
      final next = changed();
      synced.add({ReviewStore.filePath});
      await next;
      expect(controller.summaries.single.due, 1);
      expect(catalog.notesRead, 0);
    });

    test('reads the notes again when a sync brings one', () async {
      write('a.md', deck(['1']));
      await scan();
      await controller.refresh();
      write('b.md', deck(['1']));
      await indexer.applyEvents(root.path, [p.join(root.path, 'b.md')]);
      final next = changed();
      synced.add({'b.md'});
      await next;
      expect(controller.summaries, hasLength(2));
    });

    test('counts again with a new limit at the next refresh', () async {
      write('a.md', deck(['1', '2', '3']));
      await scan();
      await controller.refresh();
      expect(controller.summaries.single.newAvailable, 3);
      perDay = 1;
      await controller.refresh();
      expect(controller.summaries.single.newAvailable, 1);
    });

    test('tells only when what it shows moved (#947)', () async {
      write('a.md', deck(['1', '2']));
      await scan();
      var told = 0;
      controller.addListener(() => told++);
      await controller.refresh();
      expect(told, 1, reason: 'the first load shows the decks');

      // A note saved elsewhere in the library, or this deck saved with the
      // same cards: the decks are read again, the counts are the same.
      File(p.join(root.path, 'a.md'))
          .setLastModifiedSync(DateTime(2026, 10, 14, 14));
      await controller.refresh();
      expect(catalog.notesRead, 1, reason: 'it did reload the deck');
      expect(told, 1, reason: 'but nothing shown moved');

      // A count moves.
      await store.write('a.md', '1', state(due: today));
      await controller.refreshStates();
      expect(told, 2);
      expect(controller.summaries.single.due, 1);

      // The limit of new cards, then the study day.
      perDay = 1;
      await controller.refresh();
      expect(told, 3);
      clock = DateTime(2026, 10, 15, 12);
      await controller.refresh();
      expect(told, 4);
      expect(controller.today, DateTime(2026, 10, 15));
    });

    test('keeps the snapshot current when it does not tell', () async {
      write('a.md', deck(['1', '2']));
      await scan();
      await controller.refresh();
      await store.write('a.md', '1', state(due: DateTime(2026, 11)));
      await controller.refreshStates();
      var told = 0;
      controller.addListener(() => told++);
      // The same card graded again, still not due: no count moves, the
      // state does, and a session started now starts from it.
      await store.write('a.md', '1', state(due: DateTime(2026, 12)));
      await controller.refreshStates();
      expect(told, 0);
      expect(controller.snapshot.states['a.md']!['1']!.due, DateTime(2026, 12));
    });

    test('overlapping refreshes end with the full one done', () async {
      write('a.md', deck(['1']));
      await scan();
      await controller.refresh();
      write('b.md', deck(['1']));
      await indexer.applyEvents(root.path, [p.join(root.path, 'b.md')]);
      await Future.wait([controller.refresh(), controller.refreshStates()]);
      expect(controller.summaries, hasLength(2));
    });
  });
}

String _json(ReviewState state) {
  return jsonEncode(state.toJson());
}
