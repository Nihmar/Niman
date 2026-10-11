// #717: deleting a PDF or book offers to take its own notes — companions
// and the OCR sidecar — along, and the trash Undo brings them back
// together; nothing to carry, no question.
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

  Widget buildApp() => ProviderScope(
    overrides: [librarySessionProvider.overrideWithValue(controller)],
    child: const NimanApp(),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  /// The sidecar of [owner] at the root, as recognition writes it.
  Future<void> seedSidecar(String owner) => controller.seedFile(
    '${owner.substring(0, owner.length - '.pdf'.length)}.ocr.md',
    content: '---\nocr: "[[$owner]]"\n---\n\n## p. 1\n\nRecognized.\n',
  );

  /// The companion of [owner] at the root.
  Future<void> seedCompanion(String owner) => controller.seedFile(
    '$owner - Annotation.md',
    content: '---\nannotates: "[[$owner]]"\n---\n\n## p. 3\n\nA note.\n',
  );

  /// Deletes the root row [name] through its long-press menu, the phone's
  /// way.
  Future<void> deleteRow(WidgetTester tester, String name) async {
    await tester.longPress(noteRow(name, offstage: true));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('menu-delete')),
      100,
      scrollable: find.ancestor(
        of: find.byKey(const Key('menu-delete')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const Key('menu-delete')));
    await settle(tester);
  }

  Future<void> confirmDelete(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextButton, AppStrings.actionDelete));
    await settle(tester);
  }

  testWidgets('deleting a PDF carries its notes, and Undo brings them back', (
    tester,
  ) async {
    await open(tester);
    await controller.seedFile('Dune.pdf');
    await seedCompanion('Dune.pdf');
    await seedSidecar('Dune.pdf');
    await settle(tester);

    await deleteRow(tester, 'Dune.pdf');
    // One question, the count in it, checked: the notes go unless untold.
    expect(find.byKey(const Key('delete-carry-notes')), findsOne);
    expect(find.text(AppStrings.deleteNotesToo(2)), findsOne);
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('delete-carry-notes')))
          .value,
      isTrue,
    );

    await confirmDelete(tester);
    expect(noteRow('Dune.pdf', offstage: true), findsNothing);
    expect(noteRow('Dune.pdf - Annotation.md', offstage: true), findsNothing);
    expect(noteRow('Dune.ocr.md', offstage: true), findsNothing);
    expect(await controller.ops!.trashItems(), hasLength(3));

    await tester.tap(find.text(AppStrings.actionUndo));
    await settle(tester);
    expect(noteRow('Dune.pdf', offstage: true), findsOne);
    expect(noteRow('Dune.pdf - Annotation.md', offstage: true), findsOne);
    expect(noteRow('Dune.ocr.md', offstage: true), findsOne);
    expect(await controller.ops!.trashItems(), isEmpty);
  });

  testWidgets('unticking the box deletes the file alone', (tester) async {
    await open(tester);
    await controller.seedFile('Dune.pdf');
    await seedCompanion('Dune.pdf');
    await settle(tester);

    await deleteRow(tester, 'Dune.pdf');
    await tester.tap(find.byKey(const Key('delete-carry-notes')));
    await settle(tester);
    await confirmDelete(tester);

    expect(noteRow('Dune.pdf', offstage: true), findsNothing);
    expect(noteRow('Dune.pdf - Annotation.md', offstage: true), findsOne);
    expect(await controller.ops!.trashItems(), hasLength(1));
  });

  testWidgets('cancelling the question deletes nothing', (tester) async {
    await open(tester);
    await controller.seedFile('Dune.pdf');
    await seedCompanion('Dune.pdf');
    await settle(tester);

    await deleteRow(tester, 'Dune.pdf');
    await tester.tap(find.widgetWithText(TextButton, AppStrings.actionCancel));
    await settle(tester);

    expect(noteRow('Dune.pdf', offstage: true), findsOne);
    expect(noteRow('Dune.pdf - Annotation.md', offstage: true), findsOne);
    expect(await controller.ops!.trashItems(), isEmpty);
  });

  testWidgets('a note with no notes of its own still deletes without asking', (
    tester,
  ) async {
    await open(tester);
    await controller.seedFile('Plain.md');
    await settle(tester);

    await deleteRow(tester, 'Plain.md');
    expect(find.byType(AlertDialog), findsNothing);
    expect(noteRow('Plain.md', offstage: true), findsNothing);
  });

  testWidgets("a folder carries its files' companions from outside", (
    tester,
  ) async {
    await open(tester);
    await controller.createFolder(parentPath: '', name: 'Books');
    await controller.seedFile('Books/Dune.pdf');
    await controller.seedFile(
      'Books/Dune.ocr.md',
      content: '---\nocr: "[[Dune.pdf]]"\n---\n\nRecognized.\n',
    );
    await controller.seedFile(
      'Dune notes.md',
      content: '---\nannotates: "[[Books/Dune.pdf]]"\n---\n',
    );
    await settle(tester);

    await deleteRow(tester, 'Books');
    // The sidecar inside is not a choice: it goes with the folder.
    expect(find.text(AppStrings.deleteNotesToo(1)), findsOne);
    await confirmDelete(tester);

    expect(noteRow('Books', offstage: true), findsNothing);
    expect(noteRow('Dune notes.md', offstage: true), findsNothing);
    expect(await controller.ops!.trashItems(), hasLength(2));

    await tester.tap(find.text(AppStrings.actionUndo));
    await settle(tester);
    expect(noteRow('Books', offstage: true), findsOne);
    expect(noteRow('Dune notes.md', offstage: true), findsOne);
  });

  testWidgets('deleting for good asks once, notes on the same question', (
    tester,
  ) async {
    await open(tester);
    await controller.ops!.setTrashEnabled(enabled: false);
    await controller.seedFile('Dune.pdf');
    await seedSidecar('Dune.pdf');
    await settle(tester);

    await deleteRow(tester, 'Dune.pdf');
    expect(find.text(AppStrings.deleteForeverConfirm('Dune.pdf')), findsOne);
    expect(find.byKey(const Key('delete-carry-notes')), findsOne);
    await confirmDelete(tester);

    expect(noteRow('Dune.pdf', offstage: true), findsNothing);
    expect(noteRow('Dune.ocr.md', offstage: true), findsNothing);
  });
}
