// #1188: the occurrences of an event in a date range, counted from its first
// day — no drift, `until:` inclusive, `except:` skipped, and a range far from
// the anchor reached by arithmetic. The property tests hold the engine to a
// day-by-day oracle that shares none of its arithmetic.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_dates.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';

List<DateTime> _occ(
  String rule,
  DateTime anchor,
  DateTime from,
  DateTime to, {
  RecurrenceBounds? bounds,
}) =>
    RecurrenceRule.parse(rule)!
        .occurrences(anchor: anchor, from: from, to: to, bounds: bounds);

String _fmt(Iterable<DateTime> days) => days.map(formatIsoDate).join(' ');

/// Every date of [rule] from [anchor] to [to], found by testing each day in
/// turn against the rule's definition — no stepping, no clamping helpers.
List<DateTime> _oracle(RecurrenceRule rule, DateTime anchor, DateTime to) {
  final result = <DateTime>[];
  final n = rule.interval;
  var businessCount = 0;
  for (
    var d = anchor;
    !d.isAfter(to);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    final days = daysBetween(anchor, d);
    final months = (d.year * 12 + d.month) - (anchor.year * 12 + anchor.month);
    if (d != anchor && d.weekday <= DateTime.friday) businessCount++;
    final lastOfMonth = DateTime(d.year, d.month + 1, 0).day;
    final sameDay = d.day == min(anchor.day, lastOfMonth);
    final bool hit;
    if (d == anchor) {
      hit = true;
    } else if (rule.weekdays.isNotEmpty) {
      final weeks = daysBetween(mondayOf(anchor), mondayOf(d)) ~/ 7;
      hit = weeks % n == 0 && rule.weekdays.contains(d.weekday);
    } else if (rule.nthWeekday != null) {
      hit = months % n == 0 && rule.nthWeekday!.matches(d);
    } else {
      hit = switch (rule.unit) {
        RecurrenceUnit.day => days % n == 0,
        RecurrenceUnit.week => days % (7 * n) == 0,
        RecurrenceUnit.month => months % n == 0 && sameDay,
        RecurrenceUnit.year =>
          months % (12 * n) == 0 && d.month == anchor.month && sameDay,
        RecurrenceUnit.businessDay =>
          d.weekday <= DateTime.friday && businessCount % n == 0,
      };
    }
    if (hit) result.add(d);
  }
  return result;
}

void main() {
  group('plain steps', () {
    test('daily and weekly', () {
      expect(
        _fmt(
          _occ(
            '1d',
            DateTime(2026, 10, 21),
            DateTime(2026, 10, 23),
            DateTime(2026, 10, 26),
          ),
        ),
        '2026-10-23 2026-10-24 2026-10-25 2026-10-26',
      );
      expect(
        _fmt(
          _occ(
            '1w',
            DateTime(2026, 10, 21),
            DateTime(2026, 10),
            DateTime(2026, 11, 20),
          ),
        ),
        '2026-10-21 2026-10-28 2026-11-04 2026-11-11 2026-11-18',
      );
    });

    test('nothing before the anchor', () {
      expect(
        _occ(
          '1d',
          DateTime(2026, 10, 21),
          DateTime(2026, 10),
          DateTime(2026, 10, 20),
        ),
        isEmpty,
      );
    });

    test('an empty or reversed range', () {
      expect(
        _occ('1d', DateTime(2026), DateTime(2026, 2), DateTime(2026)),
        isEmpty,
      );
      expect(
        _occ('1w', DateTime(2026), DateTime(2026, 1, 2), DateTime(2026, 1, 2)),
        isEmpty,
      );
      expect(_occ('1w', DateTime(2026), DateTime(2026), DateTime(2026)), [
        DateTime(2026),
      ]);
    });

    test('times of day on the arguments are ignored', () {
      expect(
        _occ(
          '1w',
          DateTime(2026, 10, 21, 9, 30),
          DateTime(2026, 10, 29, 23),
          DateTime(2026, 10, 29, 1),
        ),
        isEmpty,
      );
      expect(
        _occ(
          '1w',
          DateTime(2026, 10, 21, 9, 30),
          DateTime(2026, 10, 28, 23),
          DateTime(2026, 10, 28, 23),
        ),
        [DateTime(2026, 10, 28)],
      );
    });
  });

  group('no drift', () {
    test('monthly on the 31st', () {
      expect(
        _fmt(
          _occ(
            '1m',
            DateTime(2026, 1, 31),
            DateTime(2026),
            DateTime(2026, 7, 31),
          ),
        ),
        '2026-01-31 2026-02-28 2026-03-31 2026-04-30 2026-05-31 '
        '2026-06-30 2026-07-31',
      );
    });

    test('every two months from the 31st', () {
      expect(
        _fmt(
          _occ(
            '2m',
            DateTime(2026, 1, 31),
            DateTime(2026),
            DateTime(2026, 12, 31),
          ),
        ),
        '2026-01-31 2026-03-31 2026-05-31 2026-07-31 2026-09-30 2026-11-30',
      );
    });

    test('leap day yearly', () {
      expect(
        _fmt(_occ('1y', DateTime(2024, 2, 29), DateTime(2024), DateTime(2029))),
        '2024-02-29 2025-02-28 2026-02-28 2027-02-28 2028-02-29',
      );
      expect(
        _fmt(_occ('4y', DateTime(2024, 2, 29), DateTime(2024), DateTime(2040))),
        '2024-02-29 2028-02-29 2032-02-29 2036-02-29',
      );
    });

    test('February 2028 in a monthly series from the 30th', () {
      expect(
        _occ(
          '1m',
          DateTime(2026, 1, 30),
          DateTime(2028, 2),
          DateTime(2028, 2, 29),
        ),
        [DateTime(2028, 2, 29)],
      );
    });
  });

  group('business days', () {
    test('every weekday, from a Wednesday', () {
      expect(
        _fmt(
          _occ(
            '1b',
            DateTime(2026, 10, 21),
            DateTime(2026, 10, 21),
            DateTime(2026, 10, 28),
          ),
        ),
        '2026-10-21 2026-10-22 2026-10-23 2026-10-26 2026-10-27 2026-10-28',
      );
    });

    test('every three business days', () {
      expect(
        _fmt(
          _occ(
            '3b',
            DateTime(2026, 10, 21),
            DateTime(2026, 10, 21),
            DateTime(2026, 11, 10),
          ),
        ),
        '2026-10-21 2026-10-26 2026-10-29 2026-11-03 2026-11-06',
      );
    });

    test('an anchor on a Saturday begins the series itself', () {
      final saturday = DateTime(2026, 10, 31);
      expect(saturday.weekday, DateTime.saturday);
      expect(
        _fmt(_occ('1b', saturday, saturday, DateTime(2026, 11, 4))),
        '2026-10-31 2026-11-02 2026-11-03 2026-11-04',
      );
    });
  });

  group('weekday lists', () {
    test('Monday, Wednesday, Friday', () {
      expect(
        _fmt(
          _occ(
            '1w;mo,we,fr',
            DateTime(2026, 10, 21),
            DateTime(2026, 10, 19),
            DateTime(2026, 11, 2),
          ),
        ),
        '2026-10-21 2026-10-23 2026-10-26 2026-10-28 2026-10-30 2026-11-02',
      );
    });

    test('every other week', () {
      expect(
        _fmt(
          _occ(
            '2w;mo,fr',
            DateTime(2026, 10, 19),
            DateTime(2026, 10),
            DateTime(2026, 11, 20),
          ),
        ),
        '2026-10-19 2026-10-23 2026-11-02 2026-11-06 2026-11-16 2026-11-20',
      );
    });

    test('an anchor off the list still begins the series', () {
      // Tuesday 20 October with Monday and Friday listed.
      expect(
        _fmt(
          _occ(
            '1w;mo,fr',
            DateTime(2026, 10, 20),
            DateTime(2026, 10),
            DateTime(2026, 10, 30),
          ),
        ),
        '2026-10-20 2026-10-23 2026-10-26 2026-10-30',
      );
      expect(
        _occ(
          '1w;mo,fr',
          DateTime(2026, 10, 20),
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 22),
        ),
        isEmpty,
      );
    });
  });

  group('Nth weekday of the month', () {
    test('second Tuesday', () {
      expect(
        _fmt(
          _occ(
            '1m;2tu',
            DateTime(2026, 10, 13),
            DateTime(2026),
            DateTime(2027, 1, 31),
          ),
        ),
        '2026-10-13 2026-11-10 2026-12-08 2027-01-12',
      );
    });

    test('last Friday', () {
      expect(
        _fmt(
          _occ(
            '1m;-1fr',
            DateTime(2026, 10, 30),
            DateTime(2026),
            DateTime(2027, 2, 28),
          ),
        ),
        '2026-10-30 2026-11-27 2026-12-25 2027-01-29 2027-02-26',
      );
    });

    test("an anchor before the month's Nth weekday: this month counts", () {
      // Anchor on the 1st (a Thursday); the 2nd Tuesday is the 13th.
      expect(
        _fmt(
          _occ(
            '1m;2tu',
            DateTime(2026, 10),
            DateTime(2026, 10),
            DateTime(2026, 11, 30),
          ),
        ),
        '2026-10-01 2026-10-13 2026-11-10',
      );
    });

    test("an anchor after the month's Nth weekday: next month starts", () {
      expect(
        _fmt(
          _occ(
            '1m;2tu',
            DateTime(2026, 10, 20),
            DateTime(2026, 10),
            DateTime(2026, 11, 30),
          ),
        ),
        '2026-10-20 2026-11-10',
      );
    });

    test('every second month', () {
      expect(
        _fmt(
          _occ(
            '2m;1mo',
            DateTime(2026, 10, 5),
            DateTime(2026, 10),
            DateTime(2027, 6, 30),
          ),
        ),
        '2026-10-05 2026-12-07 2027-02-01 2027-04-05 2027-06-07',
      );
    });
  });

  group('until and except', () {
    test('until is inclusive', () {
      final bounds = RecurrenceBounds(until: DateTime(2026, 11, 11));
      expect(
        _fmt(
          _occ(
            '1w',
            DateTime(2026, 10, 21),
            DateTime(2026, 10),
            DateTime(2026, 12, 31),
            bounds: bounds,
          ),
        ),
        '2026-10-21 2026-10-28 2026-11-04 2026-11-11',
      );
      final day = RecurrenceBounds(until: DateTime(2026, 11, 10));
      expect(
        _fmt(
          _occ(
            '1w',
            DateTime(2026, 10, 21),
            DateTime(2026, 10),
            DateTime(2026, 12, 31),
            bounds: day,
          ),
        ),
        '2026-10-21 2026-10-28 2026-11-04',
      );
    });

    test('until before the anchor leaves nothing, even the anchor', () {
      final bounds = RecurrenceBounds(until: DateTime(2026, 10, 20));
      expect(
        _occ(
          '1w',
          DateTime(2026, 10, 21),
          DateTime(2026),
          DateTime(2026, 12, 31),
          bounds: bounds,
        ),
        isEmpty,
      );
      expect(
        _occ(
          '1w;mo',
          DateTime(2026, 10, 21),
          DateTime(2026),
          DateTime(2026, 12, 31),
          bounds: bounds,
        ),
        isEmpty,
      );
    });

    test('except drops the dates it lists, only them', () {
      final bounds = RecurrenceBounds(
        except: [DateTime(2026, 11, 4), DateTime(2026, 11, 18)],
      );
      expect(
        _fmt(
          _occ(
            '1w',
            DateTime(2026, 10, 21),
            DateTime(2026, 10),
            DateTime(2026, 11, 25),
            bounds: bounds,
          ),
        ),
        '2026-10-21 2026-10-28 2026-11-11 2026-11-25',
      );
    });

    test(
      'except can drop the anchor, and a date that is no occurrence is inert',
      () {
        final bounds = RecurrenceBounds(
          except: [DateTime(2026, 10, 20), DateTime(2026, 10, 21)],
        );
        expect(
          _fmt(
            _occ(
              '1w;mo,fr',
              DateTime(2026, 10, 20),
              DateTime(2026, 10),
              DateTime(2026, 10, 30),
              bounds: bounds,
            ),
          ),
          '2026-10-23 2026-10-26 2026-10-30',
        );
      },
    );

    test('until and except together', () {
      final bounds = RecurrenceBounds(
        until: DateTime(2026, 12, 31),
        except: [DateTime(2026, 11, 4)],
      );
      expect(
        _fmt(
          _occ(
            '1m',
            DateTime(2026, 10, 4),
            DateTime(2026),
            DateTime(2030),
            bounds: bounds,
          ),
        ),
        '2026-10-04 2026-12-04',
      );
    });

    test('occursOn', () {
      final rule = RecurrenceRule.parse('1w')!;
      final bounds = RecurrenceBounds(except: [DateTime(2026, 11, 4)]);
      final anchor = DateTime(2026, 10, 21);
      expect(
        rule.occursOn(anchor: anchor, day: DateTime(2026, 10, 28)),
        isTrue,
      );
      expect(
        rule.occursOn(anchor: anchor, day: DateTime(2026, 10, 29)),
        isFalse,
      );
      expect(
        rule.occursOn(
          anchor: anchor,
          day: DateTime(2026, 11, 4),
          bounds: bounds,
        ),
        isFalse,
      );
    });
  });

  group('ranges far from the anchor', () {
    test('a month, ten years on, for every unit', () {
      final anchor = DateTime(2016, 3, 31);
      final from = DateTime(2026, 10);
      final to = DateTime(2026, 10, 31);
      for (final rule in [
        '1d',
        '3d',
        '1w',
        '2w',
        '1m',
        '5m',
        '1y',
        '1b',
        '4b',
        '1w;mo,we,fr',
        '2w;tu',
        '1m;2tu',
        '3m;-1fr',
      ]) {
        final parsed = RecurrenceRule.parse(rule)!;
        final expected = _oracle(
          parsed,
          anchor,
          to,
        ).where((d) => !d.isBefore(from)).toList();
        expect(
          _fmt(_occ(rule, anchor, from, to)),
          _fmt(expected),
          reason: rule,
        );
      }
    });

    test('a thousand years on costs nothing', () {
      final anchor = DateTime(2000);
      final watch = Stopwatch()..start();
      for (final rule in ['1d', '1w', '1m', '1y', '1b', '1w;mo,fr', '1m;2tu']) {
        final days = _occ(rule, anchor, DateTime(3000), DateTime(3000, 12, 31));
        expect(days, isNotEmpty, reason: rule);
        expect(days.first.isBefore(DateTime(3000)), isFalse, reason: rule);
      }
      // Iterating a thousand years of days would take seconds; the jump is
      // a handful of steps. A very loose backstop, not a performance gate.
      expect(watch.elapsedMilliseconds, lessThan(2000));
    });

    test('a range before the anchor is empty', () {
      expect(
        _occ(
          '1w',
          DateTime(2026, 10, 21),
          DateTime(2020),
          DateTime(2026, 10, 20),
        ),
        isEmpty,
      );
    });
  });

  group('property: the engine matches the day-by-day oracle', () {
    const rules = [
      '1d',
      '2d',
      '10d',
      '1w',
      '3w',
      '1m',
      '2m',
      '12m',
      '1y',
      '2y',
      '1b',
      '2b',
      '7b',
      '1w;mo',
      '1w;mo,we,fr',
      '1w;sa,su',
      '2w;tu,th',
      '3w;mo,tu,we,th,fr,sa,su',
      '1m;1mo',
      '1m;2tu',
      '1m;4su',
      '1m;-1fr',
      '2m;3we',
      '5m;-1sa',
    ];

    test('every rule, random anchors and ranges', () {
      final rng = Random(1153);
      for (final rule in rules) {
        final parsed = RecurrenceRule.parse(rule)!;
        for (var i = 0; i < 12; i++) {
          final anchor = DateTime(2023, 1, 1 + rng.nextInt(1200));
          final from = DateTime(
            anchor.year,
            anchor.month,
            anchor.day + rng.nextInt(1500) - 50,
          );
          final to = DateTime(
            from.year,
            from.month,
            from.day + rng.nextInt(120),
          );
          final expected = _oracle(
            parsed,
            anchor,
            to,
          ).where((d) => !d.isBefore(from)).toList();
          expect(
            _fmt(parsed.occurrences(anchor: anchor, from: from, to: to)),
            _fmt(expected),
            reason:
                '$rule anchor ${formatIsoDate(anchor)} '
                '${formatIsoDate(from)}..${formatIsoDate(to)}',
          );
        }
      }
    });

    test(
      'a range is exactly the filtered prefix of iterating from the anchor',
      () {
        final rng = Random(2026);
        for (final rule in rules) {
          final parsed = RecurrenceRule.parse(rule)!;
          for (var i = 0; i < 12; i++) {
            final anchor = DateTime(2020, 1, 1 + rng.nextInt(2000));
            final horizon = DateTime(anchor.year + 6, anchor.month, anchor.day);
            final all = parsed.occurrences(
              anchor: anchor,
              from: anchor,
              to: horizon,
            );
            final from = DateTime(
              anchor.year,
              anchor.month,
              anchor.day + rng.nextInt(1000) - 20,
            );
            final to = DateTime(
              from.year,
              from.month,
              from.day + rng.nextInt(200),
            );
            final expected = all
                .where((d) => !d.isBefore(from) && !d.isAfter(to))
                .toList();
            expect(
              _fmt(parsed.occurrences(anchor: anchor, from: from, to: to)),
              _fmt(expected),
              reason: '$rule from ${formatIsoDate(anchor)}',
            );
          }
        }
      },
    );

    test('bounds equal filtering the unbounded series', () {
      final rng = Random(42);
      for (final rule in rules) {
        final parsed = RecurrenceRule.parse(rule)!;
        for (var i = 0; i < 8; i++) {
          final anchor = DateTime(2024, 1, 1 + rng.nextInt(700));
          final to = DateTime(anchor.year + 2, anchor.month, anchor.day);
          final all = parsed.occurrences(anchor: anchor, from: anchor, to: to);
          final until = DateTime(
            anchor.year,
            anchor.month,
            anchor.day + rng.nextInt(800),
          );
          final except = {
            for (var j = 0; j < 5 && all.isNotEmpty; j++)
              all[rng.nextInt(all.length)],
            DateTime(anchor.year, anchor.month, anchor.day + rng.nextInt(800)),
          };
          final bounds = RecurrenceBounds(until: until, except: except);
          final expected = all
              .where((d) => !d.isAfter(until) && !except.contains(d))
              .toList();
          expect(
            _fmt(
              parsed.occurrences(
                anchor: anchor,
                from: anchor,
                to: to,
                bounds: bounds,
              ),
            ),
            _fmt(expected),
            reason: '$rule from ${formatIsoDate(anchor)}',
          );
        }
      }
    });

    test('ascending, unique, inside the range, never before the anchor', () {
      final rng = Random(7);
      for (final rule in rules) {
        final parsed = RecurrenceRule.parse(rule)!;
        final anchor = DateTime(2025, 1, 1 + rng.nextInt(400));
        final from = DateTime(2024, 6);
        final to = DateTime(2028, 6);
        final days = parsed.occurrences(anchor: anchor, from: from, to: to);
        for (var i = 0; i < days.length; i++) {
          expect(days[i].isBefore(anchor), isFalse, reason: rule);
          expect(
            days[i].isBefore(from) || days[i].isAfter(to),
            isFalse,
            reason: rule,
          );
          expect(days[i].hour, 0, reason: rule);
          if (i > 0) expect(days[i].isAfter(days[i - 1]), isTrue, reason: rule);
        }
      }
    });
  });
}
