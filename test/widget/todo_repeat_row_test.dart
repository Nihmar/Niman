// #1189: the task dialog's Repeat row reads and writes the `rec:` tag of the
// line, with the presets, and Custom in place on a desktop or in a sheet on
// a phone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';

void main() {
  final field = find.byKey(const Key('todo-dialog-field'));
  final row = find.byKey(const Key('todo-dialog-repeat'));

  /// Opens the dialog in a window [width] wide, on [initial] when given;
  /// the returned getter reads what it resolved to.
  Future<String? Function()> open(
    WidgetTester tester, {
    double width = 1200,
    String? initial,
    DateTime? due,
    TargetPlatform platform = TargetPlatform.windows,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showTodoTaskDialog(
                  context,
                  today: DateTime(2026, 9, 7),
                  initial: initial == null ? null : parseTodoLine(initial),
                  due: due,
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

  String text(WidgetTester tester) =>
      tester.widget<TextField>(field).controller!.text;

  Future<void> save(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await tester.pumpAndSettle();
  }

  Future<void> pickFromMenu(WidgetTester tester, Key item) async {
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(item));
    await tester.pumpAndSettle();
  }

  testWidgets('a new task repeats never, and writes no rec:', (tester) async {
    final result = await open(tester);
    expect(find.descendant(of: row, matching: find.text('Never')), findsOne);
    await tester.enterText(field, 'water the plants');
    await save(tester);
    expect(result(), '2026-09-07 water the plants');
  });

  testWidgets('a preset writes its rec: into the line', (tester) async {
    final result = await open(tester);
    await tester.enterText(field, 'water the plants');
    await pickFromMenu(tester, const Key('todo-repeat-preset-1'));
    expect(text(tester), 'water the plants rec:1b');
    expect(
      find.descendant(of: row, matching: find.text('Every weekday')),
      findsOne,
    );
    await save(tester);
    expect(result(), '2026-09-07 water the plants rec:1b');
  });

  testWidgets('Weekly is on the weekday of the due date', (tester) async {
    // 2026-09-09 is a Wednesday.
    await open(tester, due: DateTime(2026, 9, 9));
    await tester.enterText(field, 'water');
    await pickFromMenu(tester, const Key('todo-repeat-preset-2'));
    expect(text(tester), 'water rec:1w;we');
    expect(
      find.descendant(of: row, matching: find.text('Every week on Wed')),
      findsOne,
    );
  });

  testWidgets('a rec: typed in the text shows in the row', (tester) async {
    await open(tester);
    await tester.enterText(field, 'gym rec:+2w');
    await tester.pump();
    expect(
      find.descendant(
        of: row,
        matching: find.text('Every 2 weeks from the due date'),
      ),
      findsOne,
    );
  });

  testWidgets('a rec: nothing reads shows as written', (tester) async {
    await open(tester);
    await tester.enterText(field, 'gym rec:often');
    await tester.pump();
    expect(
      find.descendant(of: row, matching: find.text('rec:often')),
      findsOne,
    );
  });

  testWidgets('Never, or the clear button, takes the rec: out', (tester) async {
    final result = await open(tester, initial: 'gym rec:1w due:2026-09-10');
    expect(
      find.descendant(of: row, matching: find.text('Every week')),
      findsOne,
    );
    await tester.tap(find.byKey(const Key('todo-dialog-repeat-clear')));
    await tester.pump();
    expect(text(tester), 'gym due:2026-09-10');
    await save(tester);
    expect(result(), 'gym due:2026-09-10');
  });

  testWidgets('Custom opens in place on a desktop and writes as it goes', (
    tester,
  ) async {
    final result = await open(tester);
    await tester.enterText(field, 'standup');
    await pickFromMenu(tester, const Key('todo-repeat-custom'));
    // Opening it sets the rule it shows: every day.
    expect(text(tester), 'standup rec:1d');
    expect(find.byKey(const Key('todo-repeat-interval')), findsOne);

    await tester.tap(find.byKey(const Key('todo-repeat-unit-week')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('todo-repeat-interval')), '2');
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-repeat-weekday-1')));
    await tester.tap(find.byKey(const Key('todo-repeat-weekday-3')));
    await tester.tap(find.byKey(const Key('todo-repeat-from-due')));
    await tester.pump();
    expect(text(tester), 'standup rec:+2w;mo,we');
    expect(
      tester.widget<Text>(find.byKey(const Key('todo-repeat-summary'))).data,
      'Every 2 weeks on Mon, Wed from the due date',
    );
    await save(tester);
    expect(result(), '2026-09-07 standup rec:+2w;mo,we');
  });

  testWidgets('a monthly rule can be on the Nth weekday of the due date', (
    tester,
  ) async {
    // 2026-09-08 is the second Tuesday of September.
    await open(tester, due: DateTime(2026, 9, 8));
    await tester.enterText(field, 'review');
    await pickFromMenu(tester, const Key('todo-repeat-custom'));
    await tester.tap(find.byKey(const Key('todo-repeat-unit-month')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-repeat-month-2tu')));
    await tester.pump();
    expect(text(tester), 'review rec:1m;2tu');
    await tester.tap(find.byKey(const Key('todo-repeat-month--1tu')));
    await tester.pump();
    expect(text(tester), 'review rec:1m;-1tu');
    await tester.tap(find.byKey(const Key('todo-repeat-month-date')));
    await tester.pump();
    expect(text(tester), 'review rec:1m');
  });

  testWidgets('a phone edits Custom in a sheet and answers with OK', (
    tester,
  ) async {
    final result = await open(
      tester,
      width: 400,
      platform: TargetPlatform.android,
    );
    await tester.enterText(field, 'rent');
    await pickFromMenu(tester, const Key('todo-repeat-custom'));
    expect(find.byKey(const Key('todo-repeat-sheet')), findsOne);
    // Nothing is written while the sheet is open.
    await tester.tap(find.byKey(const Key('todo-repeat-unit-month')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-repeat-from-due')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('todo-repeat-sheet-ok')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('todo-repeat-sheet')), findsNothing);
    expect(text(tester), 'rent rec:+1m');
    await save(tester);
    expect(result(), '2026-09-07 rent rec:+1m');
  });
}
