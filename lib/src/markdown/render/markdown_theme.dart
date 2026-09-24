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
import 'package:niman/src/markdown/render/code_themes.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';

/// How far an ordered item's number ends before the item's text, in the
/// prose's size: the read view and `live` both set it there, and it grows
/// with the note's text.
const double numberGapEm = 0.3;

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
    required this.codeHighlight,
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
    this.highlight = markHighlightLight,
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
  /// The colour scheme fenced code is tokenised with (`highlight`'s own theme
  /// maps): the read view colours a block by its fence's language, which is a
  /// phase 2 exit criterion and something the preview never did — its
  /// `syntaxHighlighter` was never wired (only a test passed one).
  final Map<String, TextStyle> codeHighlight;

  /// The filled box a code block is drawn in.
  final Color codeBackground;

  /// The colour of a blockquote's bar.
  final Color quoteBar;

  /// The colour of a table's rules.
  final Color tableBorder;

  /// The colour of a syntax marker when `live` mode reveals one.
  final Color markerDim;

  /// The mark behind `==highlighted==` text.
  final Color highlight;

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

  /// The height of one line of prose, for the height map's estimates — at
  /// the text's own size, which a reader scales by the scaler the text is
  /// laid out at, as the text is: unlike the metrics above, it is not
  /// scaled already.
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

  /// The theme a quote's content is drawn with: its prose in the quote's
  /// style, everything else as it is — a heading or a list inside a quote
  /// is still a heading or a list.
  MarkdownTheme get quoted => MarkdownTheme(
    body: body.merge(quote),
    heading1: heading1,
    heading2: heading2,
    heading3: heading3,
    heading4: heading4,
    heading5: heading5,
    heading6: heading6,
    code: code,
    quote: quote,
    tableCell: tableCell,
    tableHeader: tableHeader,
    link: link,
    wikilink: wikilink,
    tag: tag,
    marker: marker,
    rule: rule,
    codeHighlight: codeHighlight,
    codeBackground: codeBackground,
    quoteBar: quoteBar,
    tableBorder: tableBorder,
    markerDim: markerDim,
    blockSpacing: blockSpacing,
    listIndentPerLevel: listIndentPerLevel,
    quoteIndentPerLevel: quoteIndentPerLevel,
    codePadding: codePadding,
    quoteBarWidth: quoteBarWidth,
    ruleThickness: ruleThickness,
    tableCellPadding: tableCellPadding,
    lineHeight: lineHeight,
    highlight: highlight,
  );
}

/// The source mode's typography: a copy of [theme] in a monospace face.
///
/// The source editor is read as *text* — its markers, its indents, its columns
/// —
/// and a proportional face makes the columns drift. The legacy editor set the
/// note
/// in `monospace` with these fallbacks, for the platforms where the generic
/// alias
/// does not resolve (`note_editor.dart`), and the numbers in the same face at
/// the
/// same size, dimmed.
///
/// The face is a *documentation* matter as much as a code one: set, for now,
/// and
/// meant to become a setting — see the issue "the source editor's font should
/// be a
/// setting" and `docs/user/editing.md`.
MarkdownTheme monospaceTheme(MarkdownTheme theme) {
  const fallback = <String>['Consolas', 'DejaVu Sans Mono', 'Roboto Mono'];
  TextStyle mono(TextStyle style) =>
      style.copyWith(fontFamily: 'monospace', fontFamilyFallback: fallback);
  return MarkdownTheme(
    body: mono(theme.body),
    heading1: mono(theme.heading1),
    heading2: mono(theme.heading2),
    heading3: mono(theme.heading3),
    heading4: mono(theme.heading4),
    heading5: mono(theme.heading5),
    heading6: mono(theme.heading6),
    code: mono(theme.code),
    quote: mono(theme.quote),
    tableCell: mono(theme.tableCell),
    tableHeader: mono(theme.tableHeader),
    link: mono(theme.link),
    wikilink: mono(theme.wikilink),
    tag: mono(theme.tag),
    marker: mono(theme.marker),
    codeHighlight: theme.codeHighlight,
    rule: theme.rule,
    codeBackground: theme.codeBackground,
    quoteBar: theme.quoteBar,
    tableBorder: theme.tableBorder,
    markerDim: theme.markerDim,
    blockSpacing: theme.blockSpacing,
    listIndentPerLevel: theme.listIndentPerLevel,
    quoteIndentPerLevel: theme.quoteIndentPerLevel,
    codePadding: theme.codePadding,
    quoteBarWidth: theme.quoteBarWidth,
    ruleThickness: theme.ruleThickness,
    tableCellPadding: theme.tableCellPadding,
    lineHeight: theme.lineHeight,
    highlight: theme.highlight,
  );
}

/// The note's theme for the nearest application theme, its metrics at the
/// size the note's text is read at: [scaler]'s, or the context's.
///
/// The note's size is a text scaler, and a scaler scales text as it is
/// laid out and nothing else: the metrics in pixels — the list's and the
/// quote's columns, the spacing, the paddings — are scaled here, or a note
/// set at 150% kept its columns at 100% around text half as big again.
///
/// A function rather than a factory, as `noteTextScalerOf` is: it reads
/// the context, which a constructor has no business doing.
MarkdownTheme markdownThemeOf(BuildContext context, {TextScaler? scaler}) {
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

  final em =
      (scaler ?? MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling)
          .scale(body.fontSize!);

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
    codeHighlight: theme.brightness == Brightness.dark
        ? atomOneDarkTheme
        : atomOneLightTheme,
    codeBackground: colors.surfaceContainerHighest,
    quoteBar: colors.outlineVariant,
    tableBorder: colors.outlineVariant,
    markerDim: colors.outline,
    blockSpacing: em,
    listIndentPerLevel: em * 1.6,
    quoteIndentPerLevel: em * 0.9,
    codePadding: em * 0.6,
    quoteBarWidth: 3,
    ruleThickness: 1,
    tableCellPadding: EdgeInsets.symmetric(
      horizontal: em * 0.5,
      vertical: em * 0.3,
    ),
    lineHeight: body.fontSize! * 1.5,
    highlight: markHighlightFor(dark: theme.brightness == Brightness.dark),
  );
}
