// #1191: what Skip, Edit and Delete write on one occurrence of a repeating
// event. The promises under test: each is made of `until:`, `except:` and
// plain events as the record says; only the lines it must change change,
// and every other keeps its bytes and its own ending; and what the journal
// then shows is what the action meant.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/calendar/parser.dart';
import 'package:niman/src/calendar/weekdays.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';

/// The standup, every Monday from the 5th; mixed endings, so a line that
/// moved when it should not shows in the bytes.
const List<CalendarRawLine> _lines = [
  CalendarRawLine('2026  The year of the move', '\r\n'),
  CalendarRawLine(
    '2026-10-05 w41 Mon  9-9:30 Standup @work rec:1w. 17 jog.',
    '\n',
  ),
  CalendarRawLine('2026-10-08 w41 Thu  18 dinner.', '\r\n'),
  CalendarRawLine('2026-10-12 w42 Mon  8 gym.', '\n'),
  CalendarRawLine('2026-10-13 w42 Tue  10 seminar.', ''),
];

CalendarFileContent file([List<CalendarRawLine> lines = _lines]) =>
    CalendarFileContent(lines: lines);

/// The standup's own event, on its line.
final CalendarEventRef rule = CalendarEventRef(
  line: 1,
  day: DateTime(2026, 10, 5),
  start: 20,
);

/// Every line of [before] whose text or ending is not the same in [after],
/// by index: [after] may have more lines, never fewer.
List<int> changedLines(CalendarFileContent before, CalendarFileContent after) {
  final changed = <int>[];
  for (var at = 0; at < before.lines.length; at++) {
    if (at >= after.lines.length || before.lines[at] != after.lines[at]) {
      changed.add(at);
    }
  }
  return changed;
}

/// The days from 5 October to 30 November on which [file] shows an event
/// that says [text].
List<String> daysOf(CalendarFileContent file, String text) {
  final snapshot = calendarSnapshotOf(file);
  final days = <String>[];
  for (
    var day = DateTime(2026, 10, 5);
    !day.isAfter(DateTime(2026, 11, 30));
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    final hit = snapshot.eventsFor(day).any((e) => e.event.text.contains(text));
    if (hit) days.add(_iso(day));
  }
  return days;
}

String _iso(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}'
    '-${day.day.toString().padLeft(2, '0')}';

/// The first event of [line] as the parser reads it.
CalendarEvent firstEvent(String line) =>
    parseCalendarLine(line, weekdays: calendarWeekdays).events.first;

const CalendarEventDraft _moved = CalendarEventDraft(
  text: 'Standup @work',
  startMinutes: 10 * 60,
  endMinutes: 10 * 60 + 30,
);

void main() {
  test('the fixture points at the standup', () {
    expect(firstEvent(_lines[1].text).start, rule.start);
    expect(daysOf(file(), 'Standup').take(3), [
      '2026-10-05',
      '2026-10-12',
      '2026-10-19',
    ]);
  });

  group('skip', () {
    test('writes the day into a new except:, on its own line only', () {
      final before = file();
      final after = skipCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 12),
      );
      expect(after, isNotNull);
      expect(
        after!.lines[1].text,
        '2026-10-05 w41 Mon  9-9:30 Standup @work rec:1w except:2026-10-12. '
        '17 jog.',
      );
      expect(changedLines(before, after), [1]);
      expect(after.lines.length, before.lines.length);
      expect(daysOf(after, 'Standup').take(3), [
        '2026-10-05',
        '2026-10-19',
        '2026-10-26',
      ]);
    });

    test('a second skip extends the list, in date order', () {
      final once = skipCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 26),
      )!;
      final twice = skipCalendarOccurrence(once, rule, DateTime(2026, 10, 12))!;
      expect(
        twice.lines[1].text,
        contains('rec:1w except:2026-10-12,2026-10-26. 17 jog.'),
      );
      expect(changedLines(once, twice), [1]);
    });

    test('the end and the reminder stay where they were', () {
      final before = file([
        const CalendarRawLine(
          '2026-10-05 w41 Mon  9 Standup rec:1w until:2026-12-31 rem:8:45. '
              '17 jog.',
          '\n',
        ),
      ]);
      final after = skipCalendarOccurrence(
        before,
        CalendarEventRef(line: 0, day: DateTime(2026, 10, 5), start: 20),
        DateTime(2026, 10, 12),
      )!;
      expect(
        after.lines.single.text,
        '2026-10-05 w41 Mon  9 Standup rec:1w until:2026-12-31 rem:8:45 '
        'except:2026-10-12. 17 jog.',
      );
    });

    test('an unreadable except: is left, and a readable one added', () {
      final before = file([
        const CalendarRawLine(
          '2026-10-05 w41 Mon  9 Standup rec:1w except:soon.',
          '\n',
        ),
      ]);
      final after = skipCalendarOccurrence(
        before,
        CalendarEventRef(line: 0, day: DateTime(2026, 10, 5), start: 20),
        DateTime(2026, 10, 12),
      )!;
      expect(
        after.lines.single.text,
        '2026-10-05 w41 Mon  9 Standup rec:1w except:soon except:2026-10-12.',
      );
    });

    test('the first day can be skipped: the event hides on its own day', () {
      final after = skipCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 5),
      )!;
      expect(daysOf(after, 'Standup').first, '2026-10-12');
    });

    test('a day the rule does not reach, or has skipped, is a no-op', () {
      expect(
        skipCalendarOccurrence(file(), rule, DateTime(2026, 10, 7)),
        isNull,
      );
      expect(
        skipCalendarOccurrence(file(), rule, DateTime(2026, 9, 28)),
        isNull,
      );
      final skipped = skipCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 12),
      )!;
      expect(
        skipCalendarOccurrence(skipped, rule, DateTime(2026, 10, 12)),
        isNull,
      );
    });

    test('an event with no rule has nothing to skip', () {
      final plain = CalendarEventRef(
        line: 2,
        day: DateTime(2026, 10, 8),
        start: 20,
      );
      expect(
        skipCalendarOccurrence(file(), plain, DateTime(2026, 10, 8)),
        isNull,
      );
    });

    test('a moved file makes it a no-op, not a wrong edit', () {
      final moved = file(_lines.sublist(2));
      expect(
        skipCalendarOccurrence(moved, rule, DateTime(2026, 10, 12)),
        isNull,
      );
    });
  });

  group('edit this one', () {
    test('skips the day and writes a plain event on a line that is there', () {
      final before = file();
      final after = updateCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 12),
        _moved,
        CalendarOccurrenceScope.thisOne,
      )!;
      expect(after.lines[1].text, contains('rec:1w except:2026-10-12.'));
      expect(
        after.lines[3].text,
        '2026-10-12 w42 Mon  8 gym. 10-10:30 Standup @work.',
      );
      expect(after.lines[3].text, isNot(contains('rec:')));
      expect(changedLines(before, after), [1, 3]);
      expect(daysOf(after, 'Standup').take(3), [
        '2026-10-05',
        '2026-10-12',
        '2026-10-19',
      ]);
    });

    test('a day with no line gets one, in date order', () {
      final before = file();
      final after = updateCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 19),
        _moved,
        CalendarOccurrenceScope.thisOne,
      )!;
      expect(changedLines(before, after), [1, 4], reason: 'line 4 was last');
      expect(after.lines.length, before.lines.length + 1);
      expect(
        after.lines[5].text,
        '2026-10-19 w43 Mon  10-10:30 Standup @work.',
      );
      expect(after.lines[4].ending, '\r\n', reason: "the file's own");
    });

    test('moving it puts the plain event on the day it is moved to', () {
      final after = updateCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 12),
        _moved,
        CalendarOccurrenceScope.thisOne,
        moveTo: DateTime(2026, 10, 13),
      )!;
      expect(
        after.lines[4].text,
        '2026-10-13 w42 Tue  10 seminar. 10-10:30 Standup @work.',
      );
      expect(daysOf(after, 'Standup').take(3), [
        '2026-10-05',
        '2026-10-13',
        '2026-10-19',
      ]);
    });

    test('on the first day the plain event joins the rule line', () {
      final after = updateCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 5),
        _moved,
        CalendarOccurrenceScope.thisOne,
      )!;
      expect(
        after.lines[1].text,
        '2026-10-05 w41 Mon  9-9:30 Standup @work rec:1w except:2026-10-05. '
        '10-10:30 Standup @work. 17 jog.',
      );
      expect(daysOf(after, 'Standup').take(2), ['2026-10-05', '2026-10-12']);
    });

    test('a rule in the draft is dropped: it is one plain event', () {
      final after = updateCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 12),
        _moved.withRecurrence(
          calendarDraftOf(firstEvent(_lines[1].text)).recurrence,
        ),
        CalendarOccurrenceScope.thisOne,
      )!;
      expect(after.lines[3].text, isNot(contains('rec:')));
    });
  });

  group('edit this and following', () {
    final recurrence = calendarDraftOf(firstEvent(_lines[1].text)).recurrence;
    final changed = _moved.withRecurrence(recurrence);

    test('ends the rule the day before and starts a new one', () {
      final before = file();
      final after = updateCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 12),
        changed,
        CalendarOccurrenceScope.thisAndFollowing,
      )!;
      expect(after.lines[1].text, contains('rec:1w until:2026-10-11.'));
      expect(
        after.lines[3].text,
        '2026-10-12 w42 Mon  8 gym. 10-10:30 Standup @work rec:1w.',
      );
      expect(changedLines(before, after), [1, 3]);
      final shown = daysOf(after, 'Standup');
      expect(shown.take(4), [
        '2026-10-05',
        '2026-10-12',
        '2026-10-19',
        '2026-10-26',
      ]);
      expect(shown, hasLength(9), reason: 'no day twice, none lost');
    });

    test('the end the rule had goes on the new event', () {
      final before = file([
        const CalendarRawLine(
          '2026-10-05 w41 Mon  9 Standup rec:1w until:2026-12-31.',
          '\n',
        ),
      ]);
      final line0 = CalendarEventRef(
        line: 0,
        day: DateTime(2026, 10, 5),
        start: 20,
      );
      final draft = calendarDraftOf(firstEvent(before.lines.single.text));
      final after = updateCalendarOccurrence(
        before,
        line0,
        DateTime(2026, 11, 2),
        draft,
        CalendarOccurrenceScope.thisAndFollowing,
      )!;
      expect(after.lines[0].text, contains('until:2026-11-01.'));
      expect(
        after.lines[1].text,
        '2026-11-02 w45 Mon  9 Standup rec:1w until:2026-12-31.',
      );
    });

    test(
      'skips before the day stay with the old rule, later ones go along',
      () {
        final before = file([
          const CalendarRawLine(
            '2026-10-05 w41 Mon  9 Standup rec:1w '
                'except:2026-10-12,2026-10-19,2026-11-16.',
            '\n',
          ),
        ]);
        final draft = calendarDraftOf(firstEvent(before.lines.single.text));
        final after = updateCalendarOccurrence(
          before,
          CalendarEventRef(line: 0, day: DateTime(2026, 10, 5), start: 20),
          DateTime(2026, 11, 2),
          draft,
          CalendarOccurrenceScope.thisAndFollowing,
        )!;
        expect(
          after.lines[0].text,
          '2026-10-05 w41 Mon  9 Standup rec:1w '
          'except:2026-10-12,2026-10-19,2026-11-16 until:2026-11-01.',
        );
        expect(
          after.lines[1].text,
          '2026-11-02 w45 Mon  9 Standup rec:1w except:2026-11-16.',
        );
      },
    );

    test('from the first day it is the whole rule that changes', () {
      final before = file();
      final after = updateCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 5),
        changed,
        CalendarOccurrenceScope.thisAndFollowing,
      )!;
      expect(changedLines(before, after), [1]);
      expect(
        after.lines[1].text,
        '2026-10-05 w41 Mon  10-10:30 Standup @work rec:1w. 17 jog.',
      );
    });

    test('a new rule in the draft is the one written', () {
      final every2 = changed.withRecurrence(
        calendarDraftOf(firstEvent('2026-10-05 w41 Mon  9 x rec:2w.'))
            .recurrence,
      );
      final after = updateCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 12),
        every2,
        CalendarOccurrenceScope.thisAndFollowing,
      )!;
      expect(after.lines[3].text, contains('Standup @work rec:2w.'));
      expect(daysOf(after, 'Standup').take(4), [
        '2026-10-05',
        '2026-10-12',
        '2026-10-26',
        '2026-11-09',
      ]);
    });
  });

  group('edit all', () {
    test('an end replaces an until: the grammar cannot read (#1227)', () {
      final before = file([
        const CalendarRawLine(
          '2026-10-05 w41 Mon  9 Standup rec:1w until:2026-1-31.',
          '\n',
        ),
      ]);
      final draft = calendarDraftOf(firstEvent(before.lines.single.text));
      expect(draft.recurrence!.bounds.until, isNull);
      final after = updateCalendarOccurrence(
        before,
        CalendarEventRef(line: 0, day: DateTime(2026, 10, 5), start: 20),
        DateTime(2026, 10, 19),
        draft.withRecurrence(
          CalendarRecurrence(
            rule: draft.recurrence!.rule,
            bounds: RecurrenceBounds(until: DateTime(2026, 12, 31)),
          ),
        ),
        CalendarOccurrenceScope.all,
      )!;
      expect(
        after.lines.single.text,
        '2026-10-05 w41 Mon  9 Standup rec:1w until:2026-12-31.',
      );
      expect(
        firstEvent(after.lines.single.text).recurrence!.bounds.until,
        DateTime(2026, 12, 31),
      );
    });

    test(
      'a second rec: and until: in the text give way to the form (#1227)',
      () {
        final before = file([
          const CalendarRawLine(
            '2026-10-05 w41 Mon  9 Standup rec:1w until:2026-11-30 '
                'rec:2w until:2026-12-31.',
            '\n',
          ),
        ]);
        final after = updateCalendarOccurrence(
          before,
          CalendarEventRef(line: 0, day: DateTime(2026, 10, 5), start: 20),
          DateTime(2026, 10, 19),
          calendarDraftOf(firstEvent(before.lines.single.text)),
          CalendarOccurrenceScope.all,
        )!;
        expect(
          after.lines.single.text,
          '2026-10-05 w41 Mon  9 Standup rec:1w until:2026-11-30.',
        );
      },
    );

    test('a rule added to an event with a rec: it cannot read replaces it', () {
      final before = file([
        const CalendarRawLine('2026-10-05 w41 Mon  9 Standup rec:often.', '\n'),
      ]);
      final draft = calendarDraftOf(firstEvent(before.lines.single.text));
      expect(draft.recurrence, isNull);
      final after = updateCalendarOccurrence(
        before,
        CalendarEventRef(line: 0, day: DateTime(2026, 10, 5), start: 20),
        DateTime(2026, 10, 5),
        draft.withRecurrence(
          CalendarRecurrence(
            rule: RecurrenceRule(unit: RecurrenceUnit.week),
            bounds: RecurrenceBounds(),
          ),
        ),
        CalendarOccurrenceScope.all,
      )!;
      expect(after.lines.single.text, '2026-10-05 w41 Mon  9 Standup rec:1w.');
    });

    test('rewrites the rule event itself, rule and all', () {
      final before = file();
      final draft = calendarDraftOf(firstEvent(_lines[1].text));
      final after = updateCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 19),
        CalendarEventDraft(
          text: 'Planning @work',
          startMinutes: 10 * 60,
          recurrence: draft.recurrence,
        ),
        CalendarOccurrenceScope.all,
      )!;
      expect(
        after.lines[1].text,
        '2026-10-05 w41 Mon  10 Planning @work rec:1w. 17 jog.',
      );
      expect(changedLines(before, after), [1]);
    });

    test('keeps the days the rule skips', () {
      final before = file([
        const CalendarRawLine(
          '2026-10-05 w41 Mon  9 Standup rec:1w except:2026-10-12.',
          '\n',
        ),
      ]);
      final draft = calendarDraftOf(firstEvent(before.lines.single.text));
      expect(draft.text, 'Standup');
      final after = updateCalendarOccurrence(
        before,
        CalendarEventRef(line: 0, day: DateTime(2026, 10, 5), start: 20),
        DateTime(2026, 10, 19),
        draft,
        CalendarOccurrenceScope.all,
      )!;
      expect(after.lines.single.text, before.lines.single.text);
    });
  });

  group('moving to another day', () {
    final dinner = CalendarEventRef(
      line: 2,
      day: DateTime(2026, 10, 8),
      start: 20,
    );

    test('a plain event leaves its line for the day it is moved to', () {
      final before = file();
      final after = updateCalendarOccurrence(
        before,
        dinner,
        DateTime(2026, 10, 8),
        CalendarEventDraft(
          text: 'dinner',
          startMinutes: 19 * 60,
          day: DateTime(2026, 10, 13),
        ),
        CalendarOccurrenceScope.all,
      )!;
      expect(after.lines[2].text, '2026-10-08 w41 Thu');
      expect(after.lines[4].text, '2026-10-13 w42 Tue  10 seminar. 19 dinner.');
      expect(changedLines(before, after), [2, 4]);
      expect(after.lines[2].ending, '\r\n');
    });

    test('to a day with no line, one is made in date order', () {
      final before = file();
      final after = updateCalendarOccurrence(
        before,
        dinner,
        DateTime(2026, 10, 8),
        CalendarEventDraft(text: 'dinner', day: DateTime(2026, 10, 9)),
        CalendarOccurrenceScope.all,
      )!;
      expect(after.lines.length, before.lines.length + 1);
      expect(after.lines[3].text, '2026-10-09 w41 Fri  dinner.');
      expect(after.lines[2].text, '2026-10-08 w41 Thu');
    });

    test('the same day, or none, is an edit in place', () {
      for (final day in [null, DateTime(2026, 10, 8)]) {
        final before = file();
        final after = updateCalendarOccurrence(
          before,
          dinner,
          DateTime(2026, 10, 8),
          CalendarEventDraft(text: 'dinner at 7', day: day),
          CalendarOccurrenceScope.all,
        )!;
        expect(after.lines[2].text, '2026-10-08 w41 Thu  dinner at 7.');
        expect(changedLines(before, after), [2]);
      }
    });

    test('one occurrence is skipped and written on the day it is moved to', () {
      final before = file();
      final after = updateCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 12),
        CalendarEventDraft(
          text: 'Standup @work',
          startMinutes: 10 * 60,
          day: DateTime(2026, 10, 13),
        ),
        CalendarOccurrenceScope.thisOne,
      )!;
      expect(after.lines[1].text, contains('rec:1w except:2026-10-12.'));
      expect(
        after.lines[4].text,
        '2026-10-13 w42 Tue  10 seminar. 10 Standup @work.',
      );
      expect(daysOf(after, 'Standup').take(3), [
        '2026-10-05',
        '2026-10-13',
        '2026-10-19',
      ]);
    });

    test('a series does not move: the day is ignored', () {
      final draft = calendarDraftOf(firstEvent(_lines[1].text));
      for (final scope in [
        CalendarOccurrenceScope.all,
        CalendarOccurrenceScope.thisAndFollowing,
      ]) {
        final moved = CalendarEventDraft(
          text: draft.text,
          startMinutes: draft.startMinutes,
          endMinutes: draft.endMinutes,
          recurrence: draft.recurrence,
          day: DateTime(2026, 10, 20),
        );
        final after = updateCalendarOccurrence(
          file(),
          rule,
          DateTime(2026, 10, 5),
          moved,
          scope,
        )!;
        expect(after.lines[1].text, contains('Standup @work rec:1w'));
        expect(after.lines.length, _lines.length);
      }
    });
  });

  group('delete', () {
    test('this one is a skip', () {
      final a = deleteCalendarOccurrence(
        file(),
        rule,
        DateTime(2026, 10, 12),
        CalendarOccurrenceScope.thisOne,
      );
      final b = skipCalendarOccurrence(file(), rule, DateTime(2026, 10, 12));
      expect(a!.lines, b!.lines);
    });

    test('this and following ends the rule the day before', () {
      final before = file();
      final after = deleteCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 19),
        CalendarOccurrenceScope.thisAndFollowing,
      )!;
      expect(after.lines[1].text, contains('rec:1w until:2026-10-18.'));
      expect(changedLines(before, after), [1]);
      expect(daysOf(after, 'Standup'), ['2026-10-05', '2026-10-12']);
    });

    test('this and following from the first day takes the event away', () {
      final before = file();
      final after = deleteCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 5),
        CalendarOccurrenceScope.thisAndFollowing,
      )!;
      expect(after.lines[1].text, '2026-10-05 w41 Mon  17 jog.');
      expect(changedLines(before, after), [1]);
      expect(daysOf(after, 'Standup'), isEmpty);
    });

    test('all takes the rule event away, and its line keeps the rest', () {
      final before = file();
      final after = deleteCalendarOccurrence(
        before,
        rule,
        DateTime(2026, 10, 19),
        CalendarOccurrenceScope.all,
      )!;
      expect(after.lines[1].text, '2026-10-05 w41 Mon  17 jog.');
      expect(daysOf(after, 'Standup'), isEmpty);
    });

    test(
      'an event that does not repeat is just deleted, whatever the scope',
      () {
        final plain = CalendarEventRef(
          line: 2,
          day: DateTime(2026, 10, 8),
          start: 20,
        );
        for (final scope in CalendarOccurrenceScope.values) {
          final after = deleteCalendarOccurrence(
            file(),
            plain,
            DateTime(2026, 10, 8),
            scope,
          )!;
          expect(after.lines[2].text, '2026-10-08 w41 Thu');
        }
      },
    );
  });

  group('whatever the action and the day', () {
    final recurrence = calendarDraftOf(firstEvent(_lines[1].text)).recurrence;
    final draft = _moved.withRecurrence(recurrence);
    final mondays = [for (var i = 0; i < 8; i++) DateTime(2026, 10, 5 + 7 * i)];

    test('only the rule line and the line it writes to change', () {
      final before = file();
      for (final day in mondays) {
        for (final scope in CalendarOccurrenceScope.values) {
          final edits = <String, CalendarFileContent?>{
            'skip': skipCalendarOccurrence(before, rule, day),
            'delete': deleteCalendarOccurrence(before, rule, day, scope),
            'edit': updateCalendarOccurrence(before, rule, day, draft, scope),
          };
          for (final MapEntry(:key, :value) in edits.entries) {
            final reason = '$key ${scope.name} ${_iso(day)}';
            expect(value, isNotNull, reason: reason);
            final changed = changedLines(before, value!);
            // The rule's line, the day's own line when the action writes
            // there, and the line that was last (it gains an ending).
            final allowed = {
              1,
              if (day == DateTime(2026, 10, 12)) 3 else -1,
              4,
            };
            expect(
              changed.every(allowed.contains),
              isTrue,
              reason: '$reason changed $changed',
            );
            for (final at in [0, 2]) {
              expect(value.lines[at], before.lines[at], reason: reason);
            }
          }
        }
      }
    });

    test('skipping every day once leaves nothing of the rule shown', () {
      var now = file();
      for (final day in [
        for (var i = 0; i < 9; i++) DateTime(2026, 10, 5 + 7 * i),
      ]) {
        now = skipCalendarOccurrence(now, rule, day)!;
      }
      expect(daysOf(now, 'Standup'), isEmpty);
    });
  });
}
