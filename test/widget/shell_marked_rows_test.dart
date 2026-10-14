// #712: rows marked together in the desktop's tree — their menu deletes
// them all into the trash with one Undo, and moves them all at once.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

/// Marking rows is a desktop's: the shell offers it on Linux and Windows.
final _linux = TargetPlatformVariant.only(TargetPlatform.linux);

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pump(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Box');
    for (final name in ['alpha', 'bravo', 'charlie']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  Future<void> markAlphaToBravo(WidgetTester tester) async {
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(noteRow('bravo.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);
    await tester.tap(noteRow('bravo.md'), buttons: kSecondaryButton);
    await settle(tester);
    expect(find.text('Selected: 2'), findsOne);
  }

  testWidgets('the marked rows go to the trash together, and one Undo '
      'brings them back', (tester) async {
    await pump(tester);
    await markAlphaToBravo(tester);
    await tester.tap(find.byKey(const Key('marked-menu-delete')));
    await settle(tester);
    expect(noteRow('alpha.md'), findsNothing);
    expect(noteRow('bravo.md'), findsNothing);
    expect(noteRow('charlie.md'), findsOne);

    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(noteRow('alpha.md'), findsOne);
    expect(noteRow('bravo.md'), findsOne);
  }, variant: _linux);

  testWidgets('the marked rows move into one folder', (tester) async {
    await pump(tester);
    await markAlphaToBravo(tester);
    await tester.tap(find.byKey(const Key('marked-menu-move')));
    await settle(tester);
    await tester.tap(find.text('Box').last);
    await settle(tester);
    await tester.tap(find.text('Move').last);
    await settle(tester);
    expect(await controller.find('Box/alpha.md'), isNotNull);
    expect(await controller.find('Box/bravo.md'), isNotNull);
    expect(await controller.find('charlie.md'), isNotNull);
  }, variant: _linux);
}
