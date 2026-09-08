import 'package:copist/src/editor/highlighting.dart';
import 'package:flutter/widgets.dart';

/// Display styles for the source editor's highlighting (M2a E7-influence,
/// now over re_editor's per-line `spanBuilder`).
///
/// [styleFor] maps a [TokenKind] to a [TextStyle] *override* for the line
/// span; [TokenKind.plain] maps to null (the base editor style shows). The
/// overrides change only color / weight / decoration / font-style — never
/// font size or line height — so a line keeps the editor's constant
/// metrics. [light] and [dark] are fixed palettes; the app brightness picks
/// one.
enum HighlightPalette {
  /// The light-theme palette.
  light,

  /// The dark-theme palette.
  dark;

  /// The style of the *heading text* — the region after a `#…` marker,
  /// which the tokenizer leaves unmarked: bold, at the base row size.
  TextStyle? get headingStyle => const TextStyle(fontWeight: FontWeight.bold);

  /// The [TextStyle] override for [kind] in this palette (null = base).
  ///
  /// Wikilinks (T-UI-09) track the theme: [accent] is the current
  /// ColorScheme's primary, underlined per mockup, in both palettes.
  TextStyle? styleFor(TokenKind kind, {required Color accent}) {
    if (kind == TokenKind.wikilink) {
      return TextStyle(
        color: accent,
        decoration: TextDecoration.underline,
      );
    }
    return (this == HighlightPalette.dark ? _darkStyles : _lightStyles)[kind];
  }

  // Light: the M2a row-painter colors, kept as-is.
  static const Map<TokenKind, TextStyle?> _lightStyles = {
    TokenKind.plain: null,
    TokenKind.headingMarker: TextStyle(color: _dim),
    TokenKind.bold: TextStyle(fontWeight: FontWeight.bold),
    TokenKind.italic: TextStyle(fontStyle: FontStyle.italic),
    TokenKind.strike: TextStyle(decoration: TextDecoration.lineThrough),
    TokenKind.codeInline: TextStyle(color: _code),
    TokenKind.codeFence: TextStyle(color: _codeMuted),
    TokenKind.codeLanguage: TextStyle(
      color: _codeMuted,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.link: TextStyle(
      color: _link,
      decoration: TextDecoration.underline,
    ),
    TokenKind.image: TextStyle(color: _image),
    TokenKind.listMarker: TextStyle(color: _dim),
    TokenKind.taskBox: TextStyle(color: _task),
    TokenKind.blockquote: TextStyle(
      color: _quote,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.horizontalRule: TextStyle(color: _dim),
    TokenKind.mathInline: TextStyle(color: _math),
    TokenKind.mathBlock: TextStyle(color: _math, fontStyle: FontStyle.italic),
    TokenKind.tag: TextStyle(color: _tag),
    TokenKind.frontmatter: TextStyle(
      color: _dim,
      fontStyle: FontStyle.italic,
    ),
  };

  // Dark: same structure, brighter hues on dark backgrounds. The two math
  // colors match the atom-one themes' `formula` scope (what the previous
  // codeTheme mode painted).
  static const Map<TokenKind, TextStyle?> _darkStyles = {
    TokenKind.plain: null,
    TokenKind.headingMarker: TextStyle(color: _dimDark),
    TokenKind.bold: TextStyle(fontWeight: FontWeight.w600),
    TokenKind.italic: TextStyle(fontStyle: FontStyle.italic),
    TokenKind.strike: TextStyle(decoration: TextDecoration.lineThrough),
    TokenKind.codeInline: TextStyle(color: _codeDark),
    TokenKind.codeFence: TextStyle(color: _codeMutedDark),
    TokenKind.codeLanguage: TextStyle(
      color: _codeMutedDark,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.link: TextStyle(
      color: _linkDark,
      decoration: TextDecoration.underline,
    ),
    TokenKind.image: TextStyle(color: _imageDark),
    TokenKind.listMarker: TextStyle(color: _dimDark),
    TokenKind.taskBox: TextStyle(color: _taskDark),
    TokenKind.blockquote: TextStyle(
      color: _quoteDark,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.horizontalRule: TextStyle(color: _dimDark),
    TokenKind.mathInline: TextStyle(color: _mathDark),
    TokenKind.mathBlock: TextStyle(
      color: _mathDark,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.tag: TextStyle(color: _tagDark),
    TokenKind.frontmatter: TextStyle(
      color: _dimDark,
      fontStyle: FontStyle.italic,
    ),
  };

  // Light colors.
  static const Color _dim = Color(0xFF7A7A7A);
  static const Color _code = Color(0xFF0E7C7B);
  static const Color _codeMuted = Color(0xFF5C6B73);
  static const Color _link = Color(0xFF1A5FB4);
  static const Color _image = Color(0xFF7B1FA2);
  static const Color _task = Color(0xFF2E7D32);
  static const Color _quote = Color(0xFF6B7280);
  static const Color _math = Color(0xFFAD1457);
  static const Color _tag = Color(0xFF00838F);

  // Dark colors.
  static const Color _dimDark = Color(0xFF9E9E9E);
  static const Color _codeDark = Color(0xFF56B6C2);
  static const Color _codeMutedDark = Color(0xFF7A828E);
  static const Color _linkDark = Color(0xFF61AFEF);
  static const Color _imageDark = Color(0xFFD19A66);
  static const Color _taskDark = Color(0xFF98C379);
  static const Color _quoteDark = Color(0xFF80868E);
  static const Color _mathDark = Color(0xFFC678DD);
  static const Color _tagDark = Color(0xFF4EC9B0);
}
