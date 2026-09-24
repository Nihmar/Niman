// #7: the journal's month and the browser around it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/journal/journal_calendar.dart';

void main() {
  final today = DateTime(2026, 9, 23);

  testWidgets('a month: its days, the entries dotted, taps heard', (
    tester,
  ) async {
    final tapped = <DateTime>[];
    final months = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalCalendar(
            month: DateTime(2026, 9),
            entries: {DateTime(2026, 9, 21), DateTime(2026, 9, 22)},
            today: today,
            onDay: tapped.add,
            onMonth: months.add,
          ),
        ),
      ),
    );
    expect(find.text('September 2026'), findsOne);
    expect(find.byKey(const Key('journal-dot-21')), findsOne);
    expect(find.byKey(const Key('journal-dot-23')), findsNothing);
    expect(find.byKey(const Key('journal-day-30')), findsOne);
    expect(find.byKey(const Key('journal-day-31')), findsNothing);
    await tester.tap(find.byKey(const Key('journal-day-21')));
    expect(tapped, [DateTime(2026, 9, 21)]);
    await tester.tap(find.byKey(const Key('journal-month-next')));
    expect(months, [DateTime(2026, 10)]);
  });

  testWidgets('the week starts where the language starts it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalCalendar(
            month: DateTime(2026, 9),
            entries: const {},
            today: today,
            onDay: (_) {},
            onMonth: (_) {},
          ),
        ),
      ),
    );
    // English starts on Sunday: 1 September 2026, a Tuesday, is third.
    final first = tester.getTopLeft(find.byKey(const Key('journal-day-1')));
    final sunday = tester.getTopLeft(find.byKey(const Key('journal-day-6')));
    expect(first.dx, greaterThan(sunday.dx));
    expect(
      tester.getTopLeft(find.byKey(const Key('journal-day-13'))).dx,
      sunday.dx,
    );
  });

  group('the browser', () {
    Future<List<(DateTime, bool)>> pump(
      WidgetTester tester, {
      required bool large,
    }) async {
      final opened = <(DateTime, bool)>[];
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalBrowser(
              today: today,
              large: large,
              entryDays: () async => [DateTime(2026, 9, 21), today],
              readEntry: (day) async =>
                  day == today ? '# Today\n\nRain all day\n' : '',
              onOpenDay: (day, {confirmed = false}) =>
                  opened.add((day, confirmed)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('in the dock a day opens on its tap', (tester) async {
      final opened = await pump(tester, large: false);
      await tester.tap(find.byKey(const Key('journal-day-21')));
      expect(opened, [(DateTime(2026, 9, 21), false)]);
      expect(find.text('Rain all day'), findsOne, reason: 'recent');
      expect(find.byKey(const Key('journal-day-card')), findsNothing);
    });

    testWidgets('on the phone a day is picked, then opened or made', (
      tester,
    ) async {
      final opened = await pump(tester, large: true);
      await tester.tap(find.byKey(const Key('journal-day-20')));
      await tester.pump();
      expect(opened, isEmpty);
      expect(find.text('Sunday 20 September 2026'), findsOne);
      expect(find.text('No entry for this day'), findsOne);
      await tester.tap(find.byKey(const Key('journal-day-open')));
      expect(opened, [(DateTime(2026, 9, 20), true)]);
    });
  });

  group('the tasks due on the day', () {
    List<String> dueOn(DateTime day) => day == DateTime(2026, 9, 23)
        ? ['Renew the car insurance']
        : day == DateTime(2026, 9, 20)
        ? ['Book the train']
        : const [];

    Future<List<String>> pump(
      WidgetTester tester, {
      required bool large,
      DateTime? focusDay,
    }) async {
      final opened = <String>[];
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalBrowser(
              today: today,
              large: large,
              focusDay: focusDay,
              entryDays: () async => const [],
              readEntry: (_) async => '',
              onOpenDay: (_, {confirmed = false}) {},
              dueOn: dueOn,
              onOpenTasks: () => opened.add('tasks'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets("the dock lists today's, or the entry's day's", (tester) async {
      final opened = await pump(tester, large: false);
      expect(find.text('DUE ON WED 23'), findsOne);
      await tester.tap(find.text('Renew the car insurance'));
      expect(opened, ['tasks']);

      await pump(tester, large: false, focusDay: DateTime(2026, 9, 20));
      expect(find.text('Book the train'), findsOne);
      expect(find.text('Renew the car insurance'), findsNothing);
    });

    testWidgets("the phone lists the picked day's, and none says nothing", (
      tester,
    ) async {
      await pump(tester, large: true);
      expect(find.text('Renew the car insurance'), findsOne);
      await tester.tap(find.byKey(const Key('journal-day-21')));
      await tester.pump();
      expect(find.byKey(const Key('journal-due')), findsNothing);
    });
  });
}
