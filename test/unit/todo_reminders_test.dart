// T-TD-07: reminder ids are stable, the wanted set covers open future
// reminders only, and the no-op service is inert.
import 'dart:io';

import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/reminders.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TodoSnapshot snapshotOf({
    required List<String> todo,
    List<String> done = const [],
  }) {
    return TodoSnapshot(
      todo: <TodoEntry>[
        for (var i = 0; i < todo.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(todo[i])),
      ],
      done: <TodoEntry>[
        for (var i = 0; i < done.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(done[i])),
      ],
    );
  }

  group('todoReminderId', () {
    test('is deterministic and positive 31-bit', () {
      final first = todoReminderId('call mom +errands');
      expect(first, todoReminderId('call mom +errands'));
      expect(first, greaterThanOrEqualTo(0));
      expect(first, lessThan(0x80000000));
    });

    test('differs across descriptions', () {
      expect(todoReminderId('a'), isNot(todoReminderId('b')));
    });
  });

  test('todoReminderId matches its golden values', () {
    // A compatibility contract, not a property. The id is the only handle
    // on an alarm already sitting in AlarmManager: change the hash and
    // every reminder on an installed device becomes uncancellable and
    // gets a duplicate alongside it. Recomputing the hash in the test
    // would just assert the code against itself, so these are frozen
    // literals -- if one fails, the change is the bug.
    expect(todoReminderId('call plumber'), 867842594);
    expect(
      todoReminderId(
        'buy milk +home @errand due:2026-09-09 rem:2026-09-08T10:30',
      ),
      208725283,
    );
    expect(todoReminderId('ripassare la lezione di matematica'), 1024775335);
  });

  group('wantedReminders', () {
    test('covers open future reminders with due bodies', () {
      final wanted = wantedReminders(
        snapshotOf(
          todo: [
            'future rem:2026-09-08T10:30 due:2026-09-09',
            'plain rem:2026-09-08T10:30',
            'past rem:2026-09-06T10:30',
            'no reminder here',
          ],
          done: ['x done rem:2026-09-08T10:30'],
        ),
        DateTime(2026, 9, 7),
      );
      expect(wanted, hasLength(2));
      expect(
        wanted[todoReminderId('future rem:2026-09-08T10:30 due:2026-09-09')]
            ?.body,
        'Due 2026-09-09',
      );
      expect(
        wanted[todoReminderId('plain rem:2026-09-08T10:30')]?.body,
        'Todo reminder',
      );
      expect(
        wanted[todoReminderId('future rem:2026-09-08T10:30 due:2026-09-09')]
            ?.when,
        DateTime(2026, 9, 8, 10, 30),
      );
    });

    // T-RL-03: the wanted set is a full replace, so anything it drops has
    // its pending alarm cancelled. A device log caught an alarm the OS
    // was still holding three minutes after its time, cancelled by the
    // next reconcile before it could ring.
    test('a reminder just past is still wanted, so its alarm survives', () {
      final wanted = wantedReminders(
        snapshotOf(todo: ['deferred rem:2026-09-08T14:50']),
        DateTime(2026, 9, 8, 14, 53),
      );
      expect(wanted, hasLength(1));
      expect(wanted.values.single.when, DateTime(2026, 9, 8, 14, 50));
    });

    test('a reminder past the grace window is dropped', () {
      final at = DateTime(2026, 9, 8, 14, 50);
      final wanted = wantedReminders(
        snapshotOf(todo: ['stale rem:2026-09-08T14:50']),
        at.add(reminderGrace).add(const Duration(minutes: 1)),
      );
      expect(wanted, isEmpty);
    });

    test('an x line still in todo.txt never fires', () {
      // Only a reload archives stray completed lines, so an edit that
      // completes a task in place publishes it in `todo` first.
      final wanted = wantedReminders(
        snapshotOf(todo: ['x 2026-09-07 done here rem:2026-09-08T10:30']),
        DateTime(2026, 9, 7),
      );
      expect(wanted, isEmpty);
    });

    test('showTokens keeps the project, context and tag markers', () {
      // Off by default: on a lock screen the markers are syntax with
      // nothing to explain them. On for people who file by project.
      const line = 'call plumber +home @errand #urgent rem:2026-09-08T10:30';
      expect(
        wantedReminders(
          snapshotOf(todo: [line]),
          DateTime(2026, 9, 7),
        ).values.single.title,
        'call plumber',
      );
      expect(
        wantedReminders(
          snapshotOf(todo: [line]),
          DateTime(2026, 9, 7),
          showTokens: true,
        ).values.single.title,
        'call plumber +home @errand #urgent',
      );
    });

    test('a tag-only description falls back to a generic title', () {
      final wanted = wantedReminders(
        snapshotOf(todo: ['due:2026-09-09 rem:2026-09-08T10:30']),
        DateTime(2026, 9, 7),
      );
      expect(wanted.values.single.title, 'Task reminder');
    });

    test('title shows the typed phrase, not the whole raw line', () {
      final wanted = wantedReminders(
        snapshotOf(
          todo: ['(B) call plumber +home due:2026-09-09 rem:2026-09-08T10:30'],
        ),
        DateTime(2026, 9, 7),
      );
      expect(wanted, hasLength(1));
      final entry = wanted.entries.single;
      // The id keys on the full description (stable identity); the shown
      // text drops the priority prefix, the managed due:/rem: tags and the
      // +project/@context/#tag markers, leaving the phrase the user typed.
      expect(entry.key, entry.value.id);
      expect(entry.value.title, 'call plumber');
    });
  });

  group('platform service', () {
    test('creates the no-op off Android', () async {
      final service = createReminderService();
      try {
        expect(
          service,
          Platform.isAndroid
              ? isA<LocalReminderService>()
              : isA<NoopReminderService>(),
        );
      } finally {
        await service.dispose();
      }
    });

    test('the no-op reconciles, taps nothing and launches nowhere', () async {
      const service = NoopReminderService();
      await service.reconcile({
        1: TodoReminder(
          id: 1,
          title: 't',
          body: 'b',
          when: DateTime(2030, 5, 4),
        ),
      });
      expect(await service.taps.isEmpty, isTrue);
      expect(await service.consumeLaunchPayload(), isNull);
      await service.dispose();
    });
  });
}
