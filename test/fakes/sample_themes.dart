// Sample themes for the tests (issue #269).
//
// A custom theme fills in twenty roles at each brightness, which makes
// one written out by hand in every test unreadable. These helpers fill
// them all in from two colors — a ground and an accent — so a test says
// only which of the two it is about.

import 'package:flutter/material.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/core/theme_tokens.dart';

/// The daylight ground [sampleCustomTheme] wears unless asked otherwise.
const Color sampleDayBackground = Color(0xFFF7F5F2);

/// The night ground [sampleCustomTheme] wears unless asked otherwise.
const Color sampleNightBackground = Color(0xFF101418);

/// The daylight accent [sampleCustomTheme] wears unless asked otherwise.
const Color sampleDayAccent = Color(0xFF00695C);

/// The night accent [sampleCustomTheme] wears unless asked otherwise.
const Color sampleNightAccent = Color(0xFF7FD1C1);

/// A complete custom theme: [id] and [name] as given, every role filled
/// in from the four colors above.
CustomTheme sampleCustomTheme({
  String id = 'sample',
  String name = 'Sample',
  Color dayBackground = sampleDayBackground,
  Color nightBackground = sampleNightBackground,
  Color dayAccent = sampleDayAccent,
  Color nightAccent = sampleNightAccent,
}) => CustomTheme(
  id: id,
  name: name,
  day: sampleThemeColors(
    background: dayBackground,
    accent: dayAccent,
    dark: false,
  ),
  night: sampleThemeColors(
    background: nightBackground,
    accent: nightAccent,
    dark: true,
  ),
);

/// One brightness of a sample theme: [background] and [accent] as given,
/// everything else derived to stay on the right side of the ground.
ThemeColors sampleThemeColors({
  required Color background,
  required Color accent,
  required bool dark,
}) {
  final ink = dark ? const Color(0xFFECECEC) : const Color(0xFF1A1A1A);
  final shipped = dark ? SyntaxColors.fallbackDark : SyntaxColors.fallbackLight;
  return ThemeColors(
    tokens: PaletteTokens(
      background: background,
      backdrop: _exact(Color.lerp(background, ink, 0.06)!),
      surface: _exact(Color.lerp(background, ink, 0.03)!),
      surfaceHigh: _exact(Color.lerp(background, ink, 0.07)!),
      text: ink,
      muted: _exact(Color.lerp(ink, background, 0.4)!),
      outline: _exact(Color.lerp(ink, background, 0.75)!),
      accent: accent,
      onAccent: accent.computeLuminance() > 0.5
          ? const Color(0xFF101418)
          : Colors.white,
      error: dark ? const Color(0xFFF2B8B5) : const Color(0xFFB3261E),
    ),
    syntax: shipped.copyWith(wikilink: accent),
  );
}

/// [color] with its channels rounded to what a theme file can hold.
///
/// A sample has to survive being written as `#RRGGBB` and read back —
/// that is how a real theme travels, and `Color.lerp` leaves channels no
/// 8-bit value names.
Color _exact(Color color) => Color(color.toARGB32());
