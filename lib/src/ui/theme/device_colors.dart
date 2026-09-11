// Material You: the colors the device itself is wearing (T-M6-05).
//
// Two sources, one answer. Android 12 and up hands out a whole tonal
// palette derived from the wallpaper; Windows, macOS and GTK hand out a
// single accent color, which is seeded into a scheme the same way the
// app's own seed is. Everything else answers nothing, and the `system`
// palette falls back to the shipped seed.
//
// Read once, at startup, and published on `AppThemes` rather than wrapped
// around the app in a builder: the app root already rebuilds on that
// notifier for the language and the two text sizes, and a palette that
// arrives a frame late is a palette that arrives.

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/theme.dart';

const AppLogger _log = AppLogger(name: 'theme');

/// Asks the platform for its colors and publishes them.
///
/// Never throws: a missing plugin, an OEM that answers with nonsense or a
/// platform that has no opinion all mean the same thing — the app wears
/// the colors it ships with.
Future<void> readDeviceColors() async {
  try {
    final core = await DynamicColorPlugin.getCorePalette();
    if (core != null) {
      // Tone 40 of the wallpaper's primary: the key color Material's own
      // light scheme is built around. The scheme itself is seeded here
      // rather than taken from the plugin, whose `toColorScheme` builds
      // the Material library's own `ColorScheme` and not the framework's.
      _publish(Color(core.primary.get(40)), 'wallpaper palette');
      return;
    }
  } on Object catch (error) {
    _log.warning('wallpaper palette unavailable ($error)');
  }
  try {
    final accent = await DynamicColorPlugin.getAccentColor();
    if (accent != null) {
      _publish(accent, 'system accent');
      return;
    }
  } on Object catch (error) {
    _log.warning('system accent unavailable ($error)');
  }
  _log.info('device colors: none, using the shipped seed');
}

/// Seeds both brightnesses from [accent] and publishes them.
void _publish(Color accent, String source) {
  AppThemes.setDeviceColors(
    light: ColorScheme.fromSeed(seedColor: accent),
    dark: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
  );
  _log.info('device colors: $source');
}
