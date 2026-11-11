// #1266: on a tablet whose Todo pane has the room, a task tapped opens
// beside the list rather than in a dialog; Save writes it and the panel
// goes. Without the room — held upright — the dialog; a desktop keeps its
// own way.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';
import '../fakes/tablet_shell.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late FakeTodoSource todo;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    todo = FakeTodoSource(todo: ['call the bank', 'buy bread']);
  });

  final panel = find.byKey(const Key('todo-panel'));

  Future<void> openTask(WidgetTester tester, Size size) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
      size: size,
      todo: todo,
    );
    await tester.tap(find.byKey(const Key('rail-todo')));
    await settle(tester);
    await tester.tap(find.textContaining('call the bank').first);
    await settle(tester);
  }

  testWidgets('landscape: beside the list, Save writes and closes it', (
    tester,
  ) async {
    await openTask(tester, tabletLandscape);
    expect(panel, findsOne);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.enterText(
      find.byKey(const Key('todo-dialog-field')),
      'call the bank today',
    );
    await tester.tap(find.byKey(const Key('todo-dialog-save')));
    await settle(tester);
    expect(panel, findsNothing);
    expect(todo.todoLines, contains('call the bank today'));
    expect(todo.todoLines, contains('buy bread'));
    expect(tester.takeException(), isNull);
  }, variant: tabletPlatform);

  testWidgets('another task tapped takes the panel over', (tester) async {
    await openTask(tester, tabletLandscape);
    await tester.tap(find.textContaining('buy bread').first);
    await settle(tester);
    expect(panel, findsOne);
    expect(
      tester.widget<TextField>(find.byKey(const Key('todo-dialog-field'))),
      isA<TextField>().having(
        (field) => field.controller?.text,
        'text',
        'buy bread',
      ),
    );
  }, variant: tabletPlatform);

  testWidgets('held upright: the dialog', (tester) async {
    await openTask(tester, tabletPortrait);
    expect(panel, findsNothing);
    expect(find.byType(AlertDialog), findsOne);
  }, variant: tabletPlatform);

  testWidgets('a desktop has no panel', (tester) async {
    await openTask(tester, tabletLandscape);
    expect(panel, findsNothing);
  }, variant: desktopDensity);
}
