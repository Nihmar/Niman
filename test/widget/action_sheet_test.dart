// One pop-up menu shape for the whole app (user, 2026-09-09): the tree's
// long-press menu, the outline and the heading-level picker all open as a
// modal sheet from the bottom edge.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/heading_level_sheet.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/outline_panel.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

/// Whether [finder] sits inside a modal bottom sheet.
Finder inSheet(Finder finder) =>
    find.ancestor(of: finder, matching: find.byType(BottomSheet));

void main() {
  group('the tree row menu', () {
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

    testWidgets('is a sheet, and still runs its actions', (tester) async {
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

      expect(inSheet(find.byKey(const Key('menu-rename'))), findsOneWidget);
      expect(inSheet(find.byKey(const Key('menu-delete'))), findsOneWidget);

      await tester.tap(find.byKey(const Key('menu-rename')));
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('the outline', () {
    Widget app(String note) => MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/notes/a.md',
          showLineNumbers: true,
          autofocusEditor: false,
          readNote: (_) async => note,
          writeNote: (_, _) async {},
        ),
      ),
    );

    testWidgets('opens as a sheet and jumps to the heading picked', (
      tester,
    ) async {
      await tester.pumpWidget(app('# One\n\ntext\n\n## Two\n\nmore\n'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      await tester.tap(find.byKey(const Key('outline-toggle')));
      await settle(tester);

      expect(find.byKey(const Key('outline-sheet')), findsOneWidget);
      expect(inSheet(find.text('One')), findsOneWidget);
      expect(inSheet(find.text('Two')), findsOneWidget);

      await tester.tap(inSheet(find.text('Two')));
      await settle(tester);

      // The sheet closed and the caret is on the heading's line.
      expect(find.byKey(const Key('outline-sheet')), findsNothing);
      final editor = tester.widget<NoteView>(find.byType(NoteView));
      expect(editor.path, '/notes/a.md');
    });

    testWidgets('it no longer takes room from the editor when closed', (
      tester,
    ) async {
      // It used to be an inline panel that pushed the editor up.
      await tester.pumpWidget(app('# One\n\ntext\n'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byKey(const Key('outline-sheet')), findsNothing);
      expect(find.text('One'), findsNothing);
    });

    testWidgets('a note with no headings says so', (tester) async {
      await tester.pumpWidget(app('just a paragraph\n'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      await tester.tap(find.byKey(const Key('outline-toggle')));
      await settle(tester);

      expect(find.byKey(const Key('outline-sheet')), findsOneWidget);
      expect(inSheet(find.text('No headings')), findsOneWidget);
    });

    testWidgets('dismissing it jumps nowhere', (tester) async {
      final entries = <OutlineEntry>[
        const OutlineEntry(level: 1, text: 'One', line: 0),
      ];
      int? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showOutlineSheet(context, entries: entries);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tapAt(const Offset(20, 20)); // the barrier
      await settle(tester);

      expect(picked, isNull);
    });
  });

  group('the heading-level picker', () {
    testWidgets('is a sheet, and resolves to the level picked', (tester) async {
      int? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showHeadingLevelDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await settle(tester);

      expect(find.byKey(const Key('heading-level-sheet')), findsOneWidget);
      expect(inSheet(find.byKey(const ValueKey<int>(1))), findsOneWidget);
      expect(inSheet(find.byKey(const ValueKey<int>(6))), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<int>(3)));
      await settle(tester);

      expect(picked, 3);
    });

    testWidgets('dismissing it picks nothing', (tester) async {
      int? picked;
      var returned = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  picked = await showHeadingLevelDialog(context);
                  returned = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await settle(tester);
      await tester.tapAt(const Offset(20, 20)); // the barrier
      await settle(tester);

      expect(returned, isTrue);
      expect(picked, isNull);
    });
  });
}
