// #730 phase 1: the Home's events tile — today's goals over today's
// events, read from `calendar.txt`, with a tap that opens the journal and
// a row that opens the event's line.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/calendar/calendar_source.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_calendar_source.dart';
import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession session;
  late FakeFilePicker filePicker;
  late FakeCalendarSource calendar;

  /// Today, as the tile reads it.
  final today = DateTime.now();
  String iso(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  setUp(() {
    session = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    calendar = FakeCalendarSource(
      exists: true,
      lines: [
        '${today.year}  The year of the move +home',
        '${iso(today)} w42  Writing week',
        '${iso(today)} w42 Mon  9-12 thesis chapter 3 +thesis @library.',
      ],
    );
  });

  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  Future<void> openHome(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(session),
          calendarSourceFactoryProvider.overrideWithValue((_) => calendar),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await settle(tester);
    await tester.tap(find.byKey(const Key('tab-home')));
    await settle(tester);
  }

  testWidgets("the tile shows the day's goals and its events", (tester) async {
    await openHome(tester);
    final tile = find.byKey(const Key('home-tile-eventsToday'));
    expect(tile, findsOne);
    expect(
      find.descendant(
        of: tile,
        matching: find.textContaining(AppStrings.journalWeek(42)),
      ),
      findsOne,
      reason: "the week's goal covers today",
    );
    expect(
      find.descendant(
        of: tile,
        matching: find.textContaining('thesis chapter'),
      ),
      findsOne,
    );
    expect(find.descendant(of: tile, matching: find.text('9-12')), findsOne);
  });

  testWidgets('an event opens its line in calendar.txt', (tester) async {
    await openHome(tester);
    final event = find.descendant(
      of: find.byKey(const Key('home-tile-eventsToday')),
      matching: find.textContaining('thesis chapter'),
    );
    // The tile sits below the phone's fold.
    await tester.ensureVisible(event);
    await settle(tester);
    await tester.tap(event);
    await settle(tester);

    // The file opens in the editor, the caret at the event's line: the
    // line after the year's goal.
    final view = tester.widget<NoteView>(
      find.byWidgetPredicate(
        (w) => w is NoteView && w.path.endsWith('calendar.txt'),
        skipOffstage: false,
      ),
    );
    expect(
      view.initialCaretOffset,
      // The two lines above the event's own, endings included.
      calendar.lines[0].length + 1 + calendar.lines[1].length + 1,
    );
  });

  testWidgets('a day with nothing on it says so', (tester) async {
    calendar = FakeCalendarSource();
    await openHome(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-tile-eventsToday')),
        matching: find.text(AppStrings.homeEventsEmpty),
      ),
      findsOne,
    );
  });
}
