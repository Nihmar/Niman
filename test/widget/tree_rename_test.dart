// #707: on Linux and Windows a rename happens in the tree row — the name
// selected without its extension, Enter or a click elsewhere to commit,
// Esc to give up, and a name that cannot be used said under the field —
// started from the row's menu or F2. A phone keeps the dialog.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;

  Future<void> pumpShell(WidgetTester tester, {Size? size}) async {
    controller = FakeLibrarySession();
    final picker = useFakeFilePicker();
    setSurfaceSize(tester, size ?? const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, picker);
    for (final name in ['alpha', 'beta']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  final field = find.byKey(const Key('tree-rename-field'));

  Future<void> renameFromMenu(WidgetTester tester, String row) async {
    await tester.tap(noteRow(row), buttons: kSecondaryButton);
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-rename')));
    await settle(tester);
  }

  TextEditingValue value(WidgetTester tester) =>
      tester.widget<TextField>(field).controller!.value;

  final desktop = TargetPlatformVariant.only(TargetPlatform.linux);

  testWidgets('the row becomes a field, the name selected without .md', (
    tester,
  ) async {
    await pumpShell(tester);
    await renameFromMenu(tester, 'alpha.md');

    expect(field, findsOne);
    expect(find.byType(AlertDialog), findsNothing);
    expect(value(tester).text, 'alpha.md');
    expect(
      value(tester).selection,
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );

    await tester.enterText(field, 'omega.md');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(field, findsNothing);
    expect(await controller.ops!.find('omega.md'), isNotNull);
    expect(await controller.ops!.find('alpha.md'), isNull);
  }, variant: desktop);

  testWidgets('Esc puts the name back', (tester) async {
    await pumpShell(tester);
    await renameFromMenu(tester, 'alpha.md');
    await tester.enterText(field, 'omega.md');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(field, findsNothing);
    expect(await controller.ops!.find('alpha.md'), isNotNull);
    expect(await controller.ops!.find('omega.md'), isNull);
  }, variant: desktop);

  testWidgets('a taken name stays open and says why', (tester) async {
    await pumpShell(tester);
    await renameFromMenu(tester, 'alpha.md');
    await tester.enterText(field, 'beta');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(field, findsOne);
    expect(find.text(AppStrings.renameNameTaken('beta.md')), findsOne);
    expect(await controller.ops!.find('alpha.md'), isNotNull);

    await tester.enterText(field, 'a:b');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.text(AppStrings.renameNameInvalid), findsOne);
  }, variant: desktop);

  testWidgets('F2 renames the selected row', (tester) async {
    await pumpShell(tester);
    await tester.tap(noteRow('beta.md'));
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await settle(tester);
    expect(field, findsOne);
    expect(value(tester).text, 'beta.md');
  }, variant: desktop);

  testWidgets('a phone keeps the dialog', (tester) async {
    await pumpShell(tester, size: const Size(390, 844));
    await tester.longPress(noteRow('alpha.md'));
    await settle(tester);
    final rename = find.byKey(const Key('menu-rename'));
    await tester.ensureVisible(rename);
    await settle(tester);
    await tester.tap(rename);
    await settle(tester);
    expect(find.byType(AlertDialog), findsOne);
    expect(field, findsNothing);
  });
}
