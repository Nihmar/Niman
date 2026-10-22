// A rename or a move rewrites the links in the tasks of todo.txt and
// done.txt that named what moved (#1152), as the library's link update
// setting says: with the notes' rewrite under `automatic`, after a yes under
// `ask`, never under `never`. The relocation reaches the tasks through a
// seam, so it is exercised here against a fake one; the last group runs the
// real task link map and todo store behind it.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkUpdate;
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/todo/task_link_rewriter.dart';
import 'package:niman/src/todo/task_link_rewrites.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_link_source.dart';

/// A seam that records what the relocation asked of it and what it was told
/// to write; [count] task files change, unless it [plans] nothing.
final class _FakeTaskLinks implements TaskLinkRewrites {
  new({this.count = 1, this.plans = true});

  final int count;
  final bool plans;

  /// Throws from [plan] when set.
  Error? planFailure;

  /// Throws from the rewrite's apply when set.
  Error? applyFailure;

  /// Runs inside the apply, before it ends.
  Future<void> Function()? onApply;

  final List<
    ({List<String> oldPaths, LinkMoves moves, String? from, String? to})
  >
  asked = [];
  int applied = 0;

  @override
  Future<PendingTaskRewrite?> plan({
    required Iterable<String> oldPaths,
    required LinkMoves moves,
    String? renamedFrom,
    String? renamedTo,
  }) async {
    asked.add((
      oldPaths: oldPaths.toList()..sort(),
      moves: moves,
      from: renamedFrom,
      to: renamedTo,
    ));
    final failure = planFailure;
    if (failure != null) throw failure;
    if (!plans) return null;
    return PendingTaskRewrite(
      count: count,
      apply: () async {
        applied++;
        await onApply?.call();
        final failure = applyFailure;
        if (failure != null) throw failure;
      },
    );
  }
}

void main() {
  late Directory root;
  late Directory dbDir;
  late IndexDatabase db;
  late NoteOps ops;
  late Indexer indexer;
  late LibraryConfigRepo config;

  setUp(() async {
    root = await Directory.current.createTemp('niman_task_links_');
    dbDir = await Directory.current.createTemp('niman_task_links_db_');
    db = IndexDatabase(NativeDatabase(File(p.join(dbDir.path, 'test.sqlite'))));
    addTearDown(db.close);
    config = LibraryConfigRepo(root.path);
    indexer = Indexer(db);
    ops = NoteOps(root: root.path, db: db, indexer: indexer, config: config);
  });

  tearDown(() async {
    await ops.writer.indexed;
    await root.delete(recursive: true);
    await dbDir.delete(recursive: true);
  });

  Future<void> use(LinkUpdate mode) =>
      config.update((c) => c.copyWith(linkUpdate: mode));

  /// `Old`, cited by the note `Ref`.
  Future<void> seedCited() async {
    await ops.createNote(parentPath: '', name: 'Old');
    await ops.createNote(
      parentPath: '',
      name: 'Ref',
      content: 'See [[Old]].\n',
    );
  }

  group('automatic (the default)', () {
    test('a rename asks the seam, and applies after the notes', () async {
      await seedCited();
      final tasks = _FakeTaskLinks();
      String? refAtApply;
      tasks.onApply = () async => refAtApply = await ops.readNote('Ref.md');
      await ops.rename('Old.md', 'New', taskLinks: tasks);
      await ops.linkQuestion;
      expect(tasks.asked, hasLength(1));
      final asked = tasks.asked.single;
      expect(asked.oldPaths, ['Old.md']);
      expect(asked.from, 'Old.md');
      expect(asked.to, 'New.md');
      expect(asked.moves.find('Old', tail: false)?.path, 'New.md');
      expect(tasks.applied, 1);
      // The notes' rewrite was done when the tasks' began.
      expect(refAtApply, 'See [[New]].\n');
    });

    test('a move carries the paths, and no new name', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createFolder(parentPath: '', name: 'Archive');
      await ops.createNote(parentPath: 'Docs', name: 'a');
      final tasks = _FakeTaskLinks();
      await ops.move('Docs/a.md', 'Archive', taskLinks: tasks);
      await ops.linkQuestion;
      final asked = tasks.asked.single;
      expect(asked.oldPaths, ['Docs/a.md']);
      expect(asked.from, isNull);
      expect(asked.to, isNull);
      expect(asked.moves.find('Docs/a.md', tail: false)?.path, 'Archive/a.md');
      expect(tasks.applied, 1);
    });

    test('a folder move asks for every note under it', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createFolder(parentPath: '', name: 'Archive');
      await ops.createNote(parentPath: 'Docs', name: 'a');
      await ops.createNote(parentPath: 'Docs', name: 'b');
      final tasks = _FakeTaskLinks();
      await ops.move('Docs', 'Archive', taskLinks: tasks);
      await ops.linkQuestion;
      final asked = tasks.asked.single;
      expect(asked.oldPaths, ['Docs/a.md', 'Docs/b.md']);
      expect(asked.from, isNull);
      expect(
        asked.moves.find('Docs/b.md', tail: false)?.path,
        'Archive/Docs/b.md',
      );
      expect(tasks.applied, 1);
    });

    test('a renamed folder asks no bare-name follow', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createNote(parentPath: 'Docs', name: 'a');
      final tasks = _FakeTaskLinks();
      await ops.rename('Docs', 'Papers', taskLinks: tasks);
      await ops.linkQuestion;
      expect(tasks.asked.single.from, isNull);
      expect(tasks.asked.single.to, isNull);
      expect(tasks.applied, 1);
    });

    test('tasks alone, no note linking, still rewrite', () async {
      await ops.createNote(parentPath: '', name: 'Old');
      final tasks = _FakeTaskLinks();
      await ops.rename('Old.md', 'New', taskLinks: tasks);
      await ops.linkQuestion;
      expect(tasks.applied, 1);
    });

    test('a plan with nothing to change applies nothing', () async {
      await seedCited();
      final tasks = _FakeTaskLinks(plans: false);
      await ops.rename('Old.md', 'New', taskLinks: tasks);
      await ops.linkQuestion;
      expect(tasks.asked, hasLength(1));
      expect(tasks.applied, 0);
      expect(await ops.readNote('Ref.md'), 'See [[New]].\n');
    });

    test('a move to where it already is asks nothing', () async {
      await ops.createNote(parentPath: '', name: 'Old');
      final tasks = _FakeTaskLinks();
      await ops.move('Old.md', '', taskLinks: tasks);
      await ops.linkQuestion;
      expect(tasks.asked, isEmpty);
      expect(tasks.applied, 0);
    });
  });

  group('never', () {
    test('asks no task and writes none', () async {
      await use(LinkUpdate.never);
      await seedCited();
      final tasks = _FakeTaskLinks();
      await ops.rename('Old.md', 'New', taskLinks: tasks);
      await ops.linkQuestion;
      expect(tasks.asked, isEmpty);
      expect(tasks.applied, 0);
      expect(await ops.readNote('Ref.md'), 'See [[Old]].\n');
    });
  });

  group('ask', () {
    test('counts the changing task files into the number asked', () async {
      await use(LinkUpdate.ask);
      await seedCited();
      final tasks = _FakeTaskLinks(count: 2);
      final counts = <int>[];
      await ops.rename(
        'Old.md',
        'New',
        taskLinks: tasks,
        confirmLinks: (notes) async {
          counts.add(notes);
          return true;
        },
      );
      await ops.linkQuestion;
      // One note, two task files.
      expect(counts, [3]);
      expect(tasks.applied, 1);
      expect(await ops.readNote('Ref.md'), 'See [[New]].\n');
    });

    test('a no leaves the tasks, and the notes, as written', () async {
      await use(LinkUpdate.ask);
      await seedCited();
      final tasks = _FakeTaskLinks();
      await ops.rename(
        'Old.md',
        'New',
        taskLinks: tasks,
        confirmLinks: (_) async => false,
      );
      await ops.linkQuestion;
      expect(tasks.applied, 0);
      expect(await ops.readNote('Ref.md'), 'See [[Old]].\n');
    });

    test('tasks alone are asked about, and applied on a yes', () async {
      await use(LinkUpdate.ask);
      await ops.createNote(parentPath: '', name: 'Old');
      final tasks = _FakeTaskLinks();
      final counts = <int>[];
      await ops.rename(
        'Old.md',
        'New',
        taskLinks: tasks,
        confirmLinks: (notes) async {
          counts.add(notes);
          return true;
        },
      );
      await ops.linkQuestion;
      expect(counts, [1]);
      expect(tasks.applied, 1);
    });

    test('nothing is asked when no note and no task would change', () async {
      await use(LinkUpdate.ask);
      await ops.createNote(parentPath: '', name: 'Old');
      final tasks = _FakeTaskLinks(plans: false);
      var asked = 0;
      await ops.rename(
        'Old.md',
        'New',
        taskLinks: tasks,
        confirmLinks: (_) async {
          asked++;
          return true;
        },
      );
      await ops.linkQuestion;
      expect(asked, 0);
    });
  });

  group('a failing seam never undoes the move', () {
    test('a plan that throws leaves the notes rewritten', () async {
      await seedCited();
      final tasks = _FakeTaskLinks()..planFailure = StateError('no map');
      final row = await ops.rename('Old.md', 'New', taskLinks: tasks);
      await ops.linkQuestion;
      expect(row.path, 'New.md');
      expect(await ops.readNote('Ref.md'), 'See [[New]].\n');
      expect(tasks.applied, 0);
    });

    test('an apply that throws leaves the move and the notes done', () async {
      await seedCited();
      final tasks = _FakeTaskLinks()..applyFailure = StateError('disk full');
      final row = await ops.rename('Old.md', 'New', taskLinks: tasks);
      await ops.linkQuestion;
      expect(row.path, 'New.md');
      expect(await ops.readNote('Ref.md'), 'See [[New]].\n');
      expect(tasks.applied, 1);
    });
  });

  group('with the real task link map and todo store', () {
    late FakeLinkSource links;
    late TodoStore store;
    late TaskLinkMap map;
    late TaskLinkRewriter rewriter;
    late _Snapshot snapshot;

    String readRaw(String name) =>
        File(p.join(root.path, name)).readAsStringSync();

    setUp(() async {
      links = FakeLinkSource(notes: ['Old.md', 'Docs/a.md', 'Other.md']);
      store = TodoStore(root: root.path);
      snapshot = _Snapshot();
      map = TaskLinkMap(
        tasks: snapshot,
        snapshot: () => snapshot.value,
        links: () async => links,
        indexDebounce: Duration.zero,
      );
      rewriter = TaskLinkRewriter(map: map, write: store.replaceLines);
      addTearDown(() {
        map.dispose();
        snapshot.dispose();
      });
    });

    /// Writes the files and lets the map read them.
    Future<void> seedTasks(String todo, String done) async {
      File(p.join(root.path, 'todo.txt')).writeAsStringSync(todo);
      File(p.join(root.path, 'done.txt')).writeAsStringSync(done);
      snapshot.value = await store.load();
      await map.settled;
    }

    test('a rename follows the bare-name and path links, both files', () async {
      await ops.createNote(parentPath: '', name: 'Old');
      await ops.createNote(parentPath: '', name: 'Other');
      await seedTasks(
        '(A) Call [[Old]] due:2026-11-02\r\n'
            'Keep [[Other]] as is\r\n'
            'See [[Old#Heading|the note]] and [x](Old.md)\r\n',
        'x 2026-10-01 Done [[Old]]\n',
      );
      await ops.rename('Old.md', 'New', taskLinks: rewriter);
      await ops.linkQuestion;
      expect(
        readRaw('todo.txt'),
        '(A) Call [[New]] due:2026-11-02\r\n'
        'Keep [[Other]] as is\r\n'
        'See [[New#Heading|the note]] and [x](New.md)\r\n',
      );
      expect(readRaw('done.txt'), 'x 2026-10-01 Done [[New]]\n');
    });

    test('a move rewrites a path link and leaves a bare name', () async {
      await ops.createFolder(parentPath: '', name: 'Docs');
      await ops.createFolder(parentPath: '', name: 'Archive');
      await ops.createNote(parentPath: 'Docs', name: 'a');
      await seedTasks('By path [[Docs/a]]\nBy name [[a]]\n', '');
      await ops.move('Docs/a.md', 'Archive', taskLinks: rewriter);
      await ops.linkQuestion;
      expect(readRaw('todo.txt'), 'By path [[Archive/a]]\nBy name [[a]]\n');
    });

    test('a task edited by another tool meanwhile is left alone', () async {
      await ops.createNote(parentPath: '', name: 'Old');
      await seedTasks('Call [[Old]]\nOther [[Old]]\n', '');
      // Another tool changes the first line after the map has read it.
      File(p.join(root.path, 'todo.txt'))
          .writeAsStringSync('Call [[Old]] +edited\nOther [[Old]]\n');
      await ops.rename('Old.md', 'New', taskLinks: rewriter);
      await ops.linkQuestion;
      expect(readRaw('todo.txt'), 'Call [[Old]] +edited\nOther [[New]]\n');
    });

    test('with no task linking the note nothing is written', () async {
      await ops.createNote(parentPath: '', name: 'Old');
      await seedTasks('Nothing here\n', '');
      final stamp = File(p.join(root.path, 'todo.txt')).lastModifiedSync();
      await ops.rename('Old.md', 'New', taskLinks: rewriter);
      await ops.linkQuestion;
      expect(readRaw('todo.txt'), 'Nothing here\n');
      expect(File(p.join(root.path, 'todo.txt')).lastModifiedSync(), stamp);
    });
  });
}

/// The snapshot the real map follows, as a notifier it listens to.
final class _Snapshot extends ValueNotifier<TodoSnapshot?> {
  new() : super(null);
}
