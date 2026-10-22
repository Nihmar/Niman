// The map of the tasks' links (#1152): a todo.txt of ten thousand tasks, two
// thousand of them linking a note, resolved against a real index of five
// thousand notes in one batch.
//
// The numbers printed are the build from the parsed tasks to the map
// answering (the work the UI waits behind a snapshot), the same links
// resolved again after an index change (no parsing), and a lookup of the
// tasks of a note and of the links of a task.
//
// Every run holds the build to ten times the bar, a backstop a slow runner
// cannot fail; NIMAN_PERF=1 holds it to the bar itself.
//
// Printing the measure is the point of a perf test.
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/todo_store.dart';

void main() {
  final measured = Platform.environment['NIMAN_PERF'] == '1';
  const barMs = 200;
  const tasksCount = 10000;
  const linkedCount = 2000;
  const notesCount = 5000;

  test('ten thousand tasks, two thousand links, one batch', () async {
    final db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.batch((batch) {
      batch
        ..insertAll(db.notes, [
          for (var i = 0; i < notesCount; i++)
            NotesCompanion.insert(
              id: Value(i + 1),
              path: 'Folder ${i % 50}/Note $i.md',
              parent: 0,
              name: 'Note $i.md',
              nameKey: nameSortKey('Note $i.md'),
              isDir: false,
              size: 1,
              modified: DateTime.fromMillisecondsSinceEpoch(0),
              created: DateTime.fromMillisecondsSinceEpoch(0),
            ),
        ])
        ..insertAll(db.noteStems, [
          for (var i = 0; i < notesCount; i++)
            NoteStemsCompanion.insert(
              stem: 'note $i',
              noteId: i + 1,
              source: 'file',
            ),
        ]);
    });

    // One task in five links a note.
    final lines = <String>[
      for (var i = 0; i < tasksCount; i++)
        if (i % (tasksCount ~/ linkedCount) == 0)
          '(B) Task $i [[Note ${i % notesCount}]] +project$i @home '
              'due:2026-11-02'
        else
          'Task $i about nothing in particular +project$i @home',
    ];
    final snapshot = TodoSnapshot(
      todo: [
        for (var i = 0; i < lines.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
      ],
      done: const <TodoEntry>[],
    );

    final tasks = ValueNotifier<TodoSnapshot?>(null);
    addTearDown(tasks.dispose);
    final moved = StreamController<void>.broadcast();
    addTearDown(moved.close);
    final links = IndexLibraryLinks(db, changes: moved.stream);
    final map = TaskLinkMap(
      tasks: tasks,
      snapshot: () => tasks.value,
      links: () async => links,
      indexDebounce: Duration.zero,
    );
    addTearDown(map.dispose);

    final build = Stopwatch()..start();
    tasks.value = snapshot;
    await map.settled;
    build.stop();
    expect(map.index.linkCount, linkedCount);

    // The same tasks asked again after the index moved: the links are read
    // already, the batch is all that is left.
    final again = Stopwatch()..start();
    moved.add(null);
    await pumpEventQueue();
    await map.settled;
    again.stop();

    final lookup = Stopwatch()..start();
    var found = 0;
    for (var i = 0; i < 1000; i++) {
      found += map.tasksFor('Folder ${i % 50}/Note $i.md').count;
      found += map.linksOf(snapshot.todo[i].task).length;
    }
    lookup.stop();

    print(
      '$tasksCount tasks, $linkedCount links, $notesCount notes: built in '
      '${build.elapsedMilliseconds} ms (bar $barMs ms'
      '${measured ? '' : ', held to ten times it'}); resolved again in '
      '${again.elapsedMilliseconds} ms; 2000 lookups in '
      '${lookup.elapsedMicroseconds / 1000} ms',
    );
    expect(found, greaterThan(0));
    expect(build.elapsedMilliseconds, lessThan(barMs * (measured ? 1 : 10)));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
