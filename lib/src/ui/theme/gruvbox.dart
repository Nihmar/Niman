// Gruvbox — the medium light and dark variants.
//
// Gruvbox is a warm ramp with two sets of accents: the bright ones read on
// the dark ground, the faded ones on the light. Yellow carries the
// interface, which is the color the theme is known by.

import 'package:copist/src/ui/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Gruvbox's chrome at [brightness].
PaletteTokens gruvboxTokens(Brightness brightness) =>
    brightness == Brightness.dark ? _dark : _light;

/// Gruvbox's Markdown colors at [brightness].
SyntaxColors gruvboxSyntax(Brightness brightness) =>
    brightness == Brightness.dark ? _darkSyntax : _lightSyntax;

// Dark (medium): bg0 as the ground, bg0_hard behind it.
const PaletteTokens _dark = PaletteTokens(
  background: Color(0xFF282828), // bg0
  backdrop: Color(0xFF1D2021), // bg0_h
  surface: Color(0xFF3C3836), // bg1
  surfaceHigh: Color(0xFF504945), // bg2
  text: Color(0xFFEBDBB2), // fg1
  muted: Color(0xFFA89984), // fg4
  outline: Color(0xFF665C54), // bg3
  accent: Color(0xFFFABD2F), // bright yellow
  onAccent: Color(0xFF282828), // bg0
  error: Color(0xFFFB4934), // bright red
);

const SyntaxColors _darkSyntax = SyntaxColors(
  dim: Color(0xFF928374), // gray
  code: Color(0xFF8EC07C), // bright aqua
  codeMuted: Color(0xFF928374), // gray
  link: Color(0xFF83A598), // bright blue
  wikilink: Color(0xFFFABD2F), // bright yellow
  image: Color(0xFFFE8019), // bright orange
  task: Color(0xFFB8BB26), // bright green
  quote: Color(0xFFA89984), // fg4
  math: Color(0xFFD3869B), // bright purple
  tag: Color(0xFF689D6A), // neutral aqua
);

// Light (medium): bg0 as the ground, bg0_hard as the lighter step behind.
const PaletteTokens _light = PaletteTokens(
  background: Color(0xFFFBF1C7), // bg0
  backdrop: Color(0xFFF9F5D7), // bg0_h
  surface: Color(0xFFEBDBB2), // bg1
  surfaceHigh: Color(0xFFD5C4A1), // bg2
  text: Color(0xFF3C3836), // fg1
  muted: Color(0xFF7C6F64), // fg4
  outline: Color(0xFFBDAE93), // bg3
  accent: Color(0xFFB57614), // faded yellow
  onAccent: Color(0xFFFBF1C7), // bg0
  error: Color(0xFF9D0006), // faded red
);

const SyntaxColors _lightSyntax = SyntaxColors(
  dim: Color(0xFF928374), // gray
  code: Color(0xFF427B58), // faded aqua
  codeMuted: Color(0xFF928374), // gray
  link: Color(0xFF076678), // faded blue
  wikilink: Color(0xFFB57614), // faded yellow
  image: Color(0xFFAF3A03), // faded orange
  task: Color(0xFF79740E), // faded green
  quote: Color(0xFF7C6F64), // fg4
  math: Color(0xFF8F3F71), // faded purple
  tag: Color(0xFF689D6A), // neutral aqua
);
