// 2026-09-08 user feedback: the settings screen read as one wall. It is
// now grouped under headings, and every setting with more than two
// choices is a row showing its current value, changed in a dialog.
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/ui/settings.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_library_session.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  /// Pumps the settings body on a surface tall enough to hold the list.
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsBody(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the list is grouped under its five headings', (tester) async {
    await pump(tester);
    for (final heading in [
      AppStrings.settingsSectionAppearance,
      AppStrings.settingsSectionEditor,
      AppStrings.settingsSectionLibrary,
      AppStrings.settingsSectionReminders,
      AppStrings.settingsSectionDiagnostics,
    ]) {
      expect(find.text(heading), findsOne, reason: heading);
    }
  });

  testWidgets('no setting is a SegmentedButton any more', (tester) async {
    // The four inline segmented blocks are what made the screen a wall:
    // each cost three lines where a switch cost one.
    await pump(tester);
    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.byType(SegmentedButton<LinkType>), findsNothing);
    expect(find.byType(SegmentedButton<PreviewLayoutMode>), findsNothing);
  });

  testWidgets('a choice row reads its current value', (tester) async {
    await pump(tester);
    final row = find.byKey(const Key('indent-width'));
    expect(
      find.descendant(
        of: row,
        matching: find.text(AppStrings.indentWidthValue(2)),
      ),
      findsOne,
    );
  });

  testWidgets('tapping a choice row opens the dialog and applies it', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('indent-width')));
    await tester.pumpAndSettle();

    // The explanation the list no longer prints is here instead.
    expect(find.text(AppStrings.indentWidthSubtitle), findsOne);
    await tester.tap(find.byKey(const Key('settings-choice-6')));
    await tester.pumpAndSettle();

    expect(await controller.indentWidth, 6);
    expect(
      find.descendant(
        of: find.byKey(const Key('indent-width')),
        matching: find.text(AppStrings.indentWidthValue(6)),
      ),
      findsOne,
    );
  });

  testWidgets('cancelling a choice changes nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('link-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.actionCancel));
    await tester.pumpAndSettle();

    expect(await controller.linkType, LinkType.wikilink);
  });

  testWidgets('the split width is a row over a slider dialog', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('split-ratio-setting')));
    await tester.pumpAndSettle();

    final slider = find.byKey(const Key('split-ratio'));
    expect(slider, findsOne);
    await tester.drag(slider, const Offset(60, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-slider-save')));
    await tester.pumpAndSettle();

    expect(await controller.splitRatio, greaterThan(defaultSplitRatio));
  });

  testWidgets('switches keep their explanation, having no dialog', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(AppStrings.trashSubtitle), findsOne);
    expect(find.text(AppStrings.keyboardOnOpenSubtitle), findsOne);
  });

  group('the split-ratio row appears only where the panes can split', () {
    /// Pumps the settings body at [width], the way a phone or a tablet
    /// would show it.
    Future<void> pumpAt(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 2800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsBody(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
    }

    final row = find.byKey(const Key('split-ratio-setting'));

    testWidgets('hidden on a phone, where auto never splits', (tester) async {
      await pumpAt(tester, 400);
      expect(row, findsNothing);
    });

    testWidgets('shown on a tablet, where auto does split', (tester) async {
      await pumpAt(tester, 900);
      expect(row, findsOne);
    });

    testWidgets('shown on a phone when the split is forced', (tester) async {
      await controller.setPreviewMode(PreviewLayoutMode.split);
      await pumpAt(tester, 400);
      expect(row, findsOne);
    });

    testWidgets('hidden on a tablet when the switch layout is forced', (
      tester,
    ) async {
      await controller.setPreviewMode(PreviewLayoutMode.fullScreen);
      await pumpAt(tester, 900);
      expect(row, findsNothing);
    });

    testWidgets('the stored ratio survives being hidden', (tester) async {
      // Hiding the control must not reset the value: plugging in a
      // monitor brings back the split the user chose.
      await controller.setSplitRatio(0.7);
      await pumpAt(tester, 400);
      expect(row, findsNothing);
      expect(await controller.splitRatio, 0.7);
    });
  });
}
