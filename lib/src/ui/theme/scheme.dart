// A palette's color roles turned into the Material scheme the interface
// reads (T-M6-05).
//
// The one Material-shaped piece of a theme: [PaletteTokens] are the app's
// vocabulary (core/theme_tokens.dart), and this is the mapping onto
// `ColorScheme`. No widget ever asks which theme is on.

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';

/// The Material scheme a palette's [tokens] describe, at [brightness].
///
/// Seeded from the accent so the roles no palette names — the containers
/// Material derives, the inverse pair, the scrim — stay in the family,
/// then overwritten wherever the palette has an opinion. Every role the
/// app actually paints with is one of the overwritten ones.
ColorScheme schemeFromTokens(PaletteTokens tokens, Brightness brightness) {
  final seeded = ColorScheme.fromSeed(
    seedColor: tokens.accent,
    brightness: brightness,
  );
  return seeded.copyWith(
    primary: tokens.accent,
    onPrimary: tokens.onAccent,
    primaryContainer: tokens.surfaceHigh,
    onPrimaryContainer: tokens.text,
    // One accent, used everywhere it is asked for: a palette names the
    // color that carries it, not three of them, and inventing the other
    // two from the seed puts colors on screen the palette never chose.
    secondary: tokens.accent,
    onSecondary: tokens.onAccent,
    secondaryContainer: tokens.surfaceHigh,
    onSecondaryContainer: tokens.text,
    tertiary: tokens.accent,
    onTertiary: tokens.onAccent,
    tertiaryContainer: tokens.surfaceHigh,
    onTertiaryContainer: tokens.text,
    surface: tokens.background,
    onSurface: tokens.text,
    surfaceDim: tokens.backdrop,
    surfaceBright: tokens.surfaceHigh,
    surfaceContainerLowest: tokens.backdrop,
    surfaceContainerLow: tokens.background,
    surfaceContainer: tokens.surface,
    surfaceContainerHigh: tokens.surfaceHigh,
    surfaceContainerHighest: tokens.surfaceHigh,
    surfaceTint: tokens.accent,
    onSurfaceVariant: tokens.muted,
    outline: tokens.outline,
    outlineVariant: tokens.surfaceHigh,
    error: tokens.error,
    onError: tokens.onAccent,
    errorContainer: tokens.surfaceHigh,
    onErrorContainer: tokens.error,
    inverseSurface: tokens.text,
    onInverseSurface: tokens.background,
    inversePrimary: tokens.accent,
  );
}
