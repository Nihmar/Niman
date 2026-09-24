// Issue #269: making a theme of one's own, copying one, renaming it,
// deleting it — and the theme in use falling back when its own is gone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_themes.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/palettes.dart';
import 'package:niman/src/ui/theme/theme_editor_screen.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/sample_themes.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    AppThemes.reset();
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    AppThemes.reset();
  });

  /// Pumps the settings body and opens the Themes area.
  Future<void> openThemes(WidgetTester tester) async {
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
  }

  /// Opens the trailing menu of the theme with [id].
  Future<void> openMenu(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(Key('theme-menu-$id')));
    await tester.pumpAndSettle();
  }

  /// Taps [label]'s menu entry.
  Future<void> tapAction(WidgetTester tester, String action) async {
    await tester.tap(find.byKey(Key('theme-menu-$action')));
    await tester.pumpAndSettle();
  }

  /// Types [name] into the dialog's field.
  ///
  /// The field rebuilds what it enables; `enterText` alone does not pump
  /// that frame, and a tap would land on the still-disabled button.
  Future<void> typeName(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField), name);
    await tester.pumpAndSettle();
  }

  /// The dialog's confirm button.
  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.actionOk));
    await tester.pumpAndSettle();
  }

  testWidgets('a theme is made from another one', (tester) async {
    await openThemes(tester);
    await tester.tap(find.byKey(SettingsThemesScreen.newTheme));
    await tester.pumpAndSettle();
    await typeName(tester, 'Copy of Gruvbox');
    await tester.tap(find.byKey(const Key('theme-new-from-gruvbox')));
    await tester.pumpAndSettle();
    await confirm(tester);

    final theme = (await controller.customThemes()).single;
    expect(theme.name, 'Copy of Gruvbox');
    // Its colors are the ones Gruvbox wears, at both brightnesses.
    final gruvbox = themeColors(
      const BuiltinAppTheme(AppPalette.gruvbox),
      Brightness.light,
    );
    expect(theme.day.tokens.accent, gruvbox.tokens.accent);
    // It is stored, and it is what the app wears now.
    expect(await controller.theme, CustomAppTheme(theme));
    expect(AppThemes.theme, CustomAppTheme(theme));
    // It opens in the editor, to be given its own colors.
    final editor = tester.widget<ThemeEditorScreen>(
      find.byType(ThemeEditorScreen),
    );
    expect(editor.theme.id, theme.id);
    // Back from it, the list has it, worn.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ThemeEditorScreen), findsNothing);
    expect(find.text('Copy of Gruvbox'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(SettingsKeys.themeRow('custom:${theme.id}')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a theme can be started from random colors', (tester) async {
    await openThemes(tester);
    await tester.tap(find.byKey(SettingsThemesScreen.newTheme));
    await tester.pumpAndSettle();
    await typeName(tester, 'Lucky');
    await confirm(tester);

    final theme = (await controller.customThemes()).single;
    expect(theme.name, 'Lucky');
    expect(theme.day, isNot(theme.night));
  });

  testWidgets('a copy is named after the theme it came from', (tester) async {
    await openThemes(tester);
    await openMenu(tester, 'gruvbox');
    await tapAction(tester, 'duplicate');
    expect((await controller.customThemes()).single.name, 'Gruvbox 2');

    // And the next copy knows about the first.
    await openMenu(tester, 'gruvbox');
    await tapAction(tester, 'duplicate');
    expect(
      (await controller.customThemes()).map((theme) => theme.name),
      containsAll(<String>['Gruvbox 2', 'Gruvbox 3']),
    );
  });

  testWidgets('a name the list already has is refused', (tester) async {
    await openThemes(tester);
    await tester.tap(find.byKey(SettingsThemesScreen.newTheme));
    await tester.pumpAndSettle();
    await typeName(tester, 'gruvbox');
    await confirm(tester);

    expect(find.text(AppStrings.themeNameTaken), findsOneWidget);
    expect(await controller.customThemes(), isEmpty);

    // Typing on clears the complaint.
    await typeName(tester, 'Something else');
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.themeNameTaken), findsNothing);
  });

  testWidgets("a theme of one's own is renamed, mark and all", (tester) async {
    final custom = sampleCustomTheme(id: 'mine', name: 'Mine');
    await controller.saveCustomTheme(custom);
    await controller.setTheme(CustomAppTheme(custom));
    AppThemes.theme = CustomAppTheme(custom);
    await openThemes(tester);

    await openMenu(tester, 'custom:mine');
    await tapAction(tester, 'rename');
    await typeName(tester, 'Renamed');
    await confirm(tester);

    expect((await controller.customTheme('mine'))!.name, 'Renamed');
    expect(find.text('Renamed'), findsOneWidget);
    // The rename did not take the mark off the theme being worn.
    expect(
      find.descendant(
        of: find.byKey(SettingsKeys.themeRow('custom:mine')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('deleting asks first, and the theme in use falls back', (
    tester,
  ) async {
    final custom = sampleCustomTheme(id: 'mine', name: 'Mine');
    await controller.saveCustomTheme(custom);
    await controller.setTheme(CustomAppTheme(custom));
    AppThemes.theme = CustomAppTheme(custom);
    await openThemes(tester);

    await openMenu(tester, 'custom:mine');
    await tapAction(tester, 'delete');
    // The dialog says what is about to go.
    expect(find.text(AppStrings.themeDeleteBody('Mine')), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, AppStrings.actionCancel));
    await tester.pumpAndSettle();
    expect(await controller.customThemes(), hasLength(1));

    await openMenu(tester, 'custom:mine');
    await tapAction(tester, 'delete');
    await tester.tap(find.widgetWithText(TextButton, AppStrings.actionDelete));
    await tester.pumpAndSettle();

    expect(await controller.customThemes(), isEmpty);
    // Deleting the one being worn leaves the app its own colors.
    expect(await controller.theme, const BuiltinAppTheme(AppPalette.niman));
    expect(AppThemes.theme, const BuiltinAppTheme(AppPalette.niman));
    expect(find.text('Mine'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(SettingsKeys.themeRow('niman')),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a shipped theme can only be copied', (tester) async {
    await openThemes(tester);
    await openMenu(tester, 'niman');

    expect(find.byKey(const Key('theme-menu-duplicate')), findsOneWidget);
    expect(find.byKey(const Key('theme-menu-rename')), findsNothing);
    expect(find.byKey(const Key('theme-menu-delete')), findsNothing);
  });
}
