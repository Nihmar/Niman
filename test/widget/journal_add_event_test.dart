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
  final edited = <(CalendarEntryEvent, CalendarEventDraft)>[];
  final deleted = <CalendarEntryEvent>[];
  final opened = <CalendarEntryEvent>[];
  final openedDays = <(DateTime, bool)>[];

  setUp(() {
    added.clear();
    addedTasks.clear();
    edited.clear();
    deleted.clear();
    opened.clear();
    openedDays.clear();
  });

  /// The day's line, with two events on it.
  const dayLine =
      '2026-10-12 w42 Mon  9-12 thesis chapter 3 +thesis. '
      '16 dentist @city rem:15:15.';

  CalendarSnapshot snapshot() => calendarSnapshotOf(
    const CalendarFileContent(lines: [CalendarRawLine(dayLine, '\n')]),
  );

  /// Brings an event's row into view and taps it: the pane is a list, and
  /// the Events section sits below the calendar.
  Future<void> tapEvent(WidgetTester tester, String text) async {
    final row = find.textContaining(text);
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  Widget buildApp({bool large = false, List<DateTime>? entries}) {
    final at = snapshot();
    return MaterialApp(
      home: Scaffold(
        body: JournalBrowser(
          today: today,
          large: large,
          // An explicit empty list is a library with no entry at all.
          entryDays: () async => entries ?? [today],
          readEntry: (day) async => '',
          onOpenDay: (day, {confirmed = false}) =>
              openedDays.add((day, confirmed)),
          eventsOn: at.eventsFor,
          knownTokens: const {'+thesis'},
          calendarFile: at.file,
          onAddEvent: (day, event) => added.add((day, event)),
          onAddTask: addedTasks.add,
          onOpenEvent: opened.add,
          onEditEvent: (entry, event) => edited.add((entry, event)),
          onDeleteEvent: deleted.add,
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

  testWidgets('a phone edits and deletes an event from its sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(large: true));
    await tester.pumpAndSettle();

    // The dentist, with its reminder, under Events.
    await tapEvent(tester, 'dentist');
    expect(find.byKey(const Key('journal-event-sheet-grab')), findsOne);
    expect(find.textContaining('12 October'), findsWidgets);
    expect(find.text('Reminder at 15:15'), findsOne);

    // Edit opens the form, filled from the event.
    await tester.tap(find.byKey(const Key('journal-event-edit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-event-form')), findsOne);
    expect(find.text('Edit'), findsWidgets);
    final field = tester.widget<TextField>(
      find.byKey(const Key('calendar-event-text')),
    );
    expect(field.controller!.text, contains('dentist'));

    await tester.enterText(
      find.byKey(const Key('calendar-event-text')),
      'dentist @city',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-event-save')));
    await tester.pumpAndSettle();

    expect(edited, hasLength(1));
    expect(edited.single.$2.text, 'dentist @city');
    expect(edited.single.$2.startMinutes, 16 * 60);
    expect(edited.single.$2.reminderMinutes, 15 * 60 + 15);

    // Delete goes straight through.
    await tapEvent(tester, 'dentist');
    await tester.tap(find.byKey(const Key('journal-event-delete')));
    await tester.pumpAndSettle();
    expect(deleted, hasLength(1));
    expect(deleted.single.event.text, contains('dentist'));

    // And the file's own line is one tap away.
    await tapEvent(tester, 'dentist');
    await tester.tap(find.byKey(const Key('journal-event-open')));
    await tester.pumpAndSettle();
    expect(opened, hasLength(1));
  });

  testWidgets('an empty day offers New journal beside the adds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(large: true, entries: const []));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-new-entry')), findsOne);
    expect(find.byKey(const Key('journal-add-event')), findsOne);
    expect(find.byKey(const Key('journal-add-task')), findsOne);

    await tester.ensureVisible(find.byKey(const Key('journal-new-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('journal-new-entry')));
    await tester.pump();

    // Making the entry is the day's own answer: confirmed, no question.
    expect(openedDays, [(today, true)]);
  });

  testWidgets('a day with its entry offers no New journal', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(large: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-new-entry')), findsNothing);
  });

  testWidgets('a window taps an event straight into the file', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tapEvent(tester, 'dentist');

    expect(opened, hasLength(1));
    expect(find.byKey(const Key('journal-event-sheet-grab')), findsNothing);
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

  testWidgets('a phone sheet keeps the form clear of the status bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 40);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp(large: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('journal-add-event')));
    await tester.pumpAndSettle();
    final form = find.byKey(const Key('calendar-event-form'));
    expect(form, findsOne);
    // A wrapped sheet, bottom-anchored: its head is nowhere near the
    // status bar, not stretched to the full screen.
    expect(tester.getTopLeft(form).dy, greaterThanOrEqualTo(40));

    // The keyboard takes what room is left: the form scrolls instead of
    // climbing over the status bar under it.
    tester.view.viewInsets = const FakeViewPadding(bottom: 700);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(form).dy, greaterThanOrEqualTo(40));
  });
}
