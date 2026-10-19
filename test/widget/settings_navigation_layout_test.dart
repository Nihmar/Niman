// #536: Settings → Library → Navigation — a switch hides a destination,
// Settings is locked, the order is dragged, and "Only on this device"
// keeps the layout on the device instead of in the library.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/ui/settings_navigation_layout.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession session;

  setUp(() async {
    session = FakeLibrarySession();
    await session.open('/lib', create: true);
  });

  tearDown(() => session.dispose());

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsNavigationLayoutScreen(controller: session)),
    );
    await tester.pumpAndSettle();
  }

  List<String> previewed(WidgetTester tester) => [
    for (final d
        in tester.widget<ShellTabBar>(find.byType(ShellTabBar)).destinations)
      d.name,
  ];

  testWidgets('a switch hides a destination; Settings has a lock instead', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(const Key('navigation-switch-settings')), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOne);

    await tester.tap(find.byKey(const Key('navigation-switch-todo')));
    await tester.pumpAndSettle();

    final saved = await session.navigation;
    // Study starts hidden (#533), and the saved layout says so.
    expect(saved.library?.hidden, {'todo', 'study'});
    expect(saved.device, isNull);
    expect(previewed(tester), [
      'files',
      'search',
      'home',
      'quicknote',
      'settings',
    ]);
  });

  // Derived, not listed: a destination added later (the Home, #535) must
  // not change what these two prove.
  final names = [for (final d in shellDestinations()) d.name];
  final hideable = [
    for (final n in names)
      if (!lockedDestinations.contains(n)) n,
  ];
  final lastShown = [
    for (final n in names)
      if (n == hideable.first || lockedDestinations.contains(n)) n,
  ];

  testWidgets('the last destination shown besides Settings keeps its switch '
      'on (#667)', (tester) async {
    await pump(tester);
    // A destination hidden from the start (Study, #533) is off already.
    for (final name in hideable.skip(1)) {
      if (defaultHiddenDestinations.contains(name)) continue;
      await tester.tap(find.byKey(Key('navigation-switch-$name')));
      await tester.pumpAndSettle();
    }
    final last = find.byKey(Key('navigation-switch-${hideable.first}'));
    expect(tester.widget<Switch>(last).onChanged, isNull);

    await tester.tap(last);
    await tester.pumpAndSettle();

    expect(previewed(tester), lastShown);
    expect(tester.takeException(), isNull);
  });

  test('a layout that hides all but Settings shows the first back (#667)', () {
    final layout = NavigationLayout(order: names, hidden: hideable.toSet());

    expect([for (final d in visibleDestinations(layout)) d.name], lastShown);
  });

  testWidgets('dragging a row moves the destination', (tester) async {
    await pump(tester);
    final handle = find.descendant(
      of: find.byKey(const Key('navigation-row-search')),
      matching: find.byIcon(Icons.drag_handle),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(previewed(tester).first, 'search');
    expect((await session.navigation).library?.order.first, 'search');
  });

  testWidgets('only on this device keeps the layout on the device', (
    tester,
  ) async {
    await session.setNavigation(
      const NavigationLayout(hidden: {'todo'}, order: ['todo']),
      onDevice: false,
    );
    await pump(tester);

    await tester.tap(find.text('Only on this device'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navigation-switch-search')));
    await tester.pumpAndSettle();

    var saved = await session.navigation;
    expect(saved.library?.hidden, {'todo'}, reason: 'the library untouched');
    expect(saved.device?.hidden, {'todo', 'search', 'study'});

    await tester.tap(find.text('This library'));
    await tester.pumpAndSettle();
    saved = await session.navigation;
    expect(saved.device, isNull);
    expect(previewed(tester), [
      'files',
      'search',
      'home',
      'quicknote',
      'settings',
    ]);
  });

  testWidgets('a wide window previews the rail beside the list', (
    tester,
  ) async {
    await pump(tester, size: const Size(1200, 800));
    expect(find.byType(ShellTabBar), findsNothing);
    expect(find.byType(ShellRail), findsOne);
  });

  testWidgets('the start is chosen among the shown, and a hidden one says '
      'which took its place (#706)', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('navigation-start')));
    await tester.pumpAndSettle();
    // Settings and the quick note are no place to open on.
    expect(find.byKey(const Key('navigation-start-settings')), findsNothing);
    expect(find.byKey(const Key('navigation-start-quicknote')), findsNothing);
    await tester.tap(find.byKey(const Key('navigation-start-home')).last);
    await tester.pumpAndSettle();
    expect((await session.navigation).library?.start, 'home');

    await tester.tap(find.byKey(const Key('navigation-switch-home')));
    await tester.pumpAndSettle();
    final saved = (await session.navigation).library!;
    expect(saved.start, 'home', reason: 'kept, to come back with Home');
    expect(saved.hidden, {'home', 'study'});
    expect(
      find.text(
        AppStrings.navigationStartHidden(
          AppStrings.tabHome,
          AppStrings.tabFiles,
        ),
      ),
      findsOne,
    );
    expect(
      find.byKey(const Key('navigation-start-home')),
      findsNothing,
      reason: 'a hidden destination cannot be picked',
    );
  });

  // #1109: the two layers. A feature that is off greys the row in its
  // place, with the link where the switch was, and writes nothing.
  group('a feature that is off', () {
    Future<void> turnOff(WidgetTester tester, LibraryFeature feature) async {
      session.features.value = const Features().withSwitch(feature, on: false);
      await tester.pumpAndSettle();
    }

    testWidgets('keeps its row, greyed, with the link to Features', (
      tester,
    ) async {
      final opened = <bool>[];
      await session.setNavigation(
        const NavigationLayout(order: ['search', 'files', 'todo']),
        onDevice: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsNavigationLayoutScreen(
            controller: session,
            openFeatures: () => opened.add(true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await turnOff(tester, LibraryFeature.todo);

      final row = find.byKey(const Key('navigation-row-todo'));
      expect(row, findsOne, reason: 'it keeps its place');
      expect(tester.widget<ListTile>(row).enabled, isFalse);
      expect(
        find.descendant(
          of: row,
          matching: find.text(AppStrings.featureOffInLibrary),
        ),
        findsOne,
      );
      expect(find.byKey(const Key('navigation-switch-todo')), findsNothing);

      // Where the switch was, the link; it leads to Features.
      await tester.tap(find.byKey(const Key('navigation-features-todo')));
      expect(opened, [true]);
    });

    testWidgets('is left out of the preview, and nothing is written', (
      tester,
    ) async {
      await pump(tester);
      expect(previewed(tester), contains('todo'));
      await turnOff(tester, LibraryFeature.todo);

      expect(previewed(tester), isNot(contains('todo')));
      expect((await session.navigation).library, isNull);
      expect((await session.navigation).device, isNull);

      session.features.value = const Features();
      await tester.pumpAndSettle();
      expect(previewed(tester), contains('todo'));
      expect(find.byKey(const Key('navigation-switch-todo')), findsOne);
    });

    testWidgets('keeps the switch it was given, to come back with', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('navigation-switch-todo')));
      await tester.pumpAndSettle();
      final saved = await session.navigation;
      await turnOff(tester, LibraryFeature.todo);

      expect((await session.navigation).library?.hidden, saved.library?.hidden);
      session.features.value = const Features();
      await tester.pumpAndSettle();
      // Hidden by Navigation: still hidden, its switch off.
      expect(
        tester
            .widget<Switch>(find.byKey(const Key('navigation-switch-todo')))
            .value,
        isFalse,
      );
      expect(previewed(tester), isNot(contains('todo')));
    });

    testWidgets('Opens on is chosen among what is shown', (tester) async {
      await session.setNavigation(
        const NavigationLayout(
          order: ['todo', 'files', 'settings'],
          start: 'todo',
        ),
        onDevice: false,
      );
      await pump(tester);
      expect(
        tester
            .widget<DropdownButton<ShellTab>>(
              find.byKey(const Key('navigation-start')),
            )
            .value,
        ShellTab.todo,
      );
      await turnOff(tester, LibraryFeature.todo);
      expect(
        tester
            .widget<DropdownButton<ShellTab>>(
              find.byKey(const Key('navigation-start')),
            )
            .value,
        ShellTab.files,
      );
    });
  });
}
