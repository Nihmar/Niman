// The app's look (T-M6-05): how bright it is, and which colors it wears.
//
// A small global for the same reason `core/language.dart` is one: the app
// root sits above every provider, and the editor builds its style outside
// any Material ancestor. Unlike the two text sizes (T-M6-12) this one is
// app-wide and not a property of a library (design.md: the theme is
// app-side, and not synced) — the same eyes read every library on the same
// screen (user, 2026-09-10).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Brightness, ColorScheme, ThemeMode;

/// How bright the app is, plus the "follow the device" choice.
enum AppBrightness {
  /// Follow the OS setting (the default).
  system('system'),

  /// Light, whatever the OS says.
  day('day'),

  /// Dark, whatever the OS says.
  night('night');

  new(this.id);

  /// The persisted id.
  final String id;

  /// The brightness with this [id]; anything unknown is [system].
  static AppBrightness fromId(String? id) {
    for (final value in AppBrightness.values) {
      if (value.id == id) return value;
    }
    return AppBrightness.system;
  }
}

/// A set of colors the app can wear, day and night.
///
/// Each one is a mapping and nothing more: `ui/theme/` turns its color
/// roles into a Material scheme and the markdown colors, so a new entry
/// here plus a file of hex values is the whole of adding a palette.
enum AppPalette {
  /// The device's own colors (Material You): the wallpaper palette on
  /// Android 12 and up, the accent color on Windows, macOS and GTK,
  /// falling back to the shipped seed where the OS offers neither.
  system('system'),

  /// Catppuccin — Latte by day, Mocha by night.
  catppuccin('catppuccin'),

  /// Solarized — Schoonover's light and dark.
  solarized('solarized'),

  /// Gruvbox — the medium light and dark variants.
  gruvbox('gruvbox'),

  /// Niman — the app's own colors, taken from the logo.
  niman('niman');

  new(this.id);

  /// The persisted id.
  final String id;

  /// The palette with this [id]; anything unknown is [system].
  static AppPalette fromId(String? id) {
    for (final value in AppPalette.values) {
      if (value.id == id) return value;
    }
    return AppPalette.system;
  }
}

/// The theme in use: the user's brightness choice and their palette.
final class AppThemes {
  const new _();

  /// Bumped whenever either choice changes; the app root listens to it
  /// and rebuilds, so the new colors reach every open screen at once.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static AppBrightness _brightness = AppBrightness.system;
  static AppPalette _palette = AppPalette.niman;

  /// Day, night, or whatever the device says.
  static AppBrightness get brightness => _brightness;

  static set brightness(AppBrightness value) {
    if (_brightness == value) return;
    _brightness = value;
    revision.value++;
  }

  /// The colors the app wears.
  static AppPalette get palette => _palette;

  static set palette(AppPalette value) {
    if (_palette == value) return;
    _palette = value;
    revision.value++;
  }

  static ColorScheme? _deviceLight;
  static ColorScheme? _deviceDark;

  /// The device's own colors, once they have been read (Material You).
  ///
  /// Null until the platform answers, and null forever where it has
  /// nothing to say: the `system` palette falls back to the seed the app
  /// ships with, so the first frame is never colorless and a device
  /// without dynamic color is not a device without a theme.
  static ColorScheme? deviceScheme(Brightness brightness) =>
      brightness == Brightness.dark ? _deviceDark : _deviceLight;

  /// Whether the OS gave us colors of its own.
  static bool get hasDeviceColors => _deviceLight != null;

  /// Publishes what the platform answered.
  static void setDeviceColors({ColorScheme? light, ColorScheme? dark}) {
    if (_deviceLight == light && _deviceDark == dark) return;
    _deviceLight = light;
    _deviceDark = dark;
    revision.value++;
  }

  /// What the app root hands `MaterialApp.themeMode`.
  static ThemeMode get mode => switch (_brightness) {
    AppBrightness.system => ThemeMode.system,
    AppBrightness.day => ThemeMode.light,
    AppBrightness.night => ThemeMode.dark,
  };

  /// Publishes both choices at once, for the startup read.
  static void apply({
    required AppBrightness brightness,
    required AppPalette palette,
  }) {
    AppThemes.brightness = brightness;
    AppThemes.palette = palette;
  }

  /// Puts everything back to what a fresh install wears, the device's
  /// colors included.
  static void reset() {
    setDeviceColors();
    apply(brightness: AppBrightness.system, palette: AppPalette.niman);
  }
}
