// T-M6-05 and issue #269: brightness × theme. Every combination has to
// produce a readable theme, the shipped palettes have to be mappings and
// nothing else, a custom theme has to wear its own colors at both
// brightnesses, and the device's own colors have to reach `system`.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/ui/theme/palettes.dart';

import '../fakes/sample_themes.dart';

/// The WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final one = a.computeLuminance();
  final two = b.computeLuminance();
  final lighter = one > two ? one : two;
  final darker = one > two ? two : one;
  return (lighter + 0.05) / (darker + 0.05);
}

const BuiltinAppTheme _gruvbox = BuiltinAppTheme(AppPalette.gruvbox);

void main() {
  setUp(AppThemes.reset);
  tearDown(AppThemes.reset);

  group('the choices', () {
    test('an unknown id reads back as the default', () {
      expect(AppPalette.fromId('nope'), AppPalette.system);
      expect(AppPalette.fromId(null), AppPalette.system);
      expect(AppBrightness.fromId('midday'), AppBrightness.system);
    });

    test('every choice survives its id', () {
      for (final palette in AppPalette.values) {
        expect(AppPalette.fromId(palette.id), palette);
      }
      for (final brightness in AppBrightness.values) {
        expect(AppBrightness.fromId(brightness.id), brightness);
      }
    });

    test('a stored id reads back as the theme it names', () {
      final custom = sampleCustomTheme();
      expect(themeFromId('gruvbox'), _gruvbox);
      expect(
        themeFromId('custom:sample', custom: custom),
        CustomAppTheme(custom),
      );
      // A palette from a build after this one, or a row edited by hand.
      expect(themeFromId('dracula'), const BuiltinAppTheme(AppPalette.system));
      // A custom id whose theme is gone is not a palette either: the
      // session turns it into Niman's own colors before it gets here.
      expect(
        themeFromId('custom:gone'),
        const BuiltinAppTheme(AppPalette.system),
      );
    });

    test('a theme is stored under its own id', () {
      expect(_gruvbox.id, 'gruvbox');
      expect(CustomAppTheme(sampleCustomTheme(id: 'mine')).id, 'custom:mine');
      expect(AppTheme.customIdIn('custom:mine'), 'mine');
      expect(AppTheme.customIdIn('gruvbox'), isNull);
      expect(AppTheme.customIdIn('custom:'), isNull);
    });

    test('the brightness choice is what MaterialApp is handed', () {
      expect(AppThemes.mode, ThemeMode.system);
      AppThemes.brightness = AppBrightness.night;
      expect(AppThemes.mode, ThemeMode.dark);
      AppThemes.brightness = AppBrightness.day;
      expect(AppThemes.mode, ThemeMode.light);
    });

    test('a change bumps the revision, an unchanged value does not', () {
      final start = AppThemes.revision.value;
      AppThemes.theme = _gruvbox;
      expect(AppThemes.revision.value, start + 1);
      AppThemes.theme = _gruvbox;
      expect(AppThemes.revision.value, start + 1);
    });

    test('the draft is what the app wears while one is being edited', () {
      AppThemes.theme = _gruvbox;
      final custom = CustomAppTheme(sampleCustomTheme());
      AppThemes.setDraft(custom);

      expect(AppThemes.theme, _gruvbox);
      expect(AppThemes.effective, custom);

      AppThemes.setDraft(null);
      expect(AppThemes.effective, _gruvbox);
    });
  });

  group('every shipped palette at every brightness', () {
    for (final palette in AppPalette.values) {
      for (final brightness in Brightness.values) {
        test('${palette.id} renders in $brightness', () {
          final theme = buildAppTheme(BuiltinAppTheme(palette), brightness);
          final scheme = theme.colorScheme;

          expect(scheme.brightness, brightness);
          // A dark theme writes light text on a dark ground, and a light
          // one the other way: a mapping copied from the wrong end of a
          // ramp is the mistake this catches.
          final ground = scheme.surface.computeLuminance();
          final ink = scheme.onSurface.computeLuminance();
          expect(
            brightness == Brightness.dark ? ink > ground : ground > ink,
            isTrue,
            reason: 'text and ground are the wrong way round',
          );
          // Solarized is deliberately low contrast — that is the whole
          // idea of it — so the gate is the large-text one rather than
          // 4.5:1. It still fails a palette whose text is invisible.
          expect(_contrast(scheme.onSurface, scheme.surface), greaterThan(3));
          expect(_contrast(scheme.onPrimary, scheme.primary), greaterThan(3));
          // The Markdown colors travel with the theme; nothing reads
          // them from a global.
          expect(theme.extension<SyntaxColors>(), isNotNull);
        });
      }
    }

    test('the named palettes are not the shipped one', () {
      final shipped = buildAppTheme(
        const BuiltinAppTheme(AppPalette.system),
        Brightness.dark,
      ).colorScheme.primary;
      for (final palette in AppPalette.values) {
        if (palette == AppPalette.system) continue;
        expect(
          buildAppTheme(
            BuiltinAppTheme(palette),
            Brightness.dark,
          ).colorScheme.primary,
          isNot(shipped),
          reason: '${palette.id} wears the default accent',
        );
      }
    });

    test('day and night are different colors, not the same ones', () {
      for (final palette in AppPalette.values) {
        final theme = BuiltinAppTheme(palette);
        final day = themeColors(theme, Brightness.light);
        final night = themeColors(theme, Brightness.dark);
        expect(day.scheme.surface, isNot(night.scheme.surface));
        if (palette != AppPalette.system) {
          expect(day.syntax, isNot(night.syntax));
        }
      }
    });

    test('the same request twice is the same theme', () {
      // The root builds both brightnesses on every rebuild; seeding a
      // scheme each time is work worth doing once.
      expect(
        identical(
          buildAppTheme(
            const BuiltinAppTheme(AppPalette.catppuccin),
            Brightness.dark,
          ),
          buildAppTheme(
            const BuiltinAppTheme(AppPalette.catppuccin),
            Brightness.dark,
          ),
        ),
        isTrue,
      );
    });
  });

  group('a custom theme', () {
    test('wears its own colors at both brightnesses', () {
      final custom = sampleCustomTheme();
      final theme = CustomAppTheme(custom);

      final day = themeColors(theme, Brightness.light);
      expect(day.scheme.primary, const Color(0xFF00695C));
      expect(day.scheme.surface, sampleDayBackground);
      expect(day.scheme.onSurface, isNot(day.scheme.surface));

      final night = themeColors(theme, Brightness.dark);
      expect(night.scheme.primary, const Color(0xFF7FD1C1));
      expect(night.scheme.surface, sampleNightBackground);
      expect(night.scheme.brightness, Brightness.dark);
    });

    test('paints the Markdown roles it was given', () {
      final custom = sampleCustomTheme();
      final colors = themeColors(CustomAppTheme(custom), Brightness.dark);
      expect(colors.syntax.wikilink, const Color(0xFF7FD1C1));
      expect(colors.syntax.dim, SyntaxColors.fallbackDark.dim);
      expect(
        buildAppTheme(
          CustomAppTheme(custom),
          Brightness.dark,
        ).extension<SyntaxColors>(),
        colors.syntax,
      );
    });

    test('an edit is a new theme, not the cached one', () {
      final custom = sampleCustomTheme();
      final before = buildAppTheme(CustomAppTheme(custom), Brightness.light);
      // The same colors are still the same theme, cache and all.
      expect(
        identical(
          before,
          buildAppTheme(CustomAppTheme(custom), Brightness.light),
        ),
        isTrue,
      );

      final edited = CustomAppTheme(
        custom.copyWith(
          day: sampleThemeColors(
            background: sampleDayBackground,
            accent: const Color(0xFF9A3412),
            dark: false,
          ),
        ),
      );
      final after = buildAppTheme(edited, Brightness.light);
      expect(after.colorScheme.primary, const Color(0xFF9A3412));
      expect(after, isNot(before));
    });

    test('the device colors leave it alone', () {
      final custom = CustomAppTheme(sampleCustomTheme());
      AppThemes.setDeviceColors(
        light: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
      );
      expect(
        themeColors(custom, Brightness.light).scheme.primary,
        const Color(0xFF00695C),
      );
    });
  });

  group('Material You', () {
    test('the device colors reach the system palette', () {
      const system = BuiltinAppTheme(AppPalette.system);
      final before = themeColors(system, Brightness.light).scheme.primary;
      final device = ColorScheme.fromSeed(seedColor: const Color(0xFF00695C));
      AppThemes.setDeviceColors(light: device, dark: device);

      final after = themeColors(system, Brightness.light);
      expect(after.scheme.primary, device.primary);
      expect(after.scheme.primary, isNot(before));
      // Wikilinks take the accent, which is how the device's color shows
      // up inside the note as well as around it.
      expect(after.syntax.wikilink, device.primary);
      // What the device says about a wallpaper says nothing about what a
      // blockquote should read as.
      expect(after.syntax.quote, SyntaxColors.fallbackLight.quote);
    });

    test('a named palette ignores them', () {
      final before = themeColors(_gruvbox, Brightness.dark).scheme;
      AppThemes.setDeviceColors(
        light: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        dark: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.dark,
        ),
      );

      expect(
        themeColors(_gruvbox, Brightness.dark).scheme.primary,
        before.primary,
      );
    });

    test('a device with nothing to say leaves the shipped seed', () {
      expect(AppThemes.hasDeviceColors, isFalse);
      expect(
        themeColors(
          const BuiltinAppTheme(AppPalette.system),
          Brightness.light,
        ).scheme.primary,
        ColorScheme.fromSeed(seedColor: shippedSeed).primary,
      );
    });

    test('the cached theme is rebuilt when they arrive', () {
      const system = BuiltinAppTheme(AppPalette.system);
      final before = buildAppTheme(system, Brightness.light);
      AppThemes.setDeviceColors(
        light: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        dark: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.dark,
        ),
      );

      final after = buildAppTheme(system, Brightness.light);
      expect(after.colorScheme.primary, isNot(before.colorScheme.primary));
    });
  });

  group('the Markdown colors', () {
    test('a theme without them falls back to the shipped ones', () {
      // A bare MaterialApp in a test, or any widget built outside the
      // app root: the editor still paints.
      final probe = ThemeData(brightness: Brightness.dark);
      expect(probe.extension<SyntaxColors>(), isNull);
    });

    test('they compare by value, so a repaint can be decided on them', () {
      // The editor caches one span per line and drops the cache when the
      // theme moves; identity would drop it on every rebuild instead.
      const solarized = BuiltinAppTheme(AppPalette.solarized);
      expect(
        themeColors(solarized, Brightness.dark).syntax,
        themeColors(solarized, Brightness.dark).syntax,
      );
      expect(
        themeColors(solarized, Brightness.dark).syntax,
        isNot(themeColors(_gruvbox, Brightness.dark).syntax),
      );
    });
  });
}
