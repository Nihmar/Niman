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

  /// The Markdown roles, in the order [SyntaxColors] names them: the
  /// note's own, then [taskListRoles].
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
    'template',
    ...taskListRoles,
  ];

  /// The roles a task list (todo.txt, done.txt) is painted with, the last
  /// of [markdownRoles].
  static const List<String> taskListRoles = [
    'todoPriority',
    'todoDate',
    'todoProject',
    'todoContext',
    'todoKeyValue',
    'todoDone',
  ];

  /// The role each of [taskListRoles] is read from when a theme does not
  /// name it.
  ///
  /// The task-list roles came after the first themes were stored and
  /// exported, and a theme from before them is whole in every way it was
  /// when it was made: refusing it would take away a theme the user
  /// already has. So a missing task-list role takes the color the editor
  /// painted it with before it was a role of its own — the theme looks
  /// exactly as it did — while any other missing role still refuses the
  /// theme, since nothing but a hole explains it.
  static const Map<String, String> taskListRoleSources = {
    'todoPriority': 'task',
    'todoDate': 'dim',
    'todoProject': 'wikilink',
    'todoContext': 'link',
    'todoKeyValue': 'code',
    'todoDone': 'dim',
  };

  /// Every role that came after the first themes were stored and exported,
  /// with the role a theme that does not name it reads it from: the
  /// task-list roles ([taskListRoleSources]), and `template`.
  ///
  /// A template command was drawn as plain text before it had a colour of
  /// its own. Plain text would hide the very thing the role is for, so a
  /// theme from before reads it from its code colour: the command stands
  /// apart, in a colour the theme already chose.
  static const Map<String, String> laterRoleSources = {
    ...taskListRoleSources,
    'template': 'code',
  };

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
    'template': colorToHex(syntax.template),
    'todoPriority': colorToHex(syntax.todoPriority),
    'todoDate': colorToHex(syntax.todoDate),
    'todoProject': colorToHex(syntax.todoProject),
    'todoContext': colorToHex(syntax.todoContext),
    'todoKeyValue': colorToHex(syntax.todoKeyValue),
    'todoDone': colorToHex(syntax.todoDone),
  };

  /// The colors [json] describes, or null when a role is missing or is
  /// not a color. Every role has to be there: a theme with a hole in it
  /// is a theme that would wear a color from somewhere else.
  ///
  /// The one exception is a theme older than a role: one that leaves a
  /// later role out (rather than giving something that is not a color)
  /// reads it from [laterRoleSources].
  static ThemeColors? fromJson(Map<String, Object?> json) {
    final colors = <String, Color>{};
    for (final role in roleNames) {
      final value = json[role];
      if (value == null && laterRoleSources.containsKey(role)) continue;
      final color = value is String ? colorFromHex(value) : null;
      if (color == null) return null;
      colors[role] = color;
    }
    for (final MapEntry(key: role, value: source) in laterRoleSources.entries) {
      colors.putIfAbsent(role, () => colors[source]!);
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
        template: colors['template']!,
        todoPriority: colors['todoPriority']!,
        todoDate: colors['todoDate']!,
        todoProject: colors['todoProject']!,
        todoContext: colors['todoContext']!,
        todoKeyValue: colors['todoKeyValue']!,
        todoDone: colors['todoDone']!,
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
