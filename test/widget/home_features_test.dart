// #1109: the Home follows the library's features — a tile or an action whose
// feature is off is not built, the editor does not offer to add one, and the
// Home's file is never written for any of it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/home/home_tile_feature.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

const _phone = Size(390, 844);
const _desktop = Size(1600, 900);

Features _off(LibraryFeature feature) =>
    const Features().withSwitch(feature, on: false);

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> open(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          todoSourceFactoryProvider.overrideWithValue(
            (_) => FakeTodoSource(todo: ['Renew the domain']),
          ),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
  }

  Future<void> goHome(WidgetTester tester, {bool wide = false}) async {
    await tester.tap(find.byKey(Key(wide ? 'rail-home' : 'tab-home')));
    await settle(tester);
  }

  Finder tile(String id) => find.byKey(Key('home-tile-$id'));

  group('the classifiers', () {
    test('every tile kind and action kind answers a feature or core', () {
      expect(featureOfTile(HomeTileKind.journalToday), LibraryFeature.journal);
      expect(
        featureOfTile(HomeTileKind.journalCalendar),
        LibraryFeature.journal,
      );
      expect(featureOfTile(HomeTileKind.tasksDue), LibraryFeature.todo);
      expect(featureOfTile(HomeTileKind.eventsToday), LibraryFeature.calendar);
      expect(featureOfTile(HomeTileKind.search), LibraryFeature.search);
      expect(featureOfTile(HomeTileKind.study), LibraryFeature.kindFlashcards);
      for (final core in [
        HomeTileKind.actions,
        HomeTileKind.recent,
        HomeTileKind.pinned,
        HomeTileKind.topTags,
        HomeTileKind.randomNote,
      ]) {
        expect(featureOfTile(core), isNull, reason: core.name);
      }
      expect(featureOfAction(HomeActionKind.addTask), LibraryFeature.todo);
      expect(featureOfAction(HomeActionKind.journal), LibraryFeature.journal);
      expect(featureOfAction(HomeActionKind.capture), LibraryFeature.capture);
      expect(featureOfAction(HomeActionKind.newNote), isNull);
      expect(featureOfAction(HomeActionKind.openNote), isNull);
    });

    test('the layout under features hides the tiles, writes nothing', () {
      const layout = HomeLayout.defaults;
      final under = homeLayoutUnder(layout, _off(LibraryFeature.todo));
      expect(under['tasksDue']!.hidden, isTrue);
      expect(under['journalToday']!.hidden, isFalse);
      expect(layout['tasksDue']!.hidden, isFalse, reason: 'the source is not');
      expect(homeLayoutUnder(layout, const Features()), layout);
    });
  });

  testWidgets('a tile whose feature is off is not built; on again it is', (
    tester,
  ) async {
    await open(tester, _phone);
    await goHome(tester);
    expect(tile('tasksDue'), findsOne);
    expect(tile('journalToday'), findsOne);
    final kept = controller.libraryHome;

    controller.features.value = _off(LibraryFeature.todo);
    await settle(tester);
    expect(tile('tasksDue'), findsNothing);
    expect(tile('journalToday'), findsOne);
    expect(tile('recent'), findsOne, reason: 'core tiles stay');

    controller.features.value = _off(LibraryFeature.journal);
    await settle(tester);
    expect(tile('journalToday'), findsNothing);
    expect(tile('tasksDue'), findsOne);

    controller.features.value = const Features();
    await settle(tester);
    expect(tile('tasksDue'), findsOne);
    expect(tile('journalToday'), findsOne);
    expect(controller.libraryHome, kept, reason: 'the file was not written');
  });

  testWidgets('the actions of a feature that is off are not shown', (
    tester,
  ) async {
    await open(tester, _phone);
    await goHome(tester);
    for (final id in ['note', 'journal', 'task']) {
      expect(find.byKey(Key('home-action-$id')), findsOne, reason: id);
    }

    controller.features.value = _off(LibraryFeature.todo);
    await settle(tester);
    expect(find.byKey(const Key('home-action-task')), findsNothing);
    expect(find.byKey(const Key('home-action-note')), findsOne);
    expect(find.byKey(const Key('home-action-journal')), findsOne);

    controller.features.value = _off(LibraryFeature.journal);
    await settle(tester);
    expect(find.byKey(const Key('home-action-journal')), findsNothing);
    expect(find.byKey(const Key('home-action-task')), findsOne);

    controller.features.value = const Features();
    await settle(tester);
    expect(find.byKey(const Key('home-action-journal')), findsOne);
  });

  testWidgets('the desktop grid leaves out a tile that is off', (tester) async {
    controller.features.value = _off(LibraryFeature.todo);
    await open(tester, _desktop);
    await goHome(tester, wide: true);
    expect(tile('actions'), findsOne);
    expect(tile('journalToday'), findsOne);
    expect(tile('tasksDue'), findsNothing);
  });

  testWidgets('the editor does not offer a kind whose feature is off', (
    tester,
  ) async {
    controller.features.value = _off(LibraryFeature.kindFlashcards);
    await open(tester, _desktop);
    await goHome(tester, wide: true);
    await tester.tap(find.byKey(const Key('home-edit')));
    await settle(tester);

    expect(find.byKey(const Key('home-add-study')), findsNothing);
    expect(find.byKey(const Key('home-add-recent')), findsOne);
    final kept = controller.libraryHome;

    controller.features.value = const Features();
    await settle(tester);
    expect(find.byKey(const Key('home-add-study')), findsOne);
    expect(controller.libraryHome, kept, reason: 'nothing was written');
  });

  testWidgets('a tile that is off shows its sentence in the editor only', (
    tester,
  ) async {
    await open(tester, _desktop);
    await goHome(tester, wide: true);
    await tester.tap(find.byKey(const Key('home-edit')));
    await settle(tester);
    controller.features.value = _off(LibraryFeature.todo);
    await settle(tester);

    expect(tile('tasksDue'), findsOne);
    expect(find.text('Todo and reminders is off in this library'), findsOne);
  });
}
