// T-TD-05 AC: filter combos narrow the list, counts rank by task
// count, sort orders place nulls last with line-index determinism.
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_filter.dart';
import 'package:copist/src/todo/todo_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Fixed "today" for range tests.
  final today = DateTime(2026, 9, 7);

  TodoEntry entry(int index, String line) {
    return TodoEntry(lineIndex: index, task: parseTodoLine(line));
  }

  List<TodoEntry> entries(List<String> lines) {
    return <TodoEntry>[
      for (var i = 0; i < lines.length; i++) entry(i, lines[i]),
    ];
  }

  List<String> descriptions(List<TodoEntry> kept) {
    return <String>[for (final e in kept) e.task.description];
  }

  group('due ranges', () {
    final lines = entries([
      'overdue due:2026-09-01',
      'today due:2026-09-07',
      'in window due:2026-09-14',
      'past window due:2026-09-15',
      'undated',
    ]);

    test('all passes everything', () {
      const filter = TodoFilter();
      expect(
        descriptions(applyTodoFilter(lines, filter, today)),
        hasLength(5),
      );
    });

    test('overdue / today / next7 / noDate', () {
      expect(
        descriptions(
          applyTodoFilter(
            lines,
            const TodoFilter(dueRange: TodoDueRange.overdue),
            today,
          ),
        ),
        ['overdue due:2026-09-01'],
      );
      expect(
        descriptions(
          applyTodoFilter(
            lines,
            const TodoFilter(dueRange: TodoDueRange.today),
            today,
          ),
        ),
        ['today due:2026-09-07'],
      );
      expect(
        descriptions(
          applyTodoFilter(
            lines,
            const TodoFilter(dueRange: TodoDueRange.next7),
            today,
          ),
        ),
        ['today due:2026-09-07', 'in window due:2026-09-14'],
      );
      expect(
        descriptions(
          applyTodoFilter(
            lines,
            const TodoFilter(dueRange: TodoDueRange.noDate),
            today,
          ),
        ),
        ['undated'],
      );
    });
  });

  group('token chips', () {
    final lines = entries([
      'a +p1 @c1',
      'b +p1 +p2',
      'c @c1 #t1',
    ]);

    test('chips AND together', () {
      const filter = TodoFilter(tokens: {'+p1', '@c1'});
      expect(
        descriptions(applyTodoFilter(lines, filter, today)),
        ['a +p1 @c1'],
      );
    });

    test('project/context/tag namespaces stay apart', () {
      const filter = TodoFilter(tokens: {'+c1'});
      expect(applyTodoFilter(lines, filter, today), isEmpty);
    });

    test('counts rank by task count, then token', () {
      final counts = tokenCountsFor(
        lines,
        TodoDueRange.all,
        today,
      );
      expect(
        [for (final c in counts) '${c.token}:${c.count}'],
        ['+p1:2', '@c1:2', '#t1:1', '+p2:1'],
      );
    });

    test('counts ignore the token selection but honor the due range', () {
      const dated = [
        'a +p1 due:2026-09-01',
        'b +p1 +p2',
      ];
      final counts = tokenCountsFor(
        entries(dated),
        TodoDueRange.overdue,
        today,
      );
      expect(counts.single.token, '+p1');
    });

    test('pruneTokens drops chips absent from the new file', () {
      const filter = TodoFilter(tokens: {'+p1', '+gone'});
      final pruned = filter.pruneTokens({'+p1'});
      expect(pruned.tokens, {'+p1'});
      expect(
        filter.pruneTokens({'+p1', '+gone'}),
        filter,
      );
    });
  });

  group('sort', () {
    test('due: soonest first, overdue on top, undated last', () {
      final lines = entries([
        'undated',
        'later due:2026-09-10',
        'overdue due:2026-09-01',
        'today due:2026-09-07',
      ]);
      expect(
        descriptions(
          applyTodoFilter(lines, const TodoFilter(), today),
        ),
        [
          'overdue due:2026-09-01',
          'today due:2026-09-07',
          'later due:2026-09-10',
          'undated',
        ],
      );
    });

    test('due ties break by priority, then creation, then file order', () {
      final lines = entries([
        'plain due:2026-09-07',
        '(B) 2026-01-02 pri due:2026-09-07',
        '(A) 2026-01-03 pri due:2026-09-07',
        'second plain due:2026-09-07',
      ]);
      expect(
        descriptions(
          applyTodoFilter(lines, const TodoFilter(), today),
        ),
        [
          'pri due:2026-09-07',
          'pri due:2026-09-07',
          'plain due:2026-09-07',
          'second plain due:2026-09-07',
        ],
      );
      expect(
        applyTodoFilter(lines, const TodoFilter(), today)[0].lineIndex,
        2,
      );
    });

    test('priority: (A) first, unprioritized last', () {
      final lines = entries([
        'plain',
        '(B) bee',
        '(A) aye',
      ]);
      expect(
        descriptions(
          applyTodoFilter(
            lines,
            const TodoFilter(sort: TodoSort.priority),
            today,
          ),
        ),
        ['aye', 'bee', 'plain'],
      );
    });

    test('creation: newest first, undated last', () {
      final lines = entries([
        '2026-01-02 older',
        'undated',
        '2026-03-04 newer',
      ]);
      expect(
        descriptions(
          applyTodoFilter(
            lines,
            const TodoFilter(sort: TodoSort.creation),
            today,
          ),
        ),
        ['newer', 'older', 'undated'],
      );
    });
  });
}
