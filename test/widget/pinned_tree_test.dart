// T-M4-02/04: the tree shows a note under its frontmatter title, shows
// its date, and lists the pinned notes above the folder tree — pinned and
// unpinned from the row's own menu.
import 'package:copist/src/app.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/ui/note_view.dart';
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

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const CopistApp(),
    );
  }

  /// Opens a library holding the given notes (path → content).
  Future<void> openWith(
    WidgetTester tester,
    Map<String, String> notes,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    for (final entry in notes.entries) {
      await controller.createNote(
        parentPath: '',
        name: entry.key,
        content: entry.value,
      );
    }
    await settle(tester);
  }

  /// The pinned block's heading.
  Finder pinnedHeading() => find.byKey(const Key('pinned-heading'));

  testWidgets('a note is listed under its frontmatter title', (tester) async {
    await openWith(tester, {
      'raw-name': '---\ntitle: A Proper Title\n---\nbody',
    });

    expect(noteRow('A Proper Title'), findsOneWidget);
    expect(noteRow('raw-name.md'), findsNothing);
  });

  testWidgets('a note without a title keeps its filename', (tester) async {
    await openWith(tester, {'plain': 'no frontmatter'});

    expect(noteRow('plain.md'), findsOneWidget);
  });

  testWidgets('a frontmatter date shows on the row', (tester) async {
    await openWith(tester, {'dated': '---\ndate: 2026-03-01\n---\nbody'});

    expect(noteRow('2026-03-01'), findsOneWidget);
  });

  testWidgets('there is no pinned block until something is pinned', (
    tester,
  ) async {
    await openWith(tester, {'plain': 'body'});

    expect(pinnedHeading(), findsNothing);
  });

  testWidgets('a pinned note appears in the block above the tree', (
    tester,
  ) async {
    await openWith(tester, {'pinned': '---\npinned: true\n---\nbody'});

    expect(pinnedHeading(), findsOneWidget);
    expect(find.byKey(const Key('pinned-pinned.md')), findsOneWidget);
    // Once in the pinned block, once where it actually lives.
    expect(noteRow('pinned.md'), findsNWidgets(2));
  });

  testWidgets('the pinned block shows a note from any folder', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Deep');
    await controller.createNote(
      parentPath: 'Deep',
      name: 'buried',
      content: '---\npinned: true\n---\nbody',
    );
    await settle(tester);

    // The folder is collapsed, so the only row for it is the pinned one.
    expect(find.byKey(const Key('pinned-Deep/buried.md')), findsOneWidget);
    expect(noteRow('buried.md'), findsOneWidget);
  });

  testWidgets('the row menu pins a note and the block appears', (tester) async {
    await openWith(tester, {'plain': 'body\n'});

    await tester.longPress(noteRow('plain.md'));
    await settle(tester);
    expect(find.byKey(const Key('menu-pin')), findsOneWidget);
    await tester.tap(find.byKey(const Key('menu-pin')));
    await settle(tester);

    expect(pinnedHeading(), findsOneWidget);
    expect(
      controller.contentOf('plain.md'),
      '---\npinned: true\n---\n\nbody\n',
    );
  });

  testWidgets('the row menu unpins it again and the block goes', (
    tester,
  ) async {
    await openWith(tester, {'plain': '---\npinned: true\n---\n\nbody\n'});
    expect(pinnedHeading(), findsOneWidget);

    await tester.longPress(find.byKey(const Key('pinned-plain.md')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('menu-pin')));
    await settle(tester);

    expect(pinnedHeading(), findsNothing);
    expect(controller.contentOf('plain.md'), 'body\n');
  });

  testWidgets('a folder row offers no pin action', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Folder');
    await settle(tester);

    await tester.longPress(noteRow('Folder'));
    await settle(tester);

    expect(find.byKey(const Key('menu-pin')), findsNothing);
  });

  testWidgets('the heading counts what is behind it', (tester) async {
    await openWith(tester, {
      'a': '---\npinned: true\n---\nbody',
      'b': '---\npinned: true\n---\nbody',
    });

    expect(find.text('Pinned · 2'), findsOneWidget);
  });

  testWidgets('tapping the heading rolls the section up and down', (
    tester,
  ) async {
    await openWith(tester, {'pinned': '---\npinned: true\n---\nbody'});
    expect(find.byKey(const Key('pinned-pinned.md')), findsOneWidget);

    await tester.tap(pinnedHeading());
    await settle(tester);

    // Rolled up: the rows are gone, the heading and its count stay.
    expect(find.byKey(const Key('pinned-pinned.md')), findsNothing);
    expect(find.text('Pinned · 1'), findsOneWidget);
    expect(await controller.pinnedCollapsed, isTrue);

    await tester.tap(pinnedHeading());
    await settle(tester);

    expect(find.byKey(const Key('pinned-pinned.md')), findsOneWidget);
    expect(await controller.pinnedCollapsed, isFalse);
  });

  testWidgets('a library that was left rolled up opens rolled up', (
    tester,
  ) async {
    await controller.setPinnedCollapsed(collapsed: true);
    await openWith(tester, {'pinned': '---\npinned: true\n---\nbody'});

    expect(find.text('Pinned · 1'), findsOneWidget);
    expect(find.byKey(const Key('pinned-pinned.md')), findsNothing);
    // The tree below it is untouched by the roll-up.
    expect(noteRow('pinned.md'), findsOneWidget);
  });

  testWidgets('tapping a pinned row selects that note', (tester) async {
    await openWith(tester, {
      'pinned': '---\npinned: true\ntitle: Pinned One\n---\nbody',
    });

    await tester.tap(find.byKey(const Key('pinned-pinned.md')));
    await settle(tester);

    expect(find.byType(NoteView), findsOneWidget);
  });
}
