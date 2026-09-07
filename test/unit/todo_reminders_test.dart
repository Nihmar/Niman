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

    test('an x line still in todo.txt never fires', () {
      // Only a reload archives stray completed lines, so an edit that
      // completes a task in place publishes it in `todo` first.
      final wanted = wantedReminders(
        snapshotOf(
          todo: ['x 2026-09-07 done here rem:2026-09-08T10:30'],
        ),
        DateTime(2026, 9, 7),
      );
      expect(wanted, isEmpty);
    });

    test('a tag-only description falls back to a generic title', () {
      final wanted = wantedReminders(
        snapshotOf(todo: ['due:2026-09-09 rem:2026-09-08T10:30']),
        DateTime(2026, 9, 7),
      );
      expect(wanted.values.single.title, 'Task reminder');
    });

    test('title shows the entered description, not the whole raw line', () {
      final wanted = wantedReminders(
        snapshotOf(todo: [
          '(B) call plumber +home due:2026-09-09 rem:2026-09-08T10:30',
        ]),
        DateTime(2026, 9, 7),
      );
      expect(wanted, hasLength(1));
      final entry = wanted.entries.single;
      // The id keys on the full description (stable identity); the shown text
      // drops the priority prefix and the managed due:/rem: tags, leaving the
      // description the user typed.
      expect(entry.key, entry.value.id);
      expect(entry.value.title, 'call plumber +home');
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
      final service = NoopReminderService();
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
