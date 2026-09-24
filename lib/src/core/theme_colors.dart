// One theme's colors at one brightness (issue #269).
//
// Chrome roles and Markdown roles, together, because they are chosen
// together: a custom theme fills in both at day and at night, and a file
// carries both. [roleNames] is the order everything that reads or writes
// a theme walks them in — the stored columns, an exported file and the
// editor's rows all follow it, so the roles never disagree.

import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';

/// The colors of a theme at one brightness.
@immutable
final class ThemeColors {
  /// Creates the pair.
  const new({required this.tokens, required this.syntax});

  /// The chrome roles.
  final PaletteTokens tokens;

  /// The Markdown roles.
  final SyntaxColors syntax;

  /// The chrome roles, in the order [PaletteTokens] names them.
  static const List<String> chromeRoles = [
    'background',
    'backdrop',
    'surface',
    'surfaceHigh',
    'text',
    'muted',
    'outline',
    'accent',
    'onAccent',
    'error',
  ];

  /// The Markdown roles, in the order [SyntaxColors] names them.
  static const List<String> markdownRoles = [
    'dim',
    'code',
    'codeMuted',
    'link',
    'wikilink',
    'image',
    'task',
    'quote',
    'math',
    'tag',
  ];

  /// Every role, chrome first, in the order a theme file lists them.
  static const List<String> roleNames = [...chromeRoles, ...markdownRoles];

  /// The color [role] holds, or null when this build does not know the
  /// role.
  Color? colorOf(String role) {
    final hex = toJson()[role];
    return hex == null ? null : colorFromHex(hex);
  }

  /// These colors with [role] set to [color] (issue #269).
  ///
  /// Through the role map, rounding the color to `#RRGGBB` on the way: a
  /// color the editor cannot store is a color the preview must not show,
  /// or the theme would change the moment it is saved.
  ThemeColors withRole(String role, Color color) {
    final json = toJson()..[role] = colorToHex(color);
    return ThemeColors.fromJson(json)!;
  }

  /// The colors as role → `#RRGGBB`, ready to be written out.
  Map<String, String> toJson() => {
    'background': colorToHex(tokens.background),
    'backdrop': colorToHex(tokens.backdrop),
    'surface': colorToHex(tokens.surface),
    'surfaceHigh': colorToHex(tokens.surfaceHigh),
    'text': colorToHex(tokens.text),
    'muted': colorToHex(tokens.muted),
    'outline': colorToHex(tokens.outline),
    'accent': colorToHex(tokens.accent),
    'onAccent': colorToHex(tokens.onAccent),
    'error': colorToHex(tokens.error),
    'dim': colorToHex(syntax.dim),
    'code': colorToHex(syntax.code),
    'codeMuted': colorToHex(syntax.codeMuted),
    'link': colorToHex(syntax.link),
    'wikilink': colorToHex(syntax.wikilink),
    'image': colorToHex(syntax.image),
    'task': colorToHex(syntax.task),
    'quote': colorToHex(syntax.quote),
    'math': colorToHex(syntax.math),
    'tag': colorToHex(syntax.tag),
  };

  /// The colors [json] describes, or null when a role is missing or is
  /// not a color. Every role has to be there: a theme with a hole in it
  /// is a theme that would wear a color from somewhere else.
  static ThemeColors? fromJson(Map<String, Object?> json) {
    final colors = <String, Color>{};
    for (final role in roleNames) {
      final value = json[role];
      final color = value is String ? colorFromHex(value) : null;
      if (color == null) return null;
      colors[role] = color;
    }
    return ThemeColors(
      tokens: PaletteTokens(
        background: colors['background']!,
        backdrop: colors['backdrop']!,
        surface: colors['surface']!,
        surfaceHigh: colors['surfaceHigh']!,
        text: colors['text']!,
        muted: colors['muted']!,
        outline: colors['outline']!,
        accent: colors['accent']!,
        onAccent: colors['onAccent']!,
        error: colors['error']!,
      ),
      syntax: SyntaxColors(
        dim: colors['dim']!,
        code: colors['code']!,
        codeMuted: colors['codeMuted']!,
        link: colors['link']!,
        wikilink: colors['wikilink']!,
        image: colors['image']!,
        task: colors['task']!,
        quote: colors['quote']!,
        math: colors['math']!,
        tag: colors['tag']!,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeColors && other.tokens == tokens && other.syntax == syntax;

  @override
  int get hashCode => Object.hash(tokens, syntax);
}

/// [color] as `#RRGGBB`, the form a theme file writes it in.
String colorToHex(Color color) {
  final rgb = (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return '#${rgb.toUpperCase()}';
}

/// The color `#RRGGBB` is, or null when [value] is not one.
///
/// A theme file names opaque colors only, so a second alpha channel would
/// be a second way to say the same thing; anything else reads as no color
/// at all rather than as a guess.
Color? colorFromHex(String value) {
  final match = _hexColor.firstMatch(value.trim());
  if (match == null) return null;
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}

final RegExp _hexColor = RegExp(r'^#([0-9a-fA-F]{6})$');
