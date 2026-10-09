// #535: editing the Home — on the desktop's grid in place, on the phone in
// a list of its own — and where each change is kept.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/todo/todo_source.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

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
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await tester.tap(
      find.byKey(Key(size == _desktop ? 'rail-home' : 'tab-home')),
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('home-edit')));
    await settle(tester);
  }

  HomeTile saved(String id) => controller.libraryHome![id]!;

  group('desktop', () {
    testWidgets('a tile dragged down a row lands there', (tester) async {
      await open(tester, _desktop);
      expect(find.byKey(const Key('home-add-panel')), findsOne);

      await tester.drag(
        find.byKey(const Key('home-drag-pinned')),
        const Offset(0, 124),
        kind: PointerDeviceKind.mouse,
      );
      await settle(tester);
      expect(saved('pinned').cell, (x: 2, y: 3, w: 2, h: 1));
    });

    testWidgets('a drag the pointer cancels leaves the tile (#686)', (
      tester,
    ) async {
      await open(tester, _desktop);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('home-drag-pinned'))),
        kind: PointerDeviceKind.mouse,
      );
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(0, 24));
        await tester.pump();
      }
      await gesture.cancel();
      await settle(tester);

      expect(controller.libraryHome, isNull, reason: 'nothing written');
    });

    testWidgets('a tile drawn settled is dropped from where it is drawn '
        '(#681)', (tester) async {
      // A tile with no cell yet, as a merge can leave one: drawn at the
      // foot, stored a million rows down.
      final pinned = HomeLayout.defaults['pinned']!;
      controller.libraryHome = HomeLayout.defaults.put(
        pinned.copyWith(cell: (x: 0, y: HomeTile.unplaced, w: 2, h: 1)),
      );
      await open(tester, _desktop);

      await tester.drag(
        find.byKey(const Key('home-drag-pinned')),
        const Offset(0, -124),
        kind: PointerDeviceKind.mouse,
      );
      await settle(tester);

      expect(
        saved('pinned').cell.y,
        lessThan(20),
        reason: 'a row above the foot, not a million rows down',
      );
    });

    testWidgets('a corner dragged right makes the tile wider', (tester) async {
      await open(tester, _desktop);
      await tester.drag(
        find.byKey(const Key('home-resize-recent')),
        const Offset(231, 0),
        kind: PointerDeviceKind.mouse,
      );
      await settle(tester);
      expect(saved('recent').cell.w, 2);
      final journal = saved('journalToday').cell;
      final recent = saved('recent').cell;
      expect(
        journal.y >= recent.y + recent.h || journal.y + journal.h <= recent.y,
        isTrue,
        reason: 'the tile it grew into moved out of its way',
      );
    });

    testWidgets('a hidden tile waits in the panel and comes back', (
      tester,
    ) async {
      await open(tester, _desktop);
      await tester.tap(find.byKey(const Key('home-hide-tasksDue')));
      await settle(tester);
      expect(saved('tasksDue').hidden, isTrue);
      expect(find.byKey(const Key('home-edit-tasksDue')), findsNothing);

      await tester.tap(find.byKey(const Key('home-show-tasksDue')));
      await settle(tester);
      expect(saved('tasksDue').hidden, isFalse);
      expect(find.byKey(const Key('home-edit-tasksDue')), findsOne);
    });

    testWidgets('a kind is added from the panel, once', (tester) async {
      await open(tester, _desktop);
      await tester.ensureVisible(find.byKey(const Key('home-add-topTags')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('home-add-topTags')));
      await settle(tester);
      expect(saved('topTags').hidden, isFalse);
      final row = tester.widget<ListTile>(
        find.byKey(const Key('home-add-topTags')),
      );
      expect(row.enabled, isFalse, reason: 'a Home holds one');
    });

    testWidgets('the menu moves a tile without a pointer', (tester) async {
      await open(tester, _desktop);
      final before = HomeLayout.defaults['actions']!.cell;
      await tester.tap(find.byKey(const Key('home-move-actions')));
      await settle(tester);
      await tester.tap(find.text('Wider').last);
      await settle(tester);
      expect(saved('actions').cell.w, before.w + 1);
    });

    testWidgets('only on this device, and back to the library', (tester) async {
      await open(tester, _desktop);
      await tester.tap(find.text('Only on this device'));
      await settle(tester);
      expect(controller.deviceHome, isNotNull);

      await tester.tap(find.byKey(const Key('home-hide-pinned')));
      await settle(tester);
      expect(controller.deviceHome!['pinned']!.hidden, isTrue);
      expect(controller.libraryHome, isNull, reason: 'library untouched');

      await tester.tap(find.text('This library'));
      await settle(tester);
      await tester.tap(
        find.byKey(const Key('home-use-library-dialog-confirm')),
      );
      await settle(tester);
      expect(controller.deviceHome, isNull);
      expect(find.byKey(const Key('home-edit-pinned')), findsOne);
    });

    testWidgets('reset asks, then puts the defaults back', (tester) async {
      controller.libraryHome = HomeLayout.defaults.hide('pinned');
      await open(tester, _desktop);
      await tester.tap(find.byKey(const Key('home-reset')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('home-reset-dialog-confirm')));
      await settle(tester);
      expect(controller.libraryHome, HomeLayout.defaults);
    });

    testWidgets('done leaves the editor for the Home', (tester) async {
      await open(tester, _desktop);
      await tester.tap(find.byKey(const Key('home-edit-done')));
      await settle(tester);
      expect(find.byKey(const Key('home-add-panel')), findsNothing);
      expect(find.byKey(const Key('home-tile-actions')), findsOne);
    });
  });

  group('phone', () {
    testWidgets('a switch hides a tile on every device', (tester) async {
      await open(tester, _phone);
      expect(find.byKey(const Key('home-column-editor')), findsOne);
      await tester.tap(find.byKey(const Key('home-switch-recent')));
      await settle(tester);
      expect(saved('recent').hidden, isTrue);

      await tester.pageBack();
      await settle(tester);
      expect(find.byKey(const Key('home-tile-recent')), findsNothing);
    });

    testWidgets('a saved search is added, set and shown', (tester) async {
      await controller.createNote(parentPath: '', name: 'Plans');
      controller.searchHits = [
        const SearchHit(
          noteId: 0,
          path: 'Plans.md',
          title: 'Plans',
          snippet: '',
        ),
      ];
      await open(tester, _phone);
      final list = find.descendant(
        of: find.byKey(const Key('home-column-editor')),
        matching: find.byType(Scrollable),
      );
      final add = find.byKey(const Key('home-add-search'));
      await tester.scrollUntilVisible(add, 200, scrollable: list.first);
      await tester.tap(add);
      await settle(tester);
      final id = controller.libraryHome!.tiles
          .firstWhere((t) => t.kind == HomeTileKind.search)
          .id;

      final settings = find.byKey(Key('home-settings-$id'));
      await tester.scrollUntilVisible(settings, -200, scrollable: list.first);
      await tester.tap(settings);
      await settle(tester);
      await tester.enterText(
        find.byKey(const Key('home-search-title')),
        'Plans',
      );
      await tester.enterText(
        find.byKey(const Key('home-search-query')),
        'plans',
      );
      await tester.tap(find.byKey(const Key('home-search-save')));
      await settle(tester);
      expect(saved(id).query, 'plans');
      expect(saved(id).title, 'Plans');

      await tester.pageBack();
      await settle(tester);
      // Plans is a recent note too: the one wanted is the search's.
      final row = find.descendant(
        of: find.byKey(Key('home-tile-$id')),
        matching: find.byKey(const Key('home-note-Plans.md')),
      );
      await tester.scrollUntilVisible(
        row,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('home-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(row, findsOne);
    });

    testWidgets('a handle drags a tile up the column', (tester) async {
      await open(tester, _phone);
      final handle = find.descendant(
        of: find.byKey(const ValueKey('tasksDue')),
        matching: find.byIcon(Icons.drag_indicator),
      );
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await settle(tester);

      final order = controller.libraryHome!.column.map((t) => t.id).toList();
      expect(
        order.indexOf('tasksDue'),
        lessThan(order.indexOf('journalToday')),
      );
    });
  });
}
