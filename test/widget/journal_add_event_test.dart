// #730 phase 3: Add event and Add task from a day — inline in the dock
// where the calendar is, a sheet on a phone, and the day's own write.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';

void main() {
  final today = DateTime(2026, 10, 12);
  final added = <(DateTime, CalendarEventDraft)>[];
  final addedTasks = <DateTime>[];

  setUp(() {
    added.clear();
    addedTasks.clear();
  });

  Widget buildApp({bool large = false}) {
    return MaterialApp(
      home: Scaffold(
        body: JournalBrowser(
          today: today,
          large: large,
          entryDays: () async => [today],
          readEntry: (day) async => '',
          onOpenDay: (day, {confirmed = false}) {},
          eventsOn: (day) => const <CalendarEntryEvent>[],
          knownTokens: const {'+thesis'},
          calendarFile: const CalendarFileContent(
            lines: [
              CalendarRawLine('2026-10-12 w42  Writing week +thesis', '\n'),
            ],
          ),
          onAddEvent: (day, event) => added.add((day, event)),
          onAddTask: addedTasks.add,
        ),
      ),
    );
  }

  testWidgets('the dock writes an event through the form', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-event-form')), findsNothing);
    await tester.tap(find.byKey(const Key('journal-add-event')));
    await tester.pump();
    expect(find.byKey(const Key('calendar-event-form')), findsOne);

    await tester.enterText(
      find.byKey(const Key('calendar-event-text')),
      'meeting with Luca',
    );
    await tester.pump();
    // The preview is the writer's own line for the day.
    expect(
      find.descendant(
        of: find.byKey(const Key('calendar-event-preview')),
        matching: find.textContaining('meeting with Luca'),
      ),
      findsOne,
    );

    await tester.tap(find.byKey(const Key('calendar-event-save')));
    await tester.pump();

    expect(added, hasLength(1));
    expect(added.single.$1, today);
    expect(added.single.$2.text, 'meeting with Luca');
    expect(find.byKey(const Key('calendar-event-form')), findsNothing);
  });

  testWidgets('leaving the form open just closes it', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('journal-add-event')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-event-cancel')));
    await tester.pump();

    expect(added, isEmpty);
    expect(find.byKey(const Key('calendar-event-form')), findsNothing);
  });

  testWidgets('Add task hands the day to the todo add', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('journal-add-task')));
    await tester.pump();

    expect(addedTasks, [today]);
  });

  testWidgets('a phone keeps the buttons in the day card, and a sheet opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(large: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-day-card')), findsOne);
    expect(
      find.descendant(
        of: find.byKey(const Key('journal-day-card')),
        matching: find.byKey(const Key('journal-add-event')),
      ),
      findsOne,
    );

    await tester.tap(find.byKey(const Key('journal-add-event')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOne);
    expect(find.byKey(const Key('calendar-event-form')), findsOne);

    await tester.enterText(
      find.byKey(const Key('calendar-event-text')),
      'dentist',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-event-save')));
    await tester.pumpAndSettle();

    expect(added, hasLength(1));
    expect(added.single.$2.text, 'dentist');
    expect(find.byType(BottomSheet), findsNothing);
  });
}
