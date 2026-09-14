import 'dart:ui' show Brightness;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/widget/widget_theme.dart';

void main() {
  group('resolveWidgetTheme', () {
    test('day forces light, night forces dark', () {
      AppThemes.apply(brightness: AppBrightness.day, palette: AppPalette.niman);
      final day = resolveWidgetTheme(platform: Brightness.dark);
      expect(day.dark, isFalse);
      AppThemes.apply(
        brightness: AppBrightness.night,
        palette: AppPalette.niman,
      );
      final night = resolveWidgetTheme(platform: Brightness.light);
      expect(night.dark, isTrue);
      AppThemes.apply(
        brightness: AppBrightness.system,
        palette: AppPalette.niman,
      );
    });

    test('system follows the platform', () {
      AppThemes.apply(
        brightness: AppBrightness.system,
        palette: AppPalette.niman,
      );
      expect(resolveWidgetTheme(platform: Brightness.dark).dark, isTrue);
      expect(resolveWidgetTheme(platform: Brightness.light).dark, isFalse);
    });

    test('colors are opaque-friendly #AARRGGBB hex', () {
      AppThemes.apply(
        brightness: AppBrightness.night,
        palette: AppPalette.niman,
      );
      final theme = resolveWidgetTheme(platform: Brightness.dark);
      for (final color in [
        theme.background,
        theme.primary,
        theme.secondary,
        theme.accent,
      ]) {
        expect(color, matches(RegExp(r'^#[0-9A-F]{8}$')));
      }
      // The card keeps the shipped translucency.
      expect(theme.background.substring(1, 3), 'E6');
      AppThemes.apply(
        brightness: AppBrightness.system,
        palette: AppPalette.niman,
      );
    });

    test('the palette moves the accent', () {
      AppThemes.apply(
        brightness: AppBrightness.night,
        palette: AppPalette.niman,
      );
      final niman = resolveWidgetTheme(platform: Brightness.dark);
      AppThemes.apply(
        brightness: AppBrightness.night,
        palette: AppPalette.gruvbox,
      );
      final gruvbox = resolveWidgetTheme(platform: Brightness.dark);
      expect(gruvbox.accent, isNot(niman.accent));
      AppThemes.apply(
        brightness: AppBrightness.system,
        palette: AppPalette.niman,
      );
    });
  });

  group('theme maps and URIs', () {
    const theme = (
      dark: true,
      background: '#E61A1C1E',
      primary: '#FFE2E2E5',
      secondary: '#FFC3C6CF',
      accent: '#FFD0BCFF',
    );

    test('toMap/fromMap round-trip', () {
      final map = widgetThemeToMap(theme);
      expect(map, {
        'dark': true,
        'background': '#E61A1C1E',
        'primary': '#FFE2E2E5',
        'secondary': '#FFC3C6CF',
        'accent': '#FFD0BCFF',
      });
      expect(widgetThemeFromMap(map.cast<String, Object?>()), theme);
    });

    test('fromMap rejects garbage', () {
      expect(widgetThemeFromMap(null), isNull);
      expect(widgetThemeFromMap({}), isNull);
      expect(
        widgetThemeFromMap({
          'dark': true,
          'background': 'red',
          'primary': '#FFE2E2E5',
          'secondary': '#FFC3C6CF',
          'accent': '#FFD0BCFF',
        }),
        isNull,
      );
    });

    test('fromUri reads appended params, rejects partial ones', () {
      final params = <String, String>{};
      appendWidgetThemeParams(params, theme);
      final uri = Uri(
        scheme: 'niman',
        host: 'todo-toggle',
        queryParameters: {'id': '7', ...params},
      );
      expect(widgetThemeFromUri(uri), theme);
      expect(widgetThemeFromUri(Uri.parse('niman://todo-toggle?id=7')), isNull);
      expect(
        widgetThemeFromUri(Uri.parse('niman://todo-toggle?id=7&td=2')),
        isNull,
      );
    });

    test('appending a null theme appends nothing', () {
      final params = <String, String>{'id': '7'};
      appendWidgetThemeParams(params, null);
      expect(params, {'id': '7'});
    });
  });
}
