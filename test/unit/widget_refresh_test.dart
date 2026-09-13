// Open-todos refresh (issue 6): pushes follow the open library's
// snapshot, and only reach configured todo widgets.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/todo/parser.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/widget/widget_refresh.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

import '../fakes/fake_library_session.dart';
import '../fakes/fake_widget_host_service.dart';
import '../fakes/fake_widget_pin_store.dart';

void main() {
  late FakeLibrarySession session;
  late List<(String, String?)> saves;

  WidgetUpdater recorder() {
    return WidgetUpdater(
      saveData: (id, data) async {
        saves.add((id, data));
        return true;
      },
      updateWidgets:
          ({required androidName, required qualifiedAndroidName}) async {
            return true;
          },
    );
  }

  TodoSnapshot snapshot(List<String> lines) {
    return TodoSnapshot(
      todo: <TodoEntry>[
        for (var i = 0; i < lines.length; i++)
          TodoEntry(lineIndex: i, task: parseTodoLine(lines[i])),
      ],
      done: const <TodoEntry>[],
    );
  }

  setUp(() {
    session = FakeLibrarySession();
    saves = [];
  });

  test('without an open library nothing pushes', () async {
    await refreshTodoWidgets(
      session: session,
      snapshot: snapshot(['task']),
      updater: recorder(),
    );
    expect(saves, isEmpty);
  });

  test('without widgets nothing pushes', () async {
    final root = p.join('/fake', 'Work');
    await session.open(root, create: false);
    await refreshTodoWidgets(
      session: session,
      snapshot: snapshot(['task']),
      updater: recorder(),
    );
    expect(saves, isEmpty);
  });

  test('a null snapshot pushes nothing', () async {
    final root = p.join('/fake', 'Work');
    await session.open(root, create: false);
    session.seedWidgetConfig(
      androidWidgetId: 7,
      provider: 'todo',
      libraryPath: root,
    );
    await refreshTodoWidgets(
      session: session,
      snapshot: null,
      updater: recorder(),
    );
    expect(saves, isEmpty);
  });

  test('a todo widget gets the sorted rows with its library', () async {
    final root = p.join('/fake', 'Work');
    await session.open(root, create: false);
    session.seedWidgetConfig(
      androidWidgetId: 7,
      provider: 'todo',
      libraryPath: root,
    );
    await refreshTodoWidgets(
      session: session,
      snapshot: snapshot(['undated', 'soon due:2026-09-08']),
      updater: recorder(),
    );

    expect(saves, hasLength(1));
    expect(saves.single.$1, 'todo_7');
    final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
    expect(payload['library'], root);
    final texts = [
      for (final row in payload['rows']! as List<Object?>)
        (row! as Map)['text'],
    ];
    expect(texts, ['soon', 'undated']);
  });

  test('note widgets and other libraries are left alone', () async {
    final root = p.join('/fake', 'Work');
    final elsewhere = p.join('/fake', 'Personal');
    await session.open(root, create: false);
    session
      ..seedWidgetConfig(
        androidWidgetId: 7,
        provider: 'todo',
        libraryPath: elsewhere,
      )
      ..seedWidgetConfig(
        androidWidgetId: 8,
        provider: 'note',
        libraryPath: root,
        notePath: 'Todo.md',
      );
    await refreshTodoWidgets(
      session: session,
      snapshot: snapshot(['task']),
      updater: recorder(),
    );
    expect(saves, isEmpty);
  });

  test('an unknown placed instance adopts the open library', () async {
    final root = p.join('/fake', 'Work');
    await session.open(root, create: false);
    final host = FakeWidgetHostService()..todoIds = [7];
    await refreshTodoWidgets(
      session: session,
      snapshot: snapshot(['task']),
      updater: recorder(),
      host: host,
    );

    final adopted = await session.widgetConfigsFor(root);
    expect(adopted.map((c) => c.androidWidgetId), [7]);
    expect(saves.map((s) => s.$1), ['todo_7']);
  });

  test('a known instance keeps its library on adopt', () async {
    final root = p.join('/fake', 'Work');
    final elsewhere = p.join('/fake', 'Personal');
    await session.open(root, create: false);
    session.seedWidgetConfig(
      androidWidgetId: 7,
      provider: 'todo',
      libraryPath: elsewhere,
    );
    final host = FakeWidgetHostService()..todoIds = [7];
    await refreshTodoWidgets(
      session: session,
      snapshot: snapshot(['task']),
      updater: recorder(),
      host: host,
    );

    // Still pinned elsewhere, so the open library pushes nothing for it.
    expect(
      (await session.widgetConfigsFor(elsewhere)).map((c) => c.libraryPath),
      [elsewhere],
    );
    expect(await session.widgetConfigsFor(root), isEmpty);
    expect(saves, isEmpty);
  });

  group('note widgets', () {
    late FakeWidgetHostService host;
    late FakeWidgetPinStore pins;
    late Map<String, String?> files;

    setUp(() {
      host = FakeWidgetHostService();
      pins = FakeWidgetPinStore();
      files = {};
    });

    Future<void> refreshNotes() {
      return refreshNoteWidgets(
        session: session,
        updater: recorder(),
        host: host,
        pinStore: pins,
        readNote: (root, notePath) async => files[notePath],
      );
    }

    test('without widgets nothing pushes', () async {
      final root = p.join('/fake', 'Work');
      await session.open(root, create: false);
      files['Note.md'] = 'hello';
      await refreshNotes();
      expect(saves, isEmpty);
    });

    test('an unknown instance adopts the pin and pushes', () async {
      final root = p.join('/fake', 'Work');
      await session.open(root, create: false);
      host.noteIds = [7];
      pins.pin = (libraryPath: root, notePath: 'Note.md');
      files['Note.md'] = '# hi\n\nbody text\n';

      await refreshNotes();

      expect(pins.pin, isNull, reason: 'the pin is consumed');
      final adopted = await session.widgetConfigsFor(root);
      expect(adopted.map((c) => c.notePath), ['Note.md']);
      expect(saves.map((s) => s.$1), ['note_7']);
      final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
      expect(payload['kind'], 'note');
      expect(payload['title'], 'Note');
      expect(payload['body'], '# hi\n\nbody text');
    });

    test('a list note pushes checklist rows', () async {
      final root = p.join('/fake', 'Work');
      await session.open(root, create: false);
      session.seedWidgetConfig(
        androidWidgetId: 7,
        provider: 'note',
        libraryPath: root,
        notePath: 'List.md',
      );
      files['List.md'] = '---\ntype: list\n---\n- [ ] milk\n- [x] eggs\n';

      await refreshNotes();

      final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
      expect(payload['kind'], 'list');
      expect(payload['body'], '☐ milk\n☑ eggs');
    });

    test('a deleted note pushes missing', () async {
      final root = p.join('/fake', 'Work');
      await session.open(root, create: false);
      session.seedWidgetConfig(
        androidWidgetId: 7,
        provider: 'note',
        libraryPath: root,
        notePath: 'Gone.md',
      );

      await refreshNotes();

      final payload = jsonDecode(saves.single.$2!) as Map<String, Object?>;
      expect(payload['kind'], 'missing');
      expect(payload['title'], 'Gone');
    });

    test("another library's pin is put back, not consumed", () async {
      final root = p.join('/fake', 'Work');
      final elsewhere = p.join('/fake', 'Personal');
      await session.open(root, create: false);
      host.noteIds = [7];
      pins.pin = (libraryPath: elsewhere, notePath: 'Note.md');
      ({String libraryPath, String notePath})? restored;
      await refreshNoteWidgets(
        session: session,
        updater: recorder(),
        host: host,
        pinStore: pins,
        restorePin: ({required libraryPath, required notePath}) async {
          restored = (libraryPath: libraryPath, notePath: notePath);
          return true;
        },
        readNote: (root, notePath) async => files[notePath],
      );

      expect(await session.widgetConfigsFor(root), isEmpty);
      expect(saves, isEmpty);
      expect(restored, (libraryPath: elsewhere, notePath: 'Note.md'));
    });
  });
}
