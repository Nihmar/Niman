// The app's lists of choices that open through `showActionSheet` (#712,
// #781): the tree row's long-press menu, the outline and the heading-level
// picker. Each is checked in both shapes — the phone's sheet from the
// bottom edge and the pointer's pop-up menu — since the shape is the
// action sheet's to choose and the behaviour is the caller's to keep.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/heading_level_sheet.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/outline_panel.dart';
import 'package:niman/src/ui/shell_row_menu.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

/// The two shapes a list of choices takes.
enum _Shape {
  /// A thumb's: a modal bottom sheet.
  sheet,

  /// A pointer's: a pop-up menu.
  menu;

  ThemeData get theme =>
      ThemeData(visualDensity: this == menu ? VisualDensity.compact : null);
}

/// Whether [finder] sits inside the list keyed [key], in [shape]: a sheet
/// is a [BottomSheet], a menu is not.
Finder _inList(Finder finder, Key key, _Shape shape) {
  final list = find.byKey(key);
  final inside = find.descendant(of: list, matching: finder);
  return switch (shape) {
    _Shape.sheet => find.descendant(
      of: find.byType(BottomSheet),
      matching: inside,
    ),
    _Shape.menu => inside,
  };
}

/// Checks the list is drawn in [shape].
void _expectShape(_Shape shape) => expect(
  find.byType(BottomSheet),
  shape == _Shape.sheet ? findsOneWidget : findsNothing,
);

/// A button opening [show] in an app of [shape].
Widget _opener(_Shape shape, Future<void> Function(BuildContext) show) =>
    MaterialApp(
      theme: shape.theme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

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

    testWidgets('a long press is a sheet, and still runs its actions', (
      tester,
    ) async {
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

      Finder inSheet(Finder finder) =>
          find.ancestor(of: finder, matching: find.byType(BottomSheet));
      expect(inSheet(find.byKey(const Key('menu-rename'))), findsOneWidget);
      expect(inSheet(find.byKey(const Key('menu-delete'))), findsOneWidget);

      // The sheet scrolls once its rows outgrow the cap (the desktop
      // "open outside Niman" entries push it there, issue #76), so reach
      // the row rather than assuming where it landed.
      final rename = find.byKey(const Key('menu-rename'));
      await tester.ensureVisible(rename);
      await settle(tester);
      await tester.tap(rename);
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    for (final shape in _Shape.values) {
      testWidgets('resolves to the action picked (${shape.name})', (
        tester,
      ) async {
        final note = Note(
          id: 1,
          path: 'Note.md',
          parent: 0,
          name: 'Note.md',
          nameKey: nameSortKey('Note.md'),
          isDir: false,
          size: 0,
          modified: DateTime.fromMillisecondsSinceEpoch(0),
          created: DateTime.fromMillisecondsSinceEpoch(0),
          pinned: false,
        );
        String? picked;
        await tester.pumpWidget(
          _opener(shape, (context) async {
            picked = await showRowMenuSheet(
              context,
              note: note,
              isQuickNote: false,
            );
          }),
        );
        await tester.tap(find.text('open'));
        await settle(tester);

        _expectShape(shape);
        expect(find.byKey(const Key('row-menu-header')), findsOneWidget);
        final rename = find.byKey(const Key('menu-rename'));
        await tester.ensureVisible(rename);
        await settle(tester);
        await tester.tap(rename);
        await settle(tester);

        expect(picked, 'rename');
        expect(find.byKey(const Key('menu-rename')), findsNothing);
      });
    }
  });

  group('the outline', () {
    Widget app(String note, _Shape shape) => MaterialApp(
      theme: shape.theme,
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

    Future<void> load(WidgetTester tester, String note, _Shape shape) async {
      await tester.pumpWidget(app(note, shape));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    }

    const outline = Key('outline-sheet');

    for (final shape in _Shape.values) {
      testWidgets('opens and jumps to the heading picked (${shape.name})', (
        tester,
      ) async {
        await load(tester, '# One\n\ntext\n\n## Two\n\nmore\n', shape);

        await tester.tap(find.byKey(const Key('outline-toggle')));
        await settle(tester);

        _expectShape(shape);
        expect(_inList(find.text('One'), outline, shape), findsOneWidget);
        expect(_inList(find.text('Two'), outline, shape), findsOneWidget);

        await tester.tap(_inList(find.text('Two'), outline, shape));
        await settle(tester);

        // The list closed and the note is still the one open.
        expect(find.byKey(outline), findsNothing);
        final editor = tester.widget<NoteView>(find.byType(NoteView));
        expect(editor.path, '/notes/a.md');
      });

      testWidgets('takes no room from the editor when closed '
          '(${shape.name})', (tester) async {
        // It used to be an inline panel that pushed the editor up.
        await load(tester, '# One\n\ntext\n', shape);

        expect(find.byKey(outline), findsNothing);
        expect(find.text('One'), findsNothing);
      });

      testWidgets('a note with no headings says so (${shape.name})', (
        tester,
      ) async {
        await load(tester, 'just a paragraph\n', shape);

        await tester.tap(find.byKey(const Key('outline-toggle')));
        await settle(tester);

        _expectShape(shape);
        expect(
          _inList(find.text('No headings'), outline, shape),
          findsOneWidget,
        );
      });

      testWidgets('dismissing it jumps nowhere (${shape.name})', (
        tester,
      ) async {
        final entries = <OutlineEntry>[
          const OutlineEntry(level: 1, text: 'One', line: 0),
        ];
        int? picked;
        var returned = false;
        await tester.pumpWidget(
          _opener(shape, (context) async {
            picked = await showOutlineSheet(context, entries: entries);
            returned = true;
          }),
        );
        await tester.tap(find.text('open'));
        await settle(tester);
        expect(find.byKey(outline), findsOneWidget);
        await tester.tapAt(const Offset(20, 20)); // the barrier
        await settle(tester);

        expect(find.byKey(outline), findsNothing);
        expect(returned, isTrue);
        expect(picked, isNull);
      });
    }
  });

  group('the heading-level picker', () {
    const picker = Key('heading-level-sheet');

    for (final shape in _Shape.values) {
      testWidgets('resolves to the level picked (${shape.name})', (
        tester,
      ) async {
        int? picked;
        await tester.pumpWidget(
          _opener(shape, (context) async {
            picked = await showHeadingLevelDialog(context);
          }),
        );

        await tester.tap(find.text('open'));
        await settle(tester);

        _expectShape(shape);
        expect(
          _inList(find.byKey(const ValueKey<int>(1)), picker, shape),
          findsOneWidget,
        );
        expect(
          _inList(find.byKey(const ValueKey<int>(6)), picker, shape),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey<int>(3)));
        await settle(tester);

        expect(picked, 3);
        expect(find.byKey(picker), findsNothing);
      });

      testWidgets('dismissing it picks nothing (${shape.name})', (
        tester,
      ) async {
        int? picked;
        var returned = false;
        await tester.pumpWidget(
          _opener(shape, (context) async {
            picked = await showHeadingLevelDialog(context);
            returned = true;
          }),
        );

        await tester.tap(find.text('open'));
        await settle(tester);
        await tester.tapAt(const Offset(20, 20)); // the barrier
        await settle(tester);

        expect(returned, isTrue);
        expect(picked, isNull);
      });
    }
  });
}
