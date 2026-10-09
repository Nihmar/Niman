// #535: the Home in the command palette — every action there by its name,
// run from it, and Go to: Home for a Home the navigation hides.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/navigation_layout.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/home/home_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> open(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1280, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> palette(WidgetTester tester, String query) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await settle(tester);
    await tester.enterText(find.byKey(const Key('palette-field')), query);
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('an action is in the palette by its name, and runs', (
    tester,
  ) async {
    controller.libraryHome = const HomeLayout([
      HomeTile(
        id: 'actions',
        kind: HomeTileKind.actions,
        cell: (x: 0, y: 0, w: 2, h: 1),
        at: 0,
        actions: [
          HomeAction(
            id: 's',
            label: 'Standup',
            kind: HomeActionKind.newNote,
            name: FieldPreset.value('Standup notes'),
            open: false,
          ),
        ],
      ),
    ]);
    await open(tester);
    await palette(tester, 'stand');

    final row = find.byKey(const Key('palette-action-s'));
    expect(row, findsOne);
    expect(find.text('Home: Standup'), findsOne);
    await tester.tap(row);
    await settle(tester);
    expect(controller.contentOf('Standup notes.md'), isNotNull);
  });

  testWidgets('a hidden tile hides its actions from the palette', (
    tester,
  ) async {
    controller.libraryHome = HomeLayout.defaults.hide('actions');
    await open(tester);
    await palette(tester, 'task');
    expect(find.byKey(const Key('palette-action-task')), findsNothing);
  });

  testWidgets('Go to: Home opens a Home the navigation hides', (tester) async {
    await controller.setNavigation(
      const NavigationLayout(
        order: ['files', 'todo', 'search', 'home', 'quicknote', 'settings'],
        hidden: {'home'},
      ),
      onDevice: false,
    );
    await open(tester);
    expect(find.byKey(const Key('rail-home')), findsNothing);
    await palette(tester, 'Home');
    await tester.tap(
      find.descendant(
        of: find.byWidgetPredicate((w) => '${w.key}'.contains('palette-item-')),
        matching: find.text('Go to: Home', findRichText: true),
      ),
    );
    await settle(tester);
    expect(find.byType(HomeScreen), findsOne);
  });
}
