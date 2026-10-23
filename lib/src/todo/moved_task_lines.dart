/// The task lines Move to tasks writes for the checkbox items of a note
/// (#1152).
library;

import 'package:niman/src/todo/parser.dart';

/// The lines to append to the two task files for a batch of moved items.
final class MovedTaskLines {
  /// Lines for `todo.txt` and for `done.txt`.
  const new({required this.todo, required this.done});

  /// The open tasks, for `todo.txt`.
  final List<String> todo;

  /// The ticked items, completed on the day they were moved, for `done.txt`.
  final List<String> done;
}

/// The task line of an item that says [text], moved on [today]: the creation
/// date the task dialog stamps, then the words — [link] after them, as the
/// dialog's pre-filled description has it.
String movedTaskLine({
  required String text,
  required String link,
  required DateTime today,
}) => formatTodoLine(
  completed: false,
  creationDate: DateTime(today.year, today.month, today.day),
  description: '$text $link',
);

/// The lines for [items] — each a (text, ticked) pair, in note order —
/// moved on [today], each linking the note by [link]. A ticked item is a
/// completed task, `x <today> <today> text [[Note]]`: completed as the Todo
/// tab completes one ([completeTodoLine]).
MovedTaskLines movedTaskLines({
  required Iterable<({String text, bool checked})> items,
  required String link,
  required DateTime today,
}) {
  final todo = <String>[];
  final done = <String>[];
  for (final item in items) {
    final line = movedTaskLine(text: item.text, link: link, today: today);
    if (item.checked) {
      done.add(completeTodoLine(line, today));
    } else {
      todo.add(line);
    }
  }
  return MovedTaskLines(todo: todo, done: done);
}
