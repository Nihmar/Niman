// Solarized — Ethan Schoonover's light and dark.
//
// Solarized is eight monotones and eight accents, and the two schemes are
// the same colors read from opposite ends: dark builds on base03, light on
// base3, and both take their text from the middle of the ramp. Blue is the
// accent, as in the original's UI examples.

import 'package:flutter/material.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// Solarized's chrome at [brightness].
PaletteTokens solarizedTokens(Brightness brightness) =>
    brightness == Brightness.dark ? _dark : _light;

/// Solarized's Markdown colors at [brightness].
SyntaxColors solarizedSyntax(Brightness brightness) =>
    brightness == Brightness.dark ? _darkSyntax : _lightSyntax;

// The accents, shared by both schemes — that is the point of Solarized.
const Color _orange = Color(0xFFCB4B16);
const Color _red = Color(0xFFDC322F);
const Color _magenta = Color(0xFFD33682);
const Color _violet = Color(0xFF6C71C4);
const Color _blue = Color(0xFF268BD2);
const Color _cyan = Color(0xFF2AA198);
const Color _green = Color(0xFF859900);

// The monotones, dark end first.
const Color _base03 = Color(0xFF002B36);
const Color _base02 = Color(0xFF073642);
const Color _base01 = Color(0xFF586E75);
const Color _base00 = Color(0xFF657B83);
const Color _base0 = Color(0xFF839496);
const Color _base1 = Color(0xFF93A1A1);
const Color _base2 = Color(0xFFEEE8D5);
const Color _base3 = Color(0xFFFDF6E3);

// Dark. The step below base03 is not in the published ramp; it is base03
// taken a shade further down, which is what the original terminal theme
// does for its own background too.
const PaletteTokens _dark = PaletteTokens(
  background: _base03,
  backdrop: Color(0xFF00212A),
  surface: _base02,
  surfaceHigh: Color(0xFF0B4451),
  text: _base0,
  muted: _base01,
  outline: _base01,
  accent: _blue,
  onAccent: _base03,
  error: _red,
);

const SyntaxColors _darkSyntax = SyntaxColors(
  dim: _base01,
  code: _cyan,
  codeMuted: _base01,
  link: _blue,
  wikilink: _blue,
  image: _violet,
  task: _green,
  quote: _base00,
  math: _magenta,
  tag: _orange,
);

// Light. Only two monotones sit above base1, so the raised surfaces run
// base3 → base2 with one blend between them.
const PaletteTokens _light = PaletteTokens(
  background: _base3,
  backdrop: Color(0xFFFFFBF0),
  surface: Color(0xFFF6F0DC),
  surfaceHigh: _base2,
  text: _base00,
  muted: _base1,
  outline: _base1,
  accent: _blue,
  onAccent: _base3,
  error: _red,
);

const SyntaxColors _lightSyntax = SyntaxColors(
  dim: _base1,
  code: _cyan,
  codeMuted: _base1,
  link: _blue,
  wikilink: _blue,
  image: _violet,
  task: _green,
  quote: _base01,
  math: _magenta,
  tag: _orange,
);
