// The bottom tab bar stays put: a note opened full-screen on a phone
// keeps the tabs, and they still switch.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:copist/src/ui/todo_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  /// Opens a phone-sized shell on a library holding one note.
  Future<void> pumpWithNote(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const CopistApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'Note');
    await settle(tester);
    await tester.tap(noteRow('Note.md'));
    await settle(tester);
  }

  testWidgets('an open note keeps the tab bar', (tester) async {
    await pumpWithNote(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.byKey(const Key('shell-tabs')), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('a tab tap from an open note switches tab', (tester) async {
    await pumpWithNote(tester);
    await tester.tap(find.byIcon(Icons.check_box_outlined));
    await settle(tester);

    expect(find.byType(NoteView), findsNothing);
    expect(find.byType(TodoTab), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('tapping the tab the note came from closes the note', (
    tester,
  ) async {
    await pumpWithNote(tester);
    await tester.tap(find.byKey(const Key('tab-files')));
    await settle(tester);

    // Back on the tree, with the note closed.
    expect(find.byType(NoteView), findsNothing);
    expect(noteRow('Note.md'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });
}
