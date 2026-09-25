// Exporting the open note as a file (#24): the ⋮ menu's entry, the format
// chooser, the save seam and the message that says where it landed.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/export/export_files.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  ({String name, Uint8List bytes, String mimeType, String dialogTitle})? saved;
  String? place;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    saved = null;
    place = null;
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
  }) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
          saveExportFileProvider.overrideWithValue(({
            required name,
            required bytes,
            required mimeType,
            required dialogTitle,
          }) async {
            saved = (
              name: name,
              bytes: bytes,
              mimeType: mimeType,
              dialogTitle: dialogTitle,
            );
            return place;
          }),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(
      parentPath: '',
      name: 'note',
      content: '# Note\n',
    );
    await settle(tester);
    await tester.tap(noteRow('note.md'));
    await settle(tester);
  }

  Future<void> chooseExport(WidgetTester tester, String format) async {
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-export')));
    await settle(tester);
    await tester.tap(find.byKey(Key('export-format-$format')));
    await settle(tester);
  }

  testWidgets('the ⋮ menu exports the note as Markdown', (tester) async {
    place = '/tmp/note.md';
    await pumpShell(tester);
    await chooseExport(tester, 'markdown');

    expect(saved?.name, 'note.md');
    expect(saved?.mimeType, 'text/markdown');
    expect(saved?.dialogTitle, AppStrings.exportTitle);
    expect(utf8.decode(saved!.bytes), '# Note\n');
    expect(find.text(AppStrings.exportDone('/tmp/note.md')), findsOne);
  });

  testWidgets('the chooser offers Markdown and HTML', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-export')));
    await settle(tester);

    expect(find.text(AppStrings.exportFormatMarkdown), findsOneWidget);
    expect(find.text(AppStrings.exportFormatHtml), findsOneWidget);
    // The HTML page is built off the UI isolate, which a widget test's
    // fake-async zone cannot wait on: `exportNote`'s HTML payload has its
    // own unit test.
    await tester.tapAt(const Offset(4, 4));
    await settle(tester);
  });

  testWidgets('choosing nothing writes nothing', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-export')));
    await settle(tester);
    await tester.tapAt(const Offset(4, 4));
    await settle(tester);
    expect(saved, isNull);
  });

  testWidgets('a dismissed save dialog says nothing', (tester) async {
    place = null;
    await pumpShell(tester);
    await chooseExport(tester, 'markdown');

    expect(saved, isNotNull, reason: 'the picker was asked');
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the palette runs it too', (tester) async {
    place = '/tmp/note.md';
    await pumpShell(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('palette-field')),
      AppStrings.exportTitle,
    );
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);

    // The command asks the format, then the save seam.
    expect(find.byKey(const Key('export-dialog')), findsOne);
    await tester.tap(find.byKey(const Key('export-format-markdown')));
    await settle(tester);
    expect(saved?.name, 'note.md');
  });

  testWidgets('a phone offers the formats in a sheet', (tester) async {
    place = '/tmp/note.md';
    await pumpShell(tester, size: const Size(400, 800));
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-export')));
    await settle(tester);

    expect(find.byKey(const Key('export-sheet')), findsOne);
    expect(find.byKey(const Key('export-dialog')), findsNothing);
    await tester.tap(find.byKey(const Key('export-format-markdown')));
    await settle(tester);
    expect(saved?.name, 'note.md');
  });
}
