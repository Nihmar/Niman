// The tree row pins a note for the next placed note widget (issue 6).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  testWidgets('the row menu pins the note for a widget', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'Note');
    await settle(tester);

    await tester.longPress(noteRow('Note.md'));
    await settle(tester);
    expect(find.byKey(const Key('menu-pin-widget')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-pin-widget')));
    await settle(tester);
    // The pin storage is the Android widget storage: off Android the
    // action reports itself unavailable instead of failing.
    expect(find.text(AppStrings.pinWidgetUnavailable), findsOneWidget);
  });
}
