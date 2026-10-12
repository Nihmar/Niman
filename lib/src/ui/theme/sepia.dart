// Sepia — paper by day, a dimmed brown by night.
//
// The reading palette the app did not ship: a warm paper ground with
// brown-black ink, and the same family at night, the paper darkened to a
// brown ground with cream ink. The accent is one muted blue — the one
// color a page of ink wants, and the one the links wear — and the
// Markdown colors are the inks that go on paper: moss and teal for code
// and tags, sienna for pictures and a task's priority, a quiet grey-brown
// for what is finished.

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';

/// Sepia's chrome at [brightness].
PaletteTokens sepiaTokens(Brightness brightness) =>
    brightness == Brightness.dark ? _dark : _light;

/// Sepia's Markdown colors at [brightness].
SyntaxColors sepiaSyntax(Brightness brightness) =>
    brightness == Brightness.dark ? _darkSyntax : _lightSyntax;

// Day — the paper. The backdrop is a step deeper (the stack of sheets
// under the page), the raised surfaces a step toward the ink.
const PaletteTokens _light = PaletteTokens(
  background: Color(0xFFF4ECD8), // the page
  backdrop: Color(0xFFE9DCC0), // the sheets below it
  surface: Color(0xFFEADFC6),
  surfaceHigh: Color(0xFFDFD1B3),
  text: Color(0xFF433422), // brown-black ink
  muted: Color(0xFF7A6A52),
  outline: Color(0xFFC9B896),
  accent: Color(0xFF4A5F87), // muted blue
  onAccent: Color(0xFFF4ECD8),
  error: Color(0xFFA6402D), // brick
);

const SyntaxColors _lightSyntax = SyntaxColors(
  dim: Color(0xFFA6977F),
  code: Color(0xFF5F7A46), // moss
  codeMuted: Color(0xFFA6977F),
  link: Color(0xFF3F6398),
  wikilink: Color(0xFF4A5F87),
  image: Color(0xFFA0522D), // sienna
  task: Color(0xFF5F7A46),
  quote: Color(0xFF7A6A52),
  math: Color(0xFF7A5C8A),
  tag: Color(0xFF4E7A6E), // teal
  template: Color(0xFF6B6A2E), // olive
  todoPriority: Color(0xFFA0522D),
  todoDate: Color(0xFF7A6A52),
  todoProject: Color(0xFF7A5C8A),
  todoContext: Color(0xFF3F6398),
  todoKeyValue: Color(0xFF5F7A46),
  todoDone: Color(0xFFA6977F), // quieter than the ink above
  calendarDate: Color(0xFF7A6A52),
  calendarHead: Color(0xFFA6977F),
  calendarTime: Color(0xFFA0522D),
  calendarAside: Color(0xFFA6977F),
  calendarMismatch: Color(0xFFA6402D),
);

// Night — the same paper in a dim room: the ground is the page's brown,
// the ink the page's cream turned over.
const PaletteTokens _dark = PaletteTokens(
  background: Color(0xFF2A2620),
  backdrop: Color(0xFF221E19),
  surface: Color(0xFF352F27),
  surfaceHigh: Color(0xFF40382E),
  text: Color(0xFFE8DCC8), // cream ink
  muted: Color(0xFFA99A83),
  outline: Color(0xFF554B3D),
  accent: Color(0xFF8FA8D0), // the blue, lit for a dark ground
  onAccent: Color(0xFF2A2620),
  error: Color(0xFFD98A7A),
);

const SyntaxColors _darkSyntax = SyntaxColors(
  dim: Color(0xFF6E6250),
  code: Color(0xFF9BB37F),
  codeMuted: Color(0xFF6E6250),
  link: Color(0xFF9DB6DC),
  wikilink: Color(0xFF8FA8D0),
  image: Color(0xFFD99A6C),
  task: Color(0xFF9BB37F),
  quote: Color(0xFFA99A83),
  math: Color(0xFFC6A2D6),
  tag: Color(0xFF86BFAE),
  template: Color(0xFFB8B26A),
  todoPriority: Color(0xFFD99A6C),
  todoDate: Color(0xFFA99A83),
  todoProject: Color(0xFFC6A2D6),
  todoContext: Color(0xFF9DB6DC),
  todoKeyValue: Color(0xFF9BB37F),
  todoDone: Color(0xFF6E6250),
  calendarDate: Color(0xFFA99A83),
  calendarHead: Color(0xFF6E6250),
  calendarTime: Color(0xFFD99A6C),
  calendarAside: Color(0xFF6E6250),
  calendarMismatch: Color(0xFFD98A7A),
);
