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

  /// Confirms with the notes (the question's own action when there is one,
  /// the plain Delete button otherwise).
  Future<void> confirmDelete(WidgetTester tester) async {
    final carry = find.byKey(const Key('delete-carry-yes'));
    await tester.tap(
      carry.evaluate().isNotEmpty
          ? carry
          : find.widgetWithText(TextButton, AppStrings.actionDelete),
    );
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
    // One question, the count on its action, taking the notes emphasised
    // the first time.
    expect(find.text(AppStrings.deleteFileOnly), findsOne);
    expect(find.text(AppStrings.deleteNotesToo(2)), findsOne);
    expect(
      tester.widget(find.byKey(const Key('delete-carry-yes'))),
      isA<FilledButton>(),
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

  // #775: a note that will not go must not leave the file and the notes
  // before it in the trash with no way back.
  testWidgets('a note that fails to delete still leaves an Undo', (
    tester,
  ) async {
    await open(tester);
    await controller.seedFile('Dune.pdf');
    await seedCompanion('Dune.pdf');
    await seedSidecar('Dune.pdf');
    await settle(tester);
    controller.failDeletes.add('Dune.ocr.md');

    await deleteRow(tester, 'Dune.pdf');
    await confirmDelete(tester);
    expect(noteRow('Dune.pdf', offstage: true), findsNothing);
    expect(noteRow('Dune.pdf - Annotation.md', offstage: true), findsNothing);
    expect(noteRow('Dune.ocr.md', offstage: true), findsOne);
    expect(await controller.ops!.trashItems(), hasLength(2));

    await tester.tap(find.text(AppStrings.actionUndo));
    await settle(tester);
    expect(noteRow('Dune.pdf', offstage: true), findsOne);
    expect(noteRow('Dune.pdf - Annotation.md', offstage: true), findsOne);
    expect(await controller.ops!.trashItems(), isEmpty);
    // The failure is still said, after the notice with its Undo.
    expect(find.text(AppStrings.shellActionFailed), findsOne);
  });

  testWidgets('choosing the file alone leaves the notes', (tester) async {
    await open(tester);
    await controller.seedFile('Dune.pdf');
    await seedCompanion('Dune.pdf');
    await settle(tester);

    await deleteRow(tester, 'Dune.pdf');
    await tester.tap(find.byKey(const Key('delete-carry-no')));
    await settle(tester);

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

  testWidgets('the last choice is the one emphasised next time', (
    tester,
  ) async {
    await open(tester);
    await controller.seedFile('Dune.pdf');
    await seedCompanion('Dune.pdf');
    await settle(tester);

    await deleteRow(tester, 'Dune.pdf');
    await tester.tap(find.byKey(const Key('delete-carry-no')));
    await settle(tester);
    expect(await controller.ops!.deleteCarriesNotes, isFalse);

    await controller.seedFile('Emma.pdf');
    await seedCompanion('Emma.pdf');
    await settle(tester);
    await deleteRow(tester, 'Emma.pdf');
    // Remembered: leaving the notes is the emphasised one now.
    expect(
      tester.widget(find.byKey(const Key('delete-carry-no'))),
      isA<FilledButton>(),
    );
    expect(
      tester.widget(find.byKey(const Key('delete-carry-yes'))),
      isA<TextButton>(),
    );
    await tester.tap(find.byKey(const Key('delete-carry-no')));
    await settle(tester);
    expect(noteRow('Emma.pdf', offstage: true), findsNothing);
    expect(noteRow('Emma.pdf - Annotation.md', offstage: true), findsOne);
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
    expect(find.text(AppStrings.deleteNotesToo(1)), findsOne);
    await confirmDelete(tester);

    expect(noteRow('Dune.pdf', offstage: true), findsNothing);
    expect(noteRow('Dune.ocr.md', offstage: true), findsNothing);
  });
}
