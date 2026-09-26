// Exporting the open note as a file (#24): the ⋮ menu's entry, the format
// chooser, the save seam and the message that says where it landed.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/export/epub_note.dart';
import 'package:niman/src/export/export_files.dart';
import 'package:niman/src/export/export_tree_book.dart';
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
  String? pickedFolder;
  String? pickedTitle;
  late EpubNoteExport epubExport;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    saved = null;
    place = null;
    pickedFolder = null;
    pickedTitle = null;
    // The real book builder typesets in an isolate the fake-async zone
    // cannot wait on; a test that does not care gets an empty book.
    epubExport =
        ({
          required text,
          required title,
          required path,
          required root,
          required language,
          linkSource,
          isCancelled,
        }) async => (
          name: 'note.epub',
          bytes: Uint8List(0),
          mimeType: 'application/epub+zip',
        );
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(1400, 900),
    String? pdfEngine,
    EpubMetadataProblem? epubProblem,
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
          pickExportFolderProvider.overrideWithValue(({
            required dialogTitle,
          }) async {
            pickedTitle = dialogTitle;
            return pickedFolder;
          }),
          // The engine search is the machine's; the tests answer for it.
          pdfEngineProvider.overrideWith((ref) => pdfEngine),
          // The metadata pre-flight reads the library root, which is not a
          // real folder here: the test answers for it.
          epubMetadataProblemProvider.overrideWithValue(
            (folder) async => epubProblem,
          ),
          // The book builder is the machine's isolate: the tests hand in
          // their own, which they can hold open and watch.
          epubNoteExportProvider.overrideWithValue(epubExport),
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

  testWidgets('the chooser offers Markdown, HTML, PDF and EPUB', (
    tester,
  ) async {
    await pumpShell(tester);
    await tester.tap(find.byKey(const Key('note-menu')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('note-menu-export')));
    await settle(tester);

    expect(find.text(AppStrings.exportFormatMarkdown), findsOneWidget);
    expect(find.text(AppStrings.exportFormatHtml), findsOneWidget);
    expect(find.text(AppStrings.exportFormatPdf), findsOneWidget);
    expect(find.text(AppStrings.exportFormatEpub), findsOneWidget);
    // The page is built off the UI isolate, and the PDF goes through the
    // printer seam: what a widget test's fake-async zone cannot wait on
    // has its own unit tests (`exportNote`'s HTML payload, `exportNotePdf`,
    // the raster pages).
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
      '${AppStrings.paletteGroupNote}: ${AppStrings.exportTitle}',
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

  testWidgets('a note EPUB export says it is working while it builds', (
    tester,
  ) async {
    place = '/tmp/note.epub';
    final release = Completer<void>();
    epubExport =
        ({
          required text,
          required title,
          required path,
          required root,
          required language,
          linkSource,
          isCancelled,
        }) async {
          await release.future;
          return (
            name: 'note.epub',
            bytes: Uint8List(0),
            mimeType: 'application/epub+zip',
          );
        };
    await pumpShell(tester);
    await chooseExport(tester, 'epub');

    // The build is under way and the dialog says so; the save picker has
    // not been asked yet.
    expect(find.byKey(const Key('export-working')), findsOneWidget);
    expect(saved, isNull);

    release.complete();
    await settle(tester);
    expect(find.byKey(const Key('export-working')), findsNothing);
    expect(saved?.name, 'note.epub');
  });

  testWidgets('an EPUB export can be stopped from its dialog', (tester) async {
    final release = Completer<void>();
    epubExport =
        ({
          required text,
          required title,
          required path,
          required root,
          required language,
          linkSource,
          isCancelled,
        }) async {
          await release.future;
          if (isCancelled?.call() ?? false) throw const EpubExportCancelled();
          return (
            name: 'note.epub',
            bytes: Uint8List(0),
            mimeType: 'application/epub+zip',
          );
        };
    await pumpShell(tester);
    await chooseExport(tester, 'epub');

    await tester.tap(find.byKey(const Key('export-working-cancel')));
    await settle(tester);
    release.complete();
    await settle(tester);

    // The dialog closes itself and a stop says nothing: no file, no
    // message.
    expect(find.byKey(const Key('export-working')), findsNothing);
    expect(saved, isNull);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a row that is not Markdown offers no export', (tester) async {
    await pumpShell(tester);
    await controller.seedFile('picture.png', content: 'not an image');
    await settle(tester);
    await tester.longPress(noteRow('picture.png'));
    await settle(tester);
    // Exporting a binary as Markdown would re-encode it silently (M1).
    expect(find.byKey(const Key('menu-export')), findsNothing);
    await tester.tapAt(const Offset(4, 4));
    await settle(tester);
    await tester.longPress(noteRow('note.md'));
    await settle(tester);
    expect(find.byKey(const Key('menu-export')), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await settle(tester);
  });

  testWidgets('a folder row exports it as one zip', (tester) async {
    // The destination dialog is dismissed: the picker was asked, and
    // nothing was written.
    pickedFolder = null;
    await pumpShell(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    await tester.longPress(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-export-folder')));
    await settle(tester);

    expect(find.byKey(const Key('export-tree-dialog')), findsOne);
    await tester.tap(find.byKey(const Key('export-tree-markdown')));
    await settle(tester);
    expect(pickedTitle, AppStrings.exportTitle);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a folder is offered PDF where an engine is', (tester) async {
    await pumpShell(tester, pdfEngine: '/usr/bin/chromium');
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    await tester.longPress(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-export-folder')));
    await settle(tester);
    expect(find.byKey(const Key('export-tree-pdf')), findsOne);
    // EPUB needs nothing to print with: it is offered everywhere.
    expect(find.byKey(const Key('export-tree-epub')), findsOne);
    await tester.tapAt(const Offset(4, 4));
    await settle(tester);
  });

  testWidgets('a folder with no index.md asks before the book is written', (
    tester,
  ) async {
    await pumpShell(tester, epubProblem: EpubMetadataProblem.missingIndex);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    await tester.longPress(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-export-folder')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('export-tree-epub')));
    await settle(tester);

    expect(find.byKey(const Key('export-epub-metadata-dialog')), findsOne);
    expect(find.text(AppStrings.exportEpubNoIndex), findsOneWidget);

    // Stopping is before the destination is even asked for (E3).
    await tester.tap(find.byKey(const Key('export-epub-cancel')));
    await settle(tester);
    expect(pickedTitle, isNull);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'an index.md without frontmatter says so, and the export can go on',
    (tester) async {
      // The destination is dismissed: the picker was asked, nothing written.
      await pumpShell(
        tester,
        epubProblem: EpubMetadataProblem.missingFrontmatter,
      );
      await controller.createFolder(parentPath: '', name: 'Docs');
      await settle(tester);
      await tester.longPress(noteRow('Docs'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('menu-export-folder')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('export-tree-epub')));
      await settle(tester);

      expect(find.text(AppStrings.exportEpubNoFrontmatter), findsOneWidget);
      await tester.tap(find.byKey(const Key('export-epub-anyway')));
      await settle(tester);
      expect(pickedTitle, AppStrings.exportTitle);
    },
  );

  testWidgets('a source in place needs no asking', (tester) async {
    await pumpShell(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    await tester.longPress(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-export-folder')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('export-tree-epub')));
    await settle(tester);

    expect(find.byKey(const Key('export-epub-metadata-dialog')), findsNothing);
    expect(pickedTitle, AppStrings.exportTitle);
  });

  testWidgets('a folder is not offered PDF where no engine is', (tester) async {
    await pumpShell(tester);
    await controller.createFolder(parentPath: '', name: 'Docs');
    await settle(tester);
    await tester.longPress(noteRow('Docs'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-export-folder')));
    await settle(tester);
    expect(find.byKey(const Key('export-tree-pdf')), findsNothing);
    expect(find.byKey(const Key('export-tree-markdown')), findsOne);
    await tester.tapAt(const Offset(4, 4));
    await settle(tester);
  });

  testWidgets('the palette exports the library', (tester) async {
    pickedFolder = null;
    await pumpShell(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    await tester.enterText(
      find.byKey(const Key('palette-field')),
      AppStrings.exportLibraryTitle,
    );
    await settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);

    // The format chooser, titled for the library, then the folder picker.
    expect(find.byKey(const Key('export-tree-dialog')), findsOne);
    expect(find.text(AppStrings.exportLibraryTitle), findsOneWidget);
    await tester.tap(find.byKey(const Key('export-tree-markdown')));
    await settle(tester);
    expect(pickedTitle, AppStrings.exportTitle);
  });
}
