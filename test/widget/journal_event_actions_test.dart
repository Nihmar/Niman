// #1191: what can be done with an event of the journal. On a window the
// dock's event has a context menu — Edit, Skip, Delete, Open in
// calendar.txt — and on a phone the event sheet has the same rows; for an
// event that repeats, Edit and Delete first ask which occurrences they
// mean, and what they hand the shell is the entry, the draft and the scope.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/calendar/calendar_store.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/ui/journal/journal_browser.dart';
import 'package:niman/src/ui/strings.dart';

void main() {
  // A Monday. The standup began on Mon 5 Oct and repeats every week; there
  // is a plain event on the 8th.
  final today = DateTime(2026, 10, 12);
  const file = [
    '2026-10-05 w41 Mon  9-9:30 Standup @work rec:1w.',
    '2026-10-08 w41 Thu  18 dinner.',
  ];

  final edited =
      <(CalendarEntryEvent, CalendarEventDraft, CalendarOccurrenceScope)>[];
  final skipped = <CalendarEntryEvent>[];
  final deleted = <(CalendarEntryEvent, CalendarOccurrenceScope)>[];
  final opened = <CalendarEntryEvent>[];
  final added = <(DateTime, CalendarEventDraft)>[];

  setUp(() {
    edited.clear();
    skipped.clear();
    deleted.clear();
    opened.clear();
    added.clear();
  });

  Future<void> pump(
    WidgetTester tester, {
    required bool phone,
    DateTime? focus,
    List<String> lines = file,
  }) async {
    final snapshot = calendarSnapshotOf(calendarFileOf(lines));
    tester.view.physicalSize = phone
        ? const Size(420, 1000)
        : const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // A window's theme is the pointer's: its choices are a pop-up.
        theme: ThemeData(
          platform: phone ? TargetPlatform.android : TargetPlatform.windows,
        ),
        home: Scaffold(
          body: JournalBrowser(
            today: today,
            large: phone,
            focusDay: focus,
            entryDays: () async => const [],
            readEntry: (day) async => '',
            onOpenDay: (day, {confirmed = false}) {},
            eventsOn: snapshot.eventsFor,
            eventDaysIn: snapshot.eventDaysIn,
            calendarFile: snapshot.file,
            onOpenEvent: opened.add,
            onAddEvent: (day, event) => added.add((day, event)),
            onEditEvent: (entry, event, scope) =>
                edited.add((entry, event, scope)),
            onSkipEvent: skipped.add,
            onDeleteEvent: (entry, scope) => deleted.add((entry, scope)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Right-clicks the event that says [text], on a window.
  Future<void> rightClick(WidgetTester tester, String text) async {
    final row = find.textContaining(text);
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(row, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
  }

  /// Picks [day] on the phone's card, and taps the event that says [text].
  Future<void> openSheet(WidgetTester tester, int day, String text) async {
    await tester.tap(find.byKey(Key('journal-day-$day')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(text));
    await tester.pumpAndSettle();
  }

  Finder key(String name) => find.byKey(Key(name));

  group('the dock, with a mouse', () {
    testWidgets('a right click opens the event menu: four rows', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');

      expect(key('journal-event-menu'), findsOne);
      expect(key('journal-event-edit'), findsOne);
      expect(key('journal-event-skip'), findsOne);
      expect(key('journal-event-delete'), findsOne);
      expect(key('journal-event-open'), findsOne);
      expect(find.text(AppStrings.calendarSkipAction), findsOne);
    });

    testWidgets('a long press opens the same menu, for a touch screen', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await tester.longPress(find.textContaining('Standup'));
      await tester.pumpAndSettle();

      expect(key('journal-event-menu'), findsOne);
      expect(key('journal-event-edit'), findsOne);
    });

    testWidgets('Skip is there for an event that does not repeat, and off', (
      tester,
    ) async {
      // The dock speaks for the day its entry is on: the dinner's.
      await pump(tester, phone: false, focus: DateTime(2026, 10, 8));
      await rightClick(tester, 'dinner');

      expect(key('journal-event-skip'), findsOne);
      expect(
        tester.widget<ListTile>(key('journal-event-skip')).enabled,
        isFalse,
      );
      await tester.tap(key('journal-event-skip'));
      await tester.pumpAndSettle();
      expect(skipped, isEmpty);
    });

    testWidgets('Skip hands over the occurrence it was opened on', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-skip'));
      await tester.pumpAndSettle();

      expect(skipped, hasLength(1));
      expect(skipped.single.day, DateTime(2026, 10, 12));
      expect(skipped.single.line.date, DateTime(2026, 10, 5));
    });

    testWidgets('Delete asks which events, and the answer goes with it', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-delete'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.calendarScopeDeleteTitle), findsOne);
      expect(find.text(AppStrings.calendarScopeThis), findsOne);
      expect(find.text(AppStrings.calendarScopeFollowing), findsOne);
      expect(find.text(AppStrings.calendarScopeAll), findsOne);
      expect(deleted, isEmpty, reason: 'nothing written before the answer');

      await tester.tap(key('journal-event-scope-following'));
      await tester.pumpAndSettle();
      expect(deleted, hasLength(1));
      expect(deleted.single.$2, CalendarOccurrenceScope.thisAndFollowing);
      expect(deleted.single.$1.day, DateTime(2026, 10, 12));
    });

    testWidgets('a question dismissed writes nothing', (tester) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-delete'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(deleted, isEmpty);
      expect(key('journal-event-scope'), findsNothing);
    });

    testWidgets('an event that does not repeat is deleted without asking', (
      tester,
    ) async {
      await pump(tester, phone: false, focus: DateTime(2026, 10, 8));
      await rightClick(tester, 'dinner');
      await tester.tap(key('journal-event-delete'));
      await tester.pumpAndSettle();

      expect(key('journal-event-scope'), findsNothing);
      expect(deleted.single.$2, CalendarOccurrenceScope.all);
    });

    testWidgets('Edit asks, then opens the form inline for that scope', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.calendarScopeEditTitle), findsOne);

      await tester.tap(key('journal-event-scope-this'));
      await tester.pumpAndSettle();

      // The form is in the pane, on the occurrence's own day, with its rows
      // off: this one becomes a plain event.
      expect(key('calendar-event-form'), findsOne);
      expect(find.textContaining('12 October'), findsWidgets);
      expect(
        tester
            .widget<TextButton>(key('calendar-event-dialog-repeat'))
            .onPressed,
        isNull,
      );
      final preview = tester.widget<Text>(
        find
            .descendant(
              of: key('calendar-event-preview'),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(
        preview.textSpan?.toPlainText() ?? preview.data,
        contains('2026-10-12'),
      );

      await tester.enterText(key('calendar-event-text'), 'Standup @home');
      await tester.pump();
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();

      expect(edited, hasLength(1));
      expect(edited.single.$3, CalendarOccurrenceScope.thisOne);
      expect(edited.single.$2.text, 'Standup @home');
      expect(edited.single.$2.recurrence, isNull);
      expect(edited.single.$1.line.date, DateTime(2026, 10, 5));
      expect(key('calendar-event-form'), findsNothing);
    });

    testWidgets('Edit for all events keeps the rule on the form', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      await tester.tap(key('journal-event-scope-all'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: key('calendar-event-dialog-repeat'),
          matching: find.text('Every week'),
        ),
        findsOne,
      );
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();
      expect(edited.single.$3, CalendarOccurrenceScope.all);
      expect(edited.single.$2.recurrence!.rule.token, '1w');
      // The rule's tokens are not left in the text the form shows.
      expect(edited.single.$2.text, 'Standup @work');
    });

    testWidgets('Open in calendar.txt goes to the rule line', (tester) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-open'));
      await tester.pumpAndSettle();

      expect(opened.single.lineIndex, 0);
      expect(opened.single.day, DateTime(2026, 10, 12));
    });
  });

  group('the dock form is the event it edits (#1218)', () {
    String typed(WidgetTester tester) =>
        tester.widget<TextField>(key('calendar-event-text')).controller!.text;

    Future<void> editFromMenu(WidgetTester tester, String text) async {
      await rightClick(tester, text);
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
    }

    testWidgets('Edit on another event while one is open starts from it', (
      tester,
    ) async {
      await pump(
        tester,
        phone: false,
        lines: const [
          '2026-10-12 w42 Mon  8 gym.',
          '2026-10-12 w42 Mon  12 lunch with Marta.',
        ],
      );
      await editFromMenu(tester, 'gym');
      expect(typed(tester), 'gym');
      await tester.enterText(key('calendar-event-text'), 'gym, typed over');
      await tester.pump();

      await editFromMenu(tester, 'lunch');
      expect(typed(tester), 'lunch with Marta');
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();

      expect(edited.single.$1.event.text, 'lunch with Marta');
      expect(edited.single.$2.text, 'lunch with Marta');
      expect(edited.single.$2.startMinutes, 12 * 60);
    });

    testWidgets('Add event while an edit is open starts empty', (tester) async {
      await pump(
        tester,
        phone: false,
        lines: const ['2026-10-12 w42 Mon  8 gym.'],
      );
      await editFromMenu(tester, 'gym');
      expect(typed(tester), 'gym');

      await tester.scrollUntilVisible(
        key('journal-add-event'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(key('journal-add-event'));
      await tester.pumpAndSettle();

      expect(typed(tester), isEmpty);
      await tester.enterText(key('calendar-event-text'), 'new');
      await tester.pump();
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();
      expect(added.single.$2.text, 'new');
      expect(edited, isEmpty);
    });
  });

  group('moving, from the form', () {
    /// The text of the preview box: the lines the write would make.
    String preview(WidgetTester tester) => tester
        .widget<Text>(
          find
              .descendant(
                of: key('calendar-event-preview'),
                matching: find.byType(Text),
              )
              .first,
        )
        .textSpan!
        .toPlainText();

    /// Picks [day] of October in the form's own calendar: in place on a
    /// window, in the system's dialog on a phone.
    Future<void> pickDay(
      WidgetTester tester,
      int day, {
      required bool phone,
    }) async {
      await tester.tap(key('calendar-event-day'));
      await tester.pumpAndSettle();
      if (phone) {
        await tester.tap(
          find.descendant(of: find.byType(Dialog), matching: find.text('$day')),
        );
        await tester.tap(find.text('OK'));
      } else {
        await tester.tap(
          find.descendant(
            of: key('calendar-event-day-panel'),
            matching: find.text('$day'),
          ),
        );
      }
      await tester.pumpAndSettle();
    }

    testWidgets('a window moves a plain event, the preview shows both lines', (
      tester,
    ) async {
      await pump(tester, phone: false, focus: DateTime(2026, 10, 8));
      await rightClick(tester, 'dinner');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      // Nothing to ask: there is one of it.
      expect(key('journal-event-scope'), findsNothing);
      expect(
        tester.widget<TextButton>(key('calendar-event-day')).onPressed,
        isNotNull,
      );

      await pickDay(tester, 9, phone: false);
      expect(
        preview(tester),
        '2026-10-08 w41 Thu\n2026-10-09 w41 Fri  18 dinner.',
        reason: 'the day it leaves, and the day it goes to',
      );

      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();
      expect(edited.single.$2.day, DateTime(2026, 10, 9));
      expect(edited.single.$3, CalendarOccurrenceScope.all);
      expect(edited.single.$1.line.date, DateTime(2026, 10, 8));
    });

    testWidgets('a phone moves a plain event with the system date picker', (
      tester,
    ) async {
      await pump(tester, phone: true);
      await openSheet(tester, 8, 'dinner');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      expect(key('journal-event-scope'), findsNothing);

      await pickDay(tester, 9, phone: true);
      expect(find.textContaining('Friday 9 October'), findsWidgets);
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();

      expect(edited.single.$2.day, DateTime(2026, 10, 9));
    });

    testWidgets('a window moves one occurrence: its day is skipped', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      await tester.tap(key('journal-event-scope-this'));
      await tester.pumpAndSettle();

      await pickDay(tester, 14, phone: false);
      expect(
        preview(tester),
        '2026-10-05 w41 Mon  9-9:30 Standup @work rec:1w except:2026-10-12.\n'
        '2026-10-14 w42 Wed  9-9:30 Standup @work.',
      );
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();

      expect(edited.single.$3, CalendarOccurrenceScope.thisOne);
      expect(edited.single.$2.day, DateTime(2026, 10, 14));
      expect(edited.single.$2.recurrence, isNull);
    });

    testWidgets('a phone moves one occurrence the same way', (tester) async {
      await pump(tester, phone: true);
      await openSheet(tester, 19, 'Standup');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      await tester.tap(key('journal-event-scope-this'));
      await tester.pumpAndSettle();

      await pickDay(tester, 21, phone: true);
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();

      expect(edited.single.$3, CalendarOccurrenceScope.thisOne);
      expect(edited.single.$2.day, DateTime(2026, 10, 21));
      expect(edited.single.$1.day, DateTime(2026, 10, 19));
    });

    testWidgets('this and following moves: the draft carries the new day', (
      tester,
    ) async {
      await pump(tester, phone: false);
      await rightClick(tester, 'Standup');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      await tester.tap(key('journal-event-scope-following'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextButton>(key('calendar-event-day')).onPressed,
        isNotNull,
      );
      await pickDay(tester, 14, phone: false);
      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();

      expect(edited.single.$3, CalendarOccurrenceScope.thisAndFollowing);
      expect(edited.single.$2.day, DateTime(2026, 10, 14));
      expect(edited.single.$1.day, DateTime(2026, 10, 12));
    });

    testWidgets(
      'an added event is written on the day the form was changed to',
      (tester) async {
        await pump(tester, phone: false);
        await tester.tap(key('journal-add-event'));
        await tester.pumpAndSettle();
        await pickDay(tester, 15, phone: false);
        await tester.enterText(key('calendar-event-text'), 'lunch');
        await tester.pump();
        await tester.tap(key('calendar-event-save'));
        await tester.pumpAndSettle();

        expect(added.single.$1, DateTime(2026, 10, 15));
        expect(added.single.$2.day, DateTime(2026, 10, 15));
      },
    );
  });

  group('the phone, with a thumb', () {
    testWidgets('a later occurrence has all four rows now', (tester) async {
      await pump(tester, phone: true);
      await openSheet(tester, 19, 'Standup');

      expect(key('journal-event-edit'), findsOne);
      expect(key('journal-event-skip'), findsOne);
      expect(key('journal-event-delete'), findsOne);
      expect(key('journal-event-open'), findsOne);
      expect(
        tester.widget<ListTile>(key('journal-event-skip')).enabled,
        isTrue,
      );
    });

    testWidgets('Skip on a plain event keeps its row, off', (tester) async {
      await pump(tester, phone: true);
      await openSheet(tester, 8, 'dinner');

      expect(
        tester.widget<ListTile>(key('journal-event-skip')).enabled,
        isFalse,
      );
    });

    testWidgets('Skip hands over the occurrence of the day picked', (
      tester,
    ) async {
      await pump(tester, phone: true);
      await openSheet(tester, 19, 'Standup');
      await tester.tap(key('journal-event-skip'));
      await tester.pumpAndSettle();

      expect(skipped.single.day, DateTime(2026, 10, 19));
    });

    testWidgets('Delete asks in a sheet, this and following among its rows', (
      tester,
    ) async {
      await pump(tester, phone: true);
      await openSheet(tester, 19, 'Standup');
      await tester.tap(key('journal-event-delete'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.calendarScopeDeleteTitle), findsOne);
      await tester.tap(key('journal-event-scope-this'));
      await tester.pumpAndSettle();

      expect(deleted.single.$2, CalendarOccurrenceScope.thisOne);
      expect(deleted.single.$1.day, DateTime(2026, 10, 19));
    });

    testWidgets('Edit asks, then the form opens on the occurrence day', (
      tester,
    ) async {
      await pump(tester, phone: true);
      await openSheet(tester, 19, 'Standup');
      await tester.tap(key('journal-event-edit'));
      await tester.pumpAndSettle();
      await tester.tap(key('journal-event-scope-following'));
      await tester.pumpAndSettle();

      expect(key('calendar-event-form'), findsOne);
      expect(find.textContaining('19 October'), findsWidgets);
      // This and following may change the rule.
      expect(
        tester
            .widget<TextButton>(key('calendar-event-dialog-repeat'))
            .onPressed,
        isNotNull,
      );

      await tester.tap(key('calendar-event-save'));
      await tester.pumpAndSettle();
      expect(edited.single.$3, CalendarOccurrenceScope.thisAndFollowing);
      expect(edited.single.$1.day, DateTime(2026, 10, 19));
      expect(edited.single.$2.recurrence!.rule.token, '1w');
    });

    testWidgets('Open in calendar.txt goes to the rule line', (tester) async {
      await pump(tester, phone: true);
      await openSheet(tester, 19, 'Standup');
      await tester.tap(key('journal-event-open'));
      await tester.pumpAndSettle();

      expect(opened.single.lineIndex, 0);
    });
  });
}
