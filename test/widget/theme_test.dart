// T-M6-05: the brightness and the palette are chosen in the settings,
// they reach every screen at once, and they are still there next time.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/theme/gruvbox.dart';
import 'package:niman/src/ui/theme/palettes.dart';
import 'package:niman/src/ui/theme/tokens.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';
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

  group('the settings rows', () {
    testWidgets('brightness starts on the device, palette on Niman', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.byKey(const Key('theme-brightness-setting')), findsOneWidget);
      expect(find.byKey(const Key('theme-palette-setting')), findsOneWidget);
      // Brightness and language read "System"; a fresh install wears the
      // app's own palette, so that row reads "Niman".
      expect(find.text('System'), findsNWidgets(2));
      expect(find.text('Niman'), findsOneWidget);
    });

    testWidgets('the palette is remembered and applied at once', (
      tester,
    ) async {
      await pumpSettings(tester);
      await choose(
        tester,
        row: const Key('theme-palette-setting'),
        value: AppPalette.gruvbox,
      );

      expect(await controller.themePalette, AppPalette.gruvbox);
      expect(AppThemes.palette, AppPalette.gruvbox);
      // The row reads what was picked.
      expect(find.text('Gruvbox'), findsOneWidget);
      // And the brightness stayed where it was.
      expect(AppThemes.brightness, AppBrightness.system);
    });

    testWidgets('the brightness is remembered and applied at once', (
      tester,
    ) async {
      await pumpSettings(tester);
      await choose(
        tester,
        row: const Key('theme-brightness-setting'),
        value: AppBrightness.night,
      );

      expect(await controller.themeBrightness, AppBrightness.night);
      expect(AppThemes.mode, ThemeMode.dark);
      // The palette is untouched, so it stays on the install default.
      expect(AppThemes.palette, AppPalette.niman);
    });

    testWidgets('every palette the app ships is offered', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.byKey(const Key('theme-palette-setting')));
      await tester.pumpAndSettle();

      for (final palette in AppPalette.values) {
        expect(
          find.byKey(Key('settings-choice-$palette')),
          findsOneWidget,
          reason: '${palette.id} is not in the dialog',
        );
      }
    });
  });

  group('what the choice reaches', () {
    testWidgets('the stored theme is on screen from the start', (tester) async {
      await controller.setThemePalette(AppPalette.gruvbox);
      await controller.setThemeBrightness(AppBrightness.night);

      await pumpApp(tester);

      final theme = themeOfTree(tester);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, gruvboxTokens(Brightness.dark).accent);
    });

    testWidgets('the Markdown colors travel with it', (tester) async {
      await controller.setThemePalette(AppPalette.gruvbox);
      await pumpApp(tester);

      // The editor and the preview read them from the theme, not from a
      // global: a palette change repaints them with everything else.
      expect(
        SyntaxColors.of(tester.element(find.byType(NoteTree))),
        gruvboxSyntax(Brightness.light),
      );
    });

    testWidgets('night is dark on a device set to light', (tester) async {
      // The device brightness is light in a widget test; the choice has
      // to win over it.
      await controller.setThemeBrightness(AppBrightness.night);
      await pumpApp(tester);

      expect(themeOfTree(tester).brightness, Brightness.dark);
    });

    testWidgets('the device colors reach a running app', (tester) async {
      // The device's colors are the `system` palette; the app now installs
      // on its own, so this one has to be asked for.
      await controller.setThemePalette(AppPalette.system);
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

    testWidgets('a named palette ignores the device colors', (tester) async {
      await controller.setThemePalette(AppPalette.gruvbox);
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

    testWidgets('the system palette wears the shipped seed with no device '
        'colors', (tester) async {
      await controller.setThemePalette(AppPalette.system);
      await pumpApp(tester);

      expect(
        themeOfTree(tester).colorScheme.primary,
        ColorScheme.fromSeed(seedColor: shippedSeed).primary,
      );
    });
  });
}
