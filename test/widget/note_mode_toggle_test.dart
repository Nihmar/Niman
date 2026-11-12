// #1266: a tablet's note says Edit | Read at its top, where a thumb reads
// which one is on; the status row's eye goes. A desktop keeps the eye.
import 'dart:ui' show Tristate;

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

  final pair = find.byKey(const Key('note-mode-toggle'));
  final eye = find.byKey(const Key('editor-preview-toggle'));

  Future<void> openAlpha(WidgetTester tester, Size size) async {
    await pumpTabletShell(
      tester,
      controller: controller,
      filePicker: filePicker,
      size: size,
    );
    // Held upright, the tree lies closed over the note: it is opened first.
    if (size.height > size.width) {
      await tester.tap(find.byKey(const Key('tabs-toggle-sidebar')));
      await settle(tester);
    }
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
  }

  bool reading(WidgetTester tester) =>
      tester
          .getSemantics(find.byKey(const Key('note-mode-read')))
          .flagsCollection
          .isSelected ==
      Tristate.isTrue;

  for (final size in [tabletLandscape, tabletPortrait]) {
    testWidgets('a tablet ${size.width.toInt()} wide: the pair, no eye', (
      tester,
    ) async {
      await openAlpha(tester, size);
      expect(pair, findsOne);
      expect(eye, findsNothing);
      expect(reading(tester), isFalse);
      expect(tester.getSize(pair).height, greaterThanOrEqualTo(40));
      // The row holds a thumb's ⋮ too.
      final menu = tester.getSize(find.byKey(const Key('note-menu')).first);
      expect(menu.height, greaterThanOrEqualTo(kMinInteractiveDimension));
      expect(tester.takeException(), isNull);
    }, variant: tabletPlatform);
  }

  testWidgets('Read shows the read view, Edit the editor', (tester) async {
    await openAlpha(tester, tabletLandscape);
    await tester.tap(find.byKey(const Key('note-mode-read')));
    await settle(tester);
    expect(reading(tester), isTrue);
    await tester.tap(find.byKey(const Key('note-mode-edit')));
    await settle(tester);
    expect(reading(tester), isFalse);
  }, variant: tabletPlatform);

  testWidgets('a desktop keeps the eye in the status row', (tester) async {
    await openAlpha(tester, tabletLandscape);
    expect(eye, findsOne);
    expect(pair, findsNothing);
  }, variant: desktopDensity);
}
