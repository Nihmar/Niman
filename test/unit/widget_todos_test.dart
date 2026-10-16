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

  group('widgetTodoSections', () {
    // Wednesday 2026-10-14: next 7 days run through 2026-10-21.
    final today = DateTime(2026, 10, 14);

    String label(String id) => 'L:$id';

    test('groups like the tab sorted by due date, empty ones hidden', () {
      final sections = widgetTodoSections(
        snapshot([
          'undated',
          'far due:2027-01-01',
          'week due:2026-10-20',
          'now due:2026-10-14',
          'late due:2026-10-01',
        ]),
        labelOf: label,
        today: today,
      );
      expect(
        [for (final s in sections) s.id],
        ['due.overdue', 'due.today', 'due.next7', 'due.later', 'due.none'],
      );
      expect(
        [for (final s in sections) s.label],
        [
          'L:due.overdue',
          'L:due.today',
          'L:due.next7',
          'L:due.later',
          'L:due.none',
        ],
      );
      expect(sections.map((s) => s.count), everyElement(1));

      final sparse = widgetTodoSections(
        snapshot(['now due:2026-10-14', 'undated']),
        labelOf: label,
        today: today,
      );
      expect([for (final s in sparse) s.id], ['due.today', 'due.none']);
      expect(widgetTodoSections(snapshot([]), labelOf: label), isEmpty);
    });

    test('blank lines and the done file never reach a section', () {
      final sections = widgetTodoSections(
        TodoSnapshot(
          todo: <TodoEntry>[
            TodoEntry(lineIndex: 0, task: parseTodoLine('   ')),
            TodoEntry(lineIndex: 1, task: parseTodoLine('open')),
          ],
          done: <TodoEntry>[
            TodoEntry(lineIndex: 0, task: parseTodoLine('x 2026-10-01 done')),
          ],
        ),
        labelOf: label,
        today: today,
      );
      expect(sections.single.id, 'due.none');
      expect(descriptions(sections.single.entries), ['open']);
    });

    test('the cap trims entries but a count stays the true count', () {
      final lines = <String>[
        for (var i = 0; i < 7; i++) 'late $i due:2026-10-01',
        for (var i = 0; i < 4; i++) 'now $i due:2026-10-14',
        for (var i = 0; i < 5; i++) 'free $i',
      ];
      final sections = widgetTodoSections(
        snapshot(lines),
        labelOf: label,
        today: today,
        limit: 9,
      );
      // Seven overdue, two of the four today; the undated ones are cut,
      // and a section left with no entry is dropped (no bare header).
      expect([for (final s in sections) s.id], ['due.overdue', 'due.today']);
      expect([for (final s in sections) s.count], [7, 4]);
      expect([for (final s in sections) s.entries.length], [7, 2]);
    });

    test('a cap landing on a section edge leaves no empty section', () {
      final sections = widgetTodoSections(
        snapshot(['late due:2026-10-01', 'now due:2026-10-14']),
        labelOf: label,
        today: today,
        limit: 1,
      );
      expect([for (final s in sections) s.id], ['due.overdue']);
    });
  });
}
