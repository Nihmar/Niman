// #730 phase 3: the Add event form — the time, the text with the tokens a
// tap away, the reminder by lead time, the line as it will be written, and
// the draft it hands over.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/ui/app_switch.dart';
import 'package:niman/src/ui/calendar_event_form.dart';

void main() {
  CalendarEventDraft? saved;
  var cancelled = 0;

  setUp(() {
    saved = null;
    cancelled = 0;
  });

  Widget buildApp({
    CalendarEventDraft? draft,
    Set<String> tokens = const <String>{},
    String preview = '2026-10-12 w42 Mon  15-16 meeting with Luca.',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CalendarEventForm(
            day: DateTime(2026, 10, 12),
            knownTokens: tokens,
            draft: draft,
            preview: (_) => preview,
            onCancel: () => cancelled++,
            onSave: (value) => saved = value,
          ),
        ),
      ),
    );
  }

  Finder saveButton() => find.byKey(const Key('calendar-event-save'));
  Finder remindSwitch() => find.byKey(const Key('calendar-event-remind'));

  testWidgets('nothing to write keeps Add out of reach', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

    await tester.enterText(find.byKey(const Key('calendar-event-text')), 'me');
    await tester.pump();
    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
  });

  testWidgets('a start time is offered; taking it back makes it untimed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    // The next whole hour, so an added event is never written untimed by
    // accident.
    final now = DateTime.now();
    final expected = ((now.hour + 1) % 24) * 60;
    await tester.enterText(find.byKey(const Key('calendar-event-text')), 'a');
    await tester.pump();
    await tester.tap(saveButton());
    expect(saved!.startMinutes, expected);

    final clear = find.byKey(const Key('calendar-event-start-clear'));
    await tester.tap(clear);
    await tester.pump();
    await tester.tap(saveButton());
    expect(saved!.startMinutes, isNull);
    expect(saved!.reminderMinutes, isNull);
  });

  testWidgets('the clock picker sets the end', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.byKey(const Key('calendar-event-end')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOne);
    await tester.tap(
      find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-event-end-clear')), findsNothing);
  });

  testWidgets('the preview is the line the writer would make', (tester) async {
    await tester.pumpWidget(buildApp(tokens: const {'+thesis'}));
    await tester.enterText(
      find.byKey(const Key('calendar-event-text')),
      'meeting with Luca',
    );
    await tester.pump();

    final preview = find.byKey(const Key('calendar-event-preview'));
    expect(preview, findsOne);
    expect(
      find.descendant(
        of: preview,
        matching: find.textContaining('meeting with Luca'),
      ),
      findsOne,
    );
    expect(find.text('The line, as it will be written'), findsOne);
  });

  testWidgets('a suggestion writes the token into the text', (tester) async {
    await tester.pumpWidget(buildApp(tokens: const {'+thesis', '@uni'}));
    await tester.tap(find.byKey(const Key('calendar-event-suggest-+thesis')));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('calendar-event-text')),
    );
    expect(field.controller!.text, contains('+thesis'));
    // Suggested once, and the pool keeps the other.
    expect(
      find.byKey(const Key('calendar-event-suggest-+thesis')),
      findsNothing,
    );
    expect(find.byKey(const Key('calendar-event-suggest-@uni')), findsOne);
  });

  testWidgets('the token buttons start a token of their own', (tester) async {
    await tester.pumpWidget(buildApp(tokens: const {'@uni'}));
    await tester.enterText(find.byKey(const Key('calendar-event-text')), 'a');
    await tester.pump();
    await tester.tap(find.text('@ Context'));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('calendar-event-text')),
    );
    expect(field.controller!.text, 'a @ ');
    expect(find.byKey(const Key('calendar-event-suggest-@uni')), findsOne);
  });

  testWidgets('Remind me is a lead time before the start', (tester) async {
    // A start with room for the lead: at 23:00 the next whole hour is
    // midnight, and a reminder that lands on the day before is not
    // written, so the wall clock must not decide this case.
    await tester.pumpWidget(
      buildApp(
        draft: const CalendarEventDraft(text: 'a', startMinutes: 9 * 60),
      ),
    );
    await tester.tap(find.byKey(const Key('calendar-event-remind')));
    await tester.pump();
    await tester.tap(saveButton());

    expect(saved!.startMinutes, 9 * 60);
    expect(saved!.reminderMinutes, 9 * 60 - 15);
  });

  testWidgets('a lead that would land before midnight is shortened (#1226)', (
    tester,
  ) async {
    // Ten minutes past midnight: the default fifteen would be yesterday's,
    // which a calendar line's clock `rem:` cannot say. The form says what it
    // writes instead of switching the reminder on and dropping it.
    await tester.pumpWidget(
      buildApp(draft: const CalendarEventDraft(text: 'a', startMinutes: 10)),
    );
    await tester.tap(find.byKey(const Key('calendar-event-remind')));
    await tester.pump();
    expect(tester.widget<AppSwitch>(remindSwitch()).value, isTrue);
    await tester.tap(saveButton());

    expect(saved!.reminderMinutes, 0, reason: 'ten minutes before, at most');
  });

  testWidgets('at midnight no reminder can be set (#1226)', (tester) async {
    await tester.pumpWidget(
      buildApp(draft: const CalendarEventDraft(text: 'a', startMinutes: 0)),
    );
    final remind = tester.widget<AppSwitch>(remindSwitch());
    expect(remind.onChanged, isNull);
    expect(remind.value, isFalse);
    await tester.tap(saveButton());
    expect(saved!.reminderMinutes, isNull);
  });

  testWidgets('an edit starts from the event it edits', (tester) async {
    await tester.pumpWidget(
      buildApp(
        draft: const CalendarEventDraft(
          text: 'thesis chapter 3 +thesis',
          startMinutes: 9 * 60,
          endMinutes: 12 * 60,
          reminderMinutes: 8 * 60 + 45,
        ),
      ),
    );
    await tester.tap(saveButton());

    expect(saved!.text, 'thesis chapter 3 +thesis');
    expect(saved!.startMinutes, 9 * 60);
    expect(saved!.endMinutes, 12 * 60);
    expect(saved!.reminderMinutes, 8 * 60 + 45, reason: '15 min before 9');
  });

  testWidgets('Cancel writes nothing', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byKey(const Key('calendar-event-text')), 'a');
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-event-cancel')));
    await tester.pump();

    expect(cancelled, 1);
    expect(saved, isNull);
  });
}
