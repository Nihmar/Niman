// Issue #269: the theme editor. The app wears the colors as they move,
// Save stores them, and leaving without saving puts back what was there.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/sample_themes.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    AppThemes.reset();
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
    await controller.saveCustomTheme(
      sampleCustomTheme(id: 'mine', name: 'Mine'),
    );
    await controller.setTheme(
      CustomAppTheme(sampleCustomTheme(id: 'mine', name: 'Mine')),
    );
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    AppThemes.reset();
  });

  /// Opens the Themes area and the editor on the stored theme.
  Future<void> openEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsBody(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-area-themes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-menu-custom:mine')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-menu-edit')));
    await tester.pumpAndSettle();
  }

  /// Picks [hex] for [role] through the dialog the row opens.
  Future<void> pick(WidgetTester tester, String role, String hex) async {
    await tester.tap(find.byKey(Key('theme-role-$role')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('color-picker-hex')), hex);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionOk));
    await tester.pumpAndSettle();
  }

  testWidgets('every role is on the page, at both brightnesses', (
    tester,
  ) async {
    await openEditor(tester);

    expect(find.text(AppStrings.themeEditorTitle), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
    for (final role in ['background', 'accent', 'error', 'wikilink', 'tag']) {
      expect(find.byKey(Key('theme-role-$role')), findsOneWidget, reason: role);
    }
    // The day side is the one shown: the sample's day accent (which the
    // wikilink shares, hence the row).
    expect(
      find.descendant(
        of: find.byKey(const Key('theme-role-accent')),
        matching: find.text(colorToHex(sampleDayAccent)),
      ),
      findsOneWidget,
    );

    // The other side is one tap away, and shows its own colors.
    await tester.tap(find.text(AppStrings.themeBrightnessNight));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('theme-role-accent')),
        matching: find.text(colorToHex(sampleNightAccent)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the app wears the color while it is being chosen', (
    tester,
  ) async {
    await openEditor(tester);
    await pick(tester, 'background', '#112233');

    // On the page, and in the draft the whole app is wearing.
    expect(find.text('#112233'), findsOneWidget);
    final draft = AppThemes.draft;
    expect(draft, isA<CustomAppTheme>());
    expect(
      (draft! as CustomAppTheme).theme.day.colorOf('background'),
      const Color(0xFF112233),
    );
    // And not stored yet.
    expect(
      (await controller.customTheme('mine'))!.day.colorOf('background'),
      sampleDayBackground,
    );
  });

  testWidgets('Save stores the colors and leaves the draft behind', (
    tester,
  ) async {
    await openEditor(tester);
    await pick(tester, 'background', '#112233');
    await tester.tap(find.byKey(const Key('theme-editor-save')));
    await tester.pumpAndSettle();

    final stored = (await controller.customTheme('mine'))!;
    expect(stored.day.colorOf('background'), const Color(0xFF112233));
    expect(stored.night, sampleCustomTheme().night);
    // The editor is gone, the app is wearing what was saved, and there is
    // no draft left over.
    expect(find.text(AppStrings.themeEditorTitle), findsNothing);
    expect(AppThemes.draft, isNull);
    expect(AppThemes.theme, CustomAppTheme(stored));
  });

  testWidgets('leaving without saving asks, and puts the colors back', (
    tester,
  ) async {
    await openEditor(tester);
    await pick(tester, 'background', '#112233');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.themeEditorDiscardTitle), findsOneWidget);

    // Staying keeps the edit and the draft.
    await tester.tap(find.widgetWithText(TextButton, AppStrings.actionCancel));
    await tester.pumpAndSettle();
    expect(find.text('#112233'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(TextButton, AppStrings.themeEditorDiscard),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.themeEditorTitle), findsNothing);
    expect(AppThemes.draft, isNull);
    expect(
      (await controller.customTheme('mine'))!.day.colorOf('background'),
      sampleDayBackground,
    );
  });

  testWidgets('an untouched theme leaves without asking', (tester) async {
    await openEditor(tester);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.themeEditorDiscardTitle), findsNothing);
    expect(find.text(AppStrings.themeEditorTitle), findsNothing);
    expect(AppThemes.draft, isNull);
  });

  testWidgets('editing a side shows that side, and puts the choice back', (
    tester,
  ) async {
    // The user's own brightness is day; opening the editor on the night
    // side previews night.
    AppThemes.brightness = AppBrightness.day;
    await controller.setThemeBrightness(AppBrightness.day);
    await openEditor(tester);
    expect(AppThemes.brightness, AppBrightness.day);

    await tester.tap(find.text(AppStrings.themeBrightnessNight));
    await tester.pumpAndSettle();
    expect(AppThemes.brightness, AppBrightness.night);

    await tester.tap(find.byKey(const Key('theme-editor-save')));
    await tester.pumpAndSettle();
    // The preview is over: day, as the user had chosen.
    expect(AppThemes.brightness, AppBrightness.day);
  });

  testWidgets('the picker refuses a hex that is not one', (tester) async {
    await openEditor(tester);
    await tester.tap(find.byKey(const Key('theme-role-accent')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('color-picker-hex')), 'teal');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.themeEditorBadColor), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('color-picker-hex')),
      '#00897B',
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.themeEditorBadColor), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionOk));
    await tester.pumpAndSettle();

    expect(
      (AppThemes.draft! as CustomAppTheme).theme.day.colorOf('accent'),
      const Color(0xFF00897B),
    );
  });
}
