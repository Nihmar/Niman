// A study session (#533): the queue of a deck or a category, the grades,
// Again coming back, undo, the summary.
// The grades read as a script of the session, a call a line.
// ignore_for_file: cascade_invocations
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/flash_card.dart';
import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/sm2.dart';
import 'package:niman/src/flashcards/study_session.dart';

final DateTime today = DateTime(2026, 10, 14);

FlashCard card(String key) => FlashCard(
  kind: CardKind.line,
  question: key,
  answer: 'answer of $key',
  key: key,
  source: const CardSource(
    firstLine: 0,
    lastLine: 0,
    content: (start: 0, end: 0),
    lines: (start: 0, end: 0),
  ),
);

ReviewState state({
  int daysAgo = 0,
  int dueIn = 0,
  DateTime? first,
  int reps = 2,
}) => ReviewState(
  ef: 2.5,
  interval: 6,
  reps: reps,
  due: DateTime(today.year, today.month, today.day + dueIn - daysAgo),
  at: DateTime.utc(2026, 10),
  first: first,
);

SessionDeck deck(
  String path,
  List<String> keys, [
  Map<String, ReviewState> states = const {},
]) => SessionDeck(
  path: path,
  cards: [for (final key in keys) card(key)],
  states: states,
);

List<String> queue(StudySession session) {
  final out = <String>[];
  // Reads the queue by grading Good and undoing, so no internals leak.
  while (!session.isDone) {
    out.add(session.current!.card.key);
    session.grade(Grade.good);
  }
  for (var i = 0; i < out.length; i++) {
    session.undo();
  }
  return out;
}

StudySession start(
  List<SessionDeck> decks, {
  int newPerDay = 20,
  DateTime Function()? clock,
}) => StudySession.start(
  decks: decks,
  today: today,
  newPerDay: newPerDay,
  clock: clock,
);

void main() {
  group('the queue', () {
    test('is the due cards oldest first, then the new ones in note order', () {
      final session = start([
        deck(
          'a.md',
          ['n1', 'd1', 'n2', 'd2', 'later', 'd3'],
          {
            'd1': state(daysAgo: 1),
            'd2': state(daysAgo: 5),
            'd3': state(),
            'later': state(dueIn: 3),
          },
        ),
      ]);
      expect(queue(session), ['d2', 'd1', 'd3', 'n1', 'n2']);
      expect(session.remainingDue, 3);
      expect(session.remainingNew, 2);
      expect(session.remainingAgain, 0);
      expect(session.remaining, 5);
    });

    test('keeps the decks and note order among cards due the same day', () {
      final session = start([
        deck('a.md', ['a1', 'a2'], {'a1': state(), 'a2': state()}),
        deck('b.md', ['b1'], {'b1': state()}),
      ]);
      expect(queue(session), ['a1', 'a2', 'b1']);
    });

    test('limits the new cards to the share left of the day, per deck', () {
      final session = start([
        deck(
          'a.md',
          ['1', '2', '3', '4', '5'],
          {'1': state(dueIn: 9, first: today)},
        ),
        deck('b.md', ['x', 'y', 'z']),
      ], newPerDay: 3);
      // a: three a day, one shown already, two left; b: three.
      expect(queue(session), ['2', '3', 'x', 'y', 'z']);
    });

    test('has no new card with a limit of none, or a limit used up', () {
      final decks = [
        deck('a.md', ['1', '2'], {'1': state(dueIn: 2, first: today)}),
      ];
      expect(queue(start(decks, newPerDay: 0)), isEmpty);
      expect(queue(start(decks, newPerDay: 1)), isEmpty);
      expect(queue(start(decks, newPerDay: 2)), ['2']);
    });

    test('an Again card of an earlier session today is due again', () {
      final session = start([
        deck('a.md', ['1', '2'], {'1': state(reps: 0, first: today)}),
      ]);
      expect(session.current!.card.key, '1');
      expect(session.currentKind, QueueKind.due);
    });

    test('is empty, and done, for a deck with nothing to study', () {
      final session = start([deck('a.md', [])]);
      expect(session.isDone, isTrue);
      expect(session.current, isNull);
      expect(session.currentKind, isNull);
      expect(session.previews, isEmpty);
    });
  });

  group('grading', () {
    test('writes the state SM-2 gives and moves to the next card', () {
      final now = DateTime.utc(2026, 10, 14, 9);
      final session = start([
        deck('a.md', ['1', '2']),
      ], clock: () => now);
      expect(session.current!.card.key, '1');
      session.show();
      expect(session.answerShown, isTrue);
      final writes = session.grade(Grade.good);
      expect(session.answerShown, isFalse);
      expect(writes, hasLength(1));
      expect(writes.single.path, 'a.md');
      expect(writes.single.key, '1');
      expect(writes.single.state, gradeCard(null, Grade.good, today, now: now));
      expect(writes.single.state!.first, today);
      expect(session.current!.card.key, '2');
      expect(session.remainingNew, 1);
    });

    test('previews the buttons for the card on show', () {
      final session = start([
        deck('a.md', ['1'], {'1': state()}),
      ]);
      expect(session.previews, intervalPreviews(state()));
      expect(
        start([
          deck('a.md', ['1']),
        ]).previews,
        intervalPreviews(null),
      );
    });

    test('Again puts the card behind the others and it comes back', () {
      final session = start([
        deck('a.md', ['1', '2', '3']),
      ]);
      session.grade(Grade.again);
      expect(session.current!.card.key, '2');
      session
        ..grade(Grade.good)
        ..grade(Grade.good);
      expect(session.current!.card.key, '1');
      expect(session.currentKind, QueueKind.again);
      expect(session.remainingAgain, 1);
      expect(session.remainingNew, 0);
      // Asked again from the state the Again set.
      expect(session.currentState!.reps, 0);
      expect(session.currentState!.due, today);
    });

    test('Again keeps coming back until it is graded another way', () {
      final session = start([
        deck('a.md', ['1', '2']),
      ]);
      session
        ..grade(Grade.again)
        ..grade(Grade.again);
      expect(session.current!.card.key, '1');
      session
        ..grade(Grade.again)
        ..grade(Grade.again);
      expect(session.current!.card.key, '1');
      expect(session.isDone, isFalse);
      final writes = session.grade(Grade.good);
      expect(session.current!.card.key, '2');
      expect(writes.single.state!.interval, 1);
      expect(writes.single.state!.first, today);
      session.grade(Grade.hard);
      expect(session.isDone, isTrue);
      expect(session.remaining, 0);
    });

    test('Hard and Easy end the card for the session', () {
      final session = start([
        deck('a.md', ['1', '2']),
      ]);
      session
        ..grade(Grade.hard)
        ..grade(Grade.easy);
      expect(session.isDone, isTrue);
    });

    test('the cards of a category come from all its decks', () {
      final session = start([
        deck('a.md', ['1'], {'1': state()}),
        deck('b.md', ['1', '2']),
      ]);
      final seen = <String>[];
      while (!session.isDone) {
        final c = session.current!;
        seen.add('${c.deckPath}:${c.card.key}');
        final writes = session.grade(Grade.good);
        expect(writes.single.path, c.deckPath);
      }
      expect(seen, ['a.md:1', 'b.md:1', 'b.md:2']);
    });
  });

  group('undo', () {
    test('takes the last grade back: the card, its state, the write', () {
      final before = state();
      final session = start([
        deck('a.md', ['1', '2'], {'1': before}),
      ]);
      session.grade(Grade.easy);
      expect(session.current!.card.key, '2');
      expect(session.undoable, 1);
      final writes = session.undo();
      expect(writes.single.key, '1');
      expect(writes.single.state, before);
      expect(session.current!.card.key, '1');
      expect(session.currentState, before);
      expect(session.undoable, 0);
      expect(session.remainingDue, 1);
      expect(session.summary.reviewed, 0);
    });

    test('of a first grade writes null: the card is new again', () {
      final session = start([
        deck('a.md', ['1']),
      ]);
      session.grade(Grade.good);
      expect(session.isDone, isTrue);
      final writes = session.undo();
      expect(writes.single.state, isNull);
      expect(session.currentKind, QueueKind.fresh);
      expect(session.currentState, isNull);
      expect(session.isDone, isFalse);
    });

    test('of an Again takes the copy at the end of the queue away', () {
      final session = start([
        deck('a.md', ['1', '2']),
      ]);
      session.grade(Grade.again);
      expect(session.remaining, 2);
      session.undo();
      expect(session.remaining, 2);
      expect(session.current!.card.key, '1');
      expect(session.currentKind, QueueKind.fresh);
      expect(session.remainingAgain, 0);
    });

    test('goes back as many grades as the session has, in order', () {
      final session = start([
        deck('a.md', ['1', '2', '3']),
      ]);
      final shown = <String>[];
      session
        ..grade(Grade.good)
        ..grade(Grade.again)
        ..grade(Grade.hard)
        ..grade(Grade.good);
      expect(session.isDone, isTrue);
      expect(session.undoable, 4);
      for (var i = 0; i < 4; i++) {
        session.undo();
        shown.add(session.current!.card.key);
      }
      expect(shown, ['2', '3', '2', '1']);
      expect(session.undo(), isEmpty);
      expect(session.remaining, 3);
      expect(session.remainingNew, 3);
      expect(session.summary.graded, 0);
    });

    test('of a card Again twice restores the state the first Again set', () {
      final session = start([
        deck('a.md', ['1']),
      ]);
      session.grade(Grade.again);
      final afterFirst = session.currentState;
      session.grade(Grade.again);
      final writes = session.undo();
      expect(writes.single.state, afterFirst);
      expect(session.remaining, 1);
      expect(session.currentState, afterFirst);
    });
  });

  group('the summary', () {
    test('counts the cards reviewed, the grades and the Agains', () {
      final session = start([
        deck('a.md', ['1', '2', '3']),
      ]);
      session
        ..grade(Grade.again)
        ..grade(Grade.good)
        ..grade(Grade.easy)
        ..grade(Grade.again)
        ..grade(Grade.good);
      final summary = session.summary;
      expect(session.isDone, isTrue);
      expect(summary.reviewed, 3);
      expect(summary.graded, 5);
      expect(summary.again, 2);
      expect(summary.grades, {
        Grade.again: 2,
        Grade.hard: 0,
        Grade.good: 2,
        Grade.easy: 1,
      });
    });

    test('times the session from its start to the last grade', () {
      var now = DateTime.utc(2026, 10, 14, 9);
      final session = start([
        deck('a.md', ['1', '2']),
      ], clock: () => now);
      now = now.add(const Duration(seconds: 30));
      session.grade(Grade.good);
      expect(session.summary.elapsed, const Duration(seconds: 30));
      now = now.add(const Duration(seconds: 45));
      session.grade(Grade.good);
      expect(session.isDone, isTrue);
      expect(session.summary.elapsed, const Duration(seconds: 75));
      // Over, the time stops with the last grade.
      now = now.add(const Duration(minutes: 10));
      expect(session.summary.elapsed, const Duration(seconds: 75));
    });

    test('says when the next cards are due across the decks', () {
      final session = start([
        deck(
          'a.md',
          ['1', '2', '3'],
          {'1': state(), '2': state(dueIn: 9), '3': state(dueIn: 2)},
        ),
        deck('b.md', ['1', '2'], {'2': state(dueIn: 2)}),
      ], newPerDay: 0);
      // Today's: a:1 only; Good gives it interval 15 days.
      session.grade(Grade.good);
      final summary = session.summary;
      expect(summary.nextDue, DateTime(2026, 10, 16));
      expect(summary.nextCount, 2);
    });

    test('moves with the cards graded in the session', () {
      final session = start([
        deck('a.md', ['1', '2']),
      ]);
      session
        ..grade(Grade.good)
        ..grade(Grade.good);
      final summary = session.summary;
      expect(summary.nextDue, DateTime(2026, 10, 15));
      expect(summary.nextCount, 2);
      session.undo();
      expect(session.summary.nextCount, 1);
    });

    test('has no next day when nothing is scheduled', () {
      final session = start([
        deck('a.md', ['1']),
      ]);
      session.grade(Grade.again);
      expect(session.summary.nextDue, isNull);
      expect(session.summary.nextCount, 0);
    });
  });
}
