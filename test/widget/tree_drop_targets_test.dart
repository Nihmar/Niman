// #1028: a drag that carries several paths — marked rows of the tree (#996)
// — let go on the grid's breadcrumb and on the grid's background hands the
// move the paths it would change, and none of the others. The tree's own
// targets are in tree_drag_test.dart.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/ui/folder_crumbs.dart';
import 'package:niman/src/ui/folder_grid.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() => session = FakeLibrarySession());
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  /// [target] under a small source that drags [data], as a marked row of the
  /// tree does.
  Widget harness(Widget target, List<String> data) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Draggable<List<String>>(
            data: data,
            feedback: const SizedBox(width: 20, height: 20),
            child: const SizedBox(
              key: Key('source'),
              width: 80,
              height: 40,
              child: Text('source'),
            ),
          ),
          Expanded(child: target),
        ],
      ),
    ),
  );

  /// The source dragged with the mouse and let go at [to].
  Future<void> dragTo(WidgetTester tester, Offset to) async {
    final start = tester.getCenter(find.byKey(const Key('source')));
    final mouse = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      await mouse.moveTo(Offset.lerp(start, to, step / 10)!);
      await tester.pump();
    }
    await mouse.up();
    await tester.pumpAndSettle();
  }

  group('the breadcrumb', () {
    final moves = <String>[];

    Widget crumbs(List<String> data) => harness(
      Align(
        alignment: Alignment.topLeft,
        child: FolderCrumbs(
          folder: 'Projects/Niman',
          onOpen: (_) {},
          onUp: () {},
          onMove: (paths, folder) =>
              moves.add('${paths.join(', ')} -> $folder'),
        ),
      ),
      data,
    );

    setUp(moves.clear);

    testWidgets('takes the paths a drop on a crumb would move', (tester) async {
      await tester.pumpWidget(
        crumbs([
          'Projects/Niman/a.md',
          'Projects/b.md', // already in Projects
          'Projects', // itself
          'Projects/Niman', // already in Projects
          'Elsewhere/c.md',
          'Projects/Niman/sub',
        ]),
      );

      await dragTo(tester, tester.getCenter(find.text('Projects')));

      expect(moves, [
        'Projects/Niman/a.md, Elsewhere/c.md, Projects/Niman/sub -> Projects',
      ]);
    });

    testWidgets('the Library crumb is the root', (tester) async {
      await tester.pumpWidget(crumbs(['Projects/b.md', 'top.md']));

      await dragTo(
        tester,
        tester.getCenter(find.text(AppStrings.libraryCrumb)),
      );

      // top.md is at the root already.
      expect(moves, ['Projects/b.md -> ']);
    });

    testWidgets('a drop that would move nothing runs nothing', (tester) async {
      await tester.pumpWidget(crumbs(['Projects/b.md', 'Projects']));

      await dragTo(tester, tester.getCenter(find.text('Projects')));

      expect(moves, isEmpty);
    });
  });

  group('the grid background', () {
    final moves = <String>[];

    setUp(moves.clear);

    Future<void> pumpGrid(WidgetTester tester, List<String> data) async {
      await session.open('/lib', create: false);
      await session.createFolder(parentPath: '', name: 'Projects');
      await session.createNote(parentPath: 'Projects', name: 'Roadmap');
      await tester.pumpWidget(
        harness(
          FolderGrid(
            controller: session,
            folder: 'Projects',
            sort: TreeSort.nameAsc,
            selectedPath: null,
            onOpen: (_) {},
            onGoTo: (_) {},
            onUp: () {},
            onMove: (paths, folder) =>
                moves.add('${paths.join(', ')} -> $folder'),
          ),
          data,
        ),
      );
      await tester.pumpAndSettle();
    }

    Offset background(WidgetTester tester) =>
        tester.getBottomLeft(find.byKey(const Key('folder-grid-scroll'))) +
        const Offset(40, -20);

    testWidgets('takes the paths a drop into the folder would move', (
      tester,
    ) async {
      await pumpGrid(tester, [
        'Projects/Roadmap.md', // already there
        'Other/a.md',
        'Other/b.md',
        'Projects', // itself
        'Projects/Deep/x.md',
      ]);

      await dragTo(tester, background(tester));

      expect(moves, ['Other/a.md, Other/b.md, Projects/Deep/x.md -> Projects']);
    });

    testWidgets('a drop that would move nothing runs nothing', (tester) async {
      await pumpGrid(tester, ['Projects/Roadmap.md', 'Projects']);

      await dragTo(tester, background(tester));

      expect(moves, isEmpty);
    });
  });
}
