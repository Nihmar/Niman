// The wide layout's islands: the tree, the panes and the side panel are
// rounded islands on the chrome's base, a gap from the window's edges and
// from each other. The panes do not move when the tree or the panel comes
// and goes but by the edge that has to; Zen takes the window edge to edge;
// the phone has no islands at all.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/island.dart';
import 'package:niman/src/ui/resize_divider.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(
            FakeWindowController(customTitleBar: true),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'alpha');
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await settle(tester);
  }

  final panes = find.byKey(const Key('panes-island'));
  final tree = find.byKey(const Key('tree-island'));
  final dock = find.byKey(const Key('dock-island'));
  const size = Size(1400, 900);
  const gap = Island.gap;

  /// The clip [island] puts around what it holds.
  ClipRRect clipOf(WidgetTester tester, Finder island) => tester.widget(
    find.descendant(of: island, matching: find.byType(ClipRRect)).first,
  );

  testWidgets('the tree, the panes and the side panel float on the base, '
      'rounded and a gap apart', (tester) async {
    await pumpAt(tester, size);
    final bar = tester.getRect(find.byKey(const Key('title-bar')));
    final treeRect = tester.getRect(tree);
    final panesRect = tester.getRect(panes);
    final dockRect = tester.getRect(dock);

    // The gap around: under the title bar, past the rail, before the
    // window's right and bottom edges.
    for (final rect in [treeRect, panesRect, dockRect]) {
      expect(rect.top, bar.bottom + gap);
      expect(rect.bottom, size.height - gap);
    }
    expect(treeRect.left, ShellRail.width + 1 + gap);
    expect(dockRect.right, size.width - gap);
    // The rail's buttons stand off the tree by the islands' gap (and the
    // base's pixel), no more: the glyphs sit near the middle between the
    // window's edge and the panel.
    final button = tester.getRect(find.byKey(const Key('rail-files')));
    expect(treeRect.left - button.right, gap + 1);
    expect(
      (button.left - (treeRect.left - button.right)).abs(),
      lessThanOrEqualTo(gap),
    );
    // The dividers are the base between two islands.
    expect(panesRect.left, treeRect.right + ResizeDivider.width);
    expect(dockRect.left, panesRect.right + ResizeDivider.width);
    // Drawing nothing, they still take the islands' full height to grab.
    for (final divider in ['tree-divider', 'dock-divider']) {
      expect(tester.getRect(find.byKey(Key(divider))).height, panesRect.height);
    }

    for (final island in [tree, panes, dock]) {
      final clip = clipOf(tester, island);
      expect(clip.borderRadius, BorderRadius.circular(Island.radius));
      expect(clip.clipBehavior, Clip.antiAlias);
    }

    // The base is the title bar's color, the island the note's ground.
    final scheme = Theme.of(tester.element(panes)).colorScheme;
    expect(
      tester
          .widget<Scaffold>(
            find.ancestor(of: panes, matching: find.byType(Scaffold)).first,
          )
          .backgroundColor,
      scheme.surfaceContainer,
    );
    final ground = tester.widget<Material>(
      find.descendant(of: panes, matching: find.byType(Material)).first,
    );
    expect(ground.color, scheme.surface);
  });

  testWidgets(
    'the tabs start at the panes island, with the tree and without',
    (tester) async {
      await pumpAt(tester, size);
      Rect tab() => tester.getRect(find.byKey(const Key('note-tab-0')));
      expect(tab().left, tester.getRect(panes).left);

      await tester.tap(find.byKey(const Key('toggle-sidebar')));
      await settle(tester);
      expect(tree, findsNothing);
      expect(tab().left, tester.getRect(panes).left);
    },
    // A desktop draws the bar's toggle at its own density: on a phone's
    // the tabs lined up while a desktop put them 6 px left.
    variant: TargetPlatformVariant.desktop(),
  );

  testWidgets('the tree and the side panel come and go, and the panes keep '
      'every other edge', (tester) async {
    await pumpAt(tester, size);
    final before = tester.getRect(panes);

    await tester.tap(find.byKey(const Key('toggle-sidebar')));
    await settle(tester);
    expect(tree, findsNothing);
    final noTree = tester.getRect(panes);
    expect(noTree.left, ShellRail.width + 1 + gap);
    expect(noTree.top, before.top);
    expect(noTree.right, before.right);
    expect(noTree.bottom, before.bottom);

    await tester.tap(find.byKey(const Key('dock-toggle')));
    await settle(tester);
    expect(dock, findsNothing);
    final alone = tester.getRect(panes);
    expect(alone.left, noTree.left);
    expect(alone.top, before.top);
    expect(alone.right, size.width - gap);
  });

  testWidgets('Zen takes the window edge to edge, square', (tester) async {
    await pumpAt(tester, size);
    await press(tester, LogicalKeyboardKey.f11);
    final zenBar = tester.getRect(find.byKey(const Key('zen-title-bar')));
    final rect = tester.getRect(panes);
    expect(rect.left, 0);
    expect(rect.right, size.width);
    expect(rect.top, zenBar.bottom);
    expect(rect.bottom, size.height);
    final clip = clipOf(tester, panes);
    expect(clip.borderRadius, BorderRadius.zero);
    expect(clip.clipBehavior, Clip.none);

    await press(tester, LogicalKeyboardKey.f11);
    expect(clipOf(tester, panes).clipBehavior, Clip.antiAlias);
    expect(tester.getRect(panes).left, greaterThan(gap));
  });

  testWidgets('a tab other than Files is one island too', (tester) async {
    await pumpAt(tester, size);
    await tester.tap(find.byKey(const Key('rail-todo')));
    await settle(tester);
    final islands = find.byType(Island).hitTestable();
    expect(islands, findsOne);
    final rect = tester.getRect(islands);
    expect(rect.left, ShellRail.width + 1 + gap);
    expect(rect.right, size.width - gap);
  });

  testWidgets('the phone has no islands', (tester) async {
    await pumpAt(tester, const Size(400, 800));
    expect(find.byType(Island, skipOffstage: false), findsNothing);
  });
}
