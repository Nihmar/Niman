// #1266: a tablet without the room for the tree beside the note — an 11″
// one in portrait — lays it over the panes when asked for, with a scrim:
// a tap outside closes it, and so do a note opened from it and Back. In
// landscape it stays beside the note, and a desktop never lays it over.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';
import '../fakes/tablet_shell.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  final toggle = find.byKey(const Key('tabs-toggle-sidebar'));
  final scrim = find.byKey(const Key('tree-scrim'));
  final overlay = find.byKey(const Key('tree-overlay'));
  Finder treeOnScreen() => noteTree().hitTestable();

  Future<void> pump(WidgetTester tester, Size size) => pumpTabletShell(
    tester,
    controller: controller,
    filePicker: filePicker,
    size: size,
  );

  bool toggleOn(WidgetTester tester) =>
      tester.widget<IconButton>(toggle).isSelected ?? false;

  testWidgets('portrait: closed, the toggle lays it over the panes', (
    tester,
  ) async {
    await pump(tester, tabletPortrait);
    expect(overlay, findsOne);
    expect(treeOnScreen(), findsNothing);
    expect(toggleOn(tester), isFalse);

    await tester.tap(toggle);
    await settle(tester);
    expect(treeOnScreen(), findsOne);
    expect(scrim, findsOne);
    expect(toggleOn(tester), isTrue);
    // Over the panes, from the rail's edge: the panes keep their width.
    final panes = tester.getRect(find.byKey(const Key('panes-island')));
    expect(tester.getRect(noteTree()).left, lessThan(panes.left + 40));
    expect(tester.takeException(), isNull);
  }, variant: tabletPlatform);

  testWidgets('a note opened from it closes it', (tester) async {
    await pump(tester, tabletPortrait);
    await tester.tap(toggle);
    await settle(tester);
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    expect(find.byKey(const Key('note-tab-0')), findsOne);
    expect(treeOnScreen(), findsNothing);
    expect(scrim, findsNothing);
  }, variant: tabletPlatform);

  testWidgets('a tap on the scrim closes it, and so does Back', (tester) async {
    await pump(tester, tabletPortrait);
    await tester.tap(toggle);
    await settle(tester);
    await tester.tapAt(tester.getRect(scrim).centerRight - const Offset(8, 0));
    await settle(tester);
    expect(treeOnScreen(), findsNothing);

    await tester.tap(toggle);
    await settle(tester);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await settle(tester);
    expect(treeOnScreen(), findsNothing);
  }, variant: tabletPlatform);

  testWidgets('the rail opens it on Files and Search, the search in it', (
    tester,
  ) async {
    await pump(tester, tabletPortrait);
    await tester.tap(find.byKey(const Key('rail-search')));
    await settle(tester);
    expect(scrim, findsOne);
    expect(
      find.descendant(
        of: find.byKey(const Key('tree-island')),
        matching: find.byType(TextField),
      ),
      findsWidgets,
    );
    await tester.tap(find.byKey(const Key('rail-files')));
    await settle(tester);
    expect(treeOnScreen(), findsOne);
  }, variant: tabletPlatform);

  testWidgets('landscape: beside the note, as before', (tester) async {
    await pump(tester, tabletLandscape);
    expect(overlay, findsNothing);
    expect(treeOnScreen(), findsOne);
    final panes = tester.getRect(find.byKey(const Key('panes-island')));
    expect(tester.getRect(noteTree()).right, lessThan(panes.left));
  }, variant: tabletPlatform);

  testWidgets('turned to portrait and back, the docked tree comes back', (
    tester,
  ) async {
    await pump(tester, tabletLandscape);
    setSurfaceSize(tester, tabletPortrait);
    await settle(tester);
    expect(treeOnScreen(), findsNothing);
    setSurfaceSize(tester, tabletLandscape);
    await settle(tester);
    expect(treeOnScreen(), findsOne);
    expect(tester.takeException(), isNull);
  }, variant: tabletPlatform);

  testWidgets('a desktop window as narrow keeps the tree beside', (
    tester,
  ) async {
    await pump(tester, tabletPortrait);
    expect(overlay, findsNothing);
    expect(treeOnScreen(), findsOne);
  }, variant: desktopDensity);
}
