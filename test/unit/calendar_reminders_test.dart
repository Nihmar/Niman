// #730 phase 3: an event's `rem:HH:MM` as a schedulable reminder — the day
// comes from the line, the id from the text, and a tap opens the journal
// on that day. The same wanted set the tasks feed, salted apart.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/todo/todo_reminder.dart';

CalendarSnapshot snapshot(List<String> lines) => calendarSnapshotOf(
  CalendarFileContent(
    lines: [for (final line in lines) CalendarRawLine(line, '\n')],
  ),
);

void main() {
  // A Sunday noon, so the day's reminders are still ahead of it.
  final now = DateTime(2026, 10, 12, 12);

  test('an event with a rem: fires on its own day', () {
    final wanted = calendarWantedReminders(
      snapshot(const [
        '2026-10-12 w42 Mon  9-12 thesis +thesis. 16 dentist @city rem:15:15.',
      ]),
      now,
    );
    expect(wanted, hasLength(1));
    final reminder = wanted.values.single;
    expect(reminder.title, 'dentist', reason: 'the markers are dropped');
    expect(reminder.body, 'Mon 12 Oct · 16');
    expect(reminder.when, DateTime(2026, 10, 12, 15, 15));
    expect(reminder.payload, 'journal:2026-10-12');
  });

  test('a Z event keeps the clock the line wrote', () {
    final wanted = calendarWantedReminders(
      snapshot(const ['2026-10-12 w42 Mon  0600Z call with Tokyo rem:1330.']),
      now,
    );
    expect(
      wanted.values.single.when,
      DateTime(2026, 10, 12, 13, 30),
      reason: "the format's own compact reading, on the line's day",
    );
  });

  test("a rem: in the file's other spellings reads too", () {
    for (final (written, expected) in [
      ('13:30', DateTime(2026, 10, 12, 13, 30)),
      ('13', DateTime(2026, 10, 12, 13)),
      ('1330', DateTime(2026, 10, 12, 13, 30)),
    ]) {
      final wanted = calendarWantedReminders(
        snapshot(['2026-10-12 w42 Mon  9 a rem:$written.']),
        now,
      );
      expect(wanted.values.single.when, expected, reason: written);
    }
    expect(
      calendarWantedReminders(
        snapshot(const ['2026-10-12 w42 Mon  9 a rem:19:00Z.']),
        now,
      ).values.single.when,
      DateTime.utc(2026, 10, 12, 19).toLocal(),
      reason: 'a Z reminder is the instant it names',
    );
  });

  test('nothing to fire: no rem:, no file, no clock, no day', () {
    final twoEvents = snapshot(const [
      '2026-10-12 w42 Mon  9-12 a. 16 b rem:15:15.',
      '2026  The year of the move +home',
    ]);
    expect(
      calendarWantedReminders(
        twoEvents,
        now,
      ).values.map((reminder) => reminder.title),
      ['b'],
    );
    expect(calendarWantedReminders(null, now), isEmpty);
    expect(
      calendarWantedReminders(
        snapshot(const [
          '2026-10-12 w42 Mon  16 a rem:25:00. 17 b rem:xx. 18 c rem:9:99.',
        ]),
        now,
      ),
      isEmpty,
    );
  });

  test('a reminder beyond the grace is dropped, one just due is kept', () {
    final wanted = calendarWantedReminders(
      snapshot(const ['2026-10-12 w42 Mon  9 a rem:09:00. 11 b rem:11:30.']),
      now,
    );
    expect(wanted, hasLength(1), reason: '11:30 is inside the hour');
    expect(wanted.values.single.when, DateTime(2026, 10, 12, 11, 30));
    expect(wanted.values.single.body, endsWith('11'));
  });

  test('the id is the day and the text, salted apart from the tasks', () {
    final day = DateTime(2026, 10, 12);
    expect(
      calendarReminderId(day, 'dentist'),
      calendarReminderId(day, 'dentist'),
    );
    expect(
      calendarReminderId(day, 'dentist'),
      isNot(calendarReminderId(DateTime(2026, 10, 13), 'dentist')),
    );
    expect(
      calendarReminderId(day, 'dentist'),
      isNot(todoReminderId('dentist')),
      reason: "an event never takes a task's id",
    );
  });

  test('showTokens keeps the markers the title otherwise drops', () {
    final file = snapshot(const [
      '2026-10-12 w42 Mon  16 dentist @city +health rem:15:15.',
    ]);
    expect(
      calendarWantedReminders(file, now).values.single.title,
      'dentist',
      reason: 'without the setting the markers are not shown',
    );
    expect(
      calendarWantedReminders(file, now, showTokens: true).values.single.title,
      'dentist @city +health',
    );
    final onlyTokens = snapshot(const [
      '2026-10-12 w42 Mon  16 +health @city rem:15:15.',
    ]);
    expect(
      calendarWantedReminders(onlyTokens, now).values.single.title,
      isNotEmpty,
      reason: 'a line that is nothing but tokens still has a title',
    );
  });

  test('the payload parses back to the day it names', () {
    final day = DateTime(2026, 10, 12);
    expect(journalReminderPayload(day), 'journal:2026-10-12');
    expect(journalReminderDayOf(journalReminderPayload(day)), day);
    expect(journalReminderDayOf('todo'), isNull);
    expect(journalReminderDayOf('journal:not-a-day'), isNull);
    expect(journalReminderDayOf(null), isNull);
  });
}
