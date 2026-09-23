/// Display styles for the source editor's highlighting (M2a E7-influence,
/// now over re_editor's per-line `spanBuilder`).
///
/// [markdownTokenStyle] maps a [TokenKind] to a [TextStyle] *override* for
/// the line span; [TokenKind.plain] maps to null (the base editor style
/// shows). The overrides change only color / weight / decoration /
/// font-style — never font size or line height — so a line keeps the
/// editor's constant metrics.
///
/// The colors come from the palette (T-M6-05), not from here: what this
/// file decides is which role a token takes and how it is drawn. That is
/// what makes a palette a list of colors and nothing else.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// The style of the *heading text* — the region after a `#…` marker,
/// which the tokenizer leaves unmarked: bold, at the base row size.
const TextStyle markdownHeadingStyle = TextStyle(fontWeight: FontWeight.bold);

/// The style of [token] with the constructs around it ([Token.outer]): each
/// one's override laid over the one outside it, the token's own last, so
/// the innermost decides a colour — and the lines are added up rather than
/// replaced, since `<u>~~x~~</u>` is underlined *and* struck through.
TextStyle? nestedTokenStyle(
  Token token,
  SyntaxColors syntax, {
  required bool dark,
}) {
  final own = markdownTokenStyle(token.kind, syntax, dark: dark);
  if (token.outer.isEmpty) return own;
  TextStyle? style;
  for (final kind in <TokenKind>[...token.outer, token.kind]) {
    final next = markdownTokenStyle(kind, syntax, dark: dark);
    if (next == null) continue;
    if (style == null) {
      style = next;
      continue;
    }
    final lines = <TextDecoration>[
      if (style.decoration != null) style.decoration!,
      if (next.decoration != null) next.decoration!,
    ];
    final features = <FontFeature>[
      ...?style.fontFeatures,
      ...?next.fontFeatures,
    ];
    style = style
        .merge(next)
        .copyWith(
          decoration: lines.isEmpty ? null : TextDecoration.combine(lines),
          fontFeatures: features.isEmpty ? null : features,
        );
  }
  return style;
}

/// The [TextStyle] override for [kind] in [syntax] (null = base style).
///
/// [dark] decides the weight of bold text and nothing else: a heavy face
/// blooms on a dark ground, so night stops one step short of it.
TextStyle? markdownTokenStyle(
  TokenKind kind,
  SyntaxColors syntax, {
  required bool dark,
}) {
  return switch (kind) {
    TokenKind.plain => null,
    TokenKind.headingMarker => TextStyle(color: syntax.dim),
    TokenKind.bold => TextStyle(
      fontWeight: dark ? FontWeight.w600 : FontWeight.bold,
    ),
    TokenKind.italic => const TextStyle(fontStyle: FontStyle.italic),
    TokenKind.strike => const TextStyle(decoration: TextDecoration.lineThrough),
    TokenKind.underline => const TextStyle(
      decoration: TextDecoration.underline,
    ),
    // Raised or lowered by the font's own glyphs where it has them; the size
    // is the line's either way, since a token never changes a line's height.
    TokenKind.superscript => const TextStyle(
      fontFeatures: <FontFeature>[FontFeature.superscripts()],
    ),
    TokenKind.subscript => const TextStyle(
      fontFeatures: <FontFeature>[FontFeature.subscripts()],
    ),
    TokenKind.codeInline => TextStyle(color: syntax.code),
    TokenKind.codeFence ||
    TokenKind.codeBlock => TextStyle(color: syntax.codeMuted),
    TokenKind.codeLanguage => TextStyle(
      color: syntax.codeMuted,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.link => TextStyle(
      color: syntax.link,
      decoration: TextDecoration.underline,
    ),
    // Wikilinks (T-UI-09) take the palette's accent, underlined per
    // mockup: they are the app's own kind of link.
    TokenKind.wikilink => TextStyle(
      color: syntax.wikilink,
      decoration: TextDecoration.underline,
    ),
    TokenKind.image => TextStyle(color: syntax.image),
    TokenKind.listMarker => TextStyle(color: syntax.dim),
    TokenKind.taskBox => TextStyle(color: syntax.task),
    TokenKind.blockquote => TextStyle(
      color: syntax.quote,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.horizontalRule => TextStyle(color: syntax.dim),
    TokenKind.mathInline => TextStyle(color: syntax.math),
    TokenKind.mathBlock => TextStyle(
      color: syntax.math,
      fontStyle: FontStyle.italic,
    ),
    TokenKind.tag => TextStyle(color: syntax.tag),
    TokenKind.frontmatter => TextStyle(
      color: syntax.dim,
      fontStyle: FontStyle.italic,
    ),
  };
}
