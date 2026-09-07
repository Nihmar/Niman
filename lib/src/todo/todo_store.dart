/// File store over `todo.txt` / `done.txt` (plan/todo-tab.md T-TD-02,
/// migration + change probing in T-TD-03).
///
/// The two files at the library root are the source of truth; the store
/// keeps no cached state (every mutation re-reads inside the writer
/// chain, so concurrent ops serialize and external edits are
/// last-write-wins, per the plan's conflict rules). Untouched lines are
/// written back from [TodoTask.toLine], so they stay byte-identical;
/// each file keeps its dominant line ending and its trailing-newline
/// state across rewrites.
///
/// Isolate discipline (the Android FUSE rule): file *content* and stats
/// are read off the UI isolate via [Isolate.run]; parsing the returned
/// bytes is pure CPU work and stays on the caller. Writes are single
/// small atomic renames through `core/files.dart`, like the note ops.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/todo/parser.dart';
import 'package:copist/src/todo/todo_files.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// The open-tasks file at the library root.
const String todoFileName = 'todo.txt';

/// The completed-tasks file at the library root.
const String doneFileName = 'done.txt';

/// One task with its 0-based line index in its file.
///
/// The UI filters entries for display (e.g. hiding blank lines) and
/// passes [lineIndex] back to the store ops, so display order never
/// disturbs file order.
final class TodoEntry {
  /// Creates an entry for [task] at file line [lineIndex].
  const TodoEntry({required this.lineIndex, required this.task});

  /// The 0-based line index in `todo.txt` or `done.txt`.
  final int lineIndex;

  /// The parsed line.
  final TodoTask task;
}

/// The parsed contents of both files: every line (including blank ones,
/// in file order) paired with its line index.
final class TodoSnapshot {
  /// Creates a snapshot of the open ([todo]) and completed ([done]) tasks.
  const TodoSnapshot({required this.todo, required this.done});

  /// The `todo.txt` lines, in file order.
  final List<TodoEntry> todo;

  /// The `done.txt` lines, in file order.
  final List<TodoEntry> done;
}

/// Existence + size + mtime of one todo file, read off the UI isolate
/// ([TodoStore.probe]).
///
/// The tab's revision-driven refresh compares these before reloading: a
/// session event that did not move either file (any note edit anywhere)
/// costs two stats and no content read.
@immutable
final class TodoFileProbe {
  /// Creates a probe: [exists] false means the file is missing (then
  /// [size] is -1 and [modified] null).
  const TodoFileProbe({
    required this.exists,
    required this.size,
    required this.modified,
  });

  /// Whether the file exists on disk.
  final bool exists;

  /// The file size in bytes (-1 when missing).
  final int size;

  /// The file mtime (null when missing).
  final DateTime? modified;

  @override
  bool operator ==(Object other) {
    return other is TodoFileProbe &&
        other.exists == exists &&
        other.size == size &&
        other.modified == modified;
  }

  @override
  int get hashCode => Object.hash(exists, size, modified);
}

/// Reads and writes `todo.txt` / `done.txt` under [root].
///
/// Stateless: each mutation re-reads both files at the head of the
/// serialized writer chain, applies its transform, and atomically
/// rewrites the files whose lines changed (a file whose lines did not
/// change is left alone, so its mtime never churns the watcher).
final class TodoStore {
  /// Creates a store over the library root at [root] (absolute path).
  TodoStore({required this.root});

  /// The absolute library root path.
  final String root;

  /// Serialized writer chain: every mutation runs inside [_synchronized],
  /// so concurrent ops apply one at a time in call order (the same
  /// pattern the note ops use).
  Future<void> _chain = Future<void>.value();

  /// Loads both files (missing files read as empty) and parses every
  /// line. Not chained: atomic renames make torn reads impossible, so a
  /// load racing a mutation sees either the old or the new file, never
  /// a mix.
  Future<TodoSnapshot> load() async {
    final bytes = await _readFiles(root);
    return TodoSnapshot(
      todo: _parseLines(bytes[0]),
      done: _parseLines(bytes[1]),
    );
  }

  /// Appends [line] to `todo.txt`, creating both files empty when
  /// missing. Returns the fresh snapshot.
  ///
  /// Throws [ArgumentError] when [line] holds more than one line.
  Future<TodoSnapshot> add(String line) async {
    _requireSingleLine(line);
    return _mutate(
      ensureFiles: true,
      allowCreate: true,
      apply: (todo, done) => todo.add(line),
    );
  }

  /// Probes both files' existence + size + mtime off the UI isolate.
  ///
  /// The tab's revision-driven refresh calls this first and only reloads
  /// content when the probes moved.
  Future<({TodoFileProbe todo, TodoFileProbe done})> probe() async {
    final raw = await _probeFiles(root);
    return (
      todo: _fileProbe(raw[0], raw[1]),
      done: _fileProbe(raw[2], raw[3]),
    );
  }

  /// Moves every completed (`x`) line from `todo.txt` to the end of
  /// `done.txt`, preserving order on both sides (the T-TD-03 migration:
  /// self-heals after external tools write `x` lines back into
  /// `todo.txt`). Returns the fresh snapshot.
  ///
  /// Idempotent: with nothing to archive neither file is rewritten (and
  /// no file is created). A missing `done.txt` is created when lines
  /// actually move.
  Future<TodoSnapshot> migrateCompleted() {
    return _mutate(
      allowCreate: true,
      apply: (todo, done) {
        final archived = <String>[];
        todo.removeWhere((line) {
          if (!parseTodoLine(line).completed) {
            return false;
          }
          archived.add(line);
          return true;
        });
        done.addAll(archived);
      },
    );
  }

  /// Replaces the `todo.txt` line at [lineIndex] with [line] (edit).
  /// Returns the fresh snapshot.
  ///
  /// Throws [ArgumentError] when [line] holds more than one line and
  /// [RangeError] when [lineIndex] is out of range.
  Future<TodoSnapshot> updateTodoAt(int lineIndex, String line) async {
    _requireSingleLine(line);
    return _mutate(apply: (todo, done) => todo[lineIndex] = line);
  }

  /// Replaces the `done.txt` line at [lineIndex] with [line] (edit from
  /// the done view). Returns the fresh snapshot.
  ///
  /// Throws [ArgumentError] when [line] holds more than one line and
  /// [RangeError] when [lineIndex] is out of range.
  Future<TodoSnapshot> updateDoneAt(int lineIndex, String line) async {
    _requireSingleLine(line);
    return _mutate(apply: (todo, done) => done[lineIndex] = line);
  }

  /// Removes the `todo.txt` line at [lineIndex] outright (no trash —
  /// these are todo.txt lines, not notes). Returns the fresh snapshot.
  ///
  /// Throws [RangeError] when [lineIndex] is out of range.
  Future<TodoSnapshot> deleteTodoAt(int lineIndex) {
    return _mutate(apply: (todo, done) => todo.removeAt(lineIndex));
  }

  /// Removes the `done.txt` line at [lineIndex] outright. Returns the
  /// fresh snapshot.
  ///
  /// Throws [RangeError] when [lineIndex] is out of range.
  Future<TodoSnapshot> deleteDoneAt(int lineIndex) {
    return _mutate(apply: (todo, done) => done.removeAt(lineIndex));
  }

  /// Checks the `todo.txt` line at [lineIndex] on [today]: removes it
  /// from `todo.txt` and appends the completed line to the end of
  /// `done.txt` ([completeTodoLine], so priority and the creation date
  /// are kept). Either file is created empty when missing. Returns the
  /// fresh snapshot.
  ///
  /// Checking an already-completed line still archives it to `done.txt`.
  /// Throws [RangeError] when [lineIndex] is out of range.
  Future<TodoSnapshot> checkAt(int lineIndex, DateTime today) {
    return _mutate(
      ensureFiles: true,
      allowCreate: true,
      apply: (todo, done) {
        final raw = todo.removeAt(lineIndex);
        done.add(completeTodoLine(raw, today));
      },
    );
  }

  /// Unchecks the `done.txt` line at [lineIndex]: removes it from
  /// `done.txt` and appends the reopened line to the end of `todo.txt`
  /// ([uncompleteTodoLine], so priority and the creation date are kept).
  /// Either file is created empty when missing. Returns the fresh
  /// snapshot.
  ///
  /// Throws [RangeError] when [lineIndex] is out of range.
  Future<TodoSnapshot> uncheckAt(int lineIndex) {
    return _mutate(
      ensureFiles: true,
      allowCreate: true,
      apply: (todo, done) {
        final raw = done.removeAt(lineIndex);
        todo.add(uncompleteTodoLine(raw));
      },
    );
  }

  /// Runs [apply] against fresh copies of both files' lines inside the
  /// writer chain, rewrites the files whose lines changed, and returns
  /// the fresh snapshot. With [ensureFiles], missing files are created
  /// empty even when their lines did not change (first add); with
  /// [allowCreate], a missing file is created when [apply] actually
  /// changed its lines (check/uncheck/migrate), while other ops hitting
  /// a missing file throw a [StateError].
  Future<TodoSnapshot> _mutate({
    required void Function(List<String> todo, List<String> done) apply,
    bool ensureFiles = false,
    bool allowCreate = false,
  }) {
    return _synchronized(() async {
      final bytes = await _readFiles(root);
      final todoFile = splitTodoFile(bytes[0]);
      final doneFile = splitTodoFile(bytes[1]);
      final todoLines = <String>[...todoFile.lines];
      final doneLines = <String>[...doneFile.lines];
      apply(todoLines, doneLines);
      // Unchanged files are left alone (no mtime churn for the watcher);
      // [ensureFiles] additionally creates missing files (first add).
      if (!_sameLines(todoLines, todoFile.lines) ||
          (ensureFiles && !todoFile.exists)) {
        await _writeFile(
          todoFileName,
          todoFile.copyWith(lines: todoLines),
          allowCreate: ensureFiles || allowCreate,
        );
      }
      if (!_sameLines(doneLines, doneFile.lines) ||
          (ensureFiles && !doneFile.exists)) {
        await _writeFile(
          doneFileName,
          doneFile.copyWith(lines: doneLines),
          allowCreate: ensureFiles || allowCreate,
        );
      }
      return TodoSnapshot(
        todo: _parseEntries(todoLines),
        done: _parseEntries(doneLines),
      );
    });
  }

  /// Enqueues [fn] behind the writer chain; errors reach the caller
  /// without breaking the chain.
  Future<T> _synchronized<T>(Future<T> Function() fn) {
    final next = _chain.then((_) => fn());
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  /// Reads both files' raw bytes off the UI isolate.
  ///
  /// Kept as its own method (no instance members referenced) so the
  /// [Isolate.run] closure captures only the sendable path — the store
  /// itself holds an unsendable future chain.
  Future<List<Uint8List?>> _readFiles(String rootPath) {
    return Isolate.run(() => _readTodoFiles(rootPath));
  }

  /// Stats both files off the UI isolate (same capture rule as
  /// [_readFiles]).
  Future<List<int>> _probeFiles(String rootPath) {
    return Isolate.run(() => _probeTodoFiles(rootPath));
  }

  /// Atomically rewrites [name] with [file]'s lines. A missing file is
  /// only created with [allowCreate]; any other op hitting a missing
  /// file throws a [StateError].
  Future<void> _writeFile(
    String name,
    TodoFileContent file, {
    required bool allowCreate,
  }) {
    final target = File(p.join(root, name));
    if (!target.existsSync() && !allowCreate) {
      throw StateError('Missing todo file: "$name"');
    }
    return writeFileAtomically(target, utf8.encode(joinTodoFile(file)));
  }
}

/// Reads both files' raw bytes off the caller's isolate (the Android
/// FUSE rule: no disk reads on the UI isolate).
///
/// Top-level and fully synchronous so it can be handed to [Isolate.run];
/// captures only the sendable [root]. Returns `[todoBytes, doneBytes]`
/// (null per missing file). Byte buffers (not strings) cross the isolate
/// boundary; decoding and line splitting stay on the caller.
List<Uint8List?> _readTodoFiles(String root) {
  Uint8List? read(String name) {
    final file = File(p.join(root, name));
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsBytesSync();
  }

  return <Uint8List?>[read(todoFileName), read(doneFileName)];
}

/// Builds a [TodoFileProbe] from a ([size], [mtimeUs]) pair ([size] < 0 =
/// missing file).
TodoFileProbe _fileProbe(int size, int mtimeUs) {
  if (size < 0) {
    return const TodoFileProbe(exists: false, size: -1, modified: null);
  }
  return TodoFileProbe(
    exists: true,
    size: size,
    modified: DateTime.fromMicrosecondsSinceEpoch(mtimeUs),
  );
}

/// Stats both files off the caller's isolate.
///
/// Top-level and fully synchronous so it can be handed to [Isolate.run];
/// captures only the sendable [root]. Returns
/// `[todoSize, todoMtimeUs, doneSize, doneMtimeUs]` (-1 per missing
/// file); only plain ints cross the isolate boundary.
List<int> _probeTodoFiles(String root) {
  List<int> probe(String name) {
    final file = File(p.join(root, name));
    if (!file.existsSync()) {
      return <int>[-1, -1];
    }
    final stat = file.statSync();
    return <int>[stat.size, stat.modified.microsecondsSinceEpoch];
  }

  return <int>[...probe(todoFileName), ...probe(doneFileName)];
}

/// Parses raw [bytes] (null = missing file) into snapshot entries.
List<TodoEntry> _parseLines(Uint8List? bytes) {
  return _parseEntries(splitTodoFile(bytes).lines);
}
/// Parses content [lines] into snapshot entries with line indices.
List<TodoEntry> _parseEntries(List<String> lines) {
  return <TodoEntry>[
    for (var i = 0; i < lines.length; i++)
      TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
  ];
}

/// Whether two line lists hold the same lines in the same order.
bool _sameLines(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Throws [ArgumentError] when [line] holds more than one line (an op
/// argument must never smuggle extra lines into a file).
void _requireSingleLine(String line) {
  if (line.contains('\n') || line.contains('\r')) {
    throw ArgumentError('A task must be a single line');
  }
}
