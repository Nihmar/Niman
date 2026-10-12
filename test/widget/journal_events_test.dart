// #730 phase 1: the journal's Events — the day's goals over them, the
// times as written, the tokens the editor colours, the aside dimmed, the
// bell of a reminder, the tap that opens the line, and the second dot the
// calendar wears for a day that has events.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_file.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/journal/journal_calendar.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/niman.dart';

void main() {
  final today = DateTime(2026, 10, 12);

  // Four events on one line, a reminder, an aside and a goal.
  const busy =
      '2026-10-12 w42 Mon  13:30-14 call with Marta @phone rem:13:15. '
      '18-19 jogging @park (if dry).';
  const file = [
    '2026  The year of the move +home',
    '2026-10  Finish the thesis draft +thesis',
    '2026-10-12 w42  Writing week',
    busy,
  ];

  CalendarSnapshot snapshot() => calendarSnapshotOf(
    CalendarFileContent(
      lines: [for (final line in file) CalendarRawLine(line, '\n')],
    ),
  );

  Future<List<CalendarEntryEvent>> pump(
    WidgetTester tester, {
    bool large = false,
    CalendarSnapshot? calendar,
    ThemeData? theme,
    bool clockTimes = false,
  }) async {
    final opened = <CalendarEntryEvent>[];
    final at = calendar ?? snapshot();
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: JournalBrowser(
            today: today,
            large: large,
            eventTimesClock: clockTimes,
            entryDays: () async => [today],
            readEntry: (day) async => '',
            onOpenDay: (day, {confirmed = false}) {},
            eventsOn: at.eventsFor,
            goalsOn: (day) => [
              for (final entry in at.goalsFor(day)) entry.line,
            ],
            eventDays: at.daysWithEvents,
            onOpenEvent: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('a clock time is the file read, not the file written', (
    tester,
  ) async {
    await pump(tester, clockTimes: true);

    expect(find.text('13:30–14:00'), findsOne);
    expect(find.text('18:00–19:00'), findsOne);
    expect(find.text('13:30-14'), findsNothing);
    expect(find.text('18-19'), findsNothing);
  });

  testWidgets("a goal's label wears the palette's goal colour (#730)", (
    tester,
  ) async {
    final syntax = nimanSyntax(Brightness.dark);
    await pump(tester, theme: ThemeData(extensions: [syntax]));

    final label = tester.widget<Text>(find.text(AppStrings.journalWeek(42)));
    expect(label.style?.color, syntax.calendarGoal);
    expect(syntax.calendarGoal, isNot(syntax.calendarHead));
  });

  testWidgets("the day's events come above Due, the goals over them", (
    tester,
  ) async {
    // A due task as well, so the order of the two sections is what is read.
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final at = snapshot();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalBrowser(
            today: today,
            entryDays: () async => [today],
            readEntry: (day) async => '',
            onOpenDay: (day, {confirmed = false}) {},
            eventsOn: at.eventsFor,
            goalsOn: (day) => [
              for (final entry in at.goalsFor(day)) entry.line,
            ],
            dueOn: (day) => ['Pay the rent'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-events')), findsOne);
    expect(find.text(AppStrings.journalEvents.toUpperCase()), findsOne);
    // The goals, the week's first, each with what it covers.
    expect(find.text(AppStrings.journalWeek(42)), findsOne);
    expect(find.text('Writing week'), findsOne);
    expect(find.text(AppStrings.monthNames[9]), findsOne);
    expect(find.text('2026'), findsOne);
    // The events, their times as written, then the due tasks below.
    expect(find.text('13:30-14'), findsOne);
    expect(find.text('18-19'), findsOne);
    expect(
      tester.getTopLeft(find.byKey(const Key('journal-events'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('journal-due'))).dy),
      reason: 'events above Due',
    );
  });

  testWidgets('an event shows its text, its tokens and its reminder', (
    tester,
  ) async {
    await pump(tester, large: true);
    expect(find.textContaining('call with Marta'), findsOneWidget);
    // A reminder wears the bell and its time.
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.text('13:15'), findsOne);
    // An aside is drawn with the event, dimmed rather than dropped.
    expect(find.textContaining('(if dry)'), findsOneWidget);
    // The tokens are on screen, drawn as runs of their own (their colours
    // are the theme's syntax roles, which the editor's own tests pin).
    final rich = tester.widgetList<RichText>(find.byType(RichText));
    expect(
      rich.any((text) => text.text.toPlainText().contains('+home')),
      isTrue,
      reason: 'a goal token is drawn',
    );
    expect(
      rich.any((text) => text.text.toPlainText().contains('@phone')),
      isTrue,
      reason: 'an event token is drawn',
    );
  });

  testWidgets('tapping an event opens its line', (tester) async {
    final opened = await pump(tester, large: true);
    expect(opened, isEmpty);

    await tester.tap(find.textContaining('call with Marta'));
    await tester.pumpAndSettle();
    expect(opened, hasLength(1));
    expect(opened.single.lineIndex, 3, reason: 'the line the event sits on');
    expect(opened.single.event.text, 'call with Marta @phone rem:13:15');
  });

  testWidgets('a day with neither events nor goals shows no section', (
    tester,
  ) async {
    await pump(
      tester,
      calendar: calendarSnapshotOf(
        const CalendarFileContent(
          lines: [CalendarRawLine('2026-10-05 w41 Mon', '\n')],
        ),
      ),
    );
    expect(find.byKey(const Key('journal-events')), findsNothing);
  });

  testWidgets('the calendar dots the days with events, beside the entries', (
    tester,
  ) async {
    final at = snapshot();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalCalendar(
            month: today,
            entries: {today},
            daysWithEvents: at.daysWithEvents,
            eventColour: const Color(0xFFD8A56B),
            today: today,
            onDay: (_) {},
            onMonth: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('journal-dot-12')), findsOne);
    expect(find.byKey(const Key('journal-events-dot-12')), findsOne);
    expect(
      find.byKey(const Key('journal-events-dot-11')),
      findsNothing,
      reason: 'a day with no event has no dot',
    );
  });
}
