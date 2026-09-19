// 0.0.8 test round: the note column (#171) is the app's shape, so a list
// note, a voice note and the Todo list keep to it like text does.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/todo/todo_controller.dart';
import 'package:niman/src/ui/kinds/list_note.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/todo_filter_bar.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';

void main() {
  void wide(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('a list note keeps to the column', (tester) async {
    wide(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/n/shopping.md',
            showLineNumbers: true,
            autofocusEditor: false,
            noteColumn: const NoteColumn(),
            readNote: (_) async => '---\ntype: list\n---\n- [ ] milk\n',
            writeNote: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = tester.getRect(find.byType(ListNoteView));
    // 1400 px wide, 700 px column: the sides take what is left.
    expect(list.left, greaterThan(300));
    expect(list.width, lessThanOrEqualTo(700 + 2 * 16));
  });

  testWidgets('the Todo list keeps to the column', (tester) async {
    wide(tester);
    final session = FakeLibrarySession();
    await session.open('/fake', create: false);
    final controller = TodoController(
      session: session,
      refreshDebounce: const Duration(milliseconds: 1),
      sourceFactory: (_) => FakeTodoSource(todo: ['buy milk']),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoTab(controller: controller, column: const NoteColumn()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(TodoFilterBar)).left, greaterThan(300));
  });
}
