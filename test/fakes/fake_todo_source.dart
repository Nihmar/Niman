import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_source.dart';
import 'package:copist/src/todo/todo_store.dart';

/// In-memory [TodoSource] for widget tests.
///
/// `testWidgets` runs in a fake-async zone where real filesystem I/O
/// never completes, so the todo UI is exercised against this fake while
/// the real store is covered by the unit tests in `test/unit/`. Mirrors
/// the real semantics the UI relies on: order-preserving moves via the
/// same pure line transforms ([completeTodoLine]/[uncompleteTodoLine]),
/// stable probes across quiet revisions, and a moving mtime per
/// mutation.
final class FakeTodoSource implements TodoSource {
  /// Creates a fake seeded with [todo] + [done] raw lines.
  FakeTodoSource({List<String>? todo, List<String>? done})
    : _todo = <String>[...?todo],
      _done = <String>[...?done];

  final List<String> _todo;
  final List<String> _done;

  /// Bumped per mutation; the probe mtime derives from it, so probes
  /// stay stable across quiet revisions and move after every write.
  int _version = 0;

  /// The current open lines (for assertions).
  List<String> get todoLines => List<String>.unmodifiable(_todo);

  /// The current completed lines (for assertions).
  List<String> get doneLines => List<String>.unmodifiable(_done);

  @override
  Future<TodoSnapshot> load() async => _snapshot();

  @override
  Future<({TodoFileProbe todo, TodoFileProbe done})> probe() async {
    final stamp = DateTime(2026, 5, 4).add(Duration(seconds: _version));
    return (
      todo: TodoFileProbe(
        exists: true,
        size: _todo.join('\n').length,
        modified: stamp,
      ),
      done: TodoFileProbe(
        exists: true,
        size: _done.join('\n').length,
        modified: stamp,
      ),
    );
  }

  @override
  Future<TodoSnapshot> migrateCompleted() async {
    final archived = <String>[];
    _todo.removeWhere((line) {
      if (!parseTodoLine(line).completed) {
        return false;
      }
      archived.add(line);
      return true;
    });
    if (archived.isNotEmpty) {
      _version++;
      _done.addAll(archived);
    }
    return _snapshot();
  }

  @override
  Future<TodoSnapshot> add(String line) async {
    _version++;
    _todo.add(line);
    return _snapshot();
  }

  @override
  Future<TodoSnapshot> checkAt(int lineIndex, DateTime today) async {
    _version++;
    final raw = _todo.removeAt(lineIndex);
    _done.add(completeTodoLine(raw, today));
    return _snapshot();
  }

  @override
  Future<TodoSnapshot> uncheckAt(int lineIndex) async {
    _version++;
    final raw = _done.removeAt(lineIndex);
    _todo.add(uncompleteTodoLine(raw));
    return _snapshot();
  }

  @override
  Future<TodoSnapshot> updateTodoAt(int lineIndex, String line) async {
    _version++;
    _todo[lineIndex] = line;
    return _snapshot();
  }

  @override
  Future<TodoSnapshot> updateDoneAt(int lineIndex, String line) async {
    _version++;
    _done[lineIndex] = line;
    return _snapshot();
  }

  @override
  Future<TodoSnapshot> deleteTodoAt(int lineIndex) async {
    _version++;
    _todo.removeAt(lineIndex);
    return _snapshot();
  }

  @override
  Future<TodoSnapshot> deleteDoneAt(int lineIndex) async {
    _version++;
    _done.removeAt(lineIndex);
    return _snapshot();
  }

  TodoSnapshot _snapshot() {
    return TodoSnapshot(
      todo: <TodoEntry>[
        for (var i = 0; i < _todo.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(_todo[i])),
      ],
      done: <TodoEntry>[
        for (var i = 0; i < _done.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(_done[i])),
      ],
    );
  }
}
