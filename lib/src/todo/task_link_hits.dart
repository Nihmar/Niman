/// What the task link map answers about a note: its tasks (#1152).
library;

import 'package:meta/meta.dart';
import 'package:niman/src/links/moved_links.dart';
import 'package:niman/src/todo/task_link.dart';
import 'package:niman/src/todo/todo_store.dart';

/// The tasks that link a note, open and done apart, each in its file's
/// order.
@immutable
final class NoteTasks {
  /// The [open] tasks of `todo.txt` and the [done] ones of `done.txt`.
  const new({required this.open, required this.done});

  /// No task links the note.
  static const NoteTasks none = NoteTasks(
    open: <TodoEntry>[],
    done: <TodoEntry>[],
  );

  /// The linking tasks of `todo.txt`.
  final List<TodoEntry> open;

  /// The linking tasks of `done.txt`.
  final List<TodoEntry> done;

  /// Whether no task links the note.
  bool get isEmpty => open.isEmpty && done.isEmpty;

  /// How many tasks link the note, open and done.
  int get count => open.length + done.length;
}

/// A task with links that resolved to files about to move, and which ones
/// (phase 1d's rename rewrite: the way a note is asked, [MovedLinks]).
@immutable
final class MovedTaskLinks {
  /// The task [entry] of [file], whose links [links] tells.
  const new({required this.file, required this.entry, required this.links});

  /// The file the task is in.
  final TaskFile file;

  /// The task, as of the snapshot the map was built from: its
  /// [TodoEntry.lineIndex] and its text.
  final TodoEntry entry;

  /// The links of its description that resolved to a moved file, each with
  /// the old path it resolved to.
  final MovedLinks links;
}
