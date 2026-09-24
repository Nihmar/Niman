// A theme invented on the spot (issue #269).
//
// One random accent, and every other role derived from it: a ground and
// an ink that belong to the accent's hue, an accent that reads on its
// own ground, and Markdown colors spread around the same wheel. The
// point is a theme that is never ugly enough to be broken and never the
// same twice — something to start editing, not a design.
//
// Every color is rounded to what a file can hold (`#RRGGBB`), because
// that is how a theme is stored and exported: a theme that does not
// survive the round trip is a theme that changes when saved.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:niman/src/core/custom_theme.dart';
import 'package:niman/src/core/theme_colors.dart';
import 'package:niman/src/core/theme_tokens.dart';

/// A complete custom theme in colors nobody chose: [name] as given, and
/// the rest around one random hue.
///
/// [random] seeds the generator, so a test can ask for the same theme
/// twice.
CustomTheme randomCustomTheme({
  required String id,
  required String name,
  Random? random,
}) {
  final rng = random ?? Random();
  final hue = rng.nextDouble() * 360;
  return CustomTheme(
    id: id,
    name: name,
    day: _variant(hue: hue, dark: false),
    night: _variant(hue: hue, dark: true),
  );
}

/// The colors of a random theme at one brightness.
ThemeColors _variant({required double hue, required bool dark}) {
  // The ground and the ink keep the hue in a whisper: enough that the two
  // brightnesses read as one theme, not enough to make text hard to read.
  final ground = dark ? _hsl(hue, 0.14, 0.09) : _hsl(hue, 0.16, 0.98);
  final ink = dark ? _hsl(hue, 0.06, 0.92) : _hsl(hue, 0.08, 0.13);
  final accent = dark ? _hsl(hue, 0.55, 0.66) : _hsl(hue, 0.62, 0.36);
  final tokens = PaletteTokens(
    background: ground,
    backdrop: _blend(ground, ink, 0.06),
    surface: _blend(ground, ink, 0.04),
    surfaceHigh: _blend(ground, ink, 0.08),
    text: ink,
    muted: _blend(ink, ground, 0.35),
    outline: _blend(ink, ground, 0.72),
    accent: accent,
    onAccent: _readableOn(accent),
    error: dark ? _hsl(8, 0.62, 0.72) : _hsl(8, 0.72, 0.38),
  );
  final distant = dark ? 0.72 : 0.34;
  final syntax = SyntaxColors(
    dim: _blend(ink, ground, 0.45),
    code: _hsl(hue + 40, 0.40, distant),
    codeMuted: _blend(ink, ground, 0.55),
    link: _hsl(hue + 200, 0.55, distant),
    wikilink: accent,
    image: _hsl(hue + 300, 0.45, distant),
    task: _hsl(hue + 120, 0.45, distant),
    quote: _blend(ink, ground, 0.42),
    math: _hsl(hue + 270, 0.45, distant),
    tag: _hsl(hue + 160, 0.45, distant),
  );
  return ThemeColors(tokens: tokens, syntax: syntax);
}

/// [hue] (degrees), [saturation] and [lightness] (0–1) as a color.
///
/// Rounded to what `#RRGGBB` can say, like every color a theme is
/// stored as.
Color _hsl(double hue, double saturation, double lightness) {
  final color = HSLColor.fromAHSL(
    1,
    hue % 360,
    saturation.clamp(0, 1),
    lightness.clamp(0, 1),
  ).toColor();
  return Color(color.toARGB32());
}

/// Black or white, whichever reads better on [color].
///
/// Picking by luminance leaves colors in the middle that read on neither;
/// comparing the two contrast ratios picks the side that cannot be wrong,
/// since their product is 21 and the better one is always above 4.5.
Color _readableOn(Color color) =>
    _contrast(color, Colors.white) >= _contrast(color, Colors.black)
    ? Colors.white
    : Colors.black;

/// The WCAG contrast ratio between two opaque colors.
double _contrast(Color a, Color b) {
  final one = a.computeLuminance();
  final two = b.computeLuminance();
  final lighter = one > two ? one : two;
  final darker = one > two ? two : one;
  return (lighter + 0.05) / (darker + 0.05);
}

/// [a] pulled [t] of the way towards [b], rounded the same way.
Color _blend(Color a, Color b, double t) =>
    Color(Color.lerp(a, b, t)!.toARGB32());
