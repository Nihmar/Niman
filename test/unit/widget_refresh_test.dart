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
}
