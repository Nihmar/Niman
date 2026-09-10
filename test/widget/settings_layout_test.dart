// 2026-09-08 user feedback: the settings screen read as one wall. It is
// now grouped under headings, and every setting with more than two
// choices is a row showing its current value, changed in a dialog.
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/ui/keyboard_shortcuts.dart';
import 'package:copist/src/ui/settings.dart';
import 'package:copist/src/ui/settings_rows.dart';
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

  testWidgets('the toolbar row sits under Editor, not Appearance', (
    tester,
  ) async {
    // It decides what the editor can do, not how the app looks (user,
    // 2026-09-09).
    await pump(tester);
    final editor = tester.getTopLeft(
      find.text(AppStrings.settingsSectionEditor),
    );
    final library = tester.getTopLeft(
      find.text(AppStrings.settingsSectionLibrary),
    );
    final toolbar = tester.getTopLeft(find.byKey(const Key('toolbar-setting')));
    expect(toolbar.dy, greaterThan(editor.dy));
    expect(toolbar.dy, lessThan(library.dy));
  });

  testWidgets('switches keep their explanation, having no dialog', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(AppStrings.trashSubtitle), findsOne);
  });

  testWidgets('the keyboard row shows on phones only, hidden on desktop', (
    tester,
  ) async {
    // The test host is a desktop platform, so the row — gated on
    // Android/iOS — is never offered here (user, 2026-09-09).
    await pump(tester);
    expect(find.text(AppStrings.keyboardOnOpenSubtitle), findsNothing);
  });

  testWidgets('the shortcuts row opens the reference where a keyboard exists', (
    tester,
  ) async {
    // The test host is a desktop platform, so a physical keyboard is
    // assumed and the row stays enabled.
    await pump(tester);
    final row = find.byKey(const Key('keyboard-shortcuts-setting'));
    expect(row, findsOneWidget);
    final tile = find.descendant(
      of: row,
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(tile).enabled, isTrue);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(KeyboardShortcutsScreen), findsOneWidget);
  });

  testWidgets('a disabled row cannot be tapped', (tester) async {
    // Phones and tablets have no physical keyboard: the shortcuts row
    // reads as disabled and its tap goes nowhere.
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsValueRow(
            title: 'Shortcuts',
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final tile = find.byType(ListTile);
    expect(tester.widget<ListTile>(tile).enabled, isFalse);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tapped, isFalse);
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

    testWidgets('no layout row is offered on a phone, whatever the mode', (
      tester,
    ) async {
      // Below 600 dp the layout is settled: one pane, and no control
      // that could say otherwise. The split/switch choice lives in the
      // editor's app bar now (user, 2026-09-09), not here.
      await controller.setPreviewMode(PreviewLayoutMode.fullScreen);
      await pumpAt(tester, 400);
      expect(row, findsNothing);
    });

    testWidgets('the full-screen mode hides the ratio on a tablet too', (
      tester,
    ) async {
      await controller.setPreviewMode(PreviewLayoutMode.fullScreen);
      await pumpAt(tester, 900);
      expect(row, findsNothing);
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
