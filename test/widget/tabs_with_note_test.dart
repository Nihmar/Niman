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

  // 2026-09-08 user request: a fullscreen action beside the preview eye,
  // giving the note's text the whole phone screen.
  group('the preview fullscreen', () {
    /// Opens the note and switches it from the editor to the preview.
    Future<void> pumpPreviewing(WidgetTester tester) async {
      await pumpWithNote(tester);
      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await settle(tester);
    }

    testWidgets('is offered only while the preview is showing', (tester) async {
      await pumpWithNote(tester);
      expect(find.byKey(const Key('preview-fullscreen')), findsNothing);

      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await settle(tester);
      expect(find.byKey(const Key('preview-fullscreen')), findsOneWidget);

      await controller.close();
      await controller.dispose();
    });

    testWidgets('hides the app bar and the tab bar', (tester) async {
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('shell-tabs')), findsNothing);
      // The note itself is still there, and so is the way out.
      expect(find.byType(NoteView), findsOneWidget);
      expect(find.byKey(const Key('preview-fullscreen-exit')), findsOneWidget);

      await controller.close();
      await controller.dispose();
    });

    testWidgets('the exit button brings the chrome back', (tester) async {
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen-exit')));
      await settle(tester);

      expect(find.byKey(const Key('shell-tabs')), findsOneWidget);
      expect(find.byKey(const Key('preview-fullscreen')), findsOneWidget);

      await controller.close();
      await controller.dispose();
    });

    testWidgets('switching back to the editor leaves fullscreen', (
      tester,
    ) async {
      // Otherwise the editor would open chromeless, with no eye to
      // press and no obvious way back.
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen-exit')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await settle(tester);

      expect(find.byKey(const Key('shell-tabs')), findsOneWidget);
      expect(find.byKey(const Key('preview-fullscreen')), findsNothing);

      await controller.close();
      await controller.dispose();
    });
  });
}
