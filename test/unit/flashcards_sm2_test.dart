import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/sm2.dart';
import 'package:niman/src/flashcards/study_day.dart';

final DateTime today = DateTime(2026, 10, 14);
final DateTime now = DateTime.utc(2026, 10, 14, 9, 12, 3);

ReviewState grade(ReviewState? state, Grade g, [DateTime? day]) =>
    gradeCard(state, g, day ?? today, now: now);

ReviewState state({
  double ef = 2.5,
  int interval = 6,
  int reps = 2,
  DateTime? due,
}) => ReviewState(
  ef: ef,
  interval: interval,
  reps: reps,
  due: due ?? DateTime(2026, 10, 20),
  at: now,
);

void main() {
  group('a new card', () {
    test('Again: due today, no reps, the ease falls', () {
      final next = grade(null, Grade.again);
      expect(next.reps, 0);
      expect(next.interval, 0);
      expect(next.due, today);
      expect(next.ef, closeTo(1.96, 1e-9));
      expect(next.at, now);
    });

    test('Hard: a day', () {
      final next = grade(null, Grade.hard);
      expect(next.interval, 1);
      expect(next.reps, 1);
      expect(next.due, DateTime(2026, 10, 15));
      expect(next.ef, closeTo(2.36, 1e-9));
    });

    test('Good: a day, the ease unchanged', () {
      final next = grade(null, Grade.good);
      expect(next.interval, 1);
      expect(next.reps, 1);
      expect(next.ef, closeTo(2.5, 1e-9));
    });

    test('Easy: two days, the ease rises', () {
      final next = grade(null, Grade.easy);
      expect(next.interval, 2);
      expect(next.reps, 1);
      expect(next.ef, closeTo(2.6, 1e-9));
    });
  });

  group('a card in its course', () {
    test('Good goes 1, 6, then by the ease', () {
      var s = grade(null, Grade.good);
      expect(s.interval, 1);
      s = grade(s, Grade.good);
      expect(s.interval, 6);
      expect(s.reps, 2);
      s = grade(s, Grade.good);
      expect(s.interval, 15);
      s = grade(s, Grade.good);
      expect(s.interval, 38);
      expect(s.reps, 4);
      expect(s.ef, closeTo(2.5, 1e-9));
    });

    test('Easy is Good times 1.3, at least a day more', () {
      expect(grade(state(), Grade.good).interval, 15);
      expect(grade(state(), Grade.easy).interval, 20);
      expect(grade(state(reps: 1, interval: 1), Grade.easy).interval, 8);
    });

    test('Hard is the interval times 1.2, at least a day more', () {
      expect(grade(state(interval: 10), Grade.hard).interval, 12);
      expect(grade(state(interval: 2), Grade.hard).interval, 3);
      expect(grade(state(interval: 1), Grade.hard).interval, 2);
      expect(grade(state(interval: 10), Grade.hard).reps, 3);
    });

    test('Good always moves on by a day, even at the lowest ease', () {
      final next = grade(state(ef: 1.3, interval: 1), Grade.good);
      expect(next.interval, 2);
    });

    test('Again starts it over and the card is asked tomorrow once Good', () {
      var s = grade(state(interval: 30, reps: 5), Grade.again);
      expect(s.reps, 0);
      expect(s.interval, 0);
      expect(s.due, today);
      s = grade(s, Grade.good);
      expect(s.interval, 1);
      expect(s.due, DateTime(2026, 10, 15));
    });

    test('the ease never goes under 1.3', () {
      var s = state(ef: 1.4);
      for (var i = 0; i < 5; i++) {
        s = grade(s, Grade.again);
      }
      expect(s.ef, 1.3);
      expect(grade(s, Grade.hard).ef, 1.3);
    });

    test('the interval uses the ease before the review', () {
      // Easy raises the ease to 2.6 but the interval is 6 * 2.5 = 15, x 1.3.
      expect(grade(state(), Grade.easy).interval, 20);
      expect(grade(state(), Grade.easy).ef, closeTo(2.6, 1e-9));
    });

    test('the due date counts calendar days across a month end', () {
      final next = grade(state(reps: 1), Grade.good, DateTime(2026, 10, 30));
      expect(next.due, DateTime(2026, 11, 5));
    });
  });

  group('previews', () {
    test('give each button its interval', () {
      expect(intervalPreviews(null), {
        Grade.again: 0,
        Grade.hard: 1,
        Grade.good: 1,
        Grade.easy: 2,
      });
      expect(intervalPreviews(state()), {
        Grade.again: 0,
        Grade.hard: 7,
        Grade.good: 15,
        Grade.easy: 20,
      });
    });

    test('match what grading does', () {
      final s = state(ef: 2.1, interval: 9, reps: 3);
      final previews = intervalPreviews(s);
      for (final g in Grade.values) {
        expect(grade(s, g).interval, previews[g]);
      }
    });
  });

  group('the state', () {
    test('roundtrips through json', () {
      final s = grade(state(), Grade.good);
      expect(ReviewState.fromJson(s.toJson()), s);
      expect(s.toJson()['due'], '2026-10-29');
      expect(s.toJson()['at'], '2026-10-14T09:12:03.000Z');
    });

    test('reads absent for anything invalid', () {
      final good = state().toJson();
      expect(ReviewState.fromJson(null), isNull);
      expect(ReviewState.fromJson('x'), isNull);
      expect(ReviewState.fromJson({...good, 'ef': 'high'}), isNull);
      expect(ReviewState.fromJson({...good, 'ef': 0.5}), isNull);
      expect(ReviewState.fromJson({...good, 'interval': 1.5}), isNull);
      expect(ReviewState.fromJson({...good, 'interval': -1}), isNull);
      expect(ReviewState.fromJson({...good, 'reps': null}), isNull);
      expect(ReviewState.fromJson({...good, 'due': '2026-02-30'}), isNull);
      expect(ReviewState.fromJson({...good, 'due': 'tomorrow'}), isNull);
      expect(ReviewState.fromJson({...good}..remove('due')), isNull);
    });

    test('a missing time reads as the epoch', () {
      final s = ReviewState.fromJson({...state().toJson()}..remove('at'));
      expect(s!.at, DateTime.utc(1970));
    });

    test('is due on its day and after', () {
      final s = state(due: DateTime(2026, 10, 14));
      expect(s.isDue(DateTime(2026, 10, 13)), isFalse);
      expect(s.isDue(DateTime(2026, 10, 14)), isTrue);
      expect(s.isDue(DateTime(2026, 10, 20)), isTrue);
      expect(s.daysUntilDue(DateTime(2026, 10, 11)), 3);
      expect(s.daysUntilDue(DateTime(2026, 10, 16)), -2);
    });
  });

  group('studyToday', () {
    test('is the calendar day by default', () {
      expect(studyToday(DateTime(2026, 10, 14, 0, 30), 0), today);
    });

    test('belongs to the day before until the day starts', () {
      expect(
        studyToday(DateTime(2026, 10, 14, 3, 59), 4),
        DateTime(2026, 10, 13),
      );
      expect(studyToday(DateTime(2026, 10, 14, 4), 4), today);
      expect(studyToday(DateTime(2026, 10, 14, 1), 4), DateTime(2026, 10, 13));
    });

    test('crosses a month and a year start', () {
      expect(studyToday(DateTime(2026, 11, 1, 2), 4), DateTime(2026, 10, 31));
      expect(studyToday(DateTime(2027, 1, 1, 2), 4), DateTime(2026, 12, 31));
    });

    test('returns a date at midnight', () {
      expect(studyToday(DateTime(2026, 10, 14, 23, 59), 4), today);
    });
  });
}
