// #1222: a picker or a sheet that answers after the form is gone. The Day
// row, the Ends row and the Repeat row's custom sheet call back into the
// form's state once the user has answered; if the dock closed or the layout
// switched while they were up, that state is disposed and the answer must be
// dropped, not thrown.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/calendar/calendar_recurrence.dart';
import 'package:niman/src/calendar/calendar_writer.dart';
import 'package:niman/src/core/recurrence/recurrence_bounds.dart';
import 'package:niman/src/core/recurrence/recurrence_rule.dart';
import 'package:niman/src/core/recurrence/recurrence_unit.dart';
import 'package:niman/src/ui/calendar_event_form.dart';

void main() {
  final shown = ValueNotifier<bool>(true);

  Future<void> open(WidgetTester tester, {CalendarEventDraft? draft}) async {
    shown.value = true;
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // A phone: the pickers are dialogs and sheets over the form.
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (context, on, _) => on
                ? SingleChildScrollView(
                    child: CalendarEventForm(
                      day: DateTime(2026, 10, 12),
                      knownTokens: const <String>{},
                      draft: draft,
                      preview: calendarEventAsText,
                      onCancel: () {},
                      onSave: (_) {},
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  /// The form goes while a dialog or a sheet is still up.
  Future<void> closeForm(WidgetTester tester) async {
    shown.value = false;
    await tester.pump();
    expect(find.byType(CalendarEventForm), findsNothing);
  }

  final weekly = CalendarEventDraft(
    text: 'standup',
    startMinutes: 9 * 60,
    recurrence: CalendarRecurrence(
      rule: RecurrenceRule(unit: RecurrenceUnit.week),
      bounds: RecurrenceBounds(),
    ),
  );

  testWidgets('a day picked after the form is gone is dropped', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('calendar-event-day')));
    await tester.pumpAndSettle();
    await closeForm(tester);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('15')),
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('an end picked after the form is gone is dropped', (
    tester,
  ) async {
    await open(tester, draft: weekly);
    await tester.tap(find.byKey(const Key('calendar-event-ends')));
    await tester.pumpAndSettle();
    await closeForm(tester);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('20')),
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a custom rule answered after the form is gone is dropped', (
    tester,
  ) async {
    await open(tester, draft: weekly);
    await tester.tap(find.byKey(const Key('calendar-event-dialog-repeat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calendar-event-repeat-custom')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-event-repeat-sheet')), findsOne);
    await closeForm(tester);

    await tester.tap(find.byKey(const Key('calendar-event-repeat-sheet-ok')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
