// Niman — the app's own colors, taken from the logo.
//
// The mark is three colors: an anthracite ground, a cream "N", and one
// blue square. Night wears them as the logo does — cream on anthracite,
// the blue the accent — and day is the same three read from the other
// end, the cream become the ground and the anthracite the ink. The rest
// of the Markdown palette is a small cool family built around the blue,
// since the logo names only the one accent.

import 'package:flutter/material.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// Niman's chrome at [brightness].
PaletteTokens nimanTokens(Brightness brightness) =>
    brightness == Brightness.dark ? _dark : _light;

/// Niman's Markdown colors at [brightness].
SyntaxColors nimanSyntax(Brightness brightness) =>
    brightness == Brightness.dark ? _darkSyntax : _lightSyntax;

// The three the logo is drawn with.
const Color _anthracite = Color(0xFF23262B); // the ground of the mark
const Color _cream = Color(0xFFF2EDE5); // the "N"
const Color _blue = Color(0xFF587CD3); // the square

// Night — the logo's own look. The grounds step down from the mark's
// anthracite; the raised surfaces step up from it.
const PaletteTokens _dark = PaletteTokens(
  background: _anthracite,
  backdrop: Color(0xFF1B1D21),
  surface: Color(0xFF2C3037),
  surfaceHigh: Color(0xFF363B44),
  text: _cream,
  muted: Color(0xFFA6A29A),
  outline: Color(0xFF4A4F59),
  accent: _blue,
  onAccent: _cream,
  error: Color(0xFFE0687A),
);

const SyntaxColors _darkSyntax = SyntaxColors(
  dim: Color(0xFF6B7079),
  code: Color(0xFF7FD1C4),
  codeMuted: Color(0xFF6B7079),
  link: Color(0xFF7CA0E6),
  wikilink: _blue,
  image: Color(0xFFD8A56B),
  task: Color(0xFF8FBF7F),
  quote: Color(0xFF9A968E),
  math: Color(0xFFC08CD8),
  tag: Color(0xFF6FB8CC),
);

// Day — the same three colors turned over: the cream is the ground and
// the anthracite the ink. The blue is nudged darker so accent-colored
// text stays readable on the light ground.
const Color _blueOnCream = Color(0xFF4762BE);

const PaletteTokens _light = PaletteTokens(
  background: _cream,
  backdrop: Color(0xFFEAE4D8),
  surface: Color(0xFFEBE5DB),
  surfaceHigh: Color(0xFFDCD5C8),
  text: _anthracite,
  muted: Color(0xFF6E7178),
  outline: Color(0xFFC4BDAF),
  accent: _blueOnCream,
  onAccent: _cream,
  error: Color(0xFFC0392B),
);

const SyntaxColors _lightSyntax = SyntaxColors(
  dim: Color(0xFF9B968C),
  code: Color(0xFF2E8C86),
  codeMuted: Color(0xFF9B968C),
  link: Color(0xFF3E63C7),
  wikilink: _blueOnCream,
  image: Color(0xFFB26A25),
  task: Color(0xFF4F8A3E),
  quote: Color(0xFF6E6A60),
  math: Color(0xFF8A44B0),
  tag: Color(0xFF217F94),
);
