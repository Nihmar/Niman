// The color roles every palette fills in (T-M6-05).
//
// A palette is a list of colors and nothing else: [PaletteTokens] says
// what the app needs, [SyntaxColors] says the same for Markdown, and
// [schemeFromTokens] turns the first into the Material scheme the whole
// interface reads. Adding a palette is adding a mapping — no widget knows
// which one it is wearing.

import 'package:flutter/material.dart';

/// The chrome roles: the surfaces the app is built out of, and the colors
/// written on them.
///
/// Four grounds rather than Material's ten: a palette author picks the
/// ground, the step below it and the two above, and [schemeFromTokens]
/// spreads those over the container ramp. Asking for ten would be asking
/// for colors the published palettes do not define.
@immutable
final class PaletteTokens {
  /// Creates a mapping. Every role is required: a palette that leaves one
  /// out is a palette with a hole in it, and the hole would be filled by
  /// a color from somewhere else.
  const new({
    required this.background,
    required this.backdrop,
    required this.surface,
    required this.surfaceHigh,
    required this.text,
    required this.muted,
    required this.outline,
    required this.accent,
    required this.onAccent,
    required this.error,
  });

  /// The app's ground: the tree, the editor, the page behind everything.
  final Color background;

  /// One step below the ground, for what sits under it (the scaffold
  /// behind a sheet, the lowest container).
  final Color backdrop;

  /// One step above the ground: cards, dialogs, the raised rows.
  final Color surface;

  /// Two steps above: menus, the bar that lifts when a list scrolls.
  final Color surfaceHigh;

  /// The color of ordinary text.
  final Color text;

  /// Secondary text: subtitles, the value on the right of a settings row.
  final Color muted;

  /// Dividers and borders.
  final Color outline;

  /// The one color that carries the interface: buttons, the caret, the
  /// selected row, the wikilinks.
  final Color accent;

  /// What is written on [accent].
  final Color onAccent;

  /// Destructive actions and failures.
  final Color error;
}

/// The Markdown roles: what the source editor paints, and what the
/// preview echoes.
///
/// A [ThemeExtension] rather than a global: unlike the text sizes, these
/// are read from widgets that all sit under the app's `Theme`, and going
/// through it means a palette change repaints them with the rest of the
/// interface instead of on its own schedule.
@immutable
final class SyntaxColors extends ThemeExtension<SyntaxColors> {
  /// Creates the Markdown colors of one palette.
  const new({
    required this.dim,
    required this.code,
    required this.codeMuted,
    required this.link,
    required this.wikilink,
    required this.image,
    required this.task,
    required this.quote,
    required this.math,
    required this.tag,
  });

  /// Markers the reader looks past: `#`, list bullets, rules,
  /// frontmatter fences.
  final Color dim;

  /// Inline code and the text inside a fence.
  final Color code;

  /// The fence itself and its language tag.
  final Color codeMuted;

  /// Markdown links.
  final Color link;

  /// Wikilinks, which are the app's own kind of link and take the
  /// palette's accent.
  final Color wikilink;

  /// Images.
  final Color image;

  /// Task boxes.
  final Color task;

  /// Blockquotes.
  final Color quote;

  /// Inline and block math.
  final Color math;

  /// Inline `#tags`.
  final Color tag;

  /// The Markdown colors at [context], falling back to the shipped ones
  /// for a theme built without them (a bare `MaterialApp` in a test).
  static SyntaxColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<SyntaxColors>() ??
        (theme.brightness == Brightness.dark ? fallbackDark : fallbackLight);
  }

  /// The light Markdown colors, for a theme that carries none.
  static const SyntaxColors fallbackLight = SyntaxColors(
    dim: Color(0xFF7A7A7A),
    code: Color(0xFF0E7C7B),
    codeMuted: Color(0xFF5C6B73),
    link: Color(0xFF1A5FB4),
    wikilink: Color(0xFF1A5FB4),
    image: Color(0xFF7B1FA2),
    task: Color(0xFF2E7D32),
    quote: Color(0xFF6B7280),
    math: Color(0xFFAD1457),
    tag: Color(0xFF00838F),
  );

  /// The dark Markdown colors, for a theme that carries none.
  static const SyntaxColors fallbackDark = SyntaxColors(
    dim: Color(0xFF9E9E9E),
    code: Color(0xFF56B6C2),
    codeMuted: Color(0xFF7A828E),
    link: Color(0xFF61AFEF),
    wikilink: Color(0xFF61AFEF),
    image: Color(0xFFD19A66),
    task: Color(0xFF98C379),
    quote: Color(0xFF80868E),
    math: Color(0xFFC678DD),
    tag: Color(0xFF4EC9B0),
  );

  @override
  SyntaxColors copyWith({
    Color? dim,
    Color? code,
    Color? codeMuted,
    Color? link,
    Color? wikilink,
    Color? image,
    Color? task,
    Color? quote,
    Color? math,
    Color? tag,
  }) {
    return SyntaxColors(
      dim: dim ?? this.dim,
      code: code ?? this.code,
      codeMuted: codeMuted ?? this.codeMuted,
      link: link ?? this.link,
      wikilink: wikilink ?? this.wikilink,
      image: image ?? this.image,
      task: task ?? this.task,
      quote: quote ?? this.quote,
      math: math ?? this.math,
      tag: tag ?? this.tag,
    );
  }

  @override
  SyntaxColors lerp(ThemeExtension<SyntaxColors>? other, double t) {
    if (other is! SyntaxColors) return this;
    return SyntaxColors(
      dim: Color.lerp(dim, other.dim, t)!,
      code: Color.lerp(code, other.code, t)!,
      codeMuted: Color.lerp(codeMuted, other.codeMuted, t)!,
      link: Color.lerp(link, other.link, t)!,
      wikilink: Color.lerp(wikilink, other.wikilink, t)!,
      image: Color.lerp(image, other.image, t)!,
      task: Color.lerp(task, other.task, t)!,
      quote: Color.lerp(quote, other.quote, t)!,
      math: Color.lerp(math, other.math, t)!,
      tag: Color.lerp(tag, other.tag, t)!,
    );
  }

  // Compared, not just carried: the editor caches one styled span per
  // line and has to know when the colors under it changed.
  @override
  bool operator ==(Object other) =>
      other is SyntaxColors &&
      other.dim == dim &&
      other.code == code &&
      other.codeMuted == codeMuted &&
      other.link == link &&
      other.wikilink == wikilink &&
      other.image == image &&
      other.task == task &&
      other.quote == quote &&
      other.math == math &&
      other.tag == tag;

  @override
  int get hashCode => Object.hash(
    dim,
    code,
    codeMuted,
    link,
    wikilink,
    image,
    task,
    quote,
    math,
    tag,
  );
}

/// The Material scheme a palette's [tokens] describe, at [brightness].
///
/// Seeded from the accent so the roles no palette names — the containers
/// Material derives, the inverse pair, the scrim — stay in the family,
/// then overwritten wherever the palette has an opinion. Every role the
/// app actually paints with is one of the overwritten ones.
ColorScheme schemeFromTokens(PaletteTokens tokens, Brightness brightness) {
  final seeded = ColorScheme.fromSeed(
    seedColor: tokens.accent,
    brightness: brightness,
  );
  return seeded.copyWith(
    primary: tokens.accent,
    onPrimary: tokens.onAccent,
    primaryContainer: tokens.surfaceHigh,
    onPrimaryContainer: tokens.text,
    // One accent, used everywhere it is asked for: a palette names the
    // color that carries it, not three of them, and inventing the other
    // two from the seed puts colors on screen the palette never chose.
    secondary: tokens.accent,
    onSecondary: tokens.onAccent,
    secondaryContainer: tokens.surfaceHigh,
    onSecondaryContainer: tokens.text,
    tertiary: tokens.accent,
    onTertiary: tokens.onAccent,
    tertiaryContainer: tokens.surfaceHigh,
    onTertiaryContainer: tokens.text,
    surface: tokens.background,
    onSurface: tokens.text,
    surfaceDim: tokens.backdrop,
    surfaceBright: tokens.surfaceHigh,
    surfaceContainerLowest: tokens.backdrop,
    surfaceContainerLow: tokens.background,
    surfaceContainer: tokens.surface,
    surfaceContainerHigh: tokens.surfaceHigh,
    surfaceContainerHighest: tokens.surfaceHigh,
    surfaceTint: tokens.accent,
    onSurfaceVariant: tokens.muted,
    outline: tokens.outline,
    outlineVariant: tokens.surfaceHigh,
    error: tokens.error,
    onError: tokens.onAccent,
    errorContainer: tokens.surfaceHigh,
    onErrorContainer: tokens.error,
    inverseSurface: tokens.text,
    onInverseSurface: tokens.background,
    inversePrimary: tokens.accent,
  );
}
