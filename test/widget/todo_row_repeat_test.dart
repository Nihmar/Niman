// #1189: a task row says what the task repeats by, beside its due date.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/ui/todo_row.dart';

void main() {
  Future<void> show(WidgetTester tester, String line, {bool done = false}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoRowSubtitle(
            task: parseTodoLine(line),
            today: DateTime(2026, 9, 7),
            done: done,
          ),
        ),
      ),
    );
  }

  final label = find.byKey(const Key('todo-row-repeat'));

  testWidgets('the repeat icon and the rule sit beside the due date', (
    tester,
  ) async {
    await show(tester, 'water rec:2w due:2026-09-10');
    expect(find.text('Due 10 Sep'), findsOne);
    expect(label, findsOne);
    expect(find.text('every 2 weeks'), findsOne);
    expect(
      find.descendant(of: label, matching: find.byIcon(Icons.repeat)),
      findsOne,
    );
  });

  testWidgets('weekdays and the Nth weekday read in words', (tester) async {
    await show(tester, 'gym rec:1w;mo,we');
    expect(find.text('every week on Mon, Wed'), findsOne);
    await show(tester, 'review rec:1m;-1fr');
    expect(find.text('every month on the last Friday'), findsOne);
  });

  testWidgets('no repeat for a plain task, an unreadable rec: or a done row', (
    tester,
  ) async {
    await show(tester, 'water due:2026-09-10');
    expect(label, findsNothing);
    await show(tester, 'water rec:often');
    expect(label, findsNothing);
    await show(tester, 'x 2026-09-07 water rec:1w', done: true);
    expect(label, findsNothing);
  });
}
