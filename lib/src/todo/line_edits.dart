/// One field of a task changed, the rest of its line kept (#712): what a
/// pointer's row menu and an edit in place write back.
library;

import 'package:niman/src/todo/parser.dart';

/// [task]'s line with its due date set to [due], or cleared when null.
String todoLineWithDue(TodoTask task, DateTime? due) => todoLineWithText(
  task,
  withKeyValueTag(
    task.description,
    'due',
    due == null ? null : formatTodoDate(due),
  ),
);

/// [task]'s line with its priority set to [priority] (`A`…`Z`), or
/// cleared when null.
String todoLineWithPriority(TodoTask task, String? priority) => formatTodoLine(
  completed: task.completed,
  priority: priority,
  completionDate: task.completionDate,
  creationDate: task.creationDate,
  description: task.description,
);

/// [task]'s line with [description] in place of its own: its tokens,
/// `due:` and `rem:` are what [description] says.
String todoLineWithText(TodoTask task, String description) => formatTodoLine(
  completed: task.completed,
  priority: task.priority,
  completionDate: task.completionDate,
  creationDate: task.creationDate,
  description: description,
);
