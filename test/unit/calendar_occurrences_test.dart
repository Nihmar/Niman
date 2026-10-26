// #1190: an event with a `rec:` shows on every day its rule reaches — the
// rule read off the event's tokens, expanded for a day or a range, each
// occurrence the same event on the same line with its own day.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';

CalendarSnapshot _snapshot(List<String> lines) =>
    calendarSnapshotOf(calendarFileOf(lines));

CalendarEvent _event(String line) => parseCalendarLine(line).events.single;

/// A standup, every week from Wed 21 Oct 2026.
const String _standup = '2026-10-21 w43 Wed  9-9:30 Standup @work rec:1w.';

void main() {
  group('the rule an event reads', () {
    test('is its rec: token', () {
      final recurrence = _event(_standup).recurrence!;
      expect(recurrence.rule.unit, RecurrenceUnit.week);
      expect(recurrence.rule.interval, 1);
      expect(recurrence.bounds.until, isNull);
      expect(recurrence.bounds.except, isEmpty);
    });

    test('carries until: and every except: list', () {
      final recurrence = _event(
        '2026-10-21 w43 Wed  9 Standup rec:1w until:2026-12-31 '
        'except:2026-11-04,2026-11-18 except:2026-12-02.',
      ).recurrence!;
      expect(recurrence.bounds.until, DateTime(2026, 12, 31));
      expect(recurrence.bounds.except, {
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 18),
        DateTime(2026, 12, 2),
      });
    });

    test('is none for an event with no rec:, or one that is unreadable', () {
      expect(_event('2026-10-21 w43 Wed  9 Standup.').recurrence, isNull);
      expect(_event('2026-10-21 w43 Wed  9 Standup rec:x.').recurrence, isNull);
      // The first rec: counts, as it does on a task.
      expect(
        _event('2026-10-21 w43 Wed  9 Standup rec:x rec:1w.').recurrence,
        isNull,
      );
    });

    test('ignores an until: or except: it cannot read', () {
      final recurrence = _event(
        '2026-10-21 w43 Wed  9 Standup rec:1w until:soon except:2026-11-04,x.',
      ).recurrence!;
      expect(recurrence.bounds.until, isNull);
      expect(recurrence.bounds.except, isEmpty);
    });

    test('rec:+ is rec: for an event', () {
      expect(
        _event('2026-10-21 w43 Wed  9 Standup rec:+1w.').recurrence,
        isNotNull,
      );
    });

    test('leaves the line byte for byte', () {
      const line =
          '2026-10-21 w43 Wed  9 Standup rec:1w until:2026-12-31. 17 x';
      expect(parseCalendarLine(line).toLine(), line);
    });

    test('flags the three keys when their value is not read', () {
      bool flagged(String token) => isUnreadableRuleToken(
        CalendarToken(
          kind: CalendarTokenKind.keyValue,
          value: token,
          start: 0,
          end: token.length,
        ),
      );
      expect(flagged('rec:1w'), isFalse);
      expect(flagged('rec:often'), isTrue);
      expect(flagged('until:2026-12-31'), isFalse);
      expect(flagged('until:2026-13-45'), isTrue);
      expect(flagged('except:2026-11-04,2026-11-18'), isFalse);
      expect(flagged('except:2026-11-04,x'), isTrue);
      expect(flagged('rem:13:15'), isFalse);
      expect(flagged('due:soon'), isFalse);
    });
  });

  group('the days a rule reaches', () {
    final snapshot = _snapshot([
      '2026-10-19 w43 Mon  8 breakfast.',
      _standup,
      '2026-10-22 w43 Thu  jogging.',
    ]);

    test('every week, from its own day on', () {
      for (final day in [
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 28),
        DateTime(2026, 11, 4),
        DateTime(2027, 1, 6),
      ]) {
        expect(snapshot.eventsFor(day).map((e) => e.event.text), [
          'Standup @work rec:1w',
        ], reason: '$day');
      }
      expect(snapshot.eventsFor(DateTime(2026, 10, 27)), isEmpty);
    });

    test('never before its own day', () {
      expect(snapshot.eventsFor(DateTime(2026, 10, 14)), isEmpty);
      expect(snapshot.eventsFor(DateTime(2026, 10, 7)), isEmpty);
    });

    test('is the event itself on its own day, shown once', () {
      final own = snapshot.eventsFor(DateTime(2026, 10, 21));
      expect(own, hasLength(1));
      expect(own.single.lineIndex, 1);
      expect(own.single.shownOn, isNull);
      expect(own.single.isLaterOccurrence, isFalse);
      expect(own.single.repeats, isTrue);
    });

    test('is the same event on the same line, with its own day', () {
      final later = snapshot.eventsFor(DateTime(2026, 11, 4)).single;
      expect(later.lineIndex, 1);
      expect(later.event.text, 'Standup @work rec:1w');
      expect(later.line.date, DateTime(2026, 10, 21));
      expect(later.day, DateTime(2026, 11, 4));
      expect(later.isLaterOccurrence, isTrue);
      expect(later.recurrence!.rule.token, '1w');
    });

    test('an event off a rule is not an occurrence', () {
      final plain = snapshot.eventsFor(DateTime(2026, 10, 22)).single;
      expect(plain.repeats, isFalse);
      expect(plain.isLaterOccurrence, isFalse);
    });

    test('come in time order with the plain events of the day', () {
      final day = _snapshot([
        '2026-10-19 w43 Mon  7 gym rec:1w.',
        '2026-10-26 w44 Mon  18 dinner. 6 run.',
      ]).eventsFor(DateTime(2026, 10, 26));
      expect(day.map((e) => e.event.text), ['run', 'gym rec:1w', 'dinner']);
    });
  });

  group('until: and except:', () {
    const line =
        '2026-10-21 w43 Wed  9 Standup rec:1w until:2026-11-11 '
        'except:2026-11-04.';
    final snapshot = _snapshot([line]);

    test('until: is the last day, inclusive', () {
      expect(snapshot.hasEventsOn(DateTime(2026, 11, 11)), isTrue);
      expect(snapshot.hasEventsOn(DateTime(2026, 11, 18)), isFalse);
      expect(snapshot.hasEventsOn(DateTime(2027, 3, 3)), isFalse);
    });

    test('except: skips that day only', () {
      expect(snapshot.hasEventsOn(DateTime(2026, 10, 28)), isTrue);
      expect(snapshot.hasEventsOn(DateTime(2026, 11, 4)), isFalse);
      expect(snapshot.hasEventsOn(DateTime(2026, 11, 11)), isTrue);
    });

    test('a skipped first day is skipped on its own line too', () {
      final skipped = _snapshot([
        '2026-10-21 w43 Wed  9 Standup rec:1w except:2026-10-21.',
      ]);
      expect(skipped.hasEventsOn(DateTime(2026, 10, 21)), isFalse);
      expect(skipped.hasEventsOn(DateTime(2026, 10, 28)), isTrue);
    });
  });

  group('the days of a range', () {
    final snapshot = _snapshot([
      '2026-10-02 w40 Fri  9 plain.',
      '2026-10-21 w43 Wed  9 Standup rec:1w until:2026-11-18.',
      '2026-10-28 w44 Wed  9 Review rec:1m.',
    ]);

    test('hold the plain days and every occurrence in the month', () {
      expect(snapshot.eventDaysIn(DateTime(2026, 11), DateTime(2026, 11, 30)), {
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 18),
        DateTime(2026, 11, 28),
      });
      expect(snapshot.eventDaysIn(DateTime(2026, 10), DateTime(2026, 10, 31)), {
        DateTime(2026, 10, 2),
        DateTime(2026, 10, 21),
        DateTime(2026, 10, 28),
      });
    });

    test('are empty before the rules begin, far on where one has ended', () {
      expect(
        snapshot.eventDaysIn(DateTime(2026, 9), DateTime(2026, 9, 30)),
        isEmpty,
      );
      // The monthly review has no end: still there years on, on the 28th.
      expect(snapshot.eventDaysIn(DateTime(2031, 5), DateTime(2031, 5, 31)), {
        DateTime(2031, 5, 28),
      });
    });

    test('agree with the day-by-day answer', () {
      final month = snapshot.eventDaysIn(
        DateTime(2026, 11),
        DateTime(2026, 11, 30),
      );
      for (var day = 1; day <= 30; day++) {
        final date = DateTime(2026, 11, day);
        expect(
          snapshot.eventsFor(date).isNotEmpty,
          month.contains(date),
          reason: '$date',
        );
      }
    });
  });

  group('two lines for one day', () {
    test('show every event of both, the rule too', () {
      final snapshot = _snapshot([
        '2026-10-21 w43 Wed  9 Standup rec:1w.',
        '2026-10-21 w43 Wed  12 lunch.',
      ]);
      expect(
        snapshot.eventsFor(DateTime(2026, 10, 21)).map((e) => e.lineIndex),
        [0, 1],
      );
      expect(
        snapshot.eventsFor(DateTime(2026, 10, 28)).map((e) => e.lineIndex),
        [0],
      );
    });

    test('two rules on one line are two occurrences', () {
      final snapshot = _snapshot([
        '2026-10-21 w43 Wed  9 Standup rec:1w. 10 Gym rec:1d.',
      ]);
      expect(snapshot.eventsFor(DateTime(2026, 10, 28)), hasLength(2));
      expect(snapshot.eventsFor(DateTime(2026, 10, 29)), hasLength(1));
    });
  });

  test('a file with no rules answers as it always did', () {
    final snapshot = _snapshot([
      '2026-10-12 w42 Mon  9-12 a.',
      '2026-10-13 w42 Tue',
      '2026-10-14 w42 Wed  9-12 b. 10-11 c.',
    ]);
    expect(snapshot.daysWithEvents, {
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 14),
    });
    expect(snapshot.eventDaysIn(DateTime(2026, 10), DateTime(2026, 10, 31)), {
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 14),
    });
    expect(snapshot.eventsFor(DateTime(2026, 10, 14)), hasLength(2));
  });
}
