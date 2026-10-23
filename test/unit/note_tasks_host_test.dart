// #1152: what a new task for a note is made of -- the shortest link that names
// the note, and the text selected in the editor on one line before it -- and
// the order the note's open tasks are listed in.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/note_task_order.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/ui/note_tasks_host.dart';

import '../fakes/note_tasks_fixture.dart';

TodoEntry _entry(int line, String text) =>
    TodoEntry(lineIndex: line, task: parseTodoLine(text));

void main() {
  group('a new task for a note', () {
    test('is the note linked by the shortest name that reaches it', () async {
      final fixture = await NoteTasksFixture.open();
      addTearDown(fixture.dispose);
      await fixture.host.add('House/Repairs.md');
      await fixture.host.add('Ideas.md');
      expect(fixture.added, ['[[Repairs]]', '[[Ideas]]']);
    });

    test('puts the selection, on one line, before the link', () async {
      final fixture = await NoteTasksFixture.open();
      addTearDown(fixture.dispose);
      await fixture.host.add(
        'Ideas.md',
        selection: '  Call   the\n\tplumber \r\n today ',
      );
      expect(fixture.added, ['Call the plumber today [[Ideas]]']);
    });

    test('a blank selection is no selection', () async {
      final fixture = await NoteTasksFixture.open();
      addTearDown(fixture.dispose);
      await fixture.host.add('Ideas.md', selection: ' \n ');
      expect(fixture.added, ['[[Ideas]]']);
    });

    test('collapses white space', () {
      expect(NoteTasksHost.oneLine(' a \n b\t\tc '), 'a b c');
      expect(NoteTasksHost.oneLine('\n'), '');
    });
  });

  group('the order of the open tasks', () {
    test('by due date, the soonest first; undated last, in file order', () {
      final sorted = sortedByDue([
        _entry(0, 'No date a'),
        _entry(1, 'Late due:2026-10-01'),
        _entry(2, 'No date b'),
        _entry(3, 'Soon due:2026-09-01'),
        _entry(4, 'Same day first due:2026-09-01'),
      ]);
      expect([for (final e in sorted) e.lineIndex], [3, 4, 1, 0, 2]);
    });

    test('is a copy: the input is left as it was', () {
      final input = [
        _entry(0, 'B due:2026-09-02'),
        _entry(1, 'A due:2026-09-01'),
      ];
      sortedByDue(input);
      expect([for (final e in input) e.lineIndex], [0, 1]);
    });
  });
}
