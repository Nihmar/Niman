// Issue #23: the workspace is kept per library on this device, written
// once after a burst of changes, and never read over what the user did.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:niman/src/workspace/workspace_controller.dart';
import 'package:niman/src/workspace/workspace_store.dart';

void main() {
  group('WorkspaceStore', () {
    late AppDatabase db;
    late WorkspaceStore store;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      store = WorkspaceStore(db);
    });
    tearDown(() => db.close());

    test('keeps one workspace per library', () async {
      final work = Workspace.empty
          .open('a.md')
          .withMemento('a.md', const NoteMemento(selectionExtent: 3));
      final home = Workspace.empty.open('b.md');
      await store.save('/lib/Work', work);
      await store.save('/lib/Home', home);
      await store.save('/lib/Work', work.open('c.md'));
      expect(await store.load('/lib/Work'), work.open('c.md'));
      expect(await store.load('/lib/Home'), home);
    });

    test('a library never seen, or forgotten, has nothing open', () async {
      expect(await store.load('/lib/New'), Workspace.empty);
      await store.save('/lib/Work', Workspace.empty.open('a.md'));
      await store.remove('/lib/Work');
      expect(await store.load('/lib/Work'), Workspace.empty);
    });

    test('an unreadable row reads as nothing open', () async {
      await db.customStatement(
        'INSERT INTO workspaces (library_path, state, updated_at) '
        "VALUES ('/lib/Work', 'not json', 0)",
      );
      expect(await store.load('/lib/Work'), Workspace.empty);
    });
  });

  group('WorkspaceController', () {
    test('a burst of changes is written once, after the last', () async {
      final saved = <Workspace>[];
      final controller =
          WorkspaceController(
              save: (w) async => saved.add(w),
              debounce: const Duration(milliseconds: 20),
            )
            ..update((w) => w.open('a.md'))
            ..update((w) => w.open('b.md'))
            ..update((w) => w.open('c.md'));
      expect(saved, isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(saved, [controller.value]);
      controller.dispose();
    });

    test('a change that changes nothing is not written', () async {
      var saves = 0;
      final controller = WorkspaceController(
        save: (_) async => saves++,
        debounce: Duration.zero,
      )..update((w) => w);
      await controller.flush();
      expect(saves, 0);
      expect(controller.touched, isFalse);
      controller.dispose();
    });

    test('what was read back does not overwrite what the user did', () {
      final controller = WorkspaceController(save: (_) async {})
        ..update((w) => w.open('now.md'))
        ..adopt(Workspace.empty.open('before.md'));
      expect(controller.value.activePath, 'now.md');
      controller.dispose();
    });

    test('read back before anything happened, it is taken', () {
      final controller = WorkspaceController(save: (_) async {})
        ..adopt(Workspace.empty.open('before.md'));
      expect(controller.value.activePath, 'before.md');
      controller.dispose();
    });

    test('a failed write loses the layout, never throws', () async {
      final controller = WorkspaceController(
        save: (_) async => throw StateError('disk full'),
        debounce: Duration.zero,
      )..update((w) => w.open('a.md'));
      await controller.flush();
      expect(controller.value.activePath, 'a.md');
      controller.dispose();
    });
  });
}
