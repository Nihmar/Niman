// #1003: the flattened list — headers and rows — of a snapshot under a
// filter: sections by sort key, the Done section last and ordered lazily,
// folded sections without their rows, the counts the filter strip reads.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_list_model.dart';
import 'package:niman/src/todo/todo_store.dart';

void main() {
  final today = DateTime(2026, 9, 7);

  List<TodoEntry> entries(List<String> lines) {
    return <TodoEntry>[
      for (var i = 0; i < lines.length; i++)
        TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
    ];
  }

  TodoSnapshot snapshot({
    List<String> todo = const <String>[],
    List<String> done = const <String>[],
  }) => TodoSnapshot(todo: entries(todo), done: entries(done));

  /// `H:id:count[:folded]` for a header, `open:name` / `done:name` for a
  /// row, to read a list at a glance.
  List<String> shape(List<TodoListItem> items) {
    return <String>[
      for (final item in items)
        switch (item) {
          TodoHeaderItem() =>
            'H:${item.section}:${item.count}${item.collapsed ? ':folded' : ''}',
          TodoRowItem() =>
            '${item.view}:${item.entry.task.description.split(' ').first}',
        },
    ];
  }

  test('open tasks are cut into the due sections, Done closes the list', () {
    final model = TodoListModel.derive(
      snapshot(
        todo: ['late due:2026-09-01', 'now due:2026-09-07', 'someday'],
        done: ['x 2026-09-02 old'],
      ),
      const TodoFilter(),
      today,
    );
    expect(shape(model.items({'done'})), [
      'H:due.overdue:1',
      'open:late',
      'H:due.today:1',
      'open:now',
      'H:due.none:1',
      'open:someday',
      'H:done:1:folded',
    ]);
  });

  test('a folded section lists only its header, Done opens in place', () {
    final model = TodoListModel.derive(
      snapshot(
        todo: ['late due:2026-09-01', 'someday'],
        done: ['x 2026-09-01 older', 'x 2026-09-03 newer'],
      ),
      const TodoFilter(),
      today,
    );
    expect(shape(model.items({'due.overdue'})), [
      'H:due.overdue:1:folded',
      'H:due.none:1',
      'open:someday',
      'H:done:2',
      'done:newer',
      'done:older',
    ]);
  });

  test('a flat list has no header, and a section without tasks is dropped', () {
    final model = TodoListModel.derive(
      snapshot(todo: ['one', 'two']),
      const TodoFilter(sort: TodoSort.creation),
      today,
    );
    expect(shape(model.items(<String>{})), ['open:one', 'open:two']);
    // Even if the id is somehow folded, the flat list has no header to open.
    expect(shape(model.items({'all'})), ['open:one', 'open:two']);

    final empty = TodoListModel.derive(
      snapshot(todo: ['task']),
      const TodoFilter(dueRange: TodoDueRange.overdue),
      today,
    );
    expect(empty.items(<String>{}), isEmpty);
    expect(empty.isEmpty, isTrue);
    expect(empty.hasNoTasks, isFalse);
  });

  test('priority sections: one per letter, then none', () {
    final model = TodoListModel.derive(
      snapshot(todo: ['(B) bee', 'plain', '(A) aye']),
      const TodoFilter(sort: TodoSort.priority),
      today,
    );
    expect(shape(model.items(<String>{})), [
      'H:priority.A:1',
      'open:aye',
      'H:priority.B:1',
      'open:bee',
      'H:priority.none:1',
      'open:plain',
    ]);
  });

  test('the filter narrows both files, and the counts say by how much', () {
    final model = TodoListModel.derive(
      snapshot(
        todo: ['a +p', 'b +q', 'c +p', '   '],
        done: ['x 2026-09-01 d +p', 'x 2026-09-01 e +q'],
      ),
      const TodoFilter(tokens: {'+p'}),
      today,
    );
    expect(model.openTotal, 3, reason: 'blank lines are not tasks');
    expect(model.openShown, 2);
    expect(model.doneTotal, 2);
    expect(model.doneShown, 1);
    expect(shape(model.items({'done'})), [
      'H:due.none:2',
      'open:a',
      'open:c',
      'H:done:1:folded',
    ]);
  });

  test('swiped entries are hidden from both files', () {
    final data = snapshot(todo: ['a', 'b'], done: ['x 2026-09-01 d']);
    final model = TodoListModel.derive(
      data,
      const TodoFilter(),
      today,
      hidden: {data.todo.first, data.done.first},
    );
    expect(shape(model.items(<String>{})), ['H:due.none:1', 'open:b']);
  });

  test('hiding is by the entries of the snapshot, never by value (#1016)', () {
    // The same line index and the same text in both files.
    final data = snapshot(todo: ['same', 'other'], done: ['same']);
    List<String> shown(Set<TodoEntry> hidden) => shape(
      TodoListModel.derive(
        data,
        const TodoFilter(),
        today,
        hidden: hidden,
      ).items(<String>{}),
    );

    // One swipe hides one row: the done twin stays.
    expect(shown({data.todo.first}), [
      'H:due.none:1',
      'open:other',
      'H:done:1',
      'done:same',
    ]);
    // An equal-valued entry that is not the snapshot's own hides nothing:
    // the requirement is the instance, and this pins it.
    final lookalike = TodoEntry(
      lineIndex: data.todo.first.lineIndex,
      task: data.todo.first.task,
    );
    expect(lookalike == data.todo.first, isFalse);
    expect(shown({lookalike}), hasLength(shown(const {}).length));
  });

  test('rows remember their file, and their ids tell the files apart', () {
    final model = TodoListModel.derive(
      snapshot(todo: ['a'], done: ['x 2026-09-01 d']),
      const TodoFilter(),
      today,
    );
    final rows = model.items(<String>{}).whereType<TodoRowItem>().toList();
    expect(rows.map((r) => r.done), [false, true]);
    expect(rows.map((r) => r.id), ['open:0', 'done:0']);
  });

  test('nothing at all is told apart from nothing left by the filter', () {
    final none = TodoListModel.derive(snapshot(), const TodoFilter(), today);
    expect(none.hasNoTasks, isTrue);
    expect(none.items(<String>{}), isEmpty);
  });
}
