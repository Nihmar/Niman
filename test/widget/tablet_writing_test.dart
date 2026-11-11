// #1266: on a tablet, writing is the note and the keyboard: with the
// keyboard up and the focus in the panes, the tree steps aside, and it
// comes back when the keyboard goes. Typing in the tree's own search keeps
// it where it is.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';
import '../fakes/tablet_shell.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Finder treeOnScreen() => noteTree().hitTestable();

  /// Puts the focus in the open note, as the editor takes it when it is
  /// typed in (the fake library has no file for the editor to load).
  Future<void> focusTheNote(WidgetTester tester) async {
    final inNote = find.descendant(
      of: find.byKey(const Key('note-menu')).first,
      matching: find.byType(Icon),
    );
    Focus.of(tester.element(inNote.first)).requestFocus();
    await settle(tester);
  }

  testWidgets('the keyboard up in a note sets the tree aside, and down '
      'brings it back', (tester) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await focusTheNote(tester);
    expect(treeOnScreen(), findsOne, reason: 'no keyboard yet');

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await settle(tester);
    expect(treeOnScreen(), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.resetViewInsets();
    await settle(tester);
    expect(treeOnScreen(), findsOne);
  }, variant: tabletPlatform);

  testWidgets("typing in the tree's search keeps it beside the note", (
    tester,
  ) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    await tester.tap(find.byKey(const Key('rail-search')));
    await settle(tester);
    final field = find.descendant(
      of: find.byKey(const Key('tree-island')),
      matching: find.byType(TextField),
    );
    await tester.tap(field.first);
    await raiseTabletKeyboard(tester, 300);
    expect(field.first.hitTestable(), findsOne);
  }, variant: tabletPlatform);

  testWidgets('a desktop keeps the tree, keyboard or not', (tester) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await focusTheNote(tester);
    await raiseTabletKeyboard(tester, 300);
    expect(treeOnScreen(), findsOne);
  }, variant: desktopDensity);
}
