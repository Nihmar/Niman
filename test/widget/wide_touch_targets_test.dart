// #849, item 7: the wide shell's chrome was drawn for a mouse -- a rail of
// 38 px buttons, a 38 px tab row, a 44 px footer, an 8 px divider -- and
// an Android tablet shows it to a thumb. On the touch density (the
// platform's own, the one the tree's rows and menus already follow) every
// one of those targets is at least Material's 48 px; with a mouse's
// density they are as they were drawn.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/resize_divider.dart';
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

  Future<void> pumpTablet(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1024, 768));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
          windowControllerProvider.overrideWithValue(FakeWindowController()),
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

  /// Home pinned beside the note: its chip joins the row.
  Future<void> pinHome(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('rail-home')));
    await settle(tester);
  }

  Size sizeOf(WidgetTester tester, String key) {
    expect(find.byKey(Key(key)), findsOne, reason: key);
    return tester.getSize(find.byKey(Key(key)));
  }

  /// The railed buttons, the tab row's, the footer's.
  const targets = [
    'rail-home',
    'rail-files',
    'rail-search',
    'rail-library',
    'rail-settings',
    'note-tab-0',
    'note-tab-close-0',
    'tab-new',
    'tab-list',
    'new-item-menu',
    'open-trash',
    'toggle-sort',
    'view-list-toggle',
    'view-grid-toggle',
  ];

  testWidgets("on a touch density every target of the chrome is a thumb's", (
    tester,
  ) async {
    await pumpTablet(tester);
    for (final key in targets) {
      final size = sizeOf(tester, key);
      expect(
        size.width,
        greaterThanOrEqualTo(kMinInteractiveDimension),
        reason: '$key is ${size.width} wide',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
        reason: '$key is ${size.height} tall',
      );
    }
    // The rows and the bar that hold them make room for them.
    expect(
      sizeOf(tester, 'pane-tab-row').height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    expect(
      sizeOf(tester, 'tree-footer').height,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    expect(
      sizeOf(tester, 'shell-rail').width,
      greaterThanOrEqualTo(kMinInteractiveDimension),
    );
    await pinHome(tester);
    for (final key in const ['content-tab-home', 'content-tab-close-home']) {
      final size = sizeOf(tester, key);
      expect(
        size.width,
        greaterThanOrEqualTo(kMinInteractiveDimension),
        reason: key,
      );
      expect(
        size.height,
        greaterThanOrEqualTo(kMinInteractiveDimension),
        reason: key,
      );
    }
    expect(tester.takeException(), isNull, reason: 'and nothing overflows');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('and the divider is grabbed by a thumb', (tester) async {
    await pumpTablet(tester);
    final tree = tester.getRect(noteTree());
    final grab = tester.getRect(find.byKey(const Key('tree-divider')));
    expect(grab.width, ResizeDivider.touchGrabWidth);
    expect(grab.width, greaterThanOrEqualTo(kMinInteractiveDimension));
    // Over the islands' edges either side of the gap, as the mouse's is.
    expect(grab.center.dx, closeTo(tree.right + ResizeDivider.width / 2, 0.5));

    // A drag from the middle of the tree island's last 20 px moves it.
    final before = tree.width;
    await tester.dragFrom(
      Offset(tree.right - 20, tree.center.dy),
      const Offset(40, 0),
    );
    await settle(tester);
    expect(tester.getRect(noteTree()).width, closeTo(before + 40, 0.5));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('the footer keeps its buttons in the narrowest tree', (
    tester,
  ) async {
    await controller.setTreeWidth(200);
    await pumpTablet(tester);
    expect(tester.takeException(), isNull);
    final footer = tester.getRect(find.byKey(const Key('tree-footer')));
    expect(footer.width, closeTo(200, 1));
    // The row scrolls from its end: the sort button, last, is in view.
    final sort = tester.getRect(find.byKey(const Key('toggle-sort')));
    expect(sort.right, lessThanOrEqualTo(footer.right));
    expect(sort.width, greaterThanOrEqualTo(kMinInteractiveDimension));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('with a mouse the chrome is as it was drawn', (tester) async {
    await pumpTablet(tester);
    const pointer = {
      'rail-home': Size(38, 38),
      'rail-files': Size(38, 38),
      'rail-search': Size(38, 38),
      'rail-library': Size(38, 38),
      'rail-settings': Size(38, 38),
      'tab-new': Size(34, 32),
      'tab-list': Size(34, 32),
    };
    for (final MapEntry(:key, value: size) in pointer.entries) {
      expect(sizeOf(tester, key), size, reason: key);
    }
    expect(sizeOf(tester, 'shell-rail').width, 42);
    expect(sizeOf(tester, 'pane-tab-row').height, 38);
    expect(sizeOf(tester, 'note-tab-0').height, 30);
    expect(sizeOf(tester, 'note-tab-close-0'), const Size(20, 20));
    expect(sizeOf(tester, 'tree-footer').height, 44);
    await pinHome(tester);
    expect(sizeOf(tester, 'content-tab-home').height, 30);
    expect(sizeOf(tester, 'content-tab-close-home'), const Size(20, 20));
    expect(sizeOf(tester, 'view-list-toggle'), const Size(28, 26));
    expect(
      tester.getSize(find.byKey(const Key('tree-divider'))).width,
      ResizeDivider.grabWidth,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
