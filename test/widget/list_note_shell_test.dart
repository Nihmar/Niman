// T-TK-06/07: the FAB's "New list note" mini — creates a `type: list`
// note in the configured folder (default `Lists/`, re-targetable via the
// library setting) and opens it.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
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

  Widget buildApp() {
    return ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const CopistApp(),
    );
  }

  testWidgets('the FAB expands into note, folder and list-note actions', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(find.byKey(const Key('new-note-action')), findsOneWidget);
    expect(find.byKey(const Key('new-folder-action')), findsOneWidget);
    expect(find.byKey(const Key('new-list-note-action')), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('New list note creates a type: list note under Lists/', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-list-note-action')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(dialogField(), 'Groceries');
    await tester.tap(find.text('OK'));
    await settle(tester);

    // The configured folder was created and the note landed in it.
    expect(await controller.ops!.find('Lists'), isNotNull);
    final note = await controller.ops!.find('Lists/Groceries.md');
    expect(note, isNotNull);
    expect(
      controller.contentOf('Lists/Groceries.md'),
      '---\ntype: list\n---\n',
    );
    // Expand Lists/ in the tree: the created note row is there.
    await tester.tap(noteRow('Lists'));
    await settle(tester);
    expect(noteRow('Groceries.md'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('changing the list folder re-targets creation', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await controller.ops!.setListNoteFolder(folder: 'Checklists');

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-list-note-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Second');
    await tester.tap(find.text('OK'));
    await settle(tester);

    expect(await controller.ops!.find('Checklists'), isNotNull);
    expect(await controller.ops!.find('Checklists/Second.md'), isNotNull);
    expect(await controller.ops!.find('Lists'), isNull);

    await controller.close();
    await controller.dispose();
  });
}
