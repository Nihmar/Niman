// #267: the task description wraps and grows downward, stays a single
// line of the task file, and the dialog is wider on a wide window.
// #268: with the room, the due date and the reminder are picked in place.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/reminder_health.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';

void main() {
  final field = find.byKey(const Key('todo-dialog-field'));

  /// Opens the add dialog in a window [width] wide; the returned getter
  /// reads what it resolved to.
  Future<String? Function()> open(
    WidgetTester tester, {
    double width = 400,
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTodoTaskDialog(
                  context,
                  today: DateTime(2026, 9, 7),
                );
              },
              child: const Text('open dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('a long description grows downward', (tester) async {
    await open(tester);
    final oneLine = tester.getSize(field).height;
    await tester.enterText(
      field,
      'call the plumber about the kitchen sink ' * 4,
    );
    await tester.pump();
    expect(tester.getSize(field).height, greaterThan(oneLine * 1.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('it grows only so far, then scrolls inside itself', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(field, 'word ' * 400);
    await tester.pump();
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.maxLines, 6);
  });

  testWidgets('Enter saves rather than breaking the line', (tester) async {
    final result = await open(tester);
    await tester.enterText(field, 'water the plants');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result(), '2026-09-07 water the plants');
  });

  testWidgets('a line break that comes in becomes a space', (tester) async {
    final result = await open(tester);
    await tester.enterText(field, 'first\nsecond');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'first second');
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await tester.pumpAndSettle();
    expect(result(), '2026-09-07 first second');
  });

  testWidgets('a wide window gives the dialog more width', (tester) async {
    await open(tester, width: 1200);
    final wide = tester.getSize(find.byType(AlertDialog)).width;
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await open(tester);
    final narrow = tester.getSize(find.byType(AlertDialog)).width;
    expect(wide, greaterThan(narrow + 100));
    expect(narrow, lessThanOrEqualTo(400));
  });

  group('dates in place (#268)', () {
    Future<String? Function()> openDesk(WidgetTester tester) =>
        open(tester, width: 1200);

    Future<void> tapDay(WidgetTester tester, String day) async {
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text(day),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the due date is a calendar under its row', (tester) async {
      final result = await openDesk(tester);
      await tester.enterText(field, 'pay rent');
      await tester.tap(find.byKey(const Key('todo-dialog-due')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(CalendarDatePicker),
        ),
        findsOne,
      );
      await tapDay(tester, '21');
      // Picked: the calendar folds away and the row says the date.
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(find.text('2026-09-21'), findsOne);
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await tester.pumpAndSettle();
      expect(result(), '2026-09-07 pay rent due:2026-09-21');
    });

    testWidgets('the reminder takes its day and time in one place', (
      tester,
    ) async {
      final result = await openDesk(tester);
      await tester.enterText(field, 'call mum');
      await tester.tap(find.byKey(const Key('todo-dialog-reminder')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      await tapDay(tester, '21');
      // A day alone is not a reminder yet: the panel stays for the time.
      expect(find.byType(CalendarDatePicker), findsOne);
      await tester.enterText(
        find.byKey(const Key('todo-reminder-time')),
        '14:30',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('todo-reminder-set')));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(find.byType(CalendarDatePicker), findsNothing);
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await tester.pumpAndSettle();
      expect(result(), '2026-09-07 call mum rem:2026-09-21T14:30');
    });

    testWidgets('a time that is not one cannot be set', (tester) async {
      await openDesk(tester);
      await tester.tap(find.byKey(const Key('todo-dialog-reminder')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('todo-reminder-time')),
        '25:00',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('todo-reminder-set')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('one calendar at a time, and a second tap closes it', (
      tester,
    ) async {
      await openDesk(tester);
      await tester.tap(find.byKey(const Key('todo-dialog-due')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('todo-dialog-reminder')));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOne);
      expect(find.byKey(const Key('todo-reminder-time')), findsOne);
      await tester.tap(find.byKey(const Key('todo-dialog-reminder')));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);
    });

    testWidgets('a phone keeps the system picker', (tester) async {
      await open(tester, height: 800);
      await tester.tap(find.byKey(const Key('todo-dialog-due')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOne);
    });

    testWidgets('so does a phone on its side', (tester) async {
      await open(tester, width: 800, height: 400);
      await tester.ensureVisible(find.byKey(const Key('todo-dialog-due')));
      await tester.tap(find.byKey(const Key('todo-dialog-due')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOne);
    });
  });

  // T-TD-07: a reminder scheduled while a precondition fails is warned
  // about where it is set, not only in the Todo tab's banner.
  group('a reminder that cannot reach the user', () {
    Future<ValueNotifier<int>> openWithHealth(
      WidgetTester tester,
      ReminderHealth health,
    ) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final opened = ValueNotifier<int>(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showTodoTaskDialog(
                  context,
                  today: DateTime(2026, 9, 7),
                  initial: parseTodoLine('call rem:2026-09-08T09:00'),
                  health: health,
                  onOpenReminderSettings: () async {
                    opened.value++;
                    return true;
                  },
                ),
                child: const Text('open dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open dialog'));
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('is warned about under the reminder, with a way out', (
      tester,
    ) async {
      final opened = await openWithHealth(
        tester,
        ReminderHealth.batteryRestricted,
      );

      expect(find.byKey(const Key('todo-dialog-reminder-warning')), findsOne);
      final fix = find.byKey(const Key('todo-dialog-reminder-settings'));
      expect(fix, findsOne);
      await tester.tap(fix);
      await tester.pump();
      expect(opened.value, 1);
    });

    testWidgets('is not warned about while the preconditions hold', (
      tester,
    ) async {
      await openWithHealth(tester, ReminderHealth.ok);
      expect(
        find.byKey(const Key('todo-dialog-reminder-warning')),
        findsNothing,
      );
    });
  });
}
