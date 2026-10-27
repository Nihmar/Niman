// #1192: a repeating event's reminders in the wanted set — the occurrences
// of the next fourteen days, every one of them, each its own alarm (#1228).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/todo/reminder_backend_plugin.dart';
import 'package:niman/src/todo/reminders.dart';

import '../fakes/fake_reminder_backend.dart';

CalendarSnapshot snapshot(List<String> lines) => calendarSnapshotOf(
  CalendarFileContent(
    lines: [for (final line in lines) CalendarRawLine(line, '\n')],
  ),
);

/// The moments of [wanted], soonest first.
List<DateTime> momentsOf(Map<int, TodoReminder> wanted) =>
    (wanted.values.map((r) => r.when).toList()..sort());

void main() {
  // A Monday noon.
  final now = DateTime(2026, 10, 26, 12);

  Map<int, TodoReminder> wantedOf(List<String> lines) =>
      calendarWantedReminders(snapshot(lines), now);

  group('the horizon', () {
    test('a daily event holds every day of the fourteen', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  16 Standup rec:1d rem:15:30.',
      ]);
      // 26 October to 8 November, today included.
      expect(momentsOf(wanted), [
        for (var day = 0; day < 14; day++) DateTime(2026, 10, 26 + day, 15, 30),
      ]);
    });

    test('a weekly event holds the occurrences of the fourteen days', () {
      // Today is the first of the fourteen, 8 November the last: the
      // occurrence of the 9th is beyond, and the one of today is past its
      // hour of grace.
      final wanted = wantedOf(const [
        '2026-10-05 w41 Mon  16 Review rec:1w rem:10:00.',
      ]);
      expect(momentsOf(wanted), [DateTime(2026, 11, 2, 10)]);

      final later = wantedOf(const [
        '2026-10-05 w41 Mon  16 Review rec:1w rem:13:00.',
      ]);
      expect(momentsOf(later), [
        DateTime(2026, 10, 26, 13),
        DateTime(2026, 11, 2, 13),
      ]);
    });

    test('a monthly event holds only what falls inside', () {
      // 30 Sep + 1 month = 30 Oct, inside; 30 Nov is not.
      final wanted = wantedOf(const [
        '2026-09-30 w40 Wed  16 Rent rec:1m rem:09:00.',
      ]);
      expect(momentsOf(wanted), [DateTime(2026, 10, 30, 9)]);
      // 10 Nov is beyond the fourteen days: nothing yet.
      expect(
        wantedOf(const ['2026-09-10 w37 Thu  16 Rent rec:1m rem:09:00.']),
        isEmpty,
      );
    });

    test('no count is kept per rule: each holds the whole horizon', () {
      const day = '2026-10-20 w43 Tue';
      final wanted = wantedOf(const [
        '$day  16 Standup rec:1d rem:15:30. 17 Gym rec:1d rem:16:30.',
      ]);
      expect(wanted, hasLength(28));
    });

    test('occurrences already past are not scheduled', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  9 Early rec:1d rem:09:00.',
      ]);
      expect(
        momentsOf(wanted).first,
        DateTime(2026, 10, 27, 9),
        reason: "today's 09:00 is more than the grace behind",
      );
      // 27 October to 8 November.
      expect(wanted, hasLength(13));
    });

    test('a reminder just due is kept, as for any event', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  11 Call rec:1d rem:11:30.',
      ]);
      expect(momentsOf(wanted).first, DateTime(2026, 10, 26, 11, 30));
    });

    test('the window follows the clock, not the file', () {
      const lines = ['2026-10-20 w43 Tue  16 Standup rec:1d rem:15:30.'];
      final file = snapshot(lines);
      final tomorrow = calendarWantedReminders(file, now);
      final later = calendarWantedReminders(
        file,
        now.add(const Duration(days: 20)),
      );
      expect(momentsOf(later).first, DateTime(2026, 11, 15, 15, 30));
      expect(
        later.keys.toSet().intersection(tomorrow.keys.toSet()),
        isEmpty,
        reason: 'twenty days on, none of the alarms is the same one',
      );
    });

    test('a rule starting later holds nothing before its first day', () {
      final wanted = wantedOf(const [
        '2026-10-29 w44 Thu  16 Standup rec:1d rem:15:30.',
      ]);
      expect(momentsOf(wanted).first, DateTime(2026, 10, 29, 15, 30));
      // 29 October to 8 November.
      expect(wanted, hasLength(11));
    });
  });

  group('the bounds', () {
    test('until: ends the reminders with the rule', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  16 Standup rec:1d until:2026-10-27 rem:15:30.',
      ]);
      expect(momentsOf(wanted), [
        DateTime(2026, 10, 26, 15, 30),
        DateTime(2026, 10, 27, 15, 30),
      ]);
    });

    test('except: removes that occurrence and the window takes the next', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  16 Standup rec:1d except:2026-10-27 rem:15:30.',
      ]);
      expect(momentsOf(wanted), [
        DateTime(2026, 10, 26, 15, 30),
        for (var day = 28; day <= 31; day++) DateTime(2026, 10, day, 15, 30),
        for (var day = 1; day <= 8; day++) DateTime(2026, 11, day, 15, 30),
      ]);
    });

    test('a skip changes the id of no alarm but its own', () {
      final plain = wantedOf(const [
        '2026-10-20 w43 Tue  16 Standup rec:1d rem:15:30.',
      ]);
      final skipped = wantedOf(const [
        '2026-10-20 w43 Tue  16 Standup rec:1d except:2026-10-27 rem:15:30.',
      ]);
      final skippedDay = plain.values
          .singleWhere((r) => r.when == DateTime(2026, 10, 27, 15, 30))
          .id;
      expect(skipped.keys, isNot(contains(skippedDay)));
      final kept = plain.keys.toSet()..remove(skippedDay);
      expect(skipped.keys.toSet(), containsAll(kept));
    });

    test('skipping the first day drops the one alarm it had', () {
      final wanted = wantedOf(const [
        '2026-10-26 w44 Mon  16 Standup rec:1d except:2026-10-26 rem:15:30.',
      ]);
      expect(momentsOf(wanted).first, DateTime(2026, 10, 27, 15, 30));
    });

    test('a rule the grammar cannot read is an event like any other', () {
      final wanted = wantedOf(const [
        '2026-10-26 w44 Mon  16 Standup rec:nonsense rem:15:30.',
      ]);
      expect(momentsOf(wanted), [DateTime(2026, 10, 26, 15, 30)]);
    });
  });

  group('the reminder', () {
    test('a clock is that time on each occurrence', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  16-17 Standup rec:1d rem:15:30.',
      ]);
      final first = wanted.values.firstWhere(
        (r) => r.when == DateTime(2026, 10, 27, 15, 30),
      );
      expect(first.title, 'Standup');
      expect(first.body, 'Tue 27 Oct · 16-17');
      expect(first.payload, 'journal:2026-10-27');
    });

    test('a full date-time keeps its distance from the first day', () {
      // Written the day before the first day: the day before each one. The
      // first day's own was yesterday evening, and is past.
      final before = wantedOf(const [
        '2026-10-26 w44 Mon  16 Trip rec:2d rem:2026-10-25T18:00.',
      ]);
      expect(momentsOf(before), [
        DateTime(2026, 10, 27, 18),
        DateTime(2026, 10, 29, 18),
        DateTime(2026, 10, 31, 18),
        DateTime(2026, 11, 2, 18),
        DateTime(2026, 11, 4, 18),
        DateTime(2026, 11, 6, 18),
      ]);
      expect(before.values.map((r) => r.payload).toSet(), {
        'journal:2026-10-28',
        'journal:2026-10-30',
        'journal:2026-11-01',
        'journal:2026-11-03',
        'journal:2026-11-05',
        'journal:2026-11-07',
      });
    });

    test('a date-time later than its occurrence is kept while ahead', () {
      // Occurrence on the 25th, reminder the day after: still due on the
      // 26th, though the occurrence is behind us.
      final wanted = wantedOf(const [
        '2026-10-24 w43 Sat  16 Follow up rec:1d rem:2026-10-25T18:00.',
      ]);
      // The occurrences of 25 October to 8 November, each reminded the day
      // after: 26 October to 9 November.
      expect(momentsOf(wanted), [
        for (var day = 0; day < 15; day++) DateTime(2026, 10, 26 + day, 18),
      ]);
    });

    test('a date-time on an event with no rule fires at its stamp', () {
      final wanted = wantedOf(const [
        '2026-10-28 w44 Wed  16 Dentist rem:2026-10-27T08:15.',
      ]);
      expect(momentsOf(wanted), [DateTime(2026, 10, 27, 8, 15)]);
      expect(wanted.values.single.payload, 'journal:2026-10-28');
    });

    test('a Z reminder is the instant it names on each occurrence', () {
      final wanted = wantedOf(const [
        '2026-10-26 w44 Mon  16 Call rec:1d rem:19:00Z.',
      ]);
      expect(momentsOf(wanted).first, DateTime.utc(2026, 10, 26, 19).toLocal());
    });
  });

  group('the ids', () {
    test('an event with no rule keeps the id it has always had', () {
      final wanted = wantedOf(const [
        '2026-10-28 w44 Wed  16 Dentist rem:15:15.',
      ]);
      expect(
        wanted.keys.single,
        calendarReminderId(DateTime(2026, 10, 28), 'Dentist rem:15:15'),
      );
    });

    test('the first day of a rule keeps the id of its event', () {
      final wanted = wantedOf(const [
        '2026-10-26 w44 Mon  16 Standup rec:1d rem:15:30.',
      ]);
      final first = wanted.values.firstWhere(
        (r) => r.when == DateTime(2026, 10, 26, 15, 30),
      );
      expect(
        first.id,
        calendarReminderId(DateTime(2026, 10, 26), 'Standup rec:1d rem:15:30'),
      );
    });

    test('every occurrence has an id of its own', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  16 Standup rec:1d rem:15:30.',
      ]);
      expect(wanted.keys.toSet(), hasLength(14));
      expect(
        wanted.keys,
        everyElement(
          isNot(
            calendarReminderId(
              DateTime(2026, 10, 20),
              'Standup rec:1d rem:15:30',
            ),
          ),
        ),
      );
    });

    test('an occurrence is the same alarm from one reconcile to the next', () {
      const lines = ['2026-10-20 w43 Tue  16 Standup rec:1d rem:15:30.'];
      final a = wantedOf(lines);
      final b = calendarWantedReminders(
        snapshot(lines),
        now.add(const Duration(minutes: 30)),
      );
      expect(b.keys.toSet(), a.keys.toSet());
    });

    test('two series of one text do not share their alarms', () {
      final wanted = wantedOf(const [
        '2026-10-20 w43 Tue  16 Standup rec:1d rem:15:30.',
        '2026-10-21 w43 Wed  16 Standup rec:1d rem:15:30.',
      ]);
      expect(wanted, hasLength(28));
    });

    test('occurrence ids are salted apart from the tasks', () {
      final anchor = DateTime(2026, 10, 20);
      final day = DateTime(2026, 10, 27);
      expect(
        calendarOccurrenceReminderId(anchor, day, 'Standup'),
        isNot(todoReminderId('Standup')),
      );
      expect(
        calendarOccurrenceReminderId(anchor, anchor, 'Standup'),
        calendarReminderId(anchor, 'Standup'),
      );
    });
  });
  group('the platform cap (#1228)', () {
    // Eight events a day on every one of the fourteen days is 112 alarms;
    // enough rules to pass Android's limit make the cap bite.
    List<String> manyRules(int count) => [
      for (var i = 0; i < count; i++)
        '2026-10-20 w43 Tue  16 Rule$i rec:1d rem:${15 + i % 8}:30.',
    ];

    test('a daily rule holds every day when the cap allows', () async {
      final backend = FakeReminderBackend(
        pendingLimit: PluginReminderBackend().pendingLimit,
      );
      final service = LocalReminderService(backend: backend, clock: () => now);
      await service.reconcile(
        wantedOf(const ['2026-10-20 w43 Tue  16 Standup rec:1d rem:15:30.']),
      );
      expect(backend.scheduled, hasLength(14));
      await service.dispose();
    });

    test('over the cap the soonest of all the rules win', () async {
      final limit = PluginReminderBackend().pendingLimit!;
      final all = wantedOf(manyRules(60)); // 60 rules x 14 days = 840
      expect(all.length, greaterThan(limit));
      final backend = FakeReminderBackend(pendingLimit: limit);
      final service = LocalReminderService(backend: backend, clock: () => now);
      await service.reconcile(all);

      expect(backend.scheduled, hasLength(limit), reason: 'the cap holds');
      final kept = backend.scheduled.map((r) => r.when).toList();
      final dropped = [
        for (final r in all.values)
          if (!backend.scheduled.any((s) => s.id == r.id)) r.when,
      ];
      expect(dropped, hasLength(all.length - limit));
      kept.sort();
      dropped.sort();
      expect(
        !kept.last.isAfter(dropped.first),
        isTrue,
        reason: 'nothing kept is later than anything left out',
      );
      // The cut falls across days, not within one rule: no rule is starved.
      final rulesKept = backend.scheduled.map((r) => r.title).toSet();
      expect(rulesKept, hasLength(60));
      await service.dispose();
    });

    test(
      'plain reminders share the cap with the rules, soonest first',
      () async {
        final limit = PluginReminderBackend().pendingLimit!;
        final wanted = <int, TodoReminder>{
          ...wantedOf(manyRules(60)),
          for (var i = 1; i <= 3; i++)
            -i: TodoReminder(
              id: -i,
              title: 'soon',
              body: '',
              when: now.add(Duration(minutes: i)),
            ),
        };
        final backend = FakeReminderBackend(pendingLimit: limit);
        final service = LocalReminderService(
          backend: backend,
          clock: () => now,
        );
        await service.reconcile(wanted);
        expect(backend.scheduled, hasLength(limit));
        expect(
          backend.scheduled.map((r) => r.id),
          containsAll(<int>[-1, -2, -3]),
        );
        await service.dispose();
      },
    );
  });
}
