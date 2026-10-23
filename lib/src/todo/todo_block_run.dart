/// Running a `todo` block against the tasks (#1152).
library;

import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link_hits.dart';
import 'package:niman/src/todo/todo_block_query.dart';
import 'package:niman/src/todo/todo_filter.dart';
import 'package:niman/src/todo/todo_store.dart';

/// The tasks [query] lists, the open ones of `todo.txt` and the completed ones
/// of `done.txt` apart, each in the order the block asked for; told against
/// [today].
///
/// [tasksFor] answers which tasks link the note at a library-relative path
/// (the task link map's question); [notePath] is the note the block is in,
/// and [namedPath] the note `link: [[Note]]` resolved to (null when it
/// resolved to none: no task then). Every line of the query must hold: the
/// link, the tokens (by the Todo tab's own matching), the due dates and the
/// priorities.
NoteTasks runTodoBlock(
  TodoBlockQuery query, {
  required TodoSnapshot snapshot,
  required NoteTasks Function(String path) tasksFor,
  required String notePath,
  required DateTime today,
  String? namedPath,
}) {
  final NoteTasks pool;
  switch (query.link) {
    case LinkThis():
      pool = tasksFor(notePath);
    case LinkNote():
      pool = namedPath == null ? NoteTasks.none : tasksFor(namedPath);
    case LinkAny():
      pool = NoteTasks(
        open: _lines(snapshot.todo),
        done: _lines(snapshot.done),
      );
  }
  final filter = TodoFilter(
    tokens: query.tokens,
    sort: query.sort == TodoBlockSort.priority
        ? TodoSort.priority
        : TodoSort.due,
  );
  List<TodoEntry> pick(List<TodoEntry> entries) {
    final kept = <TodoEntry>[
      for (final entry in entries)
        if (_matches(query, filter, entry.task, today)) entry,
    ];
    // The file's order is the lists' own; the others are the Todo tab's.
    return query.sort == TodoBlockSort.file
        ? kept
        : applyTodoFilter(kept, filter, today);
  }

  return NoteTasks(
    open: query.done == TodoBlockDone.yes
        ? const <TodoEntry>[]
        : pick(pool.open),
    done: query.done == TodoBlockDone.no
        ? const <TodoEntry>[]
        : pick(pool.done),
  );
}

/// [entries] without the blank lines a task file keeps.
List<TodoEntry> _lines(List<TodoEntry> entries) => <TodoEntry>[
  for (final entry in entries)
    if (entry.task.raw.trim().isNotEmpty) entry,
];

bool _matches(
  TodoBlockQuery query,
  TodoFilter filter,
  TodoTask task,
  DateTime today,
) {
  if (!filter.matches(task, today)) return false;
  final due = query.due;
  if (due != null && !due.matches(task.due, today)) return false;
  return query.priorityMatches(task.priority);
}
