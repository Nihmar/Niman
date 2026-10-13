// #849: a phone is a phone, on every orientation. Turned to landscape it is
// 780-915 dp wide, wider than the shell's old width-only line, and used to
// get the desktop's rail, panes and floating Settings. The shape now asks
// what the device is: Android with a shortest side under 600 dp is a phone
// and keeps the phone's layout; a tablet keeps the wide one, with the
// touch device's insets, Back, rail and palette.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/palette/palette_swipe.dart';
import 'package:niman/src/ui/tree.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/fake_window_controller.dart';
import '../fakes/shell_harness.dart';

const _phonePortrait = Size(390, 844);
const _phoneLandscape = Size(844, 390);
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

  /// Turns the window to [size], as a rotation does: the same app, a new
  /// surface.
  Future<void> turnTo(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
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

  final tabs = find.byKey(const Key('shell-tabs'));
  final rail = find.byKey(const Key('shell-rail'));
  final paneTabs = find.byKey(const Key('pane-tab-row'));
  final fullNote = find.byKey(const ValueKey('full-note'));
  final palette = find.byKey(const Key('command-palette'));

  group('the line between a phone and a tablet', () {
    testWidgets('a phone is Android under 600 dp on its shortest side', (
      tester,
    ) async {
      late bool phone;
      late bool wide;
      setSurfaceSize(tester, _phoneLandscape);
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            phone = isPhone(context);
            wide = isWideShell(context);
            return const SizedBox();
          },
        ),
      );
      expect(phone, isTrue, reason: '844x390 is a phone turned sideways');
      expect(wide, isFalse, reason: 'and no wider a shell for it');

      setSurfaceSize(tester, _shortTablet);
      await tester.pump();
      expect(phone, isFalse, reason: '600 dp is the first tablet');
      expect(wide, isTrue);
    }, variant: _android);

    testWidgets('a desktop is never a phone, however small its window', (
      tester,
    ) async {
      late bool phone;
      late bool wide;
      setSurfaceSize(tester, const Size(500, 400));
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            phone = isPhone(context);
            wide = isWideShell(context);
            return const SizedBox();
          },
        ),
      );
      expect(phone, isFalse);
      expect(wide, isFalse, reason: 'a narrow window is narrow by width');

      setSurfaceSize(tester, const Size(844, 390));
      await tester.pump();
      expect(phone, isFalse);
      expect(wide, isTrue, reason: 'a wide, short desktop window is wide');
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('the shape', () {
    testWidgets('a phone in landscape has the phone chrome', (tester) async {
      await pumpApp(tester, _phoneLandscape);
      expect(tabs, findsOne);
      expect(rail, findsNothing);

      await openAlpha(tester);
      // A page of its own with a Back, not a pane under a tab row.
      expect(fullNote, findsOne);
      expect(
        find.descendant(of: fullNote, matching: find.byType(BackButton)),
        findsOne,
      );
      expect(paneTabs, findsNothing);
    }, variant: _android);

    testWidgets('turning it keeps the shape, the note and its Back', (
      tester,
    ) async {
      await pumpApp(tester, _phonePortrait);
      expect(tabs, findsOne);
      expect(rail, findsNothing);
      final tabShell = tester.element(
        find.byKey(const ValueKey('tab-shell'), skipOffstage: false),
      );

      await turnTo(tester, _phoneLandscape);
      expect(tabs, findsOne);
      expect(rail, findsNothing);
      await turnTo(tester, _phonePortrait);
      expect(tabs, findsOne);

      await openAlpha(tester);
      expect(fullNote, findsOne);
      final note = tester.element(fullNote);

      await turnTo(tester, _phoneLandscape);
      expect(fullNote, findsOne, reason: 'the note stays open');
      expect(rail, findsNothing);
      expect(paneTabs, findsNothing);
      await turnTo(tester, _phonePortrait);
      expect(fullNote, findsOne);
      await turnTo(tester, _phoneLandscape);

      // Nothing was unmounted on the way: the same elements, so the undo,
      // the find bar, the scroll and the search query went along.
      expect(
        identical(tester.element(fullNote), note),
        isTrue,
        reason: 'the open note is the same widget tree after every turn',
      );
      expect(
        identical(
          tester.element(
            find.byKey(const ValueKey('tab-shell'), skipOffstage: false),
          ),
          tabShell,
        ),
        isTrue,
        reason: 'and so are the tabs under it',
      );

      // Its Back still closes it, in either orientation.
      expect(await tester.binding.handlePopRoute(), isTrue);
      await settle(tester);
      expect(fullNote, findsNothing);
      expect(tabs, findsOne);
      expect(find.byType(NoteTree), findsOne);
    }, variant: _android);

    testWidgets('a tablet keeps the wide layout', (tester) async {
      await pumpApp(tester, _tablet);
      expect(rail, findsOne);
      expect(tabs, findsNothing);

      await openAlpha(tester);
      expect(paneTabs, findsOne, reason: 'the open notes head the pane');
      expect(fullNote, findsNothing);

      await turnTo(tester, const Size(768, 1024));
      expect(rail, findsOne);
      expect(paneTabs, findsOne);
      expect(tabs, findsNothing);
    }, variant: _android);

    testWidgets('a desktop window follows its width, as it did', (
      tester,
    ) async {
      await pumpApp(tester, const Size(1200, 800));
      expect(rail, findsOne);
      await turnTo(tester, const Size(500, 800));
      expect(tabs, findsOne);
      expect(rail, findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('the keyboard', () {
    testWidgets('a phone in landscape lays out with it up', (tester) async {
      await pumpApp(tester, _phoneLandscape);
      await raiseKeyboard(tester, 230);
      expect(tester.takeException(), isNull);
      expect(rail, findsNothing);
      expect(tabs, findsOne);
      await openAlpha(tester);
      expect(tester.takeException(), isNull);
      expect(fullNote, findsOne);
    }, variant: _android);

    testWidgets('and so does the new item menu, opened with it up', (
      tester,
    ) async {
      await pumpApp(tester, _phoneLandscape);
      await raiseKeyboard(tester, 230);
      await tester.tap(find.byKey(const Key('new-note-fab')));
      await settleFabMenu(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('new-item-menu-scroll')), findsOne);
    }, variant: _android);

    testWidgets('the new item menu in landscape reaches its first entry', (
      tester,
    ) async {
      await pumpApp(tester, _phoneLandscape);
      await tester.tap(find.byKey(const Key('new-note-fab')));
      await settleFabMenu(tester);
      expect(tester.takeException(), isNull);
      final scroll = find.byKey(const Key('new-item-menu-scroll'));
      await tester.drag(scroll, const Offset(0, 2000));
      await settleFabMenu(tester);
      expect(
        find.byKey(const Key('journal-today-action')).hitTestable(),
        findsOne,
      );
    }, variant: _android);
  });

  group('the command palette', () {
    testWidgets('a phone in landscape opens it by touch', (tester) async {
      await pumpApp(tester, _phoneLandscape);
      expect(palette, findsNothing);
      await twoFingerSwipe(tester);
      expect(palette, findsOne);
    }, variant: _android);

    testWidgets('and from the menu of the open note', (tester) async {
      await pumpApp(tester, _phoneLandscape);
      await openAlpha(tester);
      await tester.tap(find.byKey(const Key('note-menu')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('note-menu-palette')));
      await settle(tester);
      expect(palette, findsOne);
    }, variant: _android);
  });
}
