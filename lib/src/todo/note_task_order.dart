/// The order a note's open tasks are listed in (#1152).
library;

import 'package:niman/src/todo/todo_store.dart';

/// [open] by due date, the soonest first, undated ones last. A stable sort:
/// tasks due the same day, and those with no date, keep their order in
/// `todo.txt`.
List<TodoEntry> sortedByDue(List<TodoEntry> open) {
  final dated = <TodoEntry>[];
  final undated = <TodoEntry>[];
  for (final entry in open) {
    (entry.task.due == null ? undated : dated).add(entry);
  }
  // `List.sort` is not stable: the line index breaks a tie.
  dated.sort((a, b) {
    final byDue = a.task.due!.compareTo(b.task.due!);
    return byDue != 0 ? byDue : a.lineIndex.compareTo(b.lineIndex);
  });
  return [...dated, ...undated];
}

/// [done] with the latest completed first: `done.txt` is appended to as
/// tasks are archived, so its last lines are the newest, and a note's list
/// shows what was just done at the top of its Done section.
List<TodoEntry> latestDoneFirst(List<TodoEntry> done) => [
  for (var i = done.length - 1; i >= 0; i--) done[i],
];
