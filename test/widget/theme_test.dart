// T-M6-05 and issue #269: brightness and the theme are chosen on the
// Themes page, they reach every screen at once, and they are still there
// next time.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/theme/gruvbox.dart';
import 'package:niman/src/ui/theme/palettes.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/sample_themes.dart';
import '../fakes/shell_harness.dart';

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

  /// Pumps the settings body alone, tall enough to lay the whole list out.
  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsBody(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens [area]'s screen from the settings home (issue #104): the
  /// rows the tests drive live in the pushed area screen.
  Future<void> openArea(WidgetTester tester, Key area) async {
    await tester.tap(find.byKey(area));
    await tester.pumpAndSettle();
  }

  /// Opens [row]'s dialog and takes the option for [value].
  Future<void> choose(
    WidgetTester tester, {
    required Key row,
    required Object value,
  }) async {
    await tester.tap(find.byKey(row));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('settings-choice-$value')));
    await tester.pumpAndSettle();
  }

  /// Pumps the whole app on the fake library.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await settle(tester);
  }

  /// The theme in force where the tree is built.
  ThemeData themeOfTree(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(NoteTree)));

  /// Whether the mark on [id]'s row says the app is wearing it.
  Finder markOn(String id) => find.descendant(
    of: find.byKey(SettingsKeys.themeRow(id)),
    matching: find.byType(Icon),
  );

  group('the Themes page', () {
    testWidgets('brightness starts on the device, the theme on Niman', (
      tester,
    ) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-themes'));

      expect(find.byKey(SettingsKeys.brightness), findsOneWidget);
      expect(find.byKey(SettingsKeys.theme), findsOneWidget);
      // Brightness reads "System", and so does the theme by that name; a
      // fresh install wears Niman's own colors.
      expect(find.text('System'), findsNWidgets(2));
      expect(find.text('Niman'), findsOneWidget);
      // The mark sits on the theme in use, and nowhere else.
      expect(
        find.descendant(
          of: find.byKey(SettingsKeys.themeRow('niman')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(SettingsKeys.themeRow('niman')),
          matching: find.byIcon(Icons.circle_outlined),
        ),
        findsNothing,
      );
    });

    testWidgets('the colors left Appearance', (tester) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-appearance'));

      expect(find.byKey(SettingsKeys.language), findsOneWidget);
      expect(find.byKey(SettingsKeys.brightness), findsNothing);
      expect(find.byKey(SettingsKeys.theme), findsNothing);
    });

    testWidgets('a theme is remembered and applied at once', (tester) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-themes'));
      await tester.tap(find.byKey(SettingsKeys.themeRow('gruvbox')));
      await tester.pumpAndSettle();

      expect(await controller.theme, const BuiltinAppTheme(AppPalette.gruvbox));
      expect(AppThemes.theme, const BuiltinAppTheme(AppPalette.gruvbox));
      // The mark moved with it, and the brightness stayed where it was.
      expect(
        find.descendant(
          of: find.byKey(SettingsKeys.themeRow('gruvbox')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(AppThemes.brightness, AppBrightness.system);
    });

    testWidgets('the brightness is remembered and applied at once', (
      tester,
    ) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-themes'));
      await choose(
        tester,
        row: SettingsKeys.brightness,
        value: AppBrightness.night,
      );

      expect(await controller.themeBrightness, AppBrightness.night);
      expect(AppThemes.mode, ThemeMode.dark);
      // The theme is untouched, so it stays on the install default.
      expect(AppThemes.theme, const BuiltinAppTheme(AppPalette.niman));
    });

    testWidgets('every theme the app ships is offered', (tester) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-themes'));

      for (final palette in AppPalette.values) {
        expect(
          find.byKey(SettingsKeys.themeRow(palette.id)),
          findsOneWidget,
          reason: '${palette.id} is not in the list',
        );
      }
    });

    testWidgets("a theme of the user's own is listed and can be worn", (
      tester,
    ) async {
      final custom = sampleCustomTheme(id: 'mine', name: 'My theme');
      await controller.saveCustomTheme(custom);
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-themes'));

      expect(find.text('My theme'), findsOneWidget);
      await tester.tap(find.byKey(SettingsKeys.themeRow('custom:mine')));
      await tester.pumpAndSettle();

      expect(await controller.theme, CustomAppTheme(custom));
      expect(AppThemes.theme, CustomAppTheme(custom));
      expect(
        find.descendant(
          of: find.byKey(SettingsKeys.themeRow('custom:mine')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(SettingsKeys.themeRow('niman')),
          matching: find.byIcon(Icons.circle_outlined),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the list is a searchable row of its own', (tester) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-themes'));

      // Every row keeps its own key, so nothing rides on the position it
      // has in the list.
      expect(find.byKey(SettingsKeys.themeRow('solarized')), findsOneWidget);
      expect(markOn('solarized'), findsOneWidget);
    });
  });

  group('what the choice reaches', () {
    testWidgets('the stored theme is on screen from the start', (tester) async {
      await controller.setTheme(const BuiltinAppTheme(AppPalette.gruvbox));
      await controller.setThemeBrightness(AppBrightness.night);

      await pumpApp(tester);

      final theme = themeOfTree(tester);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, gruvboxTokens(Brightness.dark).accent);
    });

    testWidgets('the Markdown colors travel with it', (tester) async {
      await controller.setTheme(const BuiltinAppTheme(AppPalette.gruvbox));
      await pumpApp(tester);

      // The editor and the preview read them from the theme, not from a
      // global: a theme change repaints them with everything else.
      expect(
        SyntaxColors.of(tester.element(find.byType(NoteTree))),
        gruvboxSyntax(Brightness.light),
      );
    });

    testWidgets("a theme of the user's own reaches the app", (tester) async {
      final custom = sampleCustomTheme();
      await controller.setTheme(CustomAppTheme(custom));
      await pumpApp(tester);

      final theme = themeOfTree(tester);
      expect(theme.colorScheme.primary, sampleDayAccent);
      expect(theme.colorScheme.surface, sampleDayBackground);
    });

    testWidgets('night is dark on a device set to light', (tester) async {
      // The device brightness is light in a widget test; the choice has
      // to win over it.
      await controller.setThemeBrightness(AppBrightness.night);
      await pumpApp(tester);

      expect(themeOfTree(tester).brightness, Brightness.dark);
    });

    testWidgets('the device colors reach a running app', (tester) async {
      // The device's colors are the `system` theme; the app now installs
      // on its own, so this one has to be asked for.
      await controller.setTheme(const BuiltinAppTheme(AppPalette.system));
      await pumpApp(tester);
      final before = themeOfTree(tester).colorScheme.primary;

      // Material You answers a frame or two after the first one, which
      // is exactly what the app root's listener is for.
      AppThemes.setDeviceColors(
        light: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        dark: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.dark,
        ),
      );
      await settle(tester);

      expect(themeOfTree(tester).colorScheme.primary, isNot(before));
    });

    testWidgets('a named theme ignores the device colors', (tester) async {
      await controller.setTheme(const BuiltinAppTheme(AppPalette.gruvbox));
      await pumpApp(tester);

      AppThemes.setDeviceColors(
        light: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        dark: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.dark,
        ),
      );
      await settle(tester);

      expect(
        themeOfTree(tester).colorScheme.primary,
        gruvboxTokens(Brightness.light).accent,
      );
    });

    testWidgets('the system theme wears the shipped seed with no device '
        'colors', (tester) async {
      await controller.setTheme(const BuiltinAppTheme(AppPalette.system));
      await pumpApp(tester);

      expect(
        themeOfTree(tester).colorScheme.primary,
        ColorScheme.fromSeed(seedColor: shippedSeed).primary,
      );
    });
  });
}
