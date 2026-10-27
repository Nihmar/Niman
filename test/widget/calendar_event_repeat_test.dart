// #1191: the event form's Repeat and Ends rows — Never and the presets, the
// custom editor in place on a window or in a sheet on a phone, an end on a
// date — and what they leave in the draft the form hands over: a rule with
// its end and the days it skips, or none.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_occurrence_edits.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/ui/calendar_event_form.dart';

void main() {
  CalendarEventDraft? saved;

  setUp(() => saved = null);

  /// The form for Monday 12 October 2026, on a window or a phone.
  Future<void> open(
    WidgetTester tester, {
    CalendarEventDraft? draft,
    CalendarOccurrenceScope? scope,
    TargetPlatform platform = TargetPlatform.windows,
    double width = 1200,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarEventForm(
              day: DateTime(2026, 10, 12),
              knownTokens: const <String>{},
              draft: draft,
              scope: scope,
              preview: calendarEventAsText,
              onCancel: () {},
              onSave: (value) => saved = value,
            ),
          ),
        ),
      ),
    );
  }

  final repeat = find.byKey(const Key('calendar-event-dialog-repeat'));
  final ends = find.byKey(const Key('calendar-event-ends'));

  Future<void> pick(WidgetTester tester, Key item) async {
    await tester.tap(repeat);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(item));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('calendar-event-save')));
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('calendar-event-text')), text);
    await tester.pump();
  }

  bool enabled(WidgetTester tester, Finder button) =>
      tester.widget<TextButton>(button).onPressed != null;

  testWidgets('a new event repeats never, and its end waits for a rule', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'standup');

    expect(find.descendant(of: repeat, matching: find.text('Never')), findsOne);
    expect(find.text('Never ends'), findsOne);
    expect(enabled(tester, repeat), isTrue);
    expect(enabled(tester, ends), isFalse, reason: 'no rule to end yet');

    await save(tester);
    expect(saved!.recurrence, isNull);
  });

  testWidgets('the menu lists what an event can repeat by', (tester) async {
    await open(tester);
    await tester.tap(repeat);
    await tester.pumpAndSettle();

    expect(find.text('Every day'), findsOne);
    expect(find.text('Every weekday'), findsOne);
    expect(find.text('Every week on Mon'), findsOne);
    expect(find.text('Every month'), findsOne);
    expect(find.text('Every month on the 2nd Monday'), findsOne);
    expect(find.text('Every year'), findsOne);
    expect(find.byKey(const Key('calendar-event-repeat-custom')), findsOne);
  });

  testWidgets('a preset is the rule the draft carries', (tester) async {
    await open(tester);
    await type(tester, 'standup');
    await pick(tester, const Key('calendar-event-repeat-preset-2'));

    expect(
      find.descendant(of: repeat, matching: find.text('Every week on Mon')),
      findsOne,
    );
    expect(enabled(tester, ends), isTrue);

    await save(tester);
    expect(saved!.recurrence!.rule.token, '1w;mo');
    expect(saved!.recurrence!.bounds.until, isNull);
    expect(saved!.text, 'standup');
  });

  testWidgets('monthly can be on the Nth weekday of the day it starts', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'book club');
    await pick(tester, const Key('calendar-event-repeat-preset-4'));
    await save(tester);
    expect(saved!.recurrence!.rule.token, '1m;2mo');
  });

  testWidgets('no preset counts from a completion: none is strict', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'x');
    await pick(tester, const Key('calendar-event-repeat-preset-3'));
    await save(tester);
    expect(saved!.recurrence!.rule.strict, isFalse);
    expect(saved!.recurrence!.rule.token, '1m');
  });

  testWidgets('Never takes the rule, and its end, away', (tester) async {
    await open(
      tester,
      draft: CalendarEventDraft(
        text: 'standup',
        recurrence: CalendarRecurrence(
          rule: RecurrenceRule.parse('1w')!,
          bounds: RecurrenceBounds(until: DateTime(2026, 12, 31)),
        ),
      ),
    );
    expect(find.text('Ends on 2026-12-31'), findsOne);

    await tester.tap(
      find.byKey(const Key('calendar-event-dialog-repeat-clear')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Never ends'), findsOne);
    expect(enabled(tester, ends), isFalse);

    await save(tester);
    expect(saved!.recurrence, isNull);
  });

  testWidgets('the end is a date from the first day on', (tester) async {
    await open(tester);
    await type(tester, 'standup');
    await pick(tester, const Key('calendar-event-repeat-preset-2'));

    await tester.tap(ends);
    await tester.pumpAndSettle();
    await tester.tap(find.text('30'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Ends on 2026-10-30'), findsOne);

    await save(tester);
    expect(saved!.recurrence!.bounds.until, DateTime(2026, 10, 30));

    // And it can be taken back.
    await tester.tap(find.byKey(const Key('calendar-event-ends-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Never ends'), findsOne);
  });

  testWidgets('an edit starts from the rule, and keeps the days it skips', (
    tester,
  ) async {
    final skipped = {DateTime(2026, 10, 19), DateTime(2026, 11, 2)};
    await open(
      tester,
      draft: CalendarEventDraft(
        text: 'standup',
        recurrence: CalendarRecurrence(
          rule: RecurrenceRule.parse('1w;mo')!,
          bounds: RecurrenceBounds(except: skipped),
        ),
      ),
      scope: CalendarOccurrenceScope.all,
    );
    expect(
      find.descendant(of: repeat, matching: find.text('Every week on Mon')),
      findsOne,
    );

    await type(tester, 'planning');
    await save(tester);
    expect(saved!.recurrence!.rule.token, '1w;mo');
    expect(saved!.recurrence!.bounds.except, skipped);
  });

  testWidgets('one occurrence only is a plain event: the rows are off', (
    tester,
  ) async {
    await open(
      tester,
      draft: CalendarEventDraft(
        text: 'standup',
        recurrence: CalendarRecurrence(
          rule: RecurrenceRule.parse('1w')!,
          bounds: RecurrenceBounds.none,
        ),
      ),
      scope: CalendarOccurrenceScope.thisOne,
    );

    expect(find.descendant(of: repeat, matching: find.text('Never')), findsOne);
    expect(enabled(tester, repeat), isFalse);
    expect(enabled(tester, ends), isFalse);
    // They keep their place all the same.
    expect(repeat, findsOne);
    expect(ends, findsOne);

    await save(tester);
    expect(saved!.recurrence, isNull);
    expect(saved!.text, 'standup');
  });

  testWidgets('Custom edits in place on a window, with no due date to count '
      'from', (tester) async {
    await open(tester);
    await type(tester, 'standup');
    await pick(tester, const Key('calendar-event-repeat-custom'));

    expect(find.byKey(const Key('calendar-event-repeat-interval')), findsOne);
    expect(
      find.byKey(const Key('calendar-event-repeat-from-due')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('calendar-event-repeat-from-completion')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const Key('calendar-event-repeat-interval')),
      '2',
    );
    await tester.tap(find.byKey(const Key('calendar-event-repeat-unit-week')));
    await tester.pump();
    await save(tester);
    expect(saved!.recurrence!.rule.token, '2w');
  });

  testWidgets('a preset picked with the editor open is what the chips show '
      '(#1220)', (tester) async {
    await open(tester);
    await type(tester, 'standup');
    await pick(tester, const Key('calendar-event-repeat-custom'));
    // The editor opened on every day; Monthly on the date is picked from the
    // menu under it.
    await tester.enterText(
      find.byKey(const Key('calendar-event-repeat-interval')),
      '2',
    );
    await tester.tap(find.byKey(const Key('calendar-event-repeat-unit-week')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-event-repeat-weekday-1')));
    await tester.pump();
    await pick(tester, const Key('calendar-event-repeat-preset-3'));

    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const Key('calendar-event-repeat-unit-month')),
          )
          .selected,
      isTrue,
      reason: 'the chips follow the menu',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('calendar-event-repeat-interval')),
          )
          .controller!
          .text,
      '1',
    );
    expect(
      find.byKey(const Key('calendar-event-repeat-weekday-1')),
      findsNothing,
      reason: 'a monthly rule has no weekday chips',
    );

    // A chip tap builds on the menu's choice, not on the stale chips.
    await tester.tap(find.byKey(const Key('calendar-event-repeat-month--1mo')));
    await tester.pump();
    await save(tester);
    expect(saved!.recurrence!.rule.token, '1m;-1mo');
  });

  testWidgets('Custom is a sheet on a phone, and OK answers with its rule', (
    tester,
  ) async {
    await open(tester, platform: TargetPlatform.android, width: 420);
    await type(tester, 'standup');
    await pick(tester, const Key('calendar-event-repeat-custom'));

    expect(find.byKey(const Key('calendar-event-repeat-sheet')), findsOne);
    await tester.tap(find.byKey(const Key('calendar-event-repeat-unit-month')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('calendar-event-repeat-sheet-ok')));
    await tester.pumpAndSettle();

    await save(tester);
    expect(saved!.recurrence!.rule.token, '1m');
  });
}
