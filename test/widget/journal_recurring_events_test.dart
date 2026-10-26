// #1190: an event with a `rec:` shows wherever an event does — the month's
// dots, the dock pane, the phone's day card and its sheet — on every day
// its rule reaches, with the repeat icon and the rule in words, and a tap
// that goes to the rule's own line.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  // A Monday. The standup began on Mon 5 Oct and repeats every week, to
  // the end of October; there is a plain event on the 8th.
  final today = DateTime(2026, 10, 12);
  const file = [
    '2026-10-05 w41 Mon  9-9:30 Standup @work rec:1w until:2026-10-26.',
    '2026-10-08 w41 Thu  18 dinner.',
  ];

  CalendarSnapshot snapshot() => calendarSnapshotOf(calendarFileOf(file));

  Future<List<CalendarEntryEvent>> pump(
    WidgetTester tester, {
    bool large = false,
    bool withSheet = true,
  }) async {
    final opened = <CalendarEntryEvent>[];
    final at = snapshot();
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalBrowser(
            today: today,
            large: large,
            entryDays: () async => const [],
            readEntry: (day) async => '',
            onOpenDay: (day, {confirmed = false}) {},
            eventsOn: at.eventsFor,
            eventDaysIn: at.eventDaysIn,
            onOpenEvent: opened.add,
            onEditEvent: withSheet ? (entry, event, scope) {} : null,
            onDeleteEvent: withSheet ? (entry, scope) {} : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  /// The row key of the standup, whatever day it shows on.
  const repeat = Key('journal-event-repeat-0-20');

  testWidgets('the dock lists the occurrence of the day, its rule beside it', (
    tester,
  ) async {
    // Today is the 12th: a week after the standup's own day.
    await pump(tester);

    expect(find.textContaining('Standup'), findsOne);
    expect(find.byKey(repeat), findsOne);
    expect(find.text(AppStrings.recurWeeks(1)), findsOne);
    expect(
      find.descendant(
        of: find.byKey(repeat),
        matching: find.byIcon(Icons.repeat),
      ),
      findsOne,
      reason: 'the outline repeat icon',
    );
  });

  testWidgets('an event that does not repeat wears no rule', (tester) async {
    await pump(tester, large: true);
    await tester.tap(find.byKey(const Key('journal-day-8')));
    await tester.pumpAndSettle();

    expect(find.textContaining('dinner'), findsOne);
    expect(find.byIcon(Icons.repeat), findsNothing);
  });

  testWidgets('the month dots every occurrence, and no day between', (
    tester,
  ) async {
    await pump(tester);

    // The standup's days (5, 12, 19, 26: until: ends it there) and the
    // dinner's.
    for (final day in [5, 8, 12, 19, 26]) {
      expect(
        find.byKey(Key('journal-events-dot-$day')),
        findsOne,
        reason: 'October $day',
      );
    }
    for (final day in [6, 11, 13, 20, 27]) {
      expect(
        find.byKey(Key('journal-events-dot-$day')),
        findsNothing,
        reason: 'October $day',
      );
    }

    // The next month: until: has ended the rule, nothing is dotted.
    await tester.tap(find.byKey(const Key('journal-month-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('journal-events-dot-2')), findsNothing);
    expect(find.byKey(const Key('journal-events-dot-9')), findsNothing);
  });

  testWidgets("the phone's day card shows the occurrence of the day picked", (
    tester,
  ) async {
    await pump(tester, large: true);
    await tester.tap(find.byKey(const Key('journal-day-19')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Standup'), findsOne);
    expect(find.byKey(repeat), findsOne);

    // Past `until:` there is nothing.
    await tester.tap(find.byKey(const Key('journal-day-27')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Standup'), findsNothing);
  });

  testWidgets('a tap on an occurrence targets the rule line', (tester) async {
    final opened = await pump(tester);

    await tester.tap(find.textContaining('Standup'));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.lineIndex, 0, reason: "the rule's own line");
    expect(opened.single.day, DateTime(2026, 10, 12));
    expect(opened.single.line.date, DateTime(2026, 10, 5));
  });

  testWidgets("the phone's sheet shows the rule and the day it is of", (
    tester,
  ) async {
    await pump(tester, large: true);
    await tester.tap(find.byKey(const Key('journal-day-19')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Standup'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-event-sheet-repeat')), findsOne);
    expect(
      find.textContaining('19'),
      findsWidgets,
      reason: 'the occurrence day, not the rule line day',
    );
    // A later copy edits and deletes by asking which of the series it
    // means (#1191), and still goes to the rule's line.
    expect(find.byKey(const Key('journal-event-edit')), findsOne);
    expect(find.byKey(const Key('journal-event-delete')), findsOne);
    expect(find.byKey(const Key('journal-event-open')), findsOne);
  });

  testWidgets('the sheet of the event on its own day still edits it', (
    tester,
  ) async {
    await pump(tester, large: true);
    await tester.tap(find.byKey(const Key('journal-day-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Standup'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-event-sheet-repeat')), findsOne);
    expect(find.byKey(const Key('journal-event-edit')), findsOne);
    expect(find.byKey(const Key('journal-event-delete')), findsOne);
    expect(find.byKey(const Key('journal-event-open')), findsOne);
  });
}
