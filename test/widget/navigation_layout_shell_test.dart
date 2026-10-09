// #536: the bar and the rail follow the library's navigation layout — its
// order, its hidden destinations — and a hidden one opened anyway is a
// page on the phone, with back to where it was opened from.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/shell_layout.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  const layout = NavigationLayout(
    order: ['search', 'files', 'settings', 'todo', 'quicknote'],
    hidden: {'todo'},
  );

  setUp(() async {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    await controller.setNavigation(layout, onDevice: false);
  });

  Future<void> open(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> ctrl(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
  }

  // The phone's way to a hidden tab: the palette's Go to.
  Future<void> goToTodo(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('search-open-palette')));
    await settle(tester);
    expect(find.byKey(const Key('command-palette')), findsOne);
    await tester.enterText(find.byKey(const Key('palette-field')), 'Todo');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => '${w.key}'.contains('palette-item-')),
        matching: find.text('Go to: Todo', findRichText: true),
      ),
    );
    await settle(tester);
  }

  double left(WidgetTester tester, String key) =>
      tester.getTopLeft(find.byKey(Key(key))).dx;

  testWidgets('phone: the bar keeps the order and leaves the hidden out', (
    tester,
  ) async {
    await open(tester, const Size(390, 844));

    expect(find.byKey(const Key('tab-todo')), findsNothing);
    expect(left(tester, 'tab-search'), lessThan(left(tester, 'tab-files')));
    expect(left(tester, 'tab-files'), lessThan(left(tester, 'tab-settings')));
    expect(
      left(tester, 'tab-settings'),
      lessThan(left(tester, 'tab-quicknote')),
    );
  });

  testWidgets('phone: a hidden tab opened anyway is a page, back leaves it', (
    tester,
  ) async {
    await open(tester, const Size(390, 844));
    await tester.tap(find.byKey(const Key('tab-search')));
    await settle(tester);

    await goToTodo(tester);
    expect(find.byType(TodoTab), findsOne);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byKey(const Key('hidden-tab-back')));
    await settle(tester);
    expect(find.byType(NavigationBar), findsOne);
    expect(
      tester.widget<ShellTabBar>(find.byType(ShellTabBar)).current,
      ShellTab.search,
    );

    // The system back leaves it the same way.
    await goToTodo(tester);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(NavigationBar), findsOne);
    expect(find.byType(TodoTab), findsNothing);
  });

  testWidgets('phone: back follows a switch to and from a visited hidden tab', (
    tester,
  ) async {
    // Both tabs mounted already, so neither switch below needs a first
    // build: the back key must still learn the tab is a page, and stop
    // being one after it.
    bool canPop() => tester
        .widget<PopScope<Object?>>(
          find
              .descendant(
                of: find.byType(NarrowShellLayout),
                matching: find.byWidgetPredicate((w) => w is PopScope),
              )
              .first,
        )
        .canPop;
    await open(tester, const Size(390, 844));
    await tester.tap(find.byKey(const Key('tab-search')));
    await settle(tester);
    await goToTodo(tester);
    await tester.tap(find.byKey(const Key('hidden-tab-back')));
    await settle(tester);
    expect(canPop(), isTrue);

    await goToTodo(tester);
    expect(canPop(), isFalse);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(TodoTab), findsNothing);
    expect(canPop(), isTrue);
  });

  testWidgets('phone: with Files hidden, the shell starts on the first shown', (
    tester,
  ) async {
    await controller.setNavigation(
      const NavigationLayout(
        order: ['quicknote', 'files', 'todo', 'search', 'settings'],
        hidden: {'files'},
      ),
      onDevice: false,
    );
    await open(tester, const Size(390, 844));

    expect(find.byKey(const Key('hidden-tab-back')), findsNothing);
    expect(
      tester.widget<ShellTabBar>(find.byType(ShellTabBar)).current,
      ShellTab.todo,
    );
  });

  testWidgets('wide: the rail follows, Settings stays at the foot', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));

    expect(find.byKey(const Key('rail-todo')), findsNothing);
    double top(String key) => tester.getTopLeft(find.byKey(Key(key))).dy;
    expect(top('rail-search'), lessThan(top('rail-files')));
    expect(top('rail-files'), lessThan(top('rail-quicknote')));
    expect(top('rail-quicknote'), lessThan(top('rail-settings')));

    await ctrl(tester, LogicalKeyboardKey.digit2);
    expect(find.byType(TodoTab), findsOne);
    expect(
      tester.widget<ShellRail>(find.byType(ShellRail)).current,
      ShellTab.todo,
    );
  });

  testWidgets("the device's own layout wins over the library's", (
    tester,
  ) async {
    await controller.setNavigation(
      const NavigationLayout(
        order: ['files', 'todo', 'search'],
        hidden: {'search'},
      ),
      onDevice: true,
    );
    await open(tester, const Size(390, 844));

    expect(find.byKey(const Key('tab-todo')), findsOne);
    expect(find.byKey(const Key('tab-search')), findsNothing);
  });

  group('the start destination (#706)', () {
    for (final (size, bar) in [
      (const Size(390, 844), 'phone'),
      (const Size(1400, 900), 'wide'),
    ]) {
      testWidgets('$bar: the shell opens on it', (tester) async {
        await controller.setNavigation(
          const NavigationLayout(start: 'home'),
          onDevice: false,
        );
        await open(tester, size);
        final current = size.width < 600
            ? tester.widget<ShellTabBar>(find.byType(ShellTabBar)).current
            : tester.widget<ShellRail>(find.byType(ShellRail)).current;
        expect(current, ShellTab.home);
      });
    }

    testWidgets('hidden, it gives way to Files', (tester) async {
      await controller.setNavigation(
        const NavigationLayout(
          order: ['files', 'todo', 'search', 'quicknote', 'settings'],
          hidden: {'todo'},
          start: 'todo',
        ),
        onDevice: false,
      );
      await open(tester, const Size(390, 844));
      expect(
        tester.widget<ShellTabBar>(find.byType(ShellTabBar)).current,
        ShellTab.files,
      );
    });

    testWidgets("the device's own start wins", (tester) async {
      await controller.setNavigation(
        const NavigationLayout(start: 'home'),
        onDevice: false,
      );
      await controller.setNavigation(
        const NavigationLayout(start: 'search'),
        onDevice: true,
      );
      await open(tester, const Size(390, 844));
      expect(
        tester.widget<ShellTabBar>(find.byType(ShellTabBar)).current,
        ShellTab.search,
      );
    });
  });
}
