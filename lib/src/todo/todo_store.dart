/// File store over `todo.txt` / `done.txt` (plan/todo-tab.md T-TD-02).
///
/// The two files at the library root are the source of truth; the store
/// keeps no cached state (every mutation re-reads inside the writer
/// chain, so concurrent ops serialize and external edits are
/// last-write-wins, per the plan's conflict rules). Untouched lines are
/// written back from [TodoTask.toLine], so they stay byte-identical;
/// each file keeps its dominant line ending and its trailing-newline
/// state across rewrites.
///
/// Isolate discipline (the Android FUSE rule): file *content* is read off
/// the UI isolate via [Isolate.run]; parsing the returned bytes is pure
/// CPU work and stays on the caller. Writes are single small atomic
/// renames through `core/files.dart`, like the note ops.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/todo/parser.dart';
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
    return _mutate(ensureFiles: true, apply: (todo, done) => todo.add(line));
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
      apply: (todo, done) {
        final raw = done.removeAt(lineIndex);
        todo.add(uncompleteTodoLine(raw));
      },
    );
  }

  /// Runs [apply] against fresh copies of both files' lines inside the
  /// writer chain, rewrites the files whose lines changed, and returns
  /// the fresh snapshot. With [ensureFiles], missing files are created
  /// empty even when their lines did not change (first add).
  Future<TodoSnapshot> _mutate({
    required void Function(List<String> todo, List<String> done) apply,
    bool ensureFiles = false,
  }) {
    return _synchronized(() async {
      final bytes = await _readFiles(root);
      final todoFile = _splitFile(bytes[0]);
      final doneFile = _splitFile(bytes[1]);
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
          allowCreate: ensureFiles,
        );
      }
      if (!_sameLines(doneLines, doneFile.lines) ||
          (ensureFiles && !doneFile.exists)) {
        await _writeFile(
          doneFileName,
          doneFile.copyWith(lines: doneLines),
          allowCreate: ensureFiles,
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

  /// Atomically rewrites [name] with [file]'s lines. A missing file is
  /// only created with [allowCreate] (the first add); any other op
  /// hitting a missing file throws a [StateError].
  Future<void> _writeFile(
    String name,
    _TodoFile file, {
    required bool allowCreate,
  }) {
    final target = File(p.join(root, name));
    if (!target.existsSync() && !allowCreate) {
      throw StateError('Missing todo file: "$name"');
    }
    return writeFileAtomically(target, utf8.encode(_joinFile(file)));
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

/// One file's lines with the formatting needed for a byte-stable
/// rewrite: the dominant line ending and whether the file ends with a
/// newline.
final class _TodoFile {
  /// Creates a file view over [lines] ([exists] false = missing file).
  const _TodoFile({
    required this.lines,
    required this.ending,
    required this.endsWithNewline,
    required this.exists,
  });

  /// The content lines (no terminators; a CRLF file's `\r`s are stripped
  /// by the split and restored by the join).
  final List<String> lines;

  /// The dominant line ending (`\r\n` or `\n`; `\n` for new files).
  final String ending;

  /// Whether the file ends with a newline.
  final bool endsWithNewline;

  /// Whether the file exists on disk.
  final bool exists;

  /// Copies the view with new [lines].
  _TodoFile copyWith({required List<String> lines}) {
    return _TodoFile(
      lines: lines,
      ending: ending,
      endsWithNewline: endsWithNewline,
      exists: exists,
    );
  }
}

/// Splits raw [bytes] (null = missing file) into a [_TodoFile].
_TodoFile _splitFile(Uint8List? bytes) {
  if (bytes == null) {
    return const _TodoFile(
      lines: <String>[],
      ending: '\n',
      endsWithNewline: false,
      exists: false,
    );
  }
  final content = utf8.decode(bytes);
  if (content.isEmpty) {
    return const _TodoFile(
      lines: <String>[],
      ending: '\n',
      endsWithNewline: false,
      exists: true,
    );
  }
  final lines = content.split('\n');
  var endsWithNewline = false;
  if (lines.last == '') {
    endsWithNewline = true;
    lines.removeLast();
  }
  // Dominant ending wins (ties keep CRLF, so a Windows file with one
  // stray LF stays CRLF); files without newlines default to `\n`.
  final crlf = '\r\n'.allMatches(content).length;
  final loneLf = '\n'.allMatches(content).length - crlf;
  final ending = crlf > 0 && crlf >= loneLf ? '\r\n' : '\n';
  return _TodoFile(
    lines: [for (final line in lines) _stripCarriageReturn(line)],
    ending: ending,
    endsWithNewline: endsWithNewline,
    exists: true,
  );
}

/// Joins [file]'s lines back, restoring the dominant ending and the
/// trailing-newline state (an empty file writes zero bytes).
String _joinFile(_TodoFile file) {
  if (file.lines.isEmpty) {
    return '';
  }
  final body = file.lines.join(file.ending);
  return file.endsWithNewline ? '$body${file.ending}' : body;
}

/// Strips the `\r` a CRLF split leaves at the line end (the parser also
/// tolerates it, but the store canonicalizes before parsing so [TodoTask]
/// round-trips carry no stray carriage returns).
String _stripCarriageReturn(String line) {
  return line.endsWith('\r') ? line.substring(0, line.length - 1) : line;
}

/// Parses raw [bytes] (null = missing file) into snapshot entries.
List<TodoEntry> _parseLines(Uint8List? bytes) {
  return _parseEntries(_splitFile(bytes).lines);
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
