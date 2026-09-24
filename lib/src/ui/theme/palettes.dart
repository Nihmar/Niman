// The themes the app can wear, and the theme built out of one (T-M6-05,
// issue #269).
//
// Every shipped palette is a mapping — a file of named colors in this
// folder — and a custom theme is the same mapping with the user's own
// colors in it; the code below is the same for both. Chrome tokens become
// a Material scheme, Markdown colors ride along as a theme extension, and
// `buildAppTheme` puts the two together. Adding a shipped palette is
// adding a mapping and one line in `_builtin`; no widget ever asks which
// theme is on.

import 'package:flutter/material.dart';
import 'package:niman/src/core/app_theme.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/ui/theme/catppuccin.dart';
import 'package:niman/src/ui/theme/gruvbox.dart';
import 'package:niman/src/ui/theme/niman.dart';
import 'package:niman/src/ui/theme/scheme.dart';
import 'package:niman/src/ui/theme/solarized.dart';

/// The seed the app has shipped since M0, and what the `system` palette
/// falls back to where the OS has no colors to offer.
const Color shippedSeed = Color(0xFF45475A);

/// A theme resolved at one brightness: the Material scheme the whole
/// interface reads, and the Markdown colors the editor and the preview
/// paint with.
@immutable
final class PaletteColors {
  /// Creates the pair.
  const new({required this.scheme, required this.syntax});

  /// The Material scheme.
  final ColorScheme scheme;

  /// The Markdown colors.
  final SyntaxColors syntax;
}

/// The colors of [theme] at [brightness].
PaletteColors themeColors(AppTheme theme, Brightness brightness) {
  return switch (theme) {
    BuiltinAppTheme(:final palette) => _builtin(palette, brightness),
    CustomAppTheme(:final theme) => _custom(theme, brightness),
  };
}

/// The theme [theme] builds at [brightness].
///
/// Cached, because the app root builds both brightnesses on every rebuild
/// and each one seeds a Material scheme, which is real work. The key
/// carries the device colors so the Material You theme is rebuilt when
/// the platform finally answers, and the theme itself by value, so an
/// edited custom theme misses the scheme its old colors built.
ThemeData buildAppTheme(AppTheme theme, Brightness brightness) {
  final key = (theme, brightness, AppThemes.deviceScheme(brightness));
  final cached = _themes[key];
  if (cached != null) return cached;
  final colors = themeColors(theme, brightness);
  final data = ThemeData(
    brightness: brightness,
    colorScheme: colors.scheme,
    extensions: [colors.syntax],
  );
  // Two entries per theme, plus a stale pair per edit; a handful of
  // themes never comes near this, and one that did would only pay for
  // rebuilding what it wears.
  if (_themes.length >= 64) _themes.clear();
  _themes[key] = data;
  return data;
}

final Map<(AppTheme, Brightness, ColorScheme?), ThemeData> _themes = {};

/// A shipped palette at [brightness].
PaletteColors _builtin(AppPalette palette, Brightness brightness) {
  return switch (palette) {
    AppPalette.system => _deviceColors(brightness),
    AppPalette.catppuccin => _mapped(
      catppuccinTokens(brightness),
      catppuccinSyntax(brightness),
      brightness,
    ),
    AppPalette.solarized => _mapped(
      solarizedTokens(brightness),
      solarizedSyntax(brightness),
      brightness,
    ),
    AppPalette.gruvbox => _mapped(
      gruvboxTokens(brightness),
      gruvboxSyntax(brightness),
      brightness,
    ),
    AppPalette.niman => _mapped(
      nimanTokens(brightness),
      nimanSyntax(brightness),
      brightness,
    ),
  };
}

/// A custom theme at [brightness]: its day colors in daylight, its night
/// colors at night, mapped exactly like a shipped palette's.
PaletteColors _custom(CustomTheme theme, Brightness brightness) {
  final colors = brightness == Brightness.dark ? theme.night : theme.day;
  return _mapped(colors.tokens, colors.syntax, brightness);
}

/// The device's own colors, or the shipped seed where there are none.
///
/// The Markdown colors stay the ones the app ships: a wallpaper says what
/// the accent is, not what a blockquote or a math span should read as.
/// Wikilinks follow the accent, which is what makes the OS color visible
/// inside the note as well as around it.
PaletteColors _deviceColors(Brightness brightness) {
  final scheme =
      AppThemes.deviceScheme(brightness) ??
      ColorScheme.fromSeed(seedColor: shippedSeed, brightness: brightness);
  final shipped = brightness == Brightness.dark
      ? SyntaxColors.fallbackDark
      : SyntaxColors.fallbackLight;
  return PaletteColors(
    scheme: scheme,
    syntax: shipped.copyWith(wikilink: scheme.primary),
  );
}

PaletteColors _mapped(
  PaletteTokens tokens,
  SyntaxColors syntax,
  Brightness brightness,
) =>
    PaletteColors(scheme: schemeFromTokens(tokens, brightness), syntax: syntax);
