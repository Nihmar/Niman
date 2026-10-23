// The tasks of a note, wired as the shell wires them (#1152): a todo source
// with canned lines, the controller over it, the map that resolves their links
// against a canned library, and the host the lists read.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/new_item_folder.dart';
import 'package:niman/src/todo/task_links.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/ui/note_link_targets.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/todo_link_host.dart';

import 'fake_library_session.dart';
import 'fake_link_source.dart';
import 'fake_todo_source.dart';
import 'fake_wikilink_suggester.dart';

/// A [NoteTasksHost] over canned `todo.txt` and `done.txt` lines.
final class NoteTasksFixture {
  new _(
    this.source,
    this.links,
    this.controller,
    this.map,
    this.linkHost,
    this.host,
    this.added,
    this.opened,
  );

  /// Opens a library at `/fake` holding the notes, with [todo] and [done] as
  /// the task files, and waits for the map to resolve their links.
  static Future<NoteTasksFixture> open({
    List<String> todo = const <String>[],
    List<String> done = const <String>[],
    List<String> notes = const <String>[
      'House/Repairs.md',
      'Ideas.md',
      'Budget 2026.md',
    ],
    DateTime? today,
  }) async {
    final day = today ?? DateTime(2026, 9, 7);
    final session = FakeLibrarySession();
    await session.open('/fake', create: false);
    final source = FakeTodoSource(todo: todo, done: done);
    final links = FakeLinkSource(notes: notes);
    final controller = TodoController(
      session: session,
      clock: () => day,
      refreshDebounce: const Duration(milliseconds: 1),
      sourceFactory: (_) => source,
    );
    final map = TaskLinkMap(
      tasks: controller,
      snapshot: () => controller.snapshot,
      links: () async => links,
      indexDebounce: Duration.zero,
    );
    final opened = <(String, String?)>[];
    final linkHost = TodoLinkHost(
      map: map,
      source: () => links,
      previewEnabled: () => false,
      suggester: FakeWikilinkSuggester.new,
      targets: (anchor) => NoteLinkTargets(
        source: links,
        notePath: '/fake/todo.txt',
        libraryRoot: '/fake',
        newItemLocation: NewItemLocation.openNoteFolder,
        outline: const [],
        jumpToHeading: (_) {},
        onOpenNote: (path, anchor) => opened.add((path, anchor)),
        createMissingNote: (path) async => path,
        anchor: anchor,
      ),
    );
    final added = <String>[];
    final fixture = NoteTasksFixture._(
      source,
      links,
      controller,
      map,
      linkHost,
      NoteTasksHost(
        links: linkHost,
        controller: controller,
        addTask: (text) async => added.add(text),
        clock: () => day,
      ),
      added,
      opened,
    );
    await controller.open();
    await map.settled;
    return fixture;
  }

  /// The task files.
  final FakeTodoSource source;

  /// The library the links resolve against.
  final FakeLinkSource links;

  /// The tasks' controller.
  final TodoController controller;

  /// The resolved links.
  final TaskLinkMap map;

  /// The links as the Todo tab follows them.
  final TodoLinkHost linkHost;

  /// What the lists read.
  final NoteTasksHost host;

  /// The text each Add task handed to the shell's add flow, in order.
  final List<String> added;

  /// The notes the chips opened, with their anchors.
  final List<(String, String?)> opened;

  /// Lets the map resolve what changed and the rows follow it.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() async {
      await map.settled;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await map.settled;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
  }

  /// Lets go of everything the fixture holds.
  void dispose() {
    linkHost.dispose();
    map.dispose();
    controller.dispose();
  }
}
