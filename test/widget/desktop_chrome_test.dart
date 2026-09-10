// T-PP-22: the desktop chrome — no window app bar, the tree's controls
// at the base of its column, and the open note's controls in the detail
// pane header; the phone keeps its app bar and FAB.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/todo/todo_source.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        librarySessionProvider.overrideWithValue(controller),
        todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
      ],
      child: const CopistApp(),
    );
  }

  Finder railDest(String label) => find.descendant(
    of: find.byKey(const Key('shell-rail')),
    matching: find.text(label),
  );

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  testWidgets('wide: no window app bar, no note FAB, footer holds the tree', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 900));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const Key('tree-footer')), findsOne);
    expect(find.byKey(const Key('new-item-menu')), findsOne);
    expect(find.byKey(const Key('open-trash')), findsOne);
    expect(find.byKey(const Key('toggle-sort')), findsOne);
    expect(find.byKey(const Key('new-note-fab')), findsNothing);
    // No note is open, so there is no editor header.
    expect(find.byKey(const Key('editor-header')), findsNothing);
  });

  testWidgets('wide: the create menu offers and runs all four actions', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 900));

    await tester.tap(find.byKey(const Key('new-item-menu')));
    await settle(tester);
    expect(find.byKey(const Key('new-note-action')), findsOne);
    expect(find.byKey(const Key('new-list-note-action')), findsOne);
    expect(find.byKey(const Key('new-from-template-action')), findsOne);
    expect(find.byKey(const Key('new-folder-action')), findsOne);

    await tester.tap(find.byKey(const Key('new-note-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'from the footer');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(await controller.ops!.find('from the footer.md'), isNotNull);
  });

  testWidgets('wide: the editor header names the note and its folder', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 900));
    await controller.createFolder(parentPath: '', name: 'Notes');
    await settle(tester);
    await controller.createNote(parentPath: 'Notes', name: 'beta');
    await settle(tester);

    // The folder starts collapsed: open it (the only chevron), then
    // select the note.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await settle(tester);
    await tester.tap(noteRow('beta.md'));
    await settle(tester);

    final header = find.byKey(const Key('editor-header'));
    expect(header, findsOne);
    expect(
      find.descendant(of: header, matching: find.text('beta.md')),
      findsOne,
    );
    expect(find.descendant(of: header, matching: find.text('Notes')), findsOne);
    // The view controls sit in the note's status row, not in the header
    // (T-PP-22, user 2026-09-10).
    final statusRow = find.byKey(const Key('status-row'));
    expect(statusRow, findsOne);
    expect(
      find.descendant(
        of: statusRow,
        matching: find.byKey(const Key('layout-mode')),
      ),
      findsOne,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.byKey(const Key('layout-mode')),
      ),
      findsNothing,
    );
  });

  testWidgets('wide: the todo panel holds switch, add and help; no FAB', (
    tester,
  ) async {
    await pumpShell(tester, const Size(1200, 900));
    await tester.tap(railDest('Todo'));
    await settle(tester);

    // Open/Done leads the filter panel (same row), with Add task and the
    // format help trailing it; the phone's add FAB is gone on desktop.
    expect(find.byKey(const Key('todo-view-switch')), findsOne);
    expect(find.byKey(const Key('todo-filter-button')), findsOne);
    expect(find.byKey(const Key('todo-add-button')), findsOne);
    expect(find.byKey(const Key('todo-help')), findsOne);
    expect(find.byKey(const Key('todo-add')), findsNothing);
    expect(
      tester.getCenter(find.byKey(const Key('todo-view-switch'))).dy,
      moreOrLessEquals(
        tester.getCenter(find.byKey(const Key('todo-filter-button'))).dy,
        epsilon: 1,
      ),
    );

    await tester.tap(find.byKey(const Key('todo-add-button')));
    await settle(tester);
    expect(find.byKey(const Key('todo-dialog-field')), findsOne);
    await tester.tap(find.text(AppStrings.todoCancel));
    await settle(tester);

    // The help opens over the tab: the rail stays on screen.
    await tester.tap(find.byKey(const Key('todo-help')));
    await settle(tester);
    expect(find.byKey(const Key('todo-help-dialog')), findsOne);
    expect(find.byKey(const Key('shell-rail')), findsOne);
    await tester.tap(find.byKey(const Key('todo-help-close')));
    await settle(tester);
    expect(find.byKey(const Key('todo-help-dialog')), findsNothing);
  });

  testWidgets('narrow: the app bar and the FAB stay, no tree footer', (
    tester,
  ) async {
    await pumpShell(tester, const Size(390, 844));

    expect(find.byType(AppBar), findsOne);
    expect(find.byKey(const Key('new-note-fab')), findsOne);
    expect(find.byKey(const Key('tree-footer')), findsNothing);
    expect(find.byKey(const Key('new-item-menu')), findsNothing);
  });
}
