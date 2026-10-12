// #730 phase 1: the calendar.txt line model and parser — the page's own
// lines, the mockups' file, the flags the editor shows, and the round trip
// every untouched line must keep.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/parser.dart';

void main() {
  group('heads', () {
    test('a year goal is a year, two spaces and its text', () {
      final line = parseCalendarLine('2026  The year of the move +home');
      expect(line.kind, CalendarLineKind.yearGoal);
      expect(line.date, DateTime(2026));
      expect(line.head, '2026');
      expect(line.goalText, 'The year of the move +home');
      expect(line.tokens.map((t) => t.value), ['home']);
      expect(line.flagged, isFalse);
      expect(line.key, '2026-01-01');
      expect(line.toLine(), '2026  The year of the move +home');
    });

    test('a month goal is a month, two spaces and its text', () {
      final line = parseCalendarLine('2026-10  Finish the thesis draft');
      expect(line.kind, CalendarLineKind.monthGoal);
      expect(line.date, DateTime(2026, 10));
      expect(line.head, '2026-10');
      expect(line.goalText, 'Finish the thesis draft');
      expect(line.key, '2026-10-01');
    });

    test('a week goal is the Monday, the week and its text', () {
      final line = parseCalendarLine('2026-10-05 w41  Reading week');
      expect(line.kind, CalendarLineKind.weekGoal);
      expect(line.date, DateTime(2026, 10, 5));
      expect(line.week, 41);
      expect(line.weekday, isNull);
      expect(line.head, '2026-10-05 w41');
      expect(line.goalText, 'Reading week');
      expect(line.weekMismatch, isFalse);
    });

    test('a day with no events is a head and nothing else', () {
      final line = parseCalendarLine('2026-10-06 w41 Tue');
      expect(line.kind, CalendarLineKind.day);
      expect(line.weekday, 'Tue');
      expect(line.head, '2026-10-06 w41 Tue');
      expect(line.events, isEmpty);
      expect(line.goalText, isNull);
    });

    test('a bare date is a day, with the room to write', () {
      final line = parseCalendarLine('2026-10-06');
      expect(line.kind, CalendarLineKind.day);
      expect(line.date, DateTime(2026, 10, 6));
      expect(line.week, isNull);
      expect(line.weekday, isNull);
      expect(line.events, isEmpty);
    });

    test('a third token Niman cannot read is a goal, not a weekday', () {
      // The record's own risk (#730): an unknown weekday reads as the
      // week's goal whose text starts with it. Display only.
      final line = parseCalendarLine('2026-10-12 w42 Mo  9-12 call.');
      expect(line.kind, CalendarLineKind.weekGoal);
      expect(line.goalText, 'Mo  9-12 call.');
      expect(line.events, isEmpty);
    });

    test("a locale's own weekday names are recognised", () {
      final weekdays = calendarWeekdayNames(const [
        ['lun', 'mar', 'mer', 'gio', 'ven', 'sab', 'dom'],
      ]);
      final line = parseCalendarLine(
        '2026-10-05 w41 lun  9-12 library.',
        weekdays: weekdays,
      );
      expect(line.kind, CalendarLineKind.day);
      expect(line.weekday, 'lun');
      expect(line.weekdayMismatch, isFalse);
    });

    test('a weekday with a trailing period is recognised', () {
      final weekdays = calendarWeekdayNames(const [
        ['lun.', 'mar.', 'mer.', 'gio.', 'ven.', 'sam.', 'dim.'],
      ]);
      final line = parseCalendarLine(
        '2026-10-05 w41 mar.  9-12 library.',
        weekdays: weekdays,
      );
      expect(line.kind, CalendarLineKind.day);
      expect(line.weekday, 'mar.');
      expect(line.weekdayMismatch, isTrue, reason: 'the 5th is a Monday');
    });

    test('a line with no date at all is other, and kept as written', () {
      const raw = 'just a note to myself';
      final line = parseCalendarLine(raw);
      expect(line.kind, CalendarLineKind.other);
      expect(line.key, isNull);
      expect(line.toLine(), raw);
    });

    test('an empty line is other too', () {
      expect(parseCalendarLine('').kind, CalendarLineKind.other);
      expect(parseCalendarLine('   ').kind, CalendarLineKind.other);
    });
  });

  group('the flags', () {
    test('a weekday that does not match its date is flagged', () {
      // The editor mockup's `2026-10-09 w41 Sat`: the 9th is a Friday.
      final line = parseCalendarLine('2026-10-09 w41 Sat  20 dinner at Anna.');
      expect(line.weekdayMismatch, isTrue);
      expect(line.weekMismatch, isFalse);
      expect(line.flagged, isTrue);
      // The date is what is read, and the line is never rewritten.
      expect(line.date, DateTime(2026, 10, 9));
      expect(line.events, hasLength(1));
      expect(line.toLine(), '2026-10-09 w41 Sat  20 dinner at Anna.');
    });

    test('a week that does not match its date is flagged', () {
      // The mockup's `2026-10-15 w41 Thu`: the 15th is in week 42.
      final line = parseCalendarLine(
        '2026-10-15 w41 Thu  8-1345 exam session +teaching (14-1545).',
      );
      expect(line.weekMismatch, isTrue);
      expect(line.weekdayMismatch, isFalse);
      expect(line.date, DateTime(2026, 10, 15));
    });

    test('a matched head is not flagged', () {
      final line = parseCalendarLine('2026-10-05 w41 Mon  9-12 library.');
      expect(line.flagged, isFalse);
    });
  });

  group('events', () {
    CalendarLine day(String events) =>
        parseCalendarLine('2026-10-12 w42 Mon  $events');

    test('the mockup day: three events, their times, tokens and dots', () {
      final line = day(
        '9-12 thesis chapter 3 +thesis @library. '
        '13:30-14 call with Marta @phone rem:13:15. '
        '18-19 jogging @park (if dry).',
      );
      expect(line.kind, CalendarLineKind.day);
      expect(line.events, hasLength(3));

      final first = line.events[0];
      expect(first.raw, '9-12 thesis chapter 3 +thesis @library');
      expect(first.text, 'thesis chapter 3 +thesis @library');
      expect(first.time!.raw, '9-12');
      expect(first.time!.start!.minutes, 9 * 60);
      expect(first.time!.end!.minutes, 12 * 60);
      expect(first.projects, ['thesis']);
      expect(first.contexts, ['library']);
      expect(first.reminder, isNull);

      final second = line.events[1];
      expect(second.raw, '13:30-14 call with Marta @phone rem:13:15');
      expect(second.text, 'call with Marta @phone rem:13:15');
      expect(second.time!.start!.minutes, 13 * 60 + 30);
      expect(second.time!.end!.minutes, 14 * 60);
      expect(second.reminder, '13:15');
      expect(
        second.raw.substring(
          second.reminderStart! - second.start,
          second.reminderEnd! - second.start,
        ),
        'rem:13:15',
      );

      final third = line.events[2];
      expect(third.text, 'jogging @park (if dry)');
      expect(third.contexts, ['park']);
      expect(third.asides, hasLength(1));
      expect(
        line.raw.substring(third.asides.single.start, third.asides.single.end),
        '(if dry)',
      );
      expect(third.tokens.map((t) => t.value), ['park']);
    });

    test('a v1.2 does not cut an event', () {
      final line = day('10-1130 seminar v1.2 review +thesis. 16 dentist.');
      expect(line.events, hasLength(2));
      expect(line.events.first.raw, '10-1130 seminar v1.2 review +thesis');
      expect(line.events.last.raw, '16 dentist');
    });

    test('the last event may go without its full stop', () {
      final line = day('16 dentist @city');
      expect(line.events.single.raw, '16 dentist @city');
      expect(line.events.single.text, 'dentist @city');
    });

    test('a semicolon ends an event too', () {
      final line = day('9-11 John; 12-16 architecture meeting.');
      expect(line.events, hasLength(2));
      expect(line.events.first.raw, '9-11 John');
    });

    test('a leading number is an hour, as the format says', () {
      final line = day('3 copies of the report.');
      expect(line.events.single.raw, '3 copies of the report');
      expect(line.events.single.time!.start!.minutes, 3 * 60);
      expect(line.events.single.text, 'copies of the report');
    });

    test('the written times parse: 8, 08:15, 0815, 0600Z, 8-1345, -12:00', () {
      expect(parseCalendarMoment('8')!.minutes, 8 * 60);
      expect(parseCalendarMoment('0815')!.minutes, 8 * 60 + 15);
      expect(parseCalendarMoment('08:15')!.minutes, 8 * 60 + 15);
      expect(parseCalendarMoment('1345')!.minutes, 13 * 60 + 45);
      expect(parseCalendarMoment('845')!.minutes, 8 * 60 + 45);
      final utc = parseCalendarMoment('0600Z')!;
      expect(utc.minutes, 6 * 60);
      expect(utc.utc, isTrue);

      final range = day('8-1345 exam session.').events.single.time!;
      expect(range.raw, '8-1345');
      expect(range.start!.minutes, 8 * 60);
      expect(range.end!.minutes, 13 * 60 + 45);

      final endOnly = day('-12:00 lunch.').events.single.time!;
      expect(endOnly.start, isNull);
      expect(endOnly.end!.minutes, 12 * 60);
      expect(day('-12:00 lunch.').events.single.text, 'lunch');
    });

    test('a number that is not a time is not one', () {
      expect(parseCalendarMoment('25:00'), isNull);
      expect(parseCalendarMoment('12345'), isNull);
      final line = day('2560 not a time.');
      expect(line.events.single.time, isNull);
      expect(line.events.single.raw, '2560 not a time');
    });

    test('an event with no time is kept, and comes as written', () {
      final line = day('lunch with Marta.');
      expect(line.events.single.time, isNull);
      expect(line.events.single.raw, 'lunch with Marta');
    });

    test('a tag keeps its colour, and drops the punctuation after it', () {
      final line = day('20 dinner at Anna #family.');
      expect(line.events.single.raw, '20 dinner at Anna #family');
      expect(line.events.single.hashtags, ['family']);
    });

    test('an aside is not read for tokens', () {
      final line = day('8-1345 exam (14-1545 +teaching).');
      final event = line.events.single;
      expect(event.tokens, isEmpty, reason: 'inside the aside');
      expect(event.asides, hasLength(1));
      expect(event.text, 'exam (14-1545 +teaching)');
    });
  });

  group('the file, read together', () {
    final file = [
      '2026  The year of the move +home',
      '2026-10  Finish the thesis draft +thesis',
      '2026-10-12 w42  Writing week',
      '2026-10-05 w41 Mon  9-12 library +thesis @library.',
      '2026-10-06 w41 Tue',
      '2026-10-12 w42 Mon  13:30-14 call with Marta @phone rem:13:15.',
      '2026-10-19 w43  Revision week',
      '2026-11-02 w45  Next month',
    ].map(parseCalendarLine).toList();

    test('every line round-trips byte for byte', () {
      for (final line in file) {
        expect(line.toLine(), line.raw);
      }
    });

    test('the day lines of a date, and the goals that apply to it', () {
      expect(calendarDaysFor(file, DateTime(2026, 10, 12)), hasLength(1));
      expect(calendarDaysFor(file, DateTime(2026, 10, 13)), isEmpty);
      final goals = calendarGoalsFor(file, DateTime(2026, 10, 12));
      expect(goals.map((g) => g.goalText), [
        'Writing week',
        'Finish the thesis draft +thesis',
        'The year of the move +home',
      ]);
    });

    test("last week's goal does not apply to this week", () {
      expect(
        calendarGoalsFor(file, DateTime(2026, 10, 19)).first.goalText,
        'Revision week',
      );
      expect(
        calendarGoalsFor(file, DateTime(2026, 10, 26)).map((g) => g.kind),
        [CalendarLineKind.monthGoal, CalendarLineKind.yearGoal],
        reason: 'no week goal for a week the file does not name',
      );
    });
  });

  group('round trip, on whatever the file holds', () {
    const heads = [
      '2026  The move',
      '2026-10  Draft',
      '2026-10-05 w41  Reading week',
      '2026-10-05 w41 Mon',
      '2026-10-05 w41 Mon  9-12 library +thesis @library.',
      '2026-10-09 w41 Sat  20 dinner #family.',
      '2026-10-15 w41 Thu  8-1345 exam +teaching (14-1545 +teaching).',
      '2026-10-12',
      '2026-10-12 w42 Mo  9-12 call.',
      '2026-10-13 w42 Tue  0600Z call @phone rem:15:15.',
      'no date at all, just words',
      '   ',
      '2026-10-26 w43 Mon  9-11; 12-13  ; 14 x.',
    ];
    const endings = ['\n', '\r\n', ''];
    const words = [
      '9',
      '8-12',
      '0815',
      '0600Z',
      '-12:00',
      'v1.2',
      'call',
      '+teach',
      '@phone',
      '#tag',
      'rem:13:15',
      '(if dry)',
      '...',
      ';',
      '.',
      '\t',
    ];

    /// A file of [lines] random pieces, with random endings: whatever a
    /// hand edit, another tool or a sync could leave.
    String randomFile(int seed) {
      final out = StringBuffer();
      var at = seed;
      final count = at % 7;
      for (var line = 0; line <= count; line++) {
        at = _next(at);
        final grows = at % 3;
        if (grows == 0) {
          out.write(heads[at % heads.length]);
        } else {
          for (var word = 0; word <= grows; word++) {
            at = _next(at);
            if (word > 0 || at % 4 == 0) out.write(' ');
            out.write(words[at % words.length]);
          }
        }
        out.write(endings[at % endings.length]);
      }
      return out.toString();
    }

    test('every random file comes back byte for byte', () {
      for (var seed = 1; seed <= 200; seed++) {
        final text = randomFile(seed);
        final bytes = Uint8List.fromList(utf8.encode(text));
        final file = splitCalendarFile(bytes);
        expect(
          joinCalendarFile(file),
          text,
          reason: 'the file model, seed $seed',
        );
        for (final line in file.lines) {
          expect(
            parseCalendarLine(line.text).toLine(),
            line.text,
            reason: 'the parser, seed $seed, line ${jsonEncode(line.raw)}',
          );
        }
      }
    });
  });

  group('odd input', () {
    test('trailing whitespace and tabs are kept', () {
      const raw = '2026-10-05 w41 Mon  9-12 library.   ';
      final line = parseCalendarLine(raw);
      expect(line.toLine(), raw);
      expect(line.events.single.raw, '9-12 library');
    });

    test('a carriage return the split left behind is not part of the line', () {
      final line = parseCalendarLine('2026-10-05 w41 Mon  9-12 x.\r');
      expect(line.toLine(), '2026-10-05 w41 Mon  9-12 x.');
    });

    test('two day lines for one date are both kept', () {
      final lines = [
        parseCalendarLine('2026-10-12 w42 Mon  9-12 a.'),
        parseCalendarLine('2026-10-12 w42 Mon  18-19 b.'),
      ];
      expect(calendarDaysFor(lines, DateTime(2026, 10, 12)), hasLength(2));
    });

    test('a line that is only a full stop is other', () {
      expect(parseCalendarLine('.').kind, CalendarLineKind.other);
    });
  });
}

/// A deterministic pseudo-random source: the property tests below run the
/// same inputs on every machine (a failure is reproducible).
int _next(int seed) => (seed * 1103515245 + 12345) & 0x7FFFFFFF;
