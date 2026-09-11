// The palettes the app ships, and the theme built out of one (T-M6-05).
//
// Every palette is a mapping — a file of named colors in this folder —
// and the code below is the same for all of them: chrome tokens become a
// Material scheme, Markdown colors ride along as a theme extension, and
// `buildAppTheme` puts the two together. Adding a palette is adding a
// mapping and one line in [paletteColors]; no widget ever asks which one
// is on.

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/ui/theme/catppuccin.dart';
import 'package:niman/src/ui/theme/gruvbox.dart';
import 'package:niman/src/ui/theme/solarized.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// The seed the app has shipped since M0, and what the `system` palette
/// falls back to where the OS has no colors to offer.
const Color shippedSeed = Color(0xFF45475A);

/// A palette resolved at one brightness: the Material scheme the whole
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

/// The colors of [palette] at [brightness].
PaletteColors paletteColors(AppPalette palette, Brightness brightness) {
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
  };
}

/// The theme [palette] builds at [brightness].
///
/// Cached, because the app root builds both brightnesses on every rebuild
/// and each one seeds a Material scheme, which is real work. The key
/// carries the device colors so the Material You theme is rebuilt when
/// the platform finally answers.
ThemeData buildAppTheme(AppPalette palette, Brightness brightness) {
  final key = (palette, brightness, AppThemes.deviceScheme(brightness));
  final cached = _themes[key];
  if (cached != null) return cached;
  final colors = paletteColors(palette, brightness);
  final theme = ThemeData(
    brightness: brightness,
    colorScheme: colors.scheme,
    extensions: [colors.syntax],
  );
  // A handful of palettes times two brightnesses; it never grows.
  _themes[key] = theme;
  return theme;
}

final Map<(AppPalette, Brightness, ColorScheme?), ThemeData> _themes = {};

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
