// #1064: the tree reads each folder once per revision, and in pages. Opening
// a folder reads that folder, closing one reads nothing, and a big folder
// reads a page until the list scrolls to the end of it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    controller = FakeLibrarySession();
    await controller.open('/lib', create: false);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
  });

  /// A tree whose open folders are [expanded], and whose pages are
  /// [pageSize] children.
  Widget tree(ValueNotifier<Set<String>> expanded, {int pageSize = 2000}) {
    return MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<Set<String>>(
          valueListenable: expanded,
          builder: (context, open, _) => NoteTree(
            controller: controller,
            selectedPath: null,
            expanded: open,
            pageSize: pageSize,
            onToggle: (_) {},
            onSelect: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('opening a folder reads it alone, closing one reads nothing', (
    tester,
  ) async {
    await controller.createFolder(parentPath: '', name: 'docs');
    await controller.createFolder(parentPath: '', name: 'other');
    await controller.createNote(parentPath: 'docs', name: 'inside');
    await controller.createNote(parentPath: 'other', name: 'beside');
    final expanded = ValueNotifier<Set<String>>(const {});
    addTearDown(expanded.dispose);
    await tester.pumpWidget(tree(expanded));
    await tester.pumpAndSettle();
    expect(controller.pageCalls, 1, reason: 'the root');

    expanded.value = {'docs'};
    await tester.pumpAndSettle();
    expect(find.text('inside.md'), findsOneWidget);
    expect(controller.pageCalls, 2, reason: 'docs alone, not the root again');

    expanded.value = {'docs', 'other'};
    await tester.pumpAndSettle();
    expect(find.text('beside.md'), findsOneWidget);
    expect(controller.pageCalls, 3, reason: 'other alone');

    expanded.value = {'other'};
    await tester.pumpAndSettle();
    expect(find.text('inside.md'), findsNothing);
    expect(controller.pageCalls, 3, reason: 'closing reads nothing');

    // Opened again: it is still read, from the cache.
    expanded.value = {'docs', 'other'};
    await tester.pumpAndSettle();
    expect(find.text('inside.md'), findsOneWidget);
    expect(controller.pageCalls, 3);
  });

  testWidgets('a change reads the open folders again, once', (tester) async {
    await controller.createFolder(parentPath: '', name: 'docs');
    await controller.createNote(parentPath: 'docs', name: 'inside');
    final expanded = ValueNotifier<Set<String>>(const {'docs'});
    addTearDown(expanded.dispose);
    await tester.pumpWidget(tree(expanded));
    await tester.pumpAndSettle();
    final before = controller.pageCalls;

    await controller.createNote(parentPath: 'docs', name: 'fresh');
    await tester.pumpAndSettle();

    expect(find.text('fresh.md'), findsOneWidget);
    expect(controller.pageCalls - before, 2, reason: 'the root and docs');
  });

  testWidgets('a note saved in place reads its own folder again, alone', (
    tester,
  ) async {
    // #1132: a title typed into a note's frontmatter re-read every open
    // folder after each save. The save says which folder it moved rows in.
    await controller.createFolder(parentPath: '', name: 'docs');
    await controller.createFolder(parentPath: '', name: 'other');
    await controller.createNote(parentPath: 'docs', name: 'inside');
    await controller.createNote(parentPath: 'other', name: 'beside');
    final expanded = ValueNotifier<Set<String>>(const {'docs', 'other'});
    addTearDown(expanded.dispose);
    await tester.pumpWidget(tree(expanded));
    await tester.pumpAndSettle();
    final before = controller.pageCalls;

    await controller.saveNote(
      'docs/inside.md',
      '---\ntitle: Renamed by its title\n---\n',
    );
    await tester.pumpAndSettle();

    expect(find.text('Renamed by its title'), findsOneWidget);
    expect(find.text('beside.md'), findsOneWidget);
    expect(controller.pageCalls - before, 1, reason: 'docs alone');
  });

  testWidgets('a big folder is read a page at a time as the list scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (var i = 0; i < 100; i++) {
      await controller.createNote(
        parentPath: '',
        name: 'n${i.toString().padLeft(3, '0')}',
      );
    }
    final expanded = ValueNotifier<Set<String>>(const {});
    addTearDown(expanded.dispose);
    await tester.pumpWidget(tree(expanded, pageSize: 20));
    await tester.pumpAndSettle();

    expect(controller.pageCalls, 1, reason: 'one page of twenty');
    expect(find.text('n000.md'), findsOneWidget);

    // Scroll to the end of what is loaded, and then of what comes.
    final list = find.byKey(const Key('note-tree-list'));
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
    }

    expect(find.text('n099.md'), findsOneWidget);
    expect(controller.pageCalls, 5, reason: 'five pages of twenty, no more');
  });
}
