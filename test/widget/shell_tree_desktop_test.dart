// #712: the desktop's tree — rows marked together, whose menu deletes
// them all into the trash with one Undo and moves them all at once, and a
// new note named in a row of its own.
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

  /// A row of the tree dragged with the mouse and let go on [to].
  Future<void> dragMouse(WidgetTester tester, Finder from, Finder to) async {
    final start = tester.getCenter(from);
    final end = tester.getCenter(to);
    final mouse = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      await mouse.moveTo(Offset.lerp(start, end, step / 10)!);
      await tester.pump();
    }
    await mouse.up();
    await settle(tester);
  }

  /// Opens the folder row [folder] with its chevron.
  Future<void> expand(WidgetTester tester, String folder) async {
    await tester.tap(
      find.descendant(
        of: find
            .ancestor(of: noteRow(folder), matching: find.byType(InkWell))
            .first,
        matching: find.byIcon(Icons.chevron_right),
      ),
    );
    await settle(tester);
  }

  testWidgets('a drag of one marked row moves them all (#996)', (tester) async {
    await pump(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(noteRow('bravo.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);

    await dragMouse(tester, noteRow('alpha.md'), noteRow('Box'));

    expect(await controller.find('Box/alpha.md'), isNotNull);
    expect(await controller.find('Box/bravo.md'), isNotNull);
    expect(await controller.find('charlie.md'), isNotNull);
  }, variant: _linux);

  testWidgets(
    'a marked folder dragged with its marked child moves once (#996)',
    (tester) async {
      await pump(tester);
      await controller.createFolder(parentPath: 'Box', name: 'Nested');
      await controller.createNote(parentPath: 'Box/Nested', name: 'leaf');
      await controller.createFolder(parentPath: '', name: 'Dest');
      await settle(tester);
      await expand(tester, 'Box');
      await expand(tester, 'Nested');
      // Mark the folder and the note under it.
      await tester.tap(noteRow('Box'));
      await settle(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tap(noteRow('leaf.md'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await settle(tester);

      await dragMouse(tester, noteRow('Box'), noteRow('Dest'));

      // The folder carried its child; the child did not move on its own.
      expect(await controller.find('Dest/Box/Nested/leaf.md'), isNotNull);
      expect(await controller.find('Box'), isNull);
      expect(await controller.find('Nested'), isNull);
    },
    variant: _linux,
  );

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

  testWidgets('a folder menu makes the kinds inside it (#997)', (tester) async {
    await pump(tester);
    // Each entry creates the kind it says, in the folder, not in the
    // library's new-note folder.
    Future<void> make(String key, String name, String type) async {
      await tester.tap(noteRow('Box'), buttons: kSecondaryButton);
      await settle(tester);
      await tester.tap(find.byKey(Key(key)));
      await settle(tester);
      await tester.enterText(dialogField(), name);
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(await controller.find('Box/$name.md'), isNotNull);
      expect(
        await controller.readNote('Box/$name.md'),
        contains('type: $type'),
      );
    }

    await make('menu-new-audio-note', 'Voice', 'audio');
    await make('menu-new-slides', 'Talk', 'slides');
    await make('menu-new-flashcards', 'Deck', 'flashcard');
    await make('menu-new-kanban', 'Board', 'kanban');
  }, variant: _linux);

  testWidgets('Duplicate from the right-click menu copies the file (#1100)', (
    tester,
  ) async {
    await pump(tester);
    await controller.saveNote('alpha.md', 'first');
    await settle(tester);

    await tester.tap(noteRow('alpha.md'), buttons: kSecondaryButton);
    await settle(tester);
    final duplicate = find.byKey(const Key('menu-duplicate'));
    expect(duplicate, findsOneWidget);
    await tester.ensureVisible(duplicate);
    await settle(tester);
    await tester.tap(duplicate);
    await settle(tester);

    expect(await controller.find('alpha_1.md'), isNotNull);
    expect(await controller.readNote('alpha_1.md'), 'first');
    expect(noteRow('alpha_1.md'), findsOneWidget);
  }, variant: _linux);

  testWidgets('a new note is named in a row of the tree; Esc gives it up', (
    tester,
  ) async {
    await pump(tester);
    Future<void> newNote() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
    }

    await newNote();
    expect(find.byType(AlertDialog), findsNothing);
    final field = find.descendant(
      of: find.byKey(const Key('tree-create-row')),
      matching: find.byType(TextField),
    );
    expect(field, findsOne);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byKey(const Key('tree-create-row')), findsNothing);

    await newNote();
    await tester.enterText(field, 'gamma');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.byKey(const Key('tree-create-row')), findsNothing);
    expect(await controller.find('gamma.md'), isNotNull);
  }, variant: _linux);
}
