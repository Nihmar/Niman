// Widget ordering (issue 6): open todos due-first/priority-tied, blanks
// dropped, row cap honored.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';

void main() {
  TodoSnapshot snapshot(List<String> lines) {
    return TodoSnapshot(
      todo: <TodoEntry>[
        for (var i = 0; i < lines.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
      ],
      done: const <TodoEntry>[],
    );
  }

  List<String> descriptions(List<TodoEntry> kept) {
    return <String>[for (final e in kept) e.task.description];
  }

  group('sortTodosForWidget', () {
    test('orders by due, undated last', () {
      final sorted = sortTodosForWidget(
        snapshot([
          'undated',
          'later due:2026-09-20',
          'sooner due:2026-09-08',
          'overdue due:2026-09-01',
        ]),
      );
      expect(descriptions(sorted), [
        'overdue due:2026-09-01',
        'sooner due:2026-09-08',
        'later due:2026-09-20',
        'undated',
      ]);
    });

    test('priority breaks due ties, unprioritized last', () {
      final sorted = sortTodosForWidget(
        snapshot([
          'plain due:2026-09-10',
          '(B) second due:2026-09-10',
          '(A) first due:2026-09-10',
        ]),
      );
      expect(descriptions(sorted), [
        'first due:2026-09-10',
        'second due:2026-09-10',
        'plain due:2026-09-10',
      ]);
    });

    test('drops blank lines like the tab does', () {
      final sorted = sortTodosForWidget(
        snapshot(['real task', '', '   ', 'another due:2026-09-10']),
      );
      expect(descriptions(sorted), ['another due:2026-09-10', 'real task']);
    });

    test('ties fall back to file order', () {
      final sorted = sortTodosForWidget(snapshot(['second', 'first']));
      expect(descriptions(sorted), ['second', 'first']);
    });

    test('caps rows at the limit', () {
      final lines = <String>[
        for (var i = 0; i < widgetTodoLimit + 5; i++) 'task $i',
      ];
      expect(sortTodosForWidget(snapshot(lines)), hasLength(widgetTodoLimit));
      expect(sortTodosForWidget(snapshot(lines), limit: 3), hasLength(3));
    });
  });
}
