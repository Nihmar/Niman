// T-TD-02 AC: todo store — move semantics (order preserved, untouched
// lines byte-identical), line-ending preservation, and serialized
// concurrent ops, all against a temp library root.
import 'dart:io';

import 'package:copist/src/todo/todo_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late TodoStore store;

  /// The raw bytes of [name] in the temp root.
  String readRaw(String name) {
    return File(p.join(root.path, name)).readAsStringSync();
  }

  /// Writes [content] bytes to [name] in the temp root.
  void writeRaw(String name, String content) {
    File(p.join(root.path, name)).writeAsStringSync(content);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('copist_todo_');
    store = TodoStore(root: root.path);
  });

  tearDown(() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  group('load', () {
    test('missing files load as empty', () async {
      final snapshot = await store.load();
      expect(snapshot.todo, isEmpty);
      expect(snapshot.done, isEmpty);
    });

    test('parses every line with its line index', () async {
      writeRaw('todo.txt', '(A) 2026-01-02 first\nsecond +p\n');
      writeRaw('done.txt', 'x 2026-09-06 2026-01-02 old\n');
      final snapshot = await store.load();
      expect(snapshot.todo, hasLength(2));
      expect(snapshot.todo[0].lineIndex, 0);
      expect(snapshot.todo[0].task.priority, 'A');
      expect(snapshot.todo[1].task.projects, ['p']);
      expect(snapshot.done.single.task.completed, isTrue);
      expect(snapshot.done.single.lineIndex, 0);
    });

    test('blank lines load as entries (the UI filters them)', () async {
      writeRaw('todo.txt', 'a\n\nb\n');
      final snapshot = await store.load();
      expect(snapshot.todo, hasLength(3));
      expect(snapshot.todo[1].task.description, isEmpty);
      expect(snapshot.todo[1].lineIndex, 1);
    });
  });

  group('add', () {
    test('first add creates both files', () async {
      await store.add('Buy milk +errands');
      expect(readRaw('todo.txt'), 'Buy milk +errands');
      expect(File(p.join(root.path, 'done.txt')).existsSync(), isTrue);
      expect(readRaw('done.txt'), isEmpty);
    });

    test('appends preserve order', () async {
      await store.add('first');
      await store.add('second');
      await store.add('third');
      expect(readRaw('todo.txt'), 'first\nsecond\nthird');
    });

    test('append preserves the dominant CRLF ending', () async {
      writeRaw('todo.txt', 'a\r\nb\r\n');
      await store.add('c');
      expect(readRaw('todo.txt'), 'a\r\nb\r\nc\r\n');
    });

    test('append preserves a missing trailing newline', () async {
      writeRaw('todo.txt', 'a\nb');
      await store.add('c');
      expect(readRaw('todo.txt'), 'a\nb\nc');
    });

    test('a multiline add is rejected', () async {
      await expectLater(store.add('a\nb'), throwsArgumentError);
    });
  });

  group('check / uncheck', () {
    test('checking moves the line to the end of done.txt', () async {
      writeRaw('todo.txt', '(A) 2026-01-02 first\nsecond +p\n(B) third\n');
      writeRaw('done.txt', 'x 2026-09-01 old\n');
      final snapshot = await store.checkAt(1, DateTime(2026, 9, 7, 15, 30));
      // Untouched todo lines byte-identical, order preserved.
      expect(readRaw('todo.txt'), '(A) 2026-01-02 first\n(B) third\n');
      expect(
        readRaw('done.txt'),
        'x 2026-09-01 old\nx 2026-09-07 second +p\n',
      );
      expect(snapshot.todo, hasLength(2));
      expect(snapshot.done, hasLength(2));
      expect(snapshot.done[1].task.completionDate, DateTime(2026, 9, 7));
    });

    test('checking keeps priority and creation date', () async {
      writeRaw('todo.txt', '(A) 2026-01-02 first\n');
      await store.checkAt(0, DateTime(2026, 9, 7));
      // done.txt is created without a trailing newline (like a first add).
      expect(readRaw('done.txt'), 'x (A) 2026-09-07 2026-01-02 first');
      expect(readRaw('todo.txt'), isEmpty);
    });

    test('unchecking appends the reopened line to todo.txt', () async {
      writeRaw('todo.txt', 'open\n');
      writeRaw(
        'done.txt',
        'x 2026-09-06 2026-01-02 first\nx 2026-09-05 second\n',
      );
      await store.uncheckAt(0);
      // Untouched done lines byte-identical.
      expect(readRaw('done.txt'), 'x 2026-09-05 second\n');
      expect(readRaw('todo.txt'), 'open\n2026-01-02 first\n');
    });

    test('unchecking keeps priority', () async {
      writeRaw('done.txt', 'x (A) 2026-09-07 2026-01-02 first\n');
      await store.uncheckAt(0);
      expect(readRaw('todo.txt'), '(A) 2026-01-02 first');
    });

    test('out-of-range moves throw', () async {
      writeRaw('todo.txt', 'only\n');
      await expectLater(
        store.checkAt(5, DateTime(2026, 9, 7)),
        throwsRangeError,
      );
      await expectLater(store.uncheckAt(0), throwsRangeError);
    });
  });

  group('edit / delete', () {
    test('edit replaces one line; the rest stay byte-identical', () async {
      writeRaw('todo.txt', 'first\nsecond\nthird\n');
      await store.updateTodoAt(1, 'SECOND +p');
      expect(readRaw('todo.txt'), 'first\nSECOND +p\nthird\n');
    });

    test('edit in the done view replaces one line', () async {
      writeRaw('done.txt', 'x 2026-09-06 first\nx 2026-09-05 second\n');
      await store.updateDoneAt(0, 'x 2026-09-06 FIRST');
      expect(readRaw('done.txt'), 'x 2026-09-06 FIRST\nx 2026-09-05 second\n');
    });

    test('a multiline edit is rejected', () async {
      writeRaw('todo.txt', 'first\n');
      await expectLater(store.updateTodoAt(0, 'a\nb'), throwsArgumentError);
    });

    test('delete removes the line; the rest stay byte-identical', () async {
      writeRaw('todo.txt', 'first\nsecond\nthird\n');
      writeRaw('done.txt', 'x 2026-09-06 old\n');
      final before = readRaw('done.txt');
      await store.deleteTodoAt(0);
      expect(readRaw('todo.txt'), 'second\nthird\n');
      // The other file is untouched (not even rewritten).
      expect(readRaw('done.txt'), before);
    });

    test('delete from the done view removes the line', () async {
      writeRaw('done.txt', 'x 2026-09-06 first\nx 2026-09-05 second\n');
      await store.deleteDoneAt(1);
      expect(readRaw('done.txt'), 'x 2026-09-06 first\n');
    });
  });

  group('migrateCompleted', () {
    test('moves x lines to done.txt preserving order', () async {
      writeRaw(
        'todo.txt',
        'open a\nx 2026-09-06 2026-01-02 stray one\nopen b\n'
        'x 2026-09-05 stray two\n',
      );
      writeRaw('done.txt', 'x 2026-09-01 old\n');
      final snapshot = await store.migrateCompleted();
      expect(readRaw('todo.txt'), 'open a\nopen b\n');
      expect(
        readRaw('done.txt'),
        'x 2026-09-01 old\n'
        'x 2026-09-06 2026-01-02 stray one\n'
        'x 2026-09-05 stray two\n',
      );
      expect(
        [for (final entry in snapshot.todo) entry.task.description],
        ['open a', 'open b'],
      );
      expect(snapshot.done, hasLength(3));
    });

    test('is idempotent: the second run writes nothing', () async {
      writeRaw('todo.txt', 'open a\nx 2026-09-06 stray\n');
      await store.migrateCompleted();
      final todoBefore = readRaw('todo.txt');
      final doneBefore = readRaw('done.txt');
      await store.migrateCompleted();
      expect(readRaw('todo.txt'), todoBefore);
      expect(readRaw('done.txt'), doneBefore);
    });

    test('creates nothing when there is nothing to archive', () async {
      final snapshot = await store.migrateCompleted();
      expect(snapshot.todo, isEmpty);
      expect(snapshot.done, isEmpty);
      expect(File(p.join(root.path, 'todo.txt')).existsSync(), isFalse);
      expect(File(p.join(root.path, 'done.txt')).existsSync(), isFalse);
    });

    test('creates a missing done.txt when lines move', () async {
      writeRaw('todo.txt', 'open\nx 2026-09-06 stray\n');
      await store.migrateCompleted();
      expect(readRaw('todo.txt'), 'open\n');
      // A created file carries no trailing newline (like a first add).
      expect(readRaw('done.txt'), 'x 2026-09-06 stray');
    });

    test('leaves open lines in done.txt alone', () async {
      writeRaw('todo.txt', 'open\n');
      writeRaw('done.txt', 'not actually done\n');
      await store.migrateCompleted();
      expect(readRaw('todo.txt'), 'open\n');
      expect(readRaw('done.txt'), 'not actually done\n');
    });
  });

  group('probe', () {
    test('missing files probe as absent', () async {
      final probes = await store.probe();
      expect(probes.todo.exists, isFalse);
      expect(probes.todo.size, -1);
      expect(probes.todo.modified, isNull);
      expect(probes.done.exists, isFalse);
    });

    test('reports size and mtime; moves after a write', () async {
      writeRaw('todo.txt', 'a\n');
      final before = await store.probe();
      expect(before.todo.exists, isTrue);
      expect(before.todo.size, 'a\n'.length);
      expect(before.todo.modified, isNotNull);
      await store.add('b');
      final after = await store.probe();
      expect(after == before, isFalse);
      expect(after.todo.size, 'a\nb\n'.length);
      // A repeated probe with no writes is stable.
      expect(await store.probe() == after, isTrue);
    });
  });

  group('serialization', () {
    test('concurrent adds land in call order', () async {
      final futures = <Future<TodoSnapshot>>[
        for (var i = 0; i < 10; i++) store.add('task $i'),
      ];
      final last = await Future.wait(futures);
      expect(
        readRaw('todo.txt'),
        [for (var i = 0; i < 10; i++) 'task $i'].join('\n'),
      );
      expect(last.last.todo, hasLength(10));
    });

    test('interleaved ops stay consistent', () async {
      await store.add('a');
      await store.add('b');
      await store.add('c');
      // Fired together: the check must see all three adds, in order.
      final results = await Future.wait([
        store.checkAt(0, DateTime(2026, 9, 7)),
        store.add('d'),
      ]);
      expect(readRaw('todo.txt'), 'b\nc\nd');
      expect(readRaw('done.txt'), 'x 2026-09-07 a');
      expect(results[0].done.single.task.description, 'a');
    });

    test('a failing op does not break the chain', () async {
      await store.add('kept');
      await expectLater(
        store.checkAt(9, DateTime(2026, 9, 7)),
        throwsRangeError,
      );
      await store.add('after');
      expect(readRaw('todo.txt'), 'kept\nafter');
    });
  });
}
