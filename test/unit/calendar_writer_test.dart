// #730 phase 3: writing calendar.txt — a new event, an edit, a delete.
// The promise under test throughout: a line the write does not touch comes
// back byte for byte, its own ending included, and a line it does touch is
// rebuilt around the event alone.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/calendar/day_style.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';

/// The mockups' file, as the app read it.
CalendarFileContent file(List<String> lines, {String ending = '\n'}) =>
    CalendarFileContent(
      lines: [for (final line in lines) CalendarRawLine(line, ending)],
    );

/// The day the mockups write into: three events, a reminder, an aside.
const String _busyDay =
    '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis @library. '
    '13:30-14 call with Marta @phone rem:13:15. '
    '18-19 jogging @park (if dry).';

const List<String> _lines = [
  '2026  The year of the move +home',
  '2026-10  Finish the thesis draft +thesis',
  '2026-10-05 w41 Mon  9-10 reading +thesis.',
  _busyDay,
  '2026-10-13 w42 Tue  10-1130 seminar v1.2 review +thesis.',
];

/// Every line of [before] whose text or ending changed in [after], by
/// index.
List<int> changedLines(CalendarFileContent before, CalendarFileContent after) {
  final changed = <int>[];
  for (var at = 0; at < before.lines.length; at++) {
    if (before.lines[at] != after.lines[at]) changed.add(at);
  }
  return changed;
}

/// The event [at] of [text]'s line, as the parser reads it back.
CalendarEvent eventOf(String text, int at) =>
    parseCalendarLine(text, weekdays: calendarWeekdays).events[at];

void main() {
  group('the draft', () {
    test('a whole hour is written compactly, a half hour is not', () {
      expect(calendarClockCompact(15 * 60), '15');
      expect(calendarClockCompact(13 * 60 + 30), '13:30');
      expect(calendarClockCompact(8 * 60 + 5), '8:05');
      expect(calendarTimeRange(15 * 60, 16 * 60), '15-16');
      expect(calendarTimeRange(13 * 60 + 30, 14 * 60), '13:30-14');
      expect(calendarTimeRange(15 * 60, null), '15');
      expect(calendarTimeRange(null, null), isNull);
    });

    test('a reminder is a padded clock time', () {
      expect(calendarClockStamp(16 * 60 + 30), '16:30');
      expect(calendarClockStamp(8 * 60 + 45), '08:45');
    });

    test('the event as written: time, text, reminder', () {
      expect(
        calendarEventAsText(
          const CalendarEventDraft(
            text: 'meeting with Luca +thesis @u',
            startMinutes: 15 * 60,
            endMinutes: 16 * 60,
            reminderMinutes: 14 * 60 + 45,
          ),
        ),
        '15-16 meeting with Luca +thesis @u rem:14:45',
      );
      expect(
        calendarEventAsText(const CalendarEventDraft(text: 'all day')),
        'all day',
      );
    });

    test('a text that would close the event early is trimmed', () {
      expect(cleanCalendarEventText('meeting.'), 'meeting');
      expect(cleanCalendarEventText('meeting... '), 'meeting');
      expect(cleanCalendarEventText('meeting; then'), 'meeting; then');
      expect(cleanCalendarEventText('  jogging  '), 'jogging');
    });
  });

  group('add', () {
    test('an event goes into the day, in time order (the mockup)', () {
      final before = file(_lines);
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 12),
        draft: const CalendarEventDraft(
          text: 'meeting with Luca +thesis @u',
          startMinutes: 15 * 60,
          endMinutes: 16 * 60,
          reminderMinutes: 14 * 60 + 45,
        ),
      );
      expect(after.lines[3].text, startsWith('2026-10-12 w42 Mon  '));
      expect(
        after.lines[3].text,
        contains(
          'rem:13:15. 15-16 meeting with Luca +thesis @u rem:14:45. '
          '18-19 jogging',
        ),
      );
      // The new event parses back as it was asked for.
      final added = eventOf(after.lines[3].text, 2);
      expect(added.text, 'meeting with Luca +thesis @u rem:14:45');
      expect(added.time!.raw, '15-16');
      expect(added.reminder, '14:45');
      // Only that line moved.
      expect(changedLines(before, after), [3]);
    });

    test('an event with no time goes after the timed ones', () {
      final after = addCalendarEvent(
        file(_lines),
        DateTime(2026, 10, 12),
        draft: const CalendarEventDraft(text: 'read the draft'),
      );
      final events = parseCalendarLine(after.lines[3].text).events;
      expect(events.map((event) => event.text), [
        'thesis chapter 3 +thesis @library',
        'call with Marta @phone rem:13:15',
        'jogging @park (if dry)',
        'read the draft',
      ]);
    });

    test('a day with no line gets one, in date order', () {
      final before = file(_lines);
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 6),
        draft: const CalendarEventDraft(
          text: 'library card',
          startMinutes: 9 * 60,
        ),
      );
      expect(after.lines[3].text, '2026-10-06 w41 Tue  9 library card.');
      // Between the 5th and the 12th, where its date belongs.
      expect(after.lines[2].text, startsWith('2026-10-05'));
      expect(after.lines[4].text, startsWith('2026-10-12'));
      expect(before.lines, isNot(after.lines));
    });

    test("a missing file is made, with the spec's English head", () {
      final after = addCalendarEvent(
        const CalendarFileContent(lines: <CalendarRawLine>[]),
        DateTime(2026, 10, 12),
        draft: const CalendarEventDraft(
          text: 'thesis chapter 3 +thesis',
          startMinutes: 9 * 60,
          endMinutes: 12 * 60,
        ),
      );
      expect(
        joinCalendarFile(after),
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis.\n',
      );
      expect(after.validUtf8, isTrue);
      expect(after.bom, isFalse);
    });

    test("a new line follows the file's own convention", () {
      // An Italian file: `mer.` for Wednesday, no week number anywhere.
      final before = file(const [
        '2026-10-05 lun.  9-10 reading.',
        '2026  The year of the move +home',
      ]);
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 7),
        draft: const CalendarEventDraft(text: 'esame', startMinutes: 8 * 60),
      );
      // After every line already there: nothing heads a later date, and
      // the year goal is the file's first line whatever its date.
      expect(after.lines.last.text, '2026-10-07 mer.  8 esame.');
    });

    test("the file's own endings are kept, line by line", () {
      const before = CalendarFileContent(
        lines: [
          CalendarRawLine('2026-10-05 w41 Mon  9-10 reading.', '\r\n'),
          CalendarRawLine('2026-10-12 w42 Mon  9-12 thesis.', '\n'),
          CalendarRawLine('2026-10-13 w42 Tue  10-1130 seminar.', '\r\n'),
        ],
      );
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 12),
        draft: const CalendarEventDraft(text: 'lunch', startMinutes: 13 * 60),
      );
      expect(after.lines[0].ending, '\r\n');
      expect(after.lines[1].ending, '\n');
      expect(after.lines[2].ending, '\r\n');
      expect(after.lines[1].text, endsWith('13 lunch.'));
      expect(changedLines(before, after), [1]);
    });

    test('a line inserted last keeps the file without a trailing newline', () {
      const before = CalendarFileContent(
        lines: [
          CalendarRawLine('2026-10-05 w41 Mon  9-10 reading.', '\n'),
          CalendarRawLine('2026-10-12 w42 Mon  9-12 thesis.', ''),
        ],
      );
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 13),
        draft: const CalendarEventDraft(text: 'lunch', startMinutes: 13 * 60),
      );
      expect(after.lines[1].ending, '\n', reason: 'the line before it');
      expect(after.lines[2].ending, '');
      expect(joinCalendarFile(after), endsWith('13 lunch.'));
    });

    test('a BOM and a lossy decode travel with the file', () {
      const before = CalendarFileContent(
        lines: [CalendarRawLine('2026-10-12 w42 Mon  9-12 thesis.', '\n')],
        bom: true,
        validUtf8: false,
      );
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 12),
        draft: const CalendarEventDraft(text: 'lunch', startMinutes: 13 * 60),
      );
      expect(after.bom, isTrue);
      expect(after.validUtf8, isFalse);
    });

    test('whatever the day, only its own line moves', () {
      final before = file(_lines);
      const draft = CalendarEventDraft(text: 'lunch', startMinutes: 13 * 60);
      for (final (index, raw) in _lines.indexed) {
        final parsed = parseCalendarLine(raw, weekdays: calendarWeekdays);
        if (parsed.kind != CalendarLineKind.day) continue;
        final after = addCalendarEvent(before, parsed.date!, draft: draft);
        expect(changedLines(before, after), [index], reason: raw);
        expect(after.lines.length, before.lines.length, reason: raw);
      }
    });

    test('an event with nothing to write is refused', () {
      expect(
        () => addCalendarEvent(
          file(_lines),
          DateTime(2026, 10, 12),
          draft: const CalendarEventDraft(text: '   '),
        ),
        throwsArgumentError,
      );
    });

    test('a day whose last event has no terminator gets one', () {
      final before = file(const ['2026-10-12 w42 Mon  9-12 thesis']);
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 12),
        draft: const CalendarEventDraft(text: 'lunch', startMinutes: 13 * 60),
      );
      expect(
        after.lines.single.text,
        '2026-10-12 w42 Mon  9-12 thesis. 13 lunch.',
      );
    });
  });

  group('update', () {
    test('an edit touches its own line, and only the event', () {
      final before = file(_lines);
      final after = updateCalendarEvent(
        before,
        _refOf(_lines[3], 2),
        const CalendarEventDraft(text: 'jogging @park'),
      );
      expect(after, isNotNull);
      expect(after!.lines[3].text, isNot(contains('(if dry)')));
      expect(after.lines[3].text, isNot(contains('read the draft')));
      expect(changedLines(before, after), [3]);
    });

    test('an edit keeps the time and the reminder when asked', () {
      final after = updateCalendarEvent(
        file(_lines),
        _refOf(_lines[3], 1),
        const CalendarEventDraft(
          text: 'call with Marta @phone',
          startMinutes: 13 * 60 + 30,
          endMinutes: 14 * 60,
          reminderMinutes: 13 * 60 + 15,
        ),
      )!;
      expect(
        after.lines[3].text,
        contains('13:30-14 call with Marta @phone rem:13:15.'),
      );
    });

    test('a changed time moves the event where the line keeps its order', () {
      final after = updateCalendarEvent(
        file(_lines),
        _refOf(_lines[3], 2),
        const CalendarEventDraft(
          text: 'jogging @park',
          startMinutes: 8 * 60,
          endMinutes: 9 * 60,
        ),
      )!;
      expect(
        after.lines[3].text,
        startsWith('2026-10-12 w42 Mon  8-9 jogging @park.'),
      );
    });

    test('a moved file makes the edit a no-op, not a wrong edit', () {
      final moved = file(const [
        '2026-10-12 w42 Mon  9-12 thesis.',
        '2026-10-13 w42 Tue  15-16 moved.',
      ]);
      expect(
        updateCalendarEvent(
          moved,
          _refOf(_lines[3], 0),
          const CalendarEventDraft(text: 'else'),
        ),
        isNull,
      );
      expect(deleteCalendarEvent(moved, _refOf(_lines[3], 0)), isNull);
    });
  });

  group('delete', () {
    test('the first event: the terminators after it go', () {
      final after = deleteCalendarEvent(file(_lines), _refOf(_lines[3], 0))!;
      expect(
        after.lines[3].text,
        '2026-10-12 w42 Mon  13:30-14 call with Marta @phone rem:13:15. '
        '18-19 jogging @park (if dry).',
      );
    });

    test('a middle event: one gap closes, the spacing stays', () {
      final after = deleteCalendarEvent(file(_lines), _refOf(_lines[3], 1))!;
      expect(
        after.lines[3].text,
        '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis @library. '
        '18-19 jogging @park (if dry).',
      );
    });

    test('the last event: its own closing dot goes with it', () {
      final after = deleteCalendarEvent(file(_lines), _refOf(_lines[3], 2))!;
      expect(
        after.lines[3].text,
        endsWith('call with Marta @phone rem:13:15.'),
      );
      expect(after.lines[3].text, isNot(contains('jogging')));
    });

    test('a day left with no event keeps its head', () {
      final after = deleteCalendarEvent(
        file(const ['2026-10-12 w42 Mon  9-12 thesis.']),
        _onlyRef('2026-10-12 w42 Mon  9-12 thesis.', 0),
      )!;
      expect(after.lines.single.text, '2026-10-12 w42 Mon');
    });

    test('the whole line stays where it was, and no other moves', () {
      final before = file(_lines);
      final after = deleteCalendarEvent(before, _refOf(_lines[3], 0))!;
      expect(changedLines(before, after), [3]);
      expect(after.lines.length, before.lines.length);
    });
  });

  group('the day style a new line is headed with', () {
    test('a file with no clue is English, week and weekday', () {
      const style = CalendarDayStyle();
      expect(style.head(DateTime(2026, 10, 7)), '2026-10-07 w41 Wed');
      expect(style.head(DateTime(2026)), '2026-01-01 w1 Thu');
    });

    test('a file teaches the writer its own names', () {
      final style = CalendarDayStyle.of(const [
        '2026-10-05 lun.  9-10 reading.',
        '2026  The year of the move +home',
      ]);
      expect(style.week, isFalse, reason: 'no head carries a week number');
      expect(style.head(DateTime(2026, 10, 7)), '2026-10-07 mer.');
    });

    test('a file that writes the week keeps it', () {
      final style = CalendarDayStyle.of(const [
        '2026-10-05 w41 Mon  9-10 reading.',
      ]);
      expect(style.week, isTrue);
      expect(style.head(DateTime(2026, 10, 7)), '2026-10-07 w41 Wed');
    });

    test('a file left without a weekday is written in English', () {
      final style = CalendarDayStyle.of(const ['2026-10-05 w41 Mon  reading.']);
      expect(style.head(DateTime(2026, 10, 7)), '2026-10-07 w41 Wed');
    });
  });

  group('the endings, whatever the file is', () {
    test('a CRLF file stays CRLF', () {
      final before = file(_lines, ending: '\r\n');
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 14),
        draft: const CalendarEventDraft(text: 'lunch', startMinutes: 13 * 60),
      );
      expect(after.lines.last.ending, '\r\n');
      expect(after.lines.first.ending, '\r\n');
    });

    test("a mixed file keeps every line's own ending", () {
      final before = CalendarFileContent(
        lines: [
          for (final (at, line) in _lines.indexed)
            CalendarRawLine(line, at.isEven ? '\n' : '\r\n'),
        ],
      );
      final after = addCalendarEvent(
        before,
        DateTime(2026, 10, 14),
        draft: const CalendarEventDraft(text: 'lunch', startMinutes: 13 * 60),
      );
      for (var at = 0; at < before.lines.length; at++) {
        expect(after.lines[at].ending, before.lines[at].ending);
      }
      // The new line takes the file's dominant ending, LF here (three
      // against two).
      expect(after.lines.last.ending, '\n');
    });
  });
}

/// The reference to the event [at] of [line], as a reader of that file
/// would hold it.
CalendarEventRef _refOf(String line, int at) {
  final parsed = parseCalendarLine(line, weekdays: calendarWeekdays);
  return CalendarEventRef(
    line: _lines.indexOf(line),
    day: parsed.date!,
    start: parsed.events[at].start,
  );
}

/// The reference to the single event of [line], on line [index].
CalendarEventRef _onlyRef(String line, int index) {
  final parsed = parseCalendarLine(line, weekdays: calendarWeekdays);
  return CalendarEventRef(
    line: index,
    day: parsed.date!,
    start: parsed.events.first.start,
  );
}
