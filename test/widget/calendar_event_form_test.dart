// #730 phase 3: the Add event form — the time, the text with the tokens a
// tap away, the reminder by lead time, the line as it will be written, and
// the draft it hands over.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
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
    await tester.pumpWidget(buildApp());
    await tester.enterText(find.byKey(const Key('calendar-event-text')), 'a');
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-event-remind')));
    await tester.pump();
    await tester.tap(saveButton());

    final start = saved!.startMinutes!;
    expect(saved!.reminderMinutes, start - 15);
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
