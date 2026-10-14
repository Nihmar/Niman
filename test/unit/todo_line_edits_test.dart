// #712: a pointer's row menu sets one field of a task and keeps the rest.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/line_edits.dart';
import 'package:niman/src/todo/parser.dart';

void main() {
  final task = parseTodoLine(
    '(B) 2026-10-01 Call Ada +work @phone due:2026-10-05 rem:2026-10-04T09:00',
  );

  test('the due date is set, moved and cleared; nothing else moves', () {
    expect(
      todoLineWithDue(task, DateTime(2026, 10, 14)),
      '(B) 2026-10-01 Call Ada +work @phone rem:2026-10-04T09:00 '
      'due:2026-10-14',
    );
    expect(
      todoLineWithDue(parseTodoLine('Buy milk'), DateTime(2026, 10, 14)),
      'Buy milk due:2026-10-14',
    );
    expect(
      todoLineWithDue(task, null),
      '(B) 2026-10-01 Call Ada +work @phone rem:2026-10-04T09:00',
    );
  });

  test('the priority is set and cleared', () {
    expect(
      todoLineWithPriority(task, 'A'),
      '(A) 2026-10-01 Call Ada +work @phone due:2026-10-05 '
      'rem:2026-10-04T09:00',
    );
    expect(
      todoLineWithPriority(task, null),
      '2026-10-01 Call Ada +work @phone due:2026-10-05 rem:2026-10-04T09:00',
    );
  });

  test('the text is replaced, a done task stays done', () {
    final done = parseTodoLine('x 2026-10-10 2026-10-01 Old text +work');
    expect(
      todoLineWithText(done, 'New text +home'),
      'x 2026-10-10 2026-10-01 New text +home',
    );
  });
}
