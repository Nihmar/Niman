// #849: the wide shell on a touch device -- an Android tablet -- keeps
// the desktop's panes and takes what a touch device needs of them: the
// system bars kept clear, a rail that scrolls under the keyboard, the
// palette by two fingers, and a Back that steps inside the app.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/folder_grid.dart';
import 'package:niman/src/ui/history/note_version_screen.dart';
import 'package:niman/src/ui/palette/palette_swipe.dart';
import 'package:niman/src/ui/settings_section_pane.dart';
import 'package:niman/src/ui/tree.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

const _tablet = Size(1024, 768);

/// A tablet short enough for the rail to be taller than the window once
/// the keyboard is up: its shortest side is the line itself.
const _shortTablet = Size(960, 600);

final _android = TargetPlatformVariant.only(TargetPlatform.android);

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    setSurfaceSize(tester, size);
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
    await controller.createNote(parentPath: '', name: 'beta');
    await settle(tester);
  }

  /// Raises the software keyboard to [height] dp, as a field being tapped
  /// does.
  Future<void> raiseKeyboard(WidgetTester tester, double height) async {
    tester.view.viewInsets = FakeViewPadding(bottom: height);
    addTearDown(tester.view.resetViewInsets);
    await settle(tester);
  }

  /// Opens `alpha.md` from the tree, as a tap does.
  Future<void> openAlpha(WidgetTester tester) async {
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
  }

  /// Drags two fingers down the middle of the shell.
  Future<void> twoFingerSwipe(WidgetTester tester) async {
    final centre = tester.getCenter(find.byType(PaletteSwipe));
    final fingers = [
      for (var i = 0; i < 2; i++)
        await tester.startGesture(centre + Offset(i * 24.0 - 12, 0)),
    ];
    for (var step = 0; step < 4; step++) {
      for (final finger in fingers) {
        await finger.moveBy(const Offset(0, (PaletteSwipe.distance + 20) / 4));
      }
      await tester.pump();
    }
    for (final finger in fingers) {
      await finger.up();
    }
    await settle(tester);
  }

  final rail = find.byKey(const Key('shell-rail'));
  final paneTabs = find.byKey(const Key('pane-tab-row'));
  final palette = find.byKey(const Key('command-palette'));

  group('the system bars', () {
    testWidgets('a tablet keeps its chrome out of them', (tester) async {
      const padding = FakeViewPadding(left: 32, top: 24, right: 40, bottom: 20);
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await pumpApp(tester, _tablet);
      await openAlpha(tester);

      final railBox = tester.getRect(rail);
      expect(railBox.left, greaterThanOrEqualTo(32));
      expect(railBox.top, greaterThanOrEqualTo(24));
      expect(railBox.bottom, lessThanOrEqualTo(768 - 20));
      // Both ends of the panes: the tree at the foot, the note's tab row
      // at the right edge.
      expect(
        tester.getRect(find.byType(NoteTree)).bottom,
        lessThanOrEqualTo(768 - 20),
      );
      expect(tester.getRect(paneTabs).right, lessThanOrEqualTo(1024 - 40));
      expect(tester.getRect(paneTabs).top, greaterThanOrEqualTo(24));
    }, variant: _android);
  });

  group('the keyboard', () {
    testWidgets('the rail of a short tablet scrolls: Settings and the library '
        'stay reachable', (tester) async {
      await pumpApp(tester, _shortTablet);
      await raiseKeyboard(tester, 330);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(rail, findsOne);

      for (final key in const ['rail-library', 'rail-settings']) {
        final button = find.byKey(Key(key));
        await tester.ensureVisible(button);
        await tester.pump();
        expect(button.hitTestable(), findsOne, reason: key);
        expect(
          tester.getRect(button).bottom,
          lessThanOrEqualTo(600 - 330),
          reason: '$key is above the keyboard',
        );
      }
    }, variant: _android);
  });

  group('the command palette', () {
    testWidgets('a tablet has no key for it either: swipe and menu', (
      tester,
    ) async {
      await pumpApp(tester, _tablet);
      await twoFingerSwipe(tester);
      expect(palette, findsOne);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(palette, findsNothing);

      await openAlpha(tester);
      await tester.tap(find.byKey(const Key('note-menu')));
      await settle(tester);
      expect(find.byKey(const Key('note-menu-palette')), findsOne);
    }, variant: _android);

    testWidgets('a desktop window keeps its key and no swipe', (tester) async {
      await pumpApp(tester, const Size(1200, 800));
      await twoFingerSwipe(tester);
      expect(palette, findsNothing);
      await openAlpha(tester);
      await tester.tap(find.byKey(const Key('note-menu')));
      await settle(tester);
      expect(find.byKey(const Key('note-menu-palette')), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('Settings on a tablet', () {
    testWidgets('a short tablet opens it as a window with two columns', (
      tester,
    ) async {
      // 600 dp tall: the window is 552 dp inside its margins, and the
      // pages in it read that as the screen. The device is still a
      // tablet, so Settings is the list beside a section, not a phone's
      // list of pages.
      await pumpApp(tester, _shortTablet);
      await tester.tap(find.byKey(const Key('rail-settings')));
      await settle(tester);
      expect(find.byType(SettingsSectionPane), findsOne);
    }, variant: _android);
  });

  group('Back on a tablet', () {
    testWidgets('closes the open note, then leaves the app', (tester) async {
      await pumpApp(tester, _tablet);
      await openAlpha(tester);
      expect(find.byKey(const Key('note-tab-0')), findsOne);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await settle(tester);
      expect(find.byKey(const Key('note-tab-0')), findsNothing);
      expect(rail, findsOne);

      expect(
        await tester.binding.handlePopRoute(),
        isFalse,
        reason: 'nothing left to step out of: Back leaves the app',
      );
    }, variant: _android);

    testWidgets('closes the side panel lying over the note first (#977)', (
      tester,
    ) async {
      // Under 1000 dp the panel has no room to dock: it is an overlay.
      await pumpApp(tester, const Size(900, 700));
      await openAlpha(tester);
      await tester.tap(find.byKey(const Key('dock-toggle')));
      await settle(tester);
      expect(find.byKey(const Key('dock-overlay')), findsOne);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await settle(tester);
      expect(find.byKey(const Key('dock-overlay')), findsNothing);
      expect(
        find.byKey(const Key('note-tab-0')),
        findsOne,
        reason: 'the note under it stays',
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await settle(tester);
      expect(find.byKey(const Key('note-tab-0')), findsNothing);
    }, variant: _android);

    testWidgets('closes a pinned Home before the note under it', (
      tester,
    ) async {
      await pumpApp(tester, _tablet);
      await openAlpha(tester);
      await tester.tap(find.byKey(const Key('rail-home')));
      await settle(tester);
      expect(find.byKey(const Key('content-tab-home')), findsOne);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await settle(tester);
      expect(find.byKey(const Key('content-tab-home')), findsNothing);
      expect(
        find.byKey(const Key('note-tab-0')),
        findsOne,
        reason: 'the note it was pinned over stays',
      );
    }, variant: _android);

    testWidgets('closes the compare page covering the note before the note', (
      tester,
    ) async {
      controller.seedVersion(
        'alpha.md',
        number: 1,
        savedAt: DateTime(2026, 10, 3, 14, 2),
        text: 'the old alpha',
      );
      await pumpApp(tester, const Size(1280, 800));
      await openAlpha(tester);
      await tester.tap(find.byKey(const Key('dock-pane-history')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('dock-history-1')));
      await settle(tester);
      expect(find.byType(NoteVersionScreen), findsOne);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await settle(tester);
      expect(find.byType(NoteVersionScreen), findsNothing);
      expect(find.byKey(const Key('compare-tab')), findsNothing);
      expect(
        find.byKey(const Key('note-tab-0')),
        findsOne,
        reason: 'the note it covered stays',
      );
    }, variant: _android);

    testWidgets('steps a folder up in the grid', (tester) async {
      await controller.setTreeView(TreeView.grid);
      await pumpApp(tester, _tablet);
      await controller.createFolder(parentPath: '', name: 'Projects');
      await settle(tester);
      await tester.tap(find.byKey(const Key('grid-tile-Projects')));
      await settle(tester);
      expect(
        tester.widget<FolderGrid>(find.byType(FolderGrid)).folder,
        'Projects',
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await settle(tester);
      expect(tester.widget<FolderGrid>(find.byType(FolderGrid)).folder, '');
    }, variant: _android);
  });

  group('The compare page on a 1024 px tablet', () {
    // The History dock needs 1000 px, so this is the narrowest window that
    // can hold both it and a compare tab (#927).
    testWidgets('opens and closes without a layout overflow', (tester) async {
      controller.seedVersion(
        'alpha.md',
        number: 1,
        savedAt: DateTime(2026, 10, 3, 14, 2),
        text: 'the old alpha',
      );
      await pumpApp(tester, _tablet);
      await openAlpha(tester);
      await tester.tap(find.byKey(const Key('dock-pane-history')));
      await settle(tester);

      // Frame by frame: the overflow showed only while the tab animated.
      Future<void> animate() async {
        await tester.pump();
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await settle(tester);
      }

      await tester.tap(find.byKey(const Key('dock-history-1')));
      await animate();
      expect(find.byKey(const Key('compare-tab')), findsOne);
      expect(find.byType(NoteVersionScreen), findsOne);

      await tester.tap(find.byKey(const Key('compare-tab-close')));
      await animate();
      expect(find.byKey(const Key('compare-tab')), findsNothing);
      expect(find.byType(NoteVersionScreen), findsNothing);

      expect(tester.takeException(), isNull);
    }, variant: _android);
  });
}
