// Catppuccin — Latte by day, Mocha by night.
//
// The published palette, mapped onto the app's roles and nothing more:
// every value below is one of Catppuccin's own named colors, so the
// mapping can be read against the style guide rather than against a color
// picker. Mauve is the accent the project itself defaults to.

import 'package:flutter/material.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// Catppuccin's chrome at [brightness].
PaletteTokens catppuccinTokens(Brightness brightness) =>
    brightness == Brightness.dark ? _mocha : _latte;

/// Catppuccin's Markdown colors at [brightness].
SyntaxColors catppuccinSyntax(Brightness brightness) =>
    brightness == Brightness.dark ? _mochaSyntax : _latteSyntax;

// Mocha (night).
const PaletteTokens _mocha = PaletteTokens(
  background: Color(0xFF1E1E2E), // base
  backdrop: Color(0xFF181825), // mantle
  surface: Color(0xFF313244), // surface0
  surfaceHigh: Color(0xFF45475A), // surface1
  text: Color(0xFFCDD6F4), // text
  muted: Color(0xFFA6ADC8), // subtext0
  outline: Color(0xFF6C7086), // overlay0
  accent: Color(0xFFCBA6F7), // mauve
  onAccent: Color(0xFF1E1E2E), // base
  error: Color(0xFFF38BA8), // red
);

const SyntaxColors _mochaSyntax = SyntaxColors(
  dim: Color(0xFF7F849C), // overlay1
  code: Color(0xFF94E2D5), // teal
  codeMuted: Color(0xFF7F849C), // overlay1
  link: Color(0xFF89B4FA), // blue
  wikilink: Color(0xFFCBA6F7), // mauve
  image: Color(0xFFFAB387), // peach
  task: Color(0xFFA6E3A1), // green
  quote: Color(0xFFA6ADC8), // subtext0
  math: Color(0xFFF5C2E7), // pink
  tag: Color(0xFF74C7EC), // sapphire
);

// Latte (day). Latte has nothing lighter than base, so the ramp runs the
// other way: the ground is the lightest color there is and everything
// raised off it is a shade darker, which is how a light Material theme
// reads anyway.
const PaletteTokens _latte = PaletteTokens(
  background: Color(0xFFEFF1F5), // base
  backdrop: Color(0xFFE6E9EF), // mantle
  surface: Color(0xFFDCE0E8), // crust
  surfaceHigh: Color(0xFFCCD0DA), // surface0
  text: Color(0xFF4C4F69), // text
  muted: Color(0xFF6C6F85), // subtext0
  outline: Color(0xFF9CA0B0), // overlay0
  accent: Color(0xFF8839EF), // mauve
  onAccent: Color(0xFFEFF1F5), // base
  error: Color(0xFFD20F39), // red
);

const SyntaxColors _latteSyntax = SyntaxColors(
  dim: Color(0xFF8C8FA1), // overlay1
  code: Color(0xFF179299), // teal
  codeMuted: Color(0xFF8C8FA1), // overlay1
  link: Color(0xFF1E66F5), // blue
  wikilink: Color(0xFF8839EF), // mauve
  image: Color(0xFFFE640B), // peach
  task: Color(0xFF40A02B), // green
  quote: Color(0xFF6C6F85), // subtext0
  math: Color(0xFFEA76CB), // pink
  tag: Color(0xFF209FB5), // sapphire
);
