/// One typography and block-metrics model for the whole surface.
///
/// The three surfaces being replaced had three authorities for how a note
/// looks — `re_editor`'s code theme, Quill's `DefaultStyles`, and
/// `flutter_markdown_plus`'s `MarkdownStyleSheet` — which is why the same note
/// moved when the surface changed (`docs/dev/unified-surface.md` §8.3). This is
/// the one place that decides, and every mode reads it.
///
/// Two rules make it *uniform* rather than merely shared:
///
/// * **one metric per construct.** The list indent is the number that indents
///   a rendered list item *and* a source line at the same depth; the block
///   spacing is a property of the block, not of the widget drawing it;
/// * **the surface applies the column itself**, so the toolbar, the find bar
///   and the status row keep to it as `docs/user/editing.md` promises.
///
/// It derives from the app's [ThemeData] on purpose: a note should look like
/// the application it is read in, and the theme is where the application has
/// already decided how that looks.
library;

import 'package:flutter/material.dart';

/// The typography and block metrics a note is drawn with.
@immutable
final class MarkdownTheme {
  /// Creates a theme.
  const new({
    required this.body,
    required this.heading1,
    required this.heading2,
    required this.heading3,
    required this.heading4,
    required this.heading5,
    required this.heading6,
    required this.code,
    required this.quote,
    required this.tableCell,
    required this.tableHeader,
    required this.link,
    required this.wikilink,
    required this.tag,
    required this.marker,
    required this.rule,
    required this.codeBackground,
    required this.quoteBar,
    required this.tableBorder,
    required this.markerDim,
    required this.blockSpacing,
    required this.listIndentPerLevel,
    required this.quoteIndentPerLevel,
    required this.codePadding,
    required this.quoteBarWidth,
    required this.ruleThickness,
    required this.tableCellPadding,
    required this.lineHeight,
  });

  /// The prose style.
  final TextStyle body;

  /// The level-one heading style.
  final TextStyle heading1;

  /// The level-two heading style.
  final TextStyle heading2;

  /// The level-three heading style.
  final TextStyle heading3;

  /// The level-four heading style.
  final TextStyle heading4;

  /// The level-five heading style.
  final TextStyle heading5;

  /// The level-six heading style.
  final TextStyle heading6;

  /// The monospace style, for code.
  final TextStyle code;

  /// The style of quoted prose.
  final TextStyle quote;

  /// A table cell's style.
  final TextStyle tableCell;

  /// A table header cell's style.
  final TextStyle tableHeader;

  /// A link's style.
  final TextStyle link;

  /// A wikilink's style.
  final TextStyle wikilink;

  /// An inline tag's style.
  final TextStyle tag;

  /// A list marker or a task box.
  final TextStyle marker;

  /// The colour of a thematic break.
  final Color rule;

  /// The background of a code block.
  final Color codeBackground;

  /// The colour of a blockquote's bar.
  final Color quoteBar;

  /// The colour of a table's rules.
  final Color tableBorder;

  /// The colour of a syntax marker when `live` mode reveals one.
  final Color markerDim;

  /// How much space goes above and below a block.
  final double blockSpacing;

  /// How far one level of list indents its content.
  final double listIndentPerLevel;

  /// How far one level of blockquote indents its content.
  final double quoteIndentPerLevel;

  /// The inset inside a code block.
  final double codePadding;

  /// The width of a blockquote's bar.
  final double quoteBarWidth;

  /// The thickness of a thematic break.
  final double ruleThickness;

  /// The inset inside a table cell.
  final EdgeInsets tableCellPadding;

  /// The height of one line of prose, for the height map's estimates.
  final double lineHeight;

  /// The heading style for [level], clamped to 1..6.
  TextStyle heading(int level) => switch (level.clamp(1, 6)) {
    1 => heading1,
    2 => heading2,
    3 => heading3,
    4 => heading4,
    5 => heading5,
    _ => heading6,
  };
}

/// The note's theme for the nearest application theme.
///
/// A function rather than a factory, as `noteTextScalerOf` is: it reads
/// the context, which a constructor has no business doing.
MarkdownTheme markdownThemeOf(BuildContext context) {
  /// context, which a constructor has no business doing.
  final theme = Theme.of(context);
  final colors = theme.colorScheme;
  final text = theme.textTheme;
  final body = (text.bodyMedium ?? const TextStyle()).copyWith(
    height: 1.5,
    color: colors.onSurface,
  );
  final mono = body.copyWith(
    fontFamily: 'monospace',
    fontFamilyFallback: const <String>['DejaVu Sans Mono', 'Courier New'],
  );

  TextStyle heading(double size, FontWeight weight) =>
      body.copyWith(fontSize: size, fontWeight: weight, height: 1.3);

  return MarkdownTheme(
    body: body,
    heading1: heading(body.fontSize! * 1.8, FontWeight.w700),
    heading2: heading(body.fontSize! * 1.5, FontWeight.w700),
    heading3: heading(body.fontSize! * 1.3, FontWeight.w600),
    heading4: heading(body.fontSize! * 1.15, FontWeight.w600),
    heading5: heading(body.fontSize!, FontWeight.w600),
    heading6: heading(body.fontSize! * 0.95, FontWeight.w600),
    code: mono,
    quote: body.copyWith(color: colors.onSurfaceVariant),
    tableCell: body.copyWith(height: 1.3),
    tableHeader: body.copyWith(height: 1.3, fontWeight: FontWeight.w600),
    link: body.copyWith(color: colors.primary),
    wikilink: body.copyWith(
      color: colors.primary,
      decoration: TextDecoration.underline,
    ),
    tag: body.copyWith(color: colors.tertiary),
    marker: body.copyWith(color: colors.onSurfaceVariant),
    rule: colors.outlineVariant,
    codeBackground: colors.surfaceContainerHighest,
    quoteBar: colors.outlineVariant,
    tableBorder: colors.outlineVariant,
    markerDim: colors.outline,
    blockSpacing: body.fontSize! * 0.75,
    listIndentPerLevel: body.fontSize! * 1.6,
    quoteIndentPerLevel: body.fontSize! * 0.9,
    codePadding: body.fontSize! * 0.6,
    quoteBarWidth: 3,
    ruleThickness: 1,
    tableCellPadding: EdgeInsets.symmetric(
      horizontal: body.fontSize! * 0.5,
      vertical: body.fontSize! * 0.3,
    ),
    lineHeight: body.fontSize! * 1.5,
  );
}
