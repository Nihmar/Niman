// #751: a save reindexes a note — its size and its time — and nothing a
// name-ordered tree draws: that tree must not read its rows again for it.
// The field orders read size and times, so for them every change is rows.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/tree.dart';

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

  Widget buildApp() => ProviderScope(
    overrides: [librarySessionProvider.overrideWithValue(controller)],
    child: const NimanApp(),
  );

  /// Opens the library and puts one note in it, so the tree draws a row.
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
  }

  testWidgets("a save leaves a name-ordered tree's rows where they are", (
    tester,
  ) async {
    await open(tester);
    final reads = controller.treeCalls;
    expect(reads, greaterThan(0), reason: 'the tree was flattened once');
    controller.bumpContents();
    await settle(tester);
    expect(
      controller.treeCalls,
      reads,
      reason: 'a save moved nothing the tree draws',
    );
  });

  // #1132: two flattens on the device log followed an open of the 1.5 MB
  // note. They were folders toggled — a tap each — not the open: a note
  // opened moves nothing the tree draws, and reads no row again.
  testWidgets('opening a note leaves the tree rows where they are', (
    tester,
  ) async {
    await open(tester);
    final reads = controller.treeCalls;
    final pages = controller.pageCalls;
    expect(find.byType(NoteView), findsNothing);
    await tester.tap(find.text('alpha.md'));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget, reason: 'the note opened');
    expect(controller.treeCalls, reads, reason: 'no flatten for an open');
    expect(controller.pageCalls, pages, reason: 'no folder read again');
  });

  testWidgets('a save flattens a tree the field order reads', (tester) async {
    await controller.setTreeSort(TreeSort.modifiedDesc);
    await open(tester);
    final reads = controller.treeCalls;
    controller.bumpContents();
    await settle(tester);
    expect(
      controller.treeCalls,
      greaterThan(reads),
      reason: 'the order reads the time a save wrote',
    );
  });

  // #760: the tree keys its rows on a revision number, and the field orders
  // and the name orders read two counters that count apart. Rows cached
  // under one counter's number must not answer for the other's.
  testWidgets('a new note shows after the order turns from a field to a name', (
    tester,
  ) async {
    await controller.open('/lib', create: false);
    await controller.createNote(parentPath: '', name: 'alpha');
    // A save: the contents counter runs ahead of the tree's.
    controller.bumpContents();
    expect(controller.revision, greaterThan(controller.treeRevision));
    final sort = ValueNotifier<TreeSort>(TreeSort.modifiedDesc);
    addTearDown(sort.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<TreeSort>(
            valueListenable: sort,
            builder: (context, value, _) => NoteTree(
              controller: controller,
              sort: value,
              selectedPath: null,
              expanded: const <String>{},
              onToggle: (_) {},
              onSelect: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ahead = controller.revision;

    sort.value = TreeSort.nameAsc;
    await tester.pumpAndSettle();
    expect(find.text('alpha.md'), findsOneWidget);

    // New notes until the tree's counter reaches the number the field
    // order last read: each one must show.
    var index = 0;
    while (controller.treeRevision < ahead) {
      final name = 'note$index';
      index++;
      await controller.createNote(parentPath: '', name: name);
      await tester.pumpAndSettle();
      expect(
        find.text('$name.md'),
        findsOneWidget,
        reason:
            'tree revision '
            '${controller.treeRevision}, contents revision $ahead',
      );
    }
  });
}
