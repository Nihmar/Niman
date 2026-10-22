// The links of the tasks in todo.txt and done.txt, resolved in memory
// (#1152): what a task links, which tasks link a note, which links follow a
// move, and that the map is rebuilt in order, never on stale tasks.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/task_link.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/todo_store.dart';

import '../fakes/fake_link_source.dart';

TodoSnapshot _snapshot(List<String> open, [List<String> done = const []]) {
  List<TodoEntry> entries(List<String> lines) => [
    for (var i = 0; i < lines.length; i++)
      TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
  ];
  return TodoSnapshot(todo: entries(open), done: entries(done));
}

void main() {
  late FakeLinkSource links;
  late ValueNotifier<TodoSnapshot?> tasks;
  late ValueNotifier<bool> enabled;
  late TaskLinkMap map;

  setUp(() {
    links = FakeLinkSource(
      notes: ['House/Repairs.md', 'Ideas.md', 'a/Twin.md', 'b/Twin.md'],
    );
    tasks = ValueNotifier<TodoSnapshot?>(null);
    enabled = ValueNotifier<bool>(true);
    map = TaskLinkMap(
      tasks: tasks,
      snapshot: () => tasks.value,
      links: () async => links,
      enabled: () => enabled.value,
      enabledChanges: enabled,
      indexDebounce: Duration.zero,
    );
    addTearDown(() {
      map.dispose();
      tasks.dispose();
      enabled.dispose();
    });
  });

  Future<void> publish(List<String> open, [List<String> done = const []]) {
    tasks.value = _snapshot(open, done);
    return map.settled;
  }

  group('what a task links', () {
    test('a wikilink resolves to its note, in the order written', () async {
      await publish([
        '(A) Call [[House/Repairs]] about [[Ideas|my ideas]] due:2026-11-02',
      ]);
      final task = tasks.value!.todo.single.task;
      final found = map.linksOf(task);
      expect(found.map((l) => l.target), ['House/Repairs', 'Ideas']);
      expect(found.map((l) => l.notePath), ['House/Repairs.md', 'Ideas.md']);
      expect(found.last.alias, 'my ideas');
      // The span is an offset into the description.
      final first = found.first.link;
      expect(
        task.description.substring(first.start, first.end),
        '[[House/Repairs]]',
      );
      expect(map.index.linkCount, 2);
    });

    test('a heading or a block is an anchor on the same note', () async {
      await publish(['Fix [[Repairs#Boiler]] and [[Repairs#^b7]]']);
      final found = map.linksOf(tasks.value!.todo.single.task);
      expect(found.map((l) => l.notePath), [
        'House/Repairs.md',
        'House/Repairs.md',
      ]);
      expect(found.map((l) => l.anchor), ['Boiler', '^b7']);
    });

    test('a Markdown link to a note is read too', () async {
      await publish(['Call [plumber](House/Repairs.md#Boiler) today']);
      final link = map.linksOf(tasks.value!.todo.single.task).single;
      expect(link.link, isA<MarkdownLink>());
      expect(link.notePath, 'House/Repairs.md');
      expect(link.anchor, 'Boiler');
      expect(link.alias, 'plumber');
    });

    test('a name two notes share is ambiguous, an absent one dead', () async {
      await publish(['See [[Twin]] and [[Nowhere]]']);
      final found = map.linksOf(tasks.value!.todo.single.task);
      expect(found[0].isAmbiguous, isTrue);
      expect(found[0].notePath, isNull);
      expect(found[0].candidates.map((n) => n.path), hasLength(2));
      expect(found[1].isDead, isTrue);
      expect(map.tasksFor('a/Twin.md').isEmpty, isTrue);
    });

    test('what cannot name a note is not a link of the task', () async {
      await publish([
        'Read [docs](https://example.com/x.md) [[#H]] [top](#top) +[[Ideas +w]]',
        'No links at all +work',
      ]);
      final first = tasks.value!.todo.first.task;
      expect(map.linksOf(first).map((l) => l.target), ['Ideas +w']);
      expect(map.linksOf(first).single.isDead, isTrue);
      expect(map.linksOf(tasks.value!.todo.last.task), isEmpty);
    });

    test('the same words give the same links in either file', () async {
      await publish(['Plan [[Ideas]]'], ['x 2026-09-02 Plan [[Ideas]]']);
      expect(
        map.linksOf(tasks.value!.done.single.task).single.notePath,
        'Ideas.md',
      );
    });
  });

  group('the tasks of a note', () {
    test('open and done apart, each in its file order, once each', () async {
      await publish(
        [
          'First [[Ideas]]',
          'Nothing here',
          'Twice [[Ideas]] and [[Ideas#Part]]',
          'Other [[House/Repairs]]',
        ],
        ['x 2026-09-02 2026-09-01 Finished [[Ideas]]'],
      );
      final found = map.tasksFor('Ideas.md');
      expect(found.open.map((e) => e.lineIndex), [0, 2]);
      expect(found.done.map((e) => e.lineIndex), [0]);
      expect(found.count, 3);
      expect(map.tasksFor('House/Repairs.md').open.single.lineIndex, 3);
      expect(map.tasksFor('Missing.md').isEmpty, isTrue);
    });

    test('an embed is carried by a move, not a task of the note', () async {
      await publish(['Look at ![[Ideas]]', 'Plan [[Ideas]]']);
      expect(map.tasksFor('Ideas.md').open.map((e) => e.lineIndex), [1]);
      expect(map.linksOf(tasks.value!.todo.first.task), isEmpty);
      final moved = map.movedBy(['Ideas.md']);
      expect(moved.map((m) => m.entry.lineIndex), [0, 1]);
    });
  });

  group('the links a move follows', () {
    test('only those that resolved to a moved file, told per task', () async {
      await publish(
        [
          'Plan [[Ideas]] and [[House/Repairs]]',
          'Nothing',
          'Read [x](House/Repairs.md) [[Twin]]',
        ],
        ['x 2026-09-02 2026-09-01 Done [[Ideas#Part]]'],
      );
      final moved = map.movedBy(['Ideas.md']);
      expect(
        [for (final m in moved) (m.file, m.entry.lineIndex)],
        [(TaskFile.todo, 0), (TaskFile.done, 0)],
      );
      expect(moved.first.links.oldPathOf('Ideas', markdown: false), 'Ideas.md');
      expect(
        moved.first.links.oldPathOf('House/Repairs', markdown: false),
        isNull,
      );
      expect(moved.last.links.oldPathOf('Ideas', markdown: false), 'Ideas.md');

      final repairs = map.movedBy(['House/Repairs.md']);
      expect(repairs.map((m) => m.entry.lineIndex), [0, 2]);
      // A Markdown href and a wiki target are two forms.
      expect(
        repairs.last.links.oldPathOf('House/Repairs.md', markdown: true),
        'House/Repairs.md',
      );
      expect(
        repairs.last.links.oldPathOf('House/Repairs.md', markdown: false),
        isNull,
      );
      expect(map.movedBy(['Nowhere.md']), isEmpty);
    });
  });

  group('the batch', () {
    test('every link of every task is one resolver call', () async {
      await publish(
        [for (var i = 0; i < 50; i++) 'Task $i [[Ideas]] [[Missing $i]]'],
        ['x 2026-09-02 Done [[Ideas]]'],
      );
      expect(links.queryBatches, 1);
      expect(map.index.linkCount, 101);
    });

    test('tasks without a link ask nothing', () async {
      await publish(['Buy milk +home', 'Call mom @phone due:2026-09-08']);
      expect(links.queryBatches, 0);
      expect(map.index.isEmpty, isTrue);
    });

    test('a change of the index resolves the links again', () async {
      await publish(['Plan [[Brand New]]']);
      final task = tasks.value!.todo.single.task;
      expect(map.linksOf(task).single.isDead, isTrue);
      var notified = 0;
      map.addListener(() => notified++);

      links.notes.add('Brand New.md');
      links.announceChange();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await map.settled;

      expect(map.linksOf(task).single.notePath, 'Brand New.md');
      expect(map.tasksFor('Brand New.md').open, hasLength(1));
      expect(notified, 1);
      expect(links.queryBatches, 2);
    });
  });

  group('rebuilding', () {
    test('a newer snapshot wins over one still being resolved', () async {
      final gate = Completer<void>();
      var running = 0;
      var most = 0;
      links.queryGate = (batch) async {
        running++;
        most = running > most ? running : most;
        if (batch == 1) await gate.future;
        running--;
      };
      final seen = <int>[];
      map.addListener(() => seen.add(map.index.linkCount));

      tasks.value = _snapshot(['Old [[Ideas]]']);
      await pumpEventQueue();
      tasks.value = _snapshot(['New [[House/Repairs]] [[Ideas]]']);
      expect(links.queryBatches, 1, reason: 'builds do not overlap');
      gate.complete();
      await map.settled;

      expect(seen, [2], reason: 'the older answer is never published');
      expect(most, 1);
      expect(map.tasksFor('House/Repairs.md').open, hasLength(1));
      expect(links.queryBatches, 2);
    });

    test('the links drawn stay while a rebuild is under way', () async {
      await publish(['Plan [[Ideas]]']);
      final before = tasks.value!.todo.single.task;
      final gate = Completer<void>();
      links.queryGate = (_) => gate.future;
      tasks.value = _snapshot(['Plan [[Ideas]]', 'More [[House/Repairs]]']);
      await pumpEventQueue();
      // Told by the words: the old answer is right for the same words.
      expect(map.linksOf(before).single.notePath, 'Ideas.md');
      gate.complete();
      await map.settled;
      expect(map.index.linkCount, 2);
    });

    test('a failed resolution leaves the last answer', () async {
      await publish(['Plan [[Ideas]]']);
      links.queryGate = (_) => throw StateError('index closed');
      await publish(['Plan [[Ideas]]', 'More [[Ideas]]']);
      expect(map.index.linkCount, 1);
      expect(
        map.linksOf(tasks.value!.todo.first.task).single.notePath,
        'Ideas.md',
      );
    });
  });

  group('inert', () {
    test('with the feature off it holds nothing and asks nothing', () async {
      enabled.value = false;
      await publish(['Plan [[Ideas]]']);
      expect(map.index.isEmpty, isTrue);
      expect(links.queryBatches, 0);

      enabled.value = true;
      await map.settled;
      expect(map.index.linkCount, 1);

      enabled.value = false;
      await map.settled;
      expect(map.index.isEmpty, isTrue);
    });

    test('with no library open (no snapshot) it is empty', () async {
      await publish(['Plan [[Ideas]]']);
      tasks.value = null;
      await map.settled;
      expect(map.index.isEmpty, isTrue);
    });

    test('disposed, it answers no more', () async {
      final loose = TaskLinkMap(
        tasks: tasks,
        snapshot: () => tasks.value,
        links: () async => links,
        indexDebounce: Duration.zero,
      );
      await loose.settled;
      var notified = 0;
      loose
        ..addListener(() => notified++)
        ..dispose();
      await publish(['Plan [[Ideas]]']);
      expect(notified, 0);
    });
  });
}
