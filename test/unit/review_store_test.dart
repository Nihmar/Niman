// When each flashcard comes back (#533): the states of a library's decks,
// kept in `.niman/review.json` by the note's library-relative path and the
// card's key.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:path/path.dart' as p;

ReviewState state({int interval = 6, DateTime? at}) => ReviewState(
  ef: 2.5,
  interval: interval,
  reps: 2,
  due: DateTime(2026, 10, 20),
  at: at ?? DateTime.utc(2026, 10, 14, 9, 12, 3),
);

void main() {
  late Directory root;
  late ReviewStore store;
  setUp(() {
    root = Directory.systemTemp.createTempSync('niman_review_');
    store = ReviewStore(root.path);
  });
  tearDown(() => root.deleteSync(recursive: true));

  File kept() => File(p.join(root.path, ReviewStore.filePath));
  Map<String, Object?> onDisk() =>
      (jsonDecode(kept().readAsStringSync()) as Map).cast<String, Object?>();

  test('is a state file of the library', () {
    expect(ReviewStore.filePath, '.niman/review.json');
  });

  group('reading the whole file only when it changed (#967)', () {
    test('a file still the version known is not decoded again', () async {
      await store.write('a.md', '1', state());
      final first = await store.readAllIfChanged(null);
      expect(first.stamp, isNotNull);
      expect(first.states, hasLength(1));

      final again = await store.readAllIfChanged(first.stamp);
      expect(again.stamp, first.stamp);
      expect(again.states, isNull);
    });

    test('a write makes the file a version to read', () async {
      await store.write('a.md', '1', state());
      final known = (await store.readAllIfChanged(null)).stamp;

      await store.write('a.md', '2', state(interval: 7));
      final read = await store.readAllIfChanged(known);
      expect(read.stamp, isNot(known));
      expect(read.states!['a.md'], hasLength(2));
    });

    test('a file that is missing is read as empty, and has no stamp', () async {
      final read = await store.readAllIfChanged(null);
      expect(read.stamp, isNull);
      expect(read.states, isEmpty);

      await store.write('a.md', '1', state());
      final known = (await store.readAllIfChanged(null)).stamp;
      kept().deleteSync();
      final gone = await store.readAllIfChanged(known);
      expect(gone.stamp, isNull);
      expect(gone.states, isEmpty);
    });
  });

  test('reads nothing from a library never studied', () async {
    expect(await store.read('a.md'), isEmpty);
    expect(await store.readAll(), isEmpty);
    expect(kept().existsSync(), isFalse);
  });

  test('reads back what it wrote, in the documented format', () async {
    await store.write('Studio/Verbs.md', 'choose', state());
    expect(onDisk(), {
      'Studio/Verbs.md': {
        'choose': {
          'ef': 2.5,
          'interval': 6,
          'reps': 2,
          'due': '2026-10-20',
          'at': '2026-10-14T09:12:03.000Z',
        },
      },
    });
    expect(await store.read('Studio/Verbs.md'), {'choose': state()});
    expect(await store.read('Studio/Other.md'), isEmpty);
  });

  test('keeps the other cards and notes when one is written', () async {
    await store.write('a.md', 'one', state());
    await store.write('a.md', 'two', state(interval: 9));
    await store.write('b.md', 'one', state(interval: 3));
    await store.write('a.md', 'one', state(interval: 15));
    expect(await store.read('a.md'), {
      'one': state(interval: 15),
      'two': state(interval: 9),
    });
    expect(await store.read('b.md'), {'one': state(interval: 3)});
    expect((await store.readAll()).keys, unorderedEquals(['a.md', 'b.md']));
  });

  test('reads the states of several notes at once', () async {
    await store.write('a.md', 'one', state());
    await store.write('b.md', 'one', state(interval: 3));
    await store.write('c.md', 'one', state(interval: 9));
    expect(await store.readMany(['a.md', 'c.md', 'never.md']), {
      'a.md': {'one': state()},
      'c.md': {'one': state(interval: 9)},
      'never.md': isEmpty,
    });
    expect(await store.readMany(const []), isEmpty);
  });

  test('queues writes issued together, none lost', () async {
    await Future.wait([
      for (var i = 0; i < 12; i++) store.write('a.md', 'card $i', state()),
      for (var i = 0; i < 12; i++)
        ReviewStore(root.path).write('b.md', 'card $i', state()),
    ]);
    expect(await store.read('a.md'), hasLength(12));
    expect(await store.read('b.md'), hasLength(12));
  });

  test('takes a card back to never reviewed with a null state', () async {
    await store.write('a.md', 'one', state());
    await store.write('a.md', 'two', state());
    await store.write('a.md', 'one', null);
    expect((await store.read('a.md')).keys, ['two']);
    await store.write('a.md', 'two', null);
    expect(onDisk(), isEmpty);
    // A card never reviewed: nothing to take back, nothing written.
    kept().deleteSync();
    await store.write('a.md', 'zero', null);
    expect(kept().existsSync(), isFalse);
  });

  group('moved', () {
    setUp(() async {
      await store.write('Studio/Verbs.md', 'k', state());
      await store.write('Studio/Sub/Nouns.md', 'k', state(interval: 3));
      await store.write('Studio 2/Verbs.md', 'k', state(interval: 9));
    });

    test('carries the entry of a renamed or moved note', () async {
      await store.moved('Studio/Verbs.md', 'Archive/Old verbs.md');
      expect(await store.read('Studio/Verbs.md'), isEmpty);
      expect(await store.read('Archive/Old verbs.md'), {'k': state()});
      expect(await store.read('Studio/Sub/Nouns.md'), isNotEmpty);
    });

    test('carries every note under a moved folder, and only them', () async {
      await store.moved('Studio', 'Lessons');
      expect((await store.readAll()).keys, [
        'Studio 2/Verbs.md',
        'Lessons/Verbs.md',
        'Lessons/Sub/Nouns.md',
      ]);
      expect(await store.read('Lessons/Sub/Nouns.md'), {
        'k': state(interval: 3),
      });
    });

    test('writes nothing when no entry moves', () async {
      final before = kept().readAsStringSync();
      await store.moved('Elsewhere', 'Somewhere');
      await store.moved('Studio/Ver', 'Studio/Other');
      expect(kept().readAsStringSync(), before);
    });
  });

  group('removed', () {
    setUp(() async {
      await store.write('Studio/Verbs.md', 'k', state());
      await store.write('Studio/Sub/Nouns.md', 'k', state());
      await store.write('Studio 2/Verbs.md', 'k', state());
    });

    test('drops a note, or a folder and every note under it', () async {
      await store.removed(['Studio/Verbs.md']);
      expect((await store.readAll()).keys, [
        'Studio/Sub/Nouns.md',
        'Studio 2/Verbs.md',
      ]);
      await store.removed(['Studio']);
      expect((await store.readAll()).keys, ['Studio 2/Verbs.md']);
    });

    test('does nothing for nothing', () async {
      await store.removed(const []);
      await store.removed(['Missing.md']);
      expect(await store.readAll(), hasLength(3));
    });
  });

  test('resetNote forgets the cards of a note and only of it', () async {
    await store.write('a.md', 'one', state());
    await store.write('a.md', 'two', state());
    await store.write('b.md', 'one', state());
    await store.resetNote('a.md');
    expect(await store.read('a.md'), isEmpty);
    expect(await store.read('b.md'), isNotEmpty);
    await store.resetNote('a.md');
  });

  test('resetAll forgets every card of every note', () async {
    await store.write('a.md', 'one', state());
    await store.write('b.md', 'one', state());
    await store.resetAll();
    expect(await store.readAll(), isEmpty);
    await store.resetAll();
  });

  group('a file that does not read', () {
    test('reads as empty and is written over', () async {
      Directory(p.join(root.path, '.niman')).createSync();
      kept().writeAsStringSync('{ not json');
      expect(await store.read('a.md'), isEmpty);
      await store.write('a.md', 'one', state());
      expect(await store.read('a.md'), {'one': state()});
    });

    test('that is not an object reads as empty', () async {
      Directory(p.join(root.path, '.niman')).createSync();
      kept().writeAsStringSync('[1, 2]');
      expect(await store.readAll(), isEmpty);
    });

    test('has invalid entries read as absent, the rest kept', () async {
      Directory(p.join(root.path, '.niman')).createSync();
      kept().writeAsStringSync(
        jsonEncode({
          'a.md': {
            'good': state().toJson(),
            'no due': {'ef': 2.5, 'interval': 1, 'reps': 1},
            'text': 'tomorrow',
            'null': null,
          },
          'b.md': 'not an object',
          'c.md': null,
        }),
      );
      expect((await store.read('a.md')).keys, ['good']);
      expect(await store.read('b.md'), isEmpty);
      expect((await store.readAll()).keys, ['a.md']);
      // A write to the note keeps what it did not touch.
      await store.write('a.md', 'new', state());
      expect(
        (onDisk()['a.md']! as Map).keys,
        containsAll(['good', 'no due', 'text', 'null', 'new']),
      );
    });
  });
}
