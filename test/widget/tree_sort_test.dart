// The tree's sort direction is part of its row cache key (#371): flipping
// the sort must reorder the rows on the same revision, without a re-index
// to push them along. The rows follow the flag the chevron is drawn from —
// not the settings write that persists it — so a write that fails still
// leaves the two showing the same order.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession session;
  late FakeFilePicker filePicker;

  setUp(() {
    session = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });
  tearDown(() async {
    await session.close();
    await session.dispose();
  });

  /// A bare [NoteTree] over the given controller — the cache is the unit
  /// under test, so the shell around it is not.
  Widget treeFor(FakeLibrarySession controller, {bool nameDesc = false}) {
    return MaterialApp(
      home: Scaffold(
        body: NoteTree(
          controller: controller,
          selectedPath: null,
          expanded: const <String>{},
          nameDesc: nameDesc,
          onToggle: (_) {},
          onSelect: (_) {},
        ),
      ),
    );
  }

  /// The vertical position of the row showing `name`, for order checks.
  double topOf(WidgetTester tester, String name) =>
      tester.getCenter(noteRow('$name.md')).dy;

  testWidgets('a sort flip reorders the rows on the same revision', (
    tester,
  ) async {
    await session.open('/lib', create: false);
    await session.createNote(parentPath: '', name: 'charlie', content: 'x');
    await session.createNote(parentPath: '', name: 'alpha', content: 'x');
    await session.createNote(parentPath: '', name: 'bravo', content: 'x');

    await tester.pumpWidget(treeFor(session));
    await tester.pumpAndSettle();
    expect(topOf(tester, 'alpha'), lessThan(topOf(tester, 'bravo')));
    expect(topOf(tester, 'bravo'), lessThan(topOf(tester, 'charlie')));

    // Only the direction changes: same controller, same revision, same
    // expanded set. The chevron's flag flips and the rows have to follow it.
    await tester.pumpWidget(treeFor(session, nameDesc: true));
    await tester.pumpAndSettle();

    expect(topOf(tester, 'charlie'), lessThan(topOf(tester, 'bravo')));
    expect(topOf(tester, 'bravo'), lessThan(topOf(tester, 'alpha')));
  });

  testWidgets('a controller change re-reads the pinned roll-up', (
    tester,
  ) async {
    final second = FakeLibrarySession();
    addTearDown(() async {
      await second.close();
      await second.dispose();
    });

    await session.open('/one', create: false);
    await session.createNote(
      parentPath: '',
      name: 'pinned',
      content: '---\npinned: true\n---\nbody',
    );
    await session.setPinnedCollapsed(collapsed: true);

    await second.open('/two', create: false);
    await second.createNote(
      parentPath: '',
      name: 'pinned',
      content: '---\npinned: true\n---\nbody',
    );
    await second.setPinnedCollapsed(collapsed: false);

    await tester.pumpWidget(treeFor(session));
    await tester.pumpAndSettle();
    // The first library was left rolled up.
    expect(find.byKey(const Key('pinned-pinned.md')), findsNothing);

    // The second keeps it open: carrying the old roll-up over would hide it.
    await tester.pumpWidget(treeFor(second));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pinned-pinned.md')), findsOneWidget);
  });

  // -- the shell, where the chevron and the tree meet -------------------

  Widget app() => ProviderScope(
    overrides: [librarySessionProvider.overrideWithValue(session)],
    child: const NimanApp(),
  );

  /// The chevron's rotation, in turns: 0 ascending, 0.5 descending.
  double chevronTurns(WidgetTester tester) => tester
      .widget<AnimatedRotation>(
        find.descendant(
          of: find.byKey(const Key('toggle-sort')),
          matching: find.byType(AnimatedRotation),
        ),
      )
      .turns;

  Future<void> openShell(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(app());
    await tester.pump();
    await openLibrary(tester, filePicker);
    await session.createNote(parentPath: '', name: 'charlie');
    await session.createNote(parentPath: '', name: 'alpha');
    await session.createNote(parentPath: '', name: 'bravo');
    await settle(tester);
  }

  testWidgets('a settings write that fails leaves the two consistent', (
    tester,
  ) async {
    await openShell(tester);
    expect(chevronTurns(tester), 0);

    // The write never lands, so no re-index follows it: the chevron turns
    // anyway and the rows must turn over with it, not stay behind on the
    // order the index already answered.
    session.failTreeSort = true;
    await tester.tap(find.byKey(const Key('toggle-sort')));
    await settle(tester);

    expect(await session.treeSort, TreeSort.nameAsc, reason: 'write failed');
    expect(chevronTurns(tester), 0.5);
    expect(topOf(tester, 'charlie'), lessThan(topOf(tester, 'bravo')));
    expect(topOf(tester, 'bravo'), lessThan(topOf(tester, 'alpha')));
  });
}
