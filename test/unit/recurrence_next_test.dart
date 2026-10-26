// #1188: the next occurrence from a base date — what a completed task
// repeats to. Month ends, leap years, business days over weekends, weekday
// lists, Nth and last weekday, strict versus completion base.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';

DateTime _next(String rule, DateTime base) =>
    RecurrenceRule.parse(rule)!.next(base);

void main() {
  group('days, weeks', () {
    test('plain steps', () {
      expect(_next('1d', DateTime(2026, 10, 26)), DateTime(2026, 10, 27));
      expect(_next('10d', DateTime(2026, 12, 25)), DateTime(2027, 1, 4));
      expect(_next('1w', DateTime(2026, 10, 26)), DateTime(2026, 11, 2));
      expect(_next('2w', DateTime(2026, 12, 28)), DateTime(2027, 1, 11));
    });

    test('a time of day on the base is ignored', () {
      expect(
        _next('1d', DateTime(2026, 10, 26, 23, 59)),
        DateTime(2026, 10, 27),
      );
    });

    test('across a clock change the date is still the next date', () {
      // 25 hours long or 23, in the zones that have them.
      for (final day in [
        DateTime(2026, 3, 28),
        DateTime(2026, 3, 29),
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 25),
        DateTime(2026, 11),
        DateTime(2026, 3, 8),
      ]) {
        final next = _next('1d', day);
        expect(next, DateTime(day.year, day.month, day.day + 1));
        expect(next.hour, 0);
        expect(_next('1w', day), DateTime(day.year, day.month, day.day + 7));
      }
    });
  });

  group('months and years clamp to the last day', () {
    test('31 January', () {
      expect(_next('1m', DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(_next('1m', DateTime(2028, 1, 31)), DateTime(2028, 2, 29));
      expect(_next('1m', DateTime(2026, 3, 31)), DateTime(2026, 4, 30));
      expect(_next('2m', DateTime(2026, 12, 31)), DateTime(2027, 2, 28));
    });

    test('a month step crosses the year', () {
      expect(_next('1m', DateTime(2026, 12, 15)), DateTime(2027, 1, 15));
      expect(_next('13m', DateTime(2026, 12, 15)), DateTime(2028, 1, 15));
    });

    test('the chain drifts from the 31st, as Simpletask documents', () {
      var day = DateTime(2026, 1, 31);
      final rule = RecurrenceRule.parse('1m')!;
      day = rule.next(day);
      expect(day, DateTime(2026, 2, 28));
      day = rule.next(day);
      expect(day, DateTime(2026, 3, 28));
    });

    test('leap day', () {
      expect(_next('1y', DateTime(2024, 2, 29)), DateTime(2025, 2, 28));
      expect(_next('4y', DateTime(2024, 2, 29)), DateTime(2028, 2, 29));
      expect(_next('1y', DateTime(2026, 6, 15)), DateTime(2027, 6, 15));
      expect(_next('12m', DateTime(2024, 2, 29)), DateTime(2025, 2, 28));
    });
  });

  group('business days', () {
    test('within a week', () {
      // 2026-10-26 is a Monday.
      expect(_next('1b', DateTime(2026, 10, 26)), DateTime(2026, 10, 27));
      expect(_next('3b', DateTime(2026, 10, 26)), DateTime(2026, 10, 29));
    });

    test('from a Friday the next is Monday', () {
      expect(_next('1b', DateTime(2026, 10, 30)), DateTime(2026, 11, 2));
      expect(_next('2b', DateTime(2026, 10, 30)), DateTime(2026, 11, 3));
      expect(_next('5b', DateTime(2026, 10, 30)), DateTime(2026, 11, 6));
    });

    test('from a Saturday or a Sunday', () {
      final saturday = DateTime(2026, 10, 31);
      final sunday = DateTime(2026, 11);
      expect(saturday.weekday, DateTime.saturday);
      expect(sunday.weekday, DateTime.sunday);
      expect(_next('1b', saturday), DateTime(2026, 11, 2));
      expect(_next('1b', sunday), DateTime(2026, 11, 2));
      expect(_next('2b', saturday), DateTime(2026, 11, 3));
      expect(_next('5b', saturday), DateTime(2026, 11, 6));
      expect(_next('6b', sunday), DateTime(2026, 11, 9));
    });

    test('across weekends and month ends', () {
      expect(_next('10b', DateTime(2026, 10, 26)), DateTime(2026, 11, 9));
      expect(_next('1b', DateTime(2026, 1, 30)), DateTime(2026, 2, 2));
      expect(_next('7b', DateTime(2026, 12, 29)), DateTime(2027, 1, 7));
    });

    test('always a business day, and exactly N of them on', () {
      final rng = Random(1188);
      for (var i = 0; i < 300; i++) {
        final base = DateTime(2020, 1, 1 + rng.nextInt(3000));
        final n = 1 + rng.nextInt(40);
        var expected = base;
        for (var left = n; left > 0;) {
          expected = DateTime(expected.year, expected.month, expected.day + 1);
          if (isBusinessDay(expected)) left--;
        }
        expect(_next('${n}b', base), expected, reason: '$base +${n}b');
      }
    });
  });

  group('weekday lists', () {
    test('the next listed weekday after the base, in its week', () {
      // 2026-10-21 Wed, 23 Fri, 26 Mon.
      expect(
        _next('1w;mo,we,fr', DateTime(2026, 10, 21)),
        DateTime(2026, 10, 23),
      );
      expect(
        _next('1w;mo,we,fr', DateTime(2026, 10, 22)),
        DateTime(2026, 10, 23),
      );
      expect(
        _next('1w;mo,we,fr', DateTime(2026, 10, 19)),
        DateTime(2026, 10, 21),
      );
    });

    test('after the last listed weekday it goes to the next week', () {
      expect(
        _next('1w;mo,we,fr', DateTime(2026, 10, 23)),
        DateTime(2026, 10, 26),
      );
      expect(
        _next('1w;mo,we,fr', DateTime(2026, 10, 25)),
        DateTime(2026, 10, 26),
      );
      expect(_next('1w;mo', DateTime(2026, 10, 26)), DateTime(2026, 11, 2));
    });

    test('honours the N-week interval', () {
      // Fri 23 Oct -> Mon two weeks after the week of the 19th: 2 Nov.
      expect(_next('2w;mo,fr', DateTime(2026, 10, 23)), DateTime(2026, 11, 2));
      // Mon 19 Oct -> Fri 23 Oct, still in its own week.
      expect(_next('2w;mo,fr', DateTime(2026, 10, 19)), DateTime(2026, 10, 23));
      expect(_next('3w;su', DateTime(2026, 10, 25)), DateTime(2026, 11, 15));
    });

    test('from a weekday that is not listed', () {
      // Tuesday 20 Oct with only Mon and Fri.
      expect(_next('1w;mo,fr', DateTime(2026, 10, 20)), DateTime(2026, 10, 23));
      expect(_next('1w;mo,fr', DateTime(2026, 10, 24)), DateTime(2026, 10, 26));
    });

    test('property: the first listed date after the base, interval apart', () {
      final rng = Random(5);
      for (var i = 0; i < 300; i++) {
        final base = DateTime(2024, 1, 1 + rng.nextInt(1500));
        final n = 1 + rng.nextInt(4);
        final listed = <int>{
          for (var j = 0; j < 1 + rng.nextInt(7); j++) 1 + rng.nextInt(7),
        };
        final rule = RecurrenceRule(
          unit: RecurrenceUnit.week,
          interval: n,
          weekdays: (listed.toList()..sort()),
        );
        final baseMonday = mondayOf(base);
        var d = base;
        while (true) {
          d = DateTime(d.year, d.month, d.day + 1);
          final weeks = daysBetween(baseMonday, mondayOf(d)) ~/ 7;
          if (listed.contains(d.weekday) && weeks % n == 0) break;
        }
        expect(rule.next(base), d, reason: '${rule.token} from $base');
      }
    });
  });

  group('Nth weekday of the month', () {
    test('second Tuesday', () {
      // October 2026: Tuesdays 6, 13, 20, 27. November: 3, 10, 17, 24.
      expect(_next('1m;2tu', DateTime(2026, 10, 13)), DateTime(2026, 11, 10));
      expect(_next('1m;2tu', DateTime(2026, 11, 10)), DateTime(2026, 12, 8));
    });

    test('last Friday, in months of different lengths', () {
      expect(_next('1m;-1fr', DateTime(2026, 10, 30)), DateTime(2026, 11, 27));
      expect(_next('1m;-1fr', DateTime(2026, 11, 27)), DateTime(2026, 12, 25));
      expect(_next('1m;-1fr', DateTime(2026, 12, 25)), DateTime(2027, 1, 29));
      // February 2024 has 29 days; its last Friday is the 23rd.
      expect(_next('1m;-1fr', DateTime(2024, 1, 26)), DateTime(2024, 2, 23));
      expect(_next('1m;-1th', DateTime(2024, 1, 25)), DateTime(2024, 2, 29));
    });

    test('N months on, from a day that is not the Nth weekday', () {
      expect(_next('1m;2tu', DateTime(2026, 10)), DateTime(2026, 11, 10));
      expect(_next('3m;1mo', DateTime(2026, 10, 31)), DateTime(2027, 1, 4));
      expect(_next('12m;-1su', DateTime(2026, 10, 15)), DateTime(2027, 10, 31));
    });

    test('first weekday of the month, across the year', () {
      expect(_next('2m;1we', DateTime(2026, 11, 4)), DateTime(2027, 1, 6));
    });

    test('property: always the Nth weekday, N months on', () {
      final rng = Random(9);
      for (var i = 0; i < 300; i++) {
        final base = DateTime(2024, 1, 1 + rng.nextInt(2000));
        final n = 1 + rng.nextInt(14);
        final nth = [1, 2, 3, 4, -1][rng.nextInt(5)];
        final code = ['mo', 'tu', 'we', 'th', 'fr', 'sa', 'su'][rng.nextInt(7)];
        final rule = RecurrenceRule.parse('${n}m;$nth$code')!;
        final next = rule.next(base);
        final months =
            (next.year * 12 + next.month) - (base.year * 12 + base.month);
        expect(months, n, reason: rule.token);
        expect(rule.nthWeekday!.matches(next), isTrue, reason: rule.token);
      }
    });
  });

  group('strict and completion bases', () {
    test('a strict rule counts from the due date', () {
      final rule = RecurrenceRule.parse('+1w')!;
      expect(
        rule.nextFor(
          completed: DateTime(2026, 10, 28),
          due: DateTime(2026, 10, 26),
        ),
        DateTime(2026, 11, 2),
      );
    });

    test('a loose rule counts from the completion', () {
      final rule = RecurrenceRule.parse('1w')!;
      expect(
        rule.nextFor(
          completed: DateTime(2026, 10, 28),
          due: DateTime(2026, 10, 26),
        ),
        DateTime(2026, 11, 4),
      );
    });

    test('no due date: the completion, strict or not', () {
      expect(
        RecurrenceRule.parse('+1w')!.nextFor(completed: DateTime(2026, 10, 28)),
        DateTime(2026, 11, 4),
      );
    });

    test('an overdue strict task moves one period, not to the future', () {
      final rule = RecurrenceRule.parse('+1w')!;
      expect(
        rule.nextFor(completed: DateTime(2026, 10, 28), due: DateTime(2026, 9)),
        DateTime(2026, 9, 8),
      );
    });
  });

  group('date helpers', () {
    test('nthWeekdayOfMonth', () {
      expect(
        nthWeekdayOfMonth(2026, 10, DateTime.tuesday, 2),
        DateTime(2026, 10, 13),
      );
      expect(
        nthWeekdayOfMonth(2026, 11, DateTime.sunday, 1),
        DateTime(2026, 11),
      );
      expect(
        nthWeekdayOfMonth(2026, 11, DateTime.friday, -1),
        DateTime(2026, 11, 27),
      );
      expect(
        nthWeekdayOfMonth(2026, 11, DateTime.monday, -1),
        DateTime(2026, 11, 30),
      );
      expect(
        nthWeekdayOfMonth(2026, 12, DateTime.thursday, 4),
        DateTime(2026, 12, 24),
      );
    });

    test('addMonthsClamped never goes past the target month', () {
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(addMonthsClamped(DateTime(2026, 1, 31), 0), DateTime(2026, 1, 31));
      expect(addMonthsClamped(DateTime(2026, 8, 31), 6), DateTime(2027, 2, 28));
    });
  });
}
