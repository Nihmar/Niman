// T-UI-05: the "+" FAB expands into New note / New folder mini FABs
// above it; the main button just toggles the menu.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

/// The mini FAB [key]'s AnimatedOpacity target (0 = hidden, 1 = shown).
double miniOpacity(WidgetTester tester, Key key) {
  return tester
      .widget<AnimatedOpacity>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(AnimatedOpacity),
        ),
      )
      .opacity;
}

/// Whether the mini FAB [key] ignores taps (true = collapsed).
bool miniIgnored(WidgetTester tester, Key key) {
  return tester
      .widget<IgnorePointer>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(IgnorePointer),
        ),
      )
      .ignoring;
}

/// Whether the FAB-menu scrim ignores taps (true = collapsed). The scrim
/// stays mounted so the reveal can animate back to the FAB.
bool scrimInert(WidgetTester tester) =>
    tester.widget<IgnorePointer>(find.byKey(const Key('fab-scrim'))).ignoring;

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [librarySessionProvider.overrideWithValue(controller)],
      child: const NimanApp(),
    );
  }

  testWidgets('the FAB expands into note and folder actions (T-UI-05)', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    // Collapsed: the minis are hidden and ignore taps; inert scrim.
    expect(find.byKey(const Key('new-note-fab')), findsOneWidget);
    expect(scrimInert(tester), isTrue);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    expect(miniOpacity(tester, const Key('new-folder-action')), 0);
    expect(miniIgnored(tester, const Key('new-folder-action')), isTrue);

    // Expand: both minis become visible and tappable.
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(scrimInert(tester), isFalse);
    expect(miniOpacity(tester, const Key('new-note-action')), 1);
    expect(miniIgnored(tester, const Key('new-note-action')), isFalse);
    expect(miniOpacity(tester, const Key('new-folder-action')), 1);
    expect(miniIgnored(tester, const Key('new-folder-action')), isFalse);

    // Each action is named on the button. Five bare icons asked which
    // one was "from a template" and which was "a list", and the tooltip
    // that answered it only appears after a long press on Android.
    expect(find.text('New note'), findsOneWidget);
    expect(find.text('New from template'), findsOneWidget);
    // The list note names its folder: the only action that does not
    // land in the FAB target folder (issue #131).
    expect(find.text('New list note · Lists'), findsOneWidget);
    expect(find.text('New voice note'), findsOneWidget);
    expect(find.text('New folder'), findsOneWidget);

    // The New note mini opens the name dialog; the menu collapses.
    await tester.tap(find.byKey(const Key('new-note-action')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    await tester.enterText(dialogField(), 'First note');
    await tester.tap(find.text('OK'));
    await settle(tester);
    // The new note opens full-screen on the phone: back to the tree
    // before reaching for the FAB again.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(noteRow('First note.md'), findsOneWidget);
    expect(scrimInert(tester), isTrue);

    // Expand again; the New folder mini creates a folder.
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-folder-action')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(dialogField(), 'Docs');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(noteRow('Docs'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('tapping the FAB again closes the menu without a dialog', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(miniOpacity(tester, const Key('new-note-action')), 1);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    expect(miniOpacity(tester, const Key('new-folder-action')), 0);
    expect(scrimInert(tester), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await controller.ops!.find('New note.md'), isNull);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('tapping the scrim dismisses the menu without a dialog', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(buildApp());
    await tester.pump();
    await openLibrary(tester, filePicker);

    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    expect(miniOpacity(tester, const Key('new-note-action')), 1);
    expect(scrimInert(tester), isFalse);

    // A tap on the body beside the buttons (the scrim) closes the menu:
    // the buttons are right-aligned, so their left half is scrim.
    final menu = tester.getRect(find.byKey(const Key('new-item-menu-scroll')));
    await tester.tapAt(Offset(menu.left / 2, menu.center.dy));
    await settleFabMenu(tester);
    expect(scrimInert(tester), isTrue);
    expect(miniOpacity(tester, const Key('new-note-action')), 0);
    expect(miniIgnored(tester, const Key('new-note-action')), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(await controller.ops!.find('New note.md'), isNull);

    // The main FAB is still usable: expand, then create a note.
    await tester.tap(find.byKey(const Key('new-note-fab')));
    await settleFabMenu(tester);
    await tester.tap(find.byKey(const Key('new-note-action')));
    await settle(tester);
    await tester.enterText(dialogField(), 'Scrim note');
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(noteRow('Scrim note.md'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  group('on a screen shorter than the menu (#849)', () {
    // 390 dp tall is a phone turned sideways, minus its bars: the nine
    // buttons are nearly 600 dp stacked.
    Future<void> openShort(WidgetTester tester) async {
      setSurfaceSize(tester, const Size(520, 390));
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await openLibrary(tester, filePicker);
      await tester.tap(find.byKey(const Key('new-note-fab')));
      await settleFabMenu(tester);
    }

    final scroll = find.byKey(const Key('new-item-menu-scroll'));

    testWidgets('the menu fits the screen and scrolls to its first entry', (
      tester,
    ) async {
      await openShort(tester);
      expect(tester.takeException(), isNull, reason: 'no overflow');
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      expect(
        tester.getRect(scroll).top,
        greaterThanOrEqualTo(0),
        reason: 'the menu stays on the screen',
      );

      // It opens on the entries nearest the button, the first one cut off.
      expect(
        find.byKey(const Key('new-folder-action')).hitTestable(),
        findsOne,
      );
      final first = find.byKey(const Key('journal-today-action'));
      expect(first.hitTestable(), findsNothing);
      await tester.drag(scroll, const Offset(0, 2000));
      await settleFabMenu(tester);
      expect(first.hitTestable(), findsOne, reason: 'a drag reaches it');
      await tester.tap(first);
      await settle(tester);
      expect(
        find.byKey(const ValueKey('full-note')),
        findsOne,
        reason: 'and the journal opens',
      );
    });

    testWidgets('a tap beside the buttons still closes the menu', (
      tester,
    ) async {
      await openShort(tester);
      final menu = tester.getRect(scroll);
      await tester.tapAt(Offset(menu.left / 2, menu.center.dy));
      await settleFabMenu(tester);
      expect(scrimInert(tester), isTrue);
    });

    testWidgets('with room, it is the plain column: nothing scrolls', (
      tester,
    ) async {
      setSurfaceSize(tester, const Size(390, 844));
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await openLibrary(tester, filePicker);
      await tester.tap(find.byKey(const Key('new-note-fab')));
      await settleFabMenu(tester);
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, 0);
      // Slim rows: nine of them, and the first — Today's journal — is on
      // screen without a scroll.
      expect(
        tester.getSize(find.byKey(const Key('journal-today-action'))).height,
        40,
      );
      expect(
        find.byKey(const Key('journal-today-action')).hitTestable(),
        findsOne,
      );
    });

    testWidgets('a tall narrow phone shows the journal entry un-scrolled', (
      tester,
    ) async {
      setSurfaceSize(tester, const Size(360, 780));
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await openLibrary(tester, filePicker);
      await tester.tap(find.byKey(const Key('new-note-fab')));
      await settleFabMenu(tester);
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, 0, reason: 'the slim menu fits');
      expect(
        find.byKey(const Key('journal-today-action')).hitTestable(),
        findsOne,
        reason: 'the first entry is on screen, no rotation needed',
      );
    });
  });
}
