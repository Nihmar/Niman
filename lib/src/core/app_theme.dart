// The theme the app wears (issue #269).
//
// Two kinds, one answer: a palette the app ships, or a theme the user
// made. Everything that paints asks the same question — the roles and
// colors at a brightness — and this is the value that carries the
// question's subject, with [id] the form it is stored under.
//
// [AppThemes] is where the answer lives at runtime: a small global for
// the same reason `core/language.dart` is one — the app root sits above
// every provider, and the editor builds its style outside any Material
// ancestor — and app-wide rather than a property of a library, because
// the same eyes read every library on the same screen (user,
// 2026-09-10).

import 'package:flutter/foundation.dart' show ValueNotifier, immutable;
import 'package:flutter/material.dart' show Brightness, ColorScheme, ThemeMode;
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme.dart';

/// A theme the app can wear.
sealed class AppTheme {
  /// For subclasses.
  const new();

  /// The id this theme is stored under (`niman`, `catppuccin`,
  /// `custom:<id>`).
  String get id;

  /// What a custom theme's id starts with; anything else is a shipped
  /// palette's.
  static const String customPrefix = 'custom:';

  /// The custom theme id inside [id], or null when it names a palette.
  static String? customIdIn(String id) {
    if (!id.startsWith(customPrefix)) return null;
    final custom = id.substring(customPrefix.length);
    return custom.isEmpty ? null : custom;
  }
}

/// One of the palettes the app ships.
@immutable
final class BuiltinAppTheme extends AppTheme {
  /// Wraps [palette].
  const new(this.palette);

  /// Which palette.
  final AppPalette palette;

  @override
  String get id => palette.id;

  @override
  bool operator ==(Object other) =>
      other is BuiltinAppTheme && other.palette == palette;

  @override
  int get hashCode => palette.hashCode;
}

/// A theme the user made.
@immutable
final class CustomAppTheme extends AppTheme {
  /// Wraps [theme].
  const new(this.theme);

  /// The theme itself, colors included.
  final CustomTheme theme;

  @override
  String get id => '${AppTheme.customPrefix}${theme.id}';

  @override
  bool operator ==(Object other) =>
      other is CustomAppTheme && other.theme == theme;

  @override
  int get hashCode => theme.hashCode;
}

/// The theme the stored [id] names, with the custom theme it points at
/// (null when this installation holds none by that id).
///
/// An id this build does not know — a palette that shipped in a later
/// one, a row edited by hand — reads as [AppPalette.system], the colors
/// the app wore before there was anything to choose.
AppTheme themeFromId(String id, {CustomTheme? custom}) {
  final customId = AppTheme.customIdIn(id);
  if (customId != null && custom != null) return CustomAppTheme(custom);
  return BuiltinAppTheme(AppPalette.fromId(id));
}

/// The theme in use: the user's brightness choice and the theme they
/// wear.
final class AppThemes {
  const new _();

  /// Bumped whenever either choice changes; the app root listens to it
  /// and rebuilds, so the new colors reach every open screen at once.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static AppBrightness _brightness = AppBrightness.system;
  static AppTheme _theme = const BuiltinAppTheme(AppPalette.niman);
  static AppTheme? _draft;

  /// Day, night, or whatever the device says.
  static AppBrightness get brightness => _brightness;

  static set brightness(AppBrightness value) {
    if (_brightness == value) return;
    _brightness = value;
    revision.value++;
  }

  /// The theme the app wears (Niman's own colors on a fresh install).
  static AppTheme get theme => _theme;

  static set theme(AppTheme value) {
    if (_theme == value) return;
    _theme = value;
    revision.value++;
  }

  /// The theme being edited right now, while the editor is open (issue
  /// #269): the app wears it so every color can be seen in place, and
  /// dropping it — Save or Cancel alike — puts back what is stored.
  static AppTheme? get draft => _draft;

  /// Starts wearing [value] for the editor, or stops with null.
  static void setDraft(AppTheme? value) {
    if (_draft == value) return;
    _draft = value;
    revision.value++;
  }

  /// What every widget wears: the draft while one is being edited, the
  /// stored theme otherwise.
  static AppTheme get effective => _draft ?? _theme;

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
    required AppTheme theme,
  }) {
    AppThemes.brightness = brightness;
    AppThemes.theme = theme;
  }

  /// Puts everything back to what a fresh install wears, the device's
  /// colors included.
  static void reset() {
    setDeviceColors();
    setDraft(null);
    apply(
      brightness: AppBrightness.system,
      theme: const BuiltinAppTheme(AppPalette.niman),
    );
  }
}
