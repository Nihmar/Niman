// Issue #41 in the app: a file a launch asks for opens the way Open file
// opens one (#77) — as its note inside the open library, on its own
// anywhere else, and on its own with no library at all — and every later
// launch brings the window forward.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/launch_args.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';
import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late FakeWindowController window;
  late StreamController<LaunchArgs> later;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    window = FakeWindowController(customTitleBar: true);
    later = StreamController<LaunchArgs>.broadcast();
  });
  tearDown(() => later.close());

  Future<void> pumpApp(WidgetTester tester, {String? startedWith}) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(window),
          launchRequestsProvider.overrideWithValue(
            LaunchRequests(file: startedWith, later: later.stream),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await settle(tester);
  }

  Future<void> launch(WidgetTester tester, String path) async {
    later.add(LaunchArgs(openPath: path));
    await settle(tester);
  }

  final outside = find.byKey(const Key('outside-file-bar'));

  testWidgets('with a library open: a file outside it opens on its own, '
      'one inside it as its note, and each brings the window forward', (
    tester,
  ) async {
    await pumpApp(tester);
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);

    await launch(tester, '/elsewhere/README.md');
    expect(outside, findsOne);
    expect(window.showCalls, 1);
    await tester.tap(
      find.descendant(of: outside, matching: find.byType(BackButton)),
    );
    await settle(tester);

    await launch(tester, '${controller.root}/alpha.md');
    expect(outside, findsNothing);
    expect(
      tester.widget<NoteView>(find.byType(NoteView)).path,
      endsWith('alpha.md'),
    );
    expect(window.showCalls, 2);
  });

  testWidgets('with no library, a later launch’s file opens on its own', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('open-outside-file')), findsOne);
    await launch(tester, '/elsewhere/draft.md');
    expect(outside, findsOne);
  });

  testWidgets('started with a file and no library to resume, it opens on '
      'its own', (tester) async {
    await pumpApp(tester, startedWith: '/elsewhere/draft.md');
    expect(outside, findsOne);
    expect(
      find.descendant(of: outside, matching: find.text('draft.md')),
      findsOne,
    );
  });

  testWidgets('started with a file while the last library resumes, the '
      'library’s shell takes it', (tester) async {
    controller = FakeLibrarySession(resumePath: '/fake/library');
    await pumpApp(tester, startedWith: '/elsewhere/draft.md');
    // Taken once, by the shell: on its own, over the library.
    expect(outside, findsOne);
    await tester.tap(
      find.descendant(of: outside, matching: find.byType(BackButton)),
    );
    await settle(tester);
    expect(outside, findsNothing);
    expect(noteTree(), findsOne);
  });

  group('a book (#1318)', () {
    final needsLibrary = find.text(AppStrings.epubConvertNeedsLibrary);
    final dialog = find.byKey(const Key('epub-convert-dialog'));

    // The dialog reads the book on an isolate, which a test's fake clock
    // does not wait for: give it the real time to answer, then close it.
    Future<void> closeDialog(WidgetTester tester) async {
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
        final start = find.byKey(const Key('epub-convert-start'));
        if (start.evaluate().isNotEmpty &&
            tester.widget<FilledButton>(start).onPressed != null) {
          break;
        }
      }
      await tester.tap(find.text(AppStrings.actionCancel));
      await settle(tester);
    }

    testWidgets('a later launch’s book is offered for conversion, never '
        'opened on its own, and its file stays', (tester) async {
      await pumpApp(tester);
      await openLibrary(tester, filePicker);
      final dir = Directory.systemTemp.createTempSync('niman_launch_book');
      addTearDown(() => dir.deleteSync(recursive: true));
      final book = writeTestEpub(
        p.join(dir.path, 'Dune.epub'),
        chapters: const [(path: 'one.xhtml', body: '<p>Arrakis</p>')],
      );

      await launch(tester, book.path);
      expect(dialog, findsOne);
      expect(outside, findsNothing);
      expect(window.showCalls, 1);
      await closeDialog(tester);
      expect(book.existsSync(), isTrue);
    });

    testWidgets('with no library, a later launch’s book says a library is '
        'needed', (tester) async {
      await pumpApp(tester);
      await launch(tester, '/elsewhere/Dune.epub');
      expect(needsLibrary, findsOne);
      expect(outside, findsNothing);
      expect(find.byKey(const Key('open-outside-file')), findsOne);
    });

    testWidgets('started with a book and no library to resume, it says a '
        'library is needed', (tester) async {
      await pumpApp(tester, startedWith: '/elsewhere/Dune.epub');
      expect(needsLibrary, findsOne);
      expect(outside, findsNothing);
    });

    testWidgets('started with a book while the last library resumes, the '
        'shell offers it for conversion', (tester) async {
      controller = FakeLibrarySession(resumePath: '/fake/library');
      final dir = Directory.systemTemp.createTempSync('niman_launch_book');
      addTearDown(() => dir.deleteSync(recursive: true));
      final book = writeTestEpub(
        p.join(dir.path, 'Dune.epub'),
        chapters: const [(path: 'one.xhtml', body: '<p>Arrakis</p>')],
      );
      await pumpApp(tester, startedWith: book.path);
      expect(dialog, findsOne);
      expect(outside, findsNothing);
      await closeDialog(tester);
    });
  });
}
