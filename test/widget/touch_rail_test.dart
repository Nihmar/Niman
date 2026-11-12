// #1266: the rail of a tablet's wide shell says what its buttons are —
// each destination's label under its icon — and holds the library at its
// top with New under it; the labels go where the rail is too short for
// them, and its width stays. A desktop keeps its icons.
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/touch_rail.dart';

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

  final rail = find.byKey(const Key('shell-rail'));
  Finder inRail(String text) =>
      find.descendant(of: rail, matching: find.text(text));

  testWidgets('a tablet labels the destinations, the library and New on top', (
    tester,
  ) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    expect(find.byType(TouchRail), findsOne);
    expect(tester.getSize(rail).width, TouchRail.width);
    for (final label in [AppStrings.tabFiles, AppStrings.tabSettings]) {
      expect(inRail(label), findsOne, reason: label);
    }
    final library = tester.getRect(find.byKey(const Key('rail-library')));
    final add = tester.getRect(find.byKey(const Key('rail-new')));
    final files = tester.getRect(find.byKey(const Key('rail-files')));
    final settings = tester.getRect(find.byKey(const Key('rail-settings')));
    expect(library.bottom, lessThanOrEqualTo(add.top));
    expect(add.bottom, lessThanOrEqualTo(files.top));
    expect(settings.top, greaterThan(files.bottom));
    for (final rect in [library, add, files, settings]) {
      expect(rect.height, greaterThanOrEqualTo(kMinInteractiveDimension));
    }
    expect(tester.takeException(), isNull);
  }, variant: tabletPlatform);

  testWidgets("New opens the tree footer's create menu", (tester) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    await tester.tap(find.byKey(const Key('rail-new')));
    await settle(tester);
    expect(find.byKey(const Key('new-note-action')), findsOne);
    expect(find.byKey(const Key('new-folder-action')), findsOne);

    await tester.tap(find.byKey(const Key('new-folder-action')));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOne, reason: 'the name is asked');
  }, variant: tabletPlatform);

  testWidgets('a destination tapped is selected', (tester) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    bool selected(String name) =>
        tester
            .getSemantics(find.byKey(Key('rail-$name')))
            .flagsCollection
            .isSelected ==
        Tristate.isTrue;
    expect(selected('files'), isTrue);
    await tester.tap(find.byKey(const Key('rail-search')));
    await settle(tester);
    expect(selected('search'), isTrue);
    expect(selected('files'), isFalse);
  }, variant: tabletPlatform);

  testWidgets('with the keyboard up the labels go and the width stays', (
    tester,
  ) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    await raiseTabletKeyboard(tester, 360);
    expect(inRail(AppStrings.tabFiles), findsNothing);
    expect(tester.getSize(rail).width, TouchRail.width);
    final settings = find.byKey(const Key('rail-settings'));
    await tester.ensureVisible(settings);
    await tester.pump();
    expect(settings.hitTestable(), findsOne);
    expect(tester.takeException(), isNull);
  }, variant: tabletPlatform);

  testWidgets('a desktop keeps the icons, their names in tooltips', (
    tester,
  ) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
    );
    expect(find.byType(TouchRail), findsNothing);
    expect(inRail(AppStrings.tabFiles), findsNothing);
    expect(find.byKey(const Key('rail-new')), findsNothing);
  }, variant: desktopDensity);
}
