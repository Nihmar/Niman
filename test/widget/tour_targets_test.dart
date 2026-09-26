// #266: the shell really claims the controls the tour points at — the
// unit test knows the ids, not that a widget registers them.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker picker;

  setUp(() {
    controller = FakeLibrarySession();
    picker = useFakeFilePicker();
  });

  Widget buildApp() => ProviderScope(
    overrides: [
      librarySessionProvider.overrideWithValue(controller),
      welcomeStoreProvider.overrideWith(
        (ref) async => MemoryWelcomeStore()..deckSeen = true,
      ),
    ],
    child: const NimanApp(),
  );

  testWidgets('the wide shell claims the targets it shows', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, picker);

    for (final id in [TourTargets.tree, TourTargets.create, TourTargets.nav]) {
      expect(tourTargetRect(id), isNotNull, reason: '$id is not claimed');
    }

    // A note open in the pane claims the pane; the chrome it builds —
    // the editor switch and the toolbar — is the note chrome's own test.
    await openNewItemMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Targets');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(noteRow('Targets.md'));
    await settle(tester);

    expect(
      tourTargetRect(TourTargets.note),
      isNotNull,
      reason: '${TourTargets.note} is not claimed',
    );

    await controller.close();
    await controller.dispose();
  });

  testWidgets('the note chrome claims its switch and toolbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            showLineNumbers: true,
            autofocusEditor: false,
            // The desktop shape: the toolbar sits above the note rather
            // than riding a keyboard that a bare test does not raise.
            toolbarTop: true,
            path: '/notes/a.md',
            readNote: (_) async => 'plain note body',
            writeNote: (_, _) async {},
            onEditorKindChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (final id in [TourTargets.modeSwitch, TourTargets.toolbar]) {
      expect(tourTargetRect(id), isNotNull, reason: '$id is not claimed');
    }
  });

  testWidgets('the phone shell claims its FAB and tab bar', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, picker);

    for (final id in [TourTargets.create, TourTargets.nav]) {
      expect(tourTargetRect(id), isNotNull, reason: '$id is not claimed');
    }

    await controller.close();
    await controller.dispose();
  });
}
