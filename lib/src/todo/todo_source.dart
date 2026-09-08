/// Data-source seam over the todo files (T-TD-04 widget-test seam).
///
/// The todo controller talks to this interface; production uses the
/// real store (disk reads, covered by unit tests) while widget tests
/// inject an in-memory fake (`test/fakes/fake_todo_source.dart`):
/// `testWidgets` runs in a fake-async zone where real filesystem I/O
/// never completes.
library;

import 'package:copist/src/todo/todo_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the todo UI layer needs from `todo.txt` / `done.txt`.
///
/// Implemented by [TodoStore] (production) and by an in-memory fake in
/// widget tests.
abstract interface class TodoSource {
  /// Loads both files (missing files read as empty) and parses every
  /// line.
  Future<TodoSnapshot> load();

  /// Probes both files' existence + size + mtime off the UI isolate.
  Future<({TodoFileProbe todo, TodoFileProbe done})> probe();

  /// Moves every completed (`x`) line from `todo.txt` to the end of
  /// `done.txt`. Idempotent.
  Future<TodoSnapshot> migrateCompleted();

  /// Appends [line] to `todo.txt`, creating both files empty when
  /// missing.
  Future<TodoSnapshot> add(String line);

  /// Checks the `todo.txt` line at [lineIndex] on [today].
  Future<TodoSnapshot> checkAt(int lineIndex, DateTime today);

  /// Reopens the `done.txt` line at [lineIndex] back into `todo.txt`.
  Future<TodoSnapshot> uncheckAt(int lineIndex);

  /// Replaces the `todo.txt` line at [lineIndex] with [line].
  Future<TodoSnapshot> updateTodoAt(int lineIndex, String line);

  /// Replaces the `done.txt` line at [lineIndex] with [line].
  Future<TodoSnapshot> updateDoneAt(int lineIndex, String line);

  /// Removes the `todo.txt` line at [lineIndex] outright.
  Future<TodoSnapshot> deleteTodoAt(int lineIndex);

  /// Removes the `done.txt` line at [lineIndex] outright.
  Future<TodoSnapshot> deleteDoneAt(int lineIndex);
}

/// Builds the todo file source per library root.
///
/// The shell reads this provider for the controller's factory so widget
/// tests can override it with an in-memory fake (the real store's
/// `Isolate.run` reads never complete in the fake-async test zone).
final todoSourceFactoryProvider = Provider<TodoSource Function(String)>((
  ref,
) {
  return _defaultTodoSource;
});

/// The production file source for [root].
TodoSource _defaultTodoSource(String root) => TodoStore(root: root);
