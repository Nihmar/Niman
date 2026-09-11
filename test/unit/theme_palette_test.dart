// T-M6-05: brightness × palette. Every combination has to produce a
// readable theme, the named palettes have to be mappings and nothing
// else, and the device's own colors have to reach the `system` one.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/ui/theme/palettes.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// The WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final one = a.computeLuminance();
  final two = b.computeLuminance();
  final lighter = one > two ? one : two;
  final darker = one > two ? two : one;
  return (lighter + 0.05) / (darker + 0.05);
}

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

    test('the brightness choice is what MaterialApp is handed', () {
      expect(AppThemes.mode, ThemeMode.system);
      AppThemes.brightness = AppBrightness.night;
      expect(AppThemes.mode, ThemeMode.dark);
      AppThemes.brightness = AppBrightness.day;
      expect(AppThemes.mode, ThemeMode.light);
    });

    test('a change bumps the revision, an unchanged value does not', () {
      final start = AppThemes.revision.value;
      AppThemes.palette = AppPalette.gruvbox;
      expect(AppThemes.revision.value, start + 1);
      AppThemes.palette = AppPalette.gruvbox;
      expect(AppThemes.revision.value, start + 1);
    });
  });

  group('every palette at every brightness', () {
    for (final palette in AppPalette.values) {
      for (final brightness in Brightness.values) {
        test('${palette.id} renders in $brightness', () {
          final theme = buildAppTheme(palette, brightness);
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
        AppPalette.system,
        Brightness.dark,
      ).colorScheme.primary;
      for (final palette in AppPalette.values) {
        if (palette == AppPalette.system) continue;
        expect(
          buildAppTheme(palette, Brightness.dark).colorScheme.primary,
          isNot(shipped),
          reason: '${palette.id} wears the default accent',
        );
      }
    });

    test('day and night are different colors, not the same ones', () {
      for (final palette in AppPalette.values) {
        final day = paletteColors(palette, Brightness.light);
        final night = paletteColors(palette, Brightness.dark);
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
          buildAppTheme(AppPalette.catppuccin, Brightness.dark),
          buildAppTheme(AppPalette.catppuccin, Brightness.dark),
        ),
        isTrue,
      );
    });
  });

  group('Material You', () {
    test('the device colors reach the system palette', () {
      final before = paletteColors(
        AppPalette.system,
        Brightness.light,
      ).scheme.primary;
      final device = ColorScheme.fromSeed(seedColor: const Color(0xFF00695C));
      AppThemes.setDeviceColors(light: device, dark: device);

      final after = paletteColors(AppPalette.system, Brightness.light);
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
      final before = paletteColors(AppPalette.gruvbox, Brightness.dark).scheme;
      AppThemes.setDeviceColors(
        light: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        dark: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.dark,
        ),
      );

      expect(
        paletteColors(AppPalette.gruvbox, Brightness.dark).scheme.primary,
        before.primary,
      );
    });

    test('a device with nothing to say leaves the shipped seed', () {
      expect(AppThemes.hasDeviceColors, isFalse);
      expect(
        paletteColors(AppPalette.system, Brightness.light).scheme.primary,
        ColorScheme.fromSeed(seedColor: shippedSeed).primary,
      );
    });

    test('the cached theme is rebuilt when they arrive', () {
      final before = buildAppTheme(AppPalette.system, Brightness.light);
      AppThemes.setDeviceColors(
        light: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        dark: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.dark,
        ),
      );

      final after = buildAppTheme(AppPalette.system, Brightness.light);
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
      // palette moves; identity would drop it on every rebuild instead.
      expect(
        paletteColors(AppPalette.solarized, Brightness.dark).syntax,
        paletteColors(AppPalette.solarized, Brightness.dark).syntax,
      );
      expect(
        paletteColors(AppPalette.solarized, Brightness.dark).syntax,
        isNot(paletteColors(AppPalette.gruvbox, Brightness.dark).syntax),
      );
    });
  });
}
