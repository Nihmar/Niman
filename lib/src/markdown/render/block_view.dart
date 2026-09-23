/// One block, drawn.
///
/// The renderer is a mapping, not an engine: the parser has already said what
/// each block is and what its inline runs are, the masker has said what is
/// drawn rather than typed, and `VisibleText` has said which characters a
/// reader sees. What is left is which widget to use — and that is all this file
/// does, so it can be read in one sitting and compared against the preview it
/// replaces.
///
/// What each kind becomes:
///
/// | block | drawn as |
/// |---|---|
/// | paragraph, heading | rich text over the visible segments |
/// | list item | the marker, then the item's own text, indented by its depth |
/// | quote | a bar and the indented content |
/// | fenced or indented code | a filled box of monospace lines |
/// | math | the display typesetter |
/// | table | a real table, cells from the source rows |
/// | thematic break | a rule |
/// | frontmatter | nothing: it is metadata, and the preview hides it too |
/// | blank | the space a blank line takes |
///
/// The kinds not yet drawn as they will be: an embed is not yet an image and a
/// table cell does not yet render its inline markup, because both need the
/// image resolution the preview owns. They are named in the Phase 2 issue
/// rather than silently rendered wrong.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/parsed_block.dart';
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/markdown/render/item_marks.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/markdown/render/visible_text.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/style_run.dart';
import 'package:niman/src/preview/code_highlight.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

/// Draws one block of a note.
final class BlockView extends StatelessWidget {
  /// Creates a view over [parsed], whose block is [ParsedBlock.block].
  const new({
    required this.parsed,
    required this.theme,
    required this.mathCache,
    this.availableWidth,
    this.onTapLink,
    this.onTapWikiLink,
    this.embedResolver,
    this.onToggleTask,
    this.scope,
    this.spaced = true,
    this.quoteNesting = 0,
    super.key,
  });

  /// Called with a task item's line when its checkbox is tapped; null draws
  /// the box and leaves it alone.
  final void Function(int line)? onToggleTask;

  /// The note's link and footnote definitions, for what a quote's content
  /// is parsed with when it is read again as blocks of its own; null reads
  /// the quote's own.
  final DocumentScope? scope;

  /// Whether the block leaves the spacing between blocks under it: all but
  /// the last block inside a quote do, whose bar would otherwise run on past
  /// its text.
  final bool spaced;

  /// How many quotes this block is inside, which bounds how deep a quote's
  /// content is read again as blocks.
  final int quoteNesting;

  /// Whether [block] leaves the spacing between blocks under it, with [next]
  /// after it: all but an item a next item follows at once — a tight list's
  /// items sit one under the other, as `live` draws them.
  static bool spacedBefore(Block block, Block? next) =>
      !(block.kind == BlockKind.listItem &&
          next != null &&
          next.kind == BlockKind.listItem &&
          next.startLine == block.endLine);

  /// Past this many quotes inside one another, a quote's content is drawn as
  /// its text rather than read again.
  static const int _maxQuoteNesting = 8;

  /// The block, parsed and ready.
  final ParsedBlock parsed;

  /// The typography and metrics it is drawn with.
  final MarkdownTheme theme;

  /// The math render cache, one per surface.
  final MathCache mathCache;

  /// How wide the pane is, so a display formula wider than it can be broken
  /// across lines instead of cut (#257). Null when the caller does not know —
  /// a test, an intrinsic pass — and the formula is drawn whole.
  final double? availableWidth;

  /// Called when a link is tapped.
  final void Function(String text, String? href)? onTapLink;

  /// Called when a wikilink is tapped.
  final void Function(ExtensionSpan span)? onTapWikiLink;

  /// Resolves an embed's target, for the round that draws images.
  final Future<String?> Function(String target)? embedResolver;

  @override
  Widget build(BuildContext context) {
    final block = parsed.block;
    final child = switch (block.kind) {
      BlockKind.paragraph => _rich(context),
      BlockKind.heading => _rich(
        context,
        style: theme.heading(block.headingLevel),
      ),
      BlockKind.listItem => _listItem(context),
      BlockKind.quote => _quote(context),
      BlockKind.fencedCode ||
      BlockKind.indentedCode => _code(context, block.fenceInfo),
      BlockKind.math => _blockMath(context),
      BlockKind.table => _table(context),
      BlockKind.thematicBreak => _rule(context),
      // A blank line is the spacing between the blocks around it, which the
      // one above leaves: drawn again here, it counted twice more.
      BlockKind.blank => const SizedBox.shrink(),
      BlockKind.frontmatter => const SizedBox.shrink(),
      BlockKind.html => _code(context, null),
    };
    if (!spaced || block.kind == BlockKind.blank) return child;
    return Padding(
      padding: EdgeInsets.only(bottom: theme.blockSpacing),
      child: child,
    );
  }

  /// The block's visible text as rich text.
  ///
  /// A block the parser consumed and gave nothing back draws nothing — a link
  /// reference definition and a footnote definition are syntax, not prose, and
  /// the parser files them elsewhere and returns an empty node list. Drawing
  /// "the text it did not cover" instead put `[^1]: fetch free fog national.`
  /// on screen where the preview draws a footnote.
  Widget _rich(BuildContext context, {TextStyle? style}) {
    if (parsed.runs.isEmpty && parsed.extensions.isEmpty) {
      return const SizedBox.shrink();
    }
    final visible = VisibleText.of(parsed);
    final base = style ?? theme.body;
    final spans = _InlineBuilder(
      visible: visible,
      theme: theme,
      base: base,
      mathCache: mathCache,
      availableWidth: availableWidth,
      onTapLink: onTapLink,
      onTapWikiLink: onTapWikiLink,
      embedResolver: embedResolver,
    ).build();
    return Text.rich(
      TextSpan(children: spans, style: base),
      textAlign: TextAlign.start,
    );
  }

  /// A list item: its marker, then its content at the item's own indent.
  ///
  /// The marker is drawn, not read from the text, and it agrees with `live`
  /// on purpose: a bullet is a dot whatever the note wrote (`-`, `*` or `+`),
  /// an ordered item keeps its number, and a task item is a box rather than
  /// the `[x]` it was written as — the text says what the note said, the
  /// screen shows what it means. The dot and the box are `live`'s own
  /// (`item_marks.dart`), in the same room: centred in the marker column,
  /// on the item's first row.
  Widget _listItem(BuildContext context) {
    final marker = _listMarker(parsed.text, parsed.block.listOrdinal);
    final depth = parsed.block.listDepth;
    // One marker column per level, so a sublist's marker sits exactly where its
    // parent's text starts.
    final offset = depth <= 0 ? 0.0 : depth * theme.listIndentPerLevel;
    // The size the item's text is read at: its marks and its number's gap
    // grow with the note's text, which is scaled as it is laid out.
    final scaler = MediaQuery.textScalerOf(context);
    final em = scaler.scale(theme.body.fontSize!);
    return Padding(
      padding: EdgeInsets.only(left: offset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: theme.listIndentPerLevel,
            child: marker.ordered
                ? _number(marker.display, em)
                : _mark(
                    em,
                    _firstRow(scaler),
                    task: marker.isTask ? marker.checked : null,
                  ),
          ),
          Expanded(child: _rich(context, style: theme.body)),
        ],
      ),
    );
  }

  /// How tall the item's first row is: one line of its text, at [scaler].
  double _firstRow(TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: ' ', style: theme.body),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final row = painter.height;
    painter.dispose();
    return row;
  }

  /// An ordered item's number: on one row, ending a few pixels before the
  /// item's text, and running out to the left when it is wider than the
  /// column — a `10.` wrapped to two rows in it, and the numbers of a list
  /// did not line up. It is where `live` draws it (`live_decorations.dart`),
  /// in its colour.
  Widget _number(String display, double em) => Padding(
    padding: EdgeInsets.only(right: em * numberGapEm),
    child: OverflowBox(
      maxWidth: double.infinity,
      // As tall as the number: the column's height is the item's to set.
      fit: OverflowBoxFit.deferToChild,
      alignment: Alignment.topRight,
      child: Text(
        display,
        style: theme.marker.copyWith(color: theme.markerDim),
        maxLines: 1,
        softWrap: false,
      ),
    ),
  );

  /// A bullet, or a task item's checkbox when [task] says whether it is
  /// ticked — the box ticked by a tap when [onToggleTask] is given, the
  /// whole marker column being the target, so a finger need not find the
  /// box's own few pixels.
  Widget _mark(double em, double row, {required bool? task}) {
    final mark = CustomPaint(
      size: Size(theme.listIndentPerLevel, row),
      painter: ItemMarkPainter(
        em: em,
        row: row,
        color: theme.markerDim,
        task: task,
      ),
    );
    final toggle = onToggleTask;
    if (task == null || toggle == null) return mark;
    final line = parsed.block.startLine;
    return Semantics(
      checked: task,
      onTap: () => toggle(line),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => toggle(line),
          child: Align(alignment: Alignment.topLeft, child: mark),
        ),
      ),
    );
  }

  /// A blockquote: a bar, and its content indented past it.
  ///
  /// The content is read again as blocks of its own — the quote's marks
  /// are already off its text — and each is drawn as any block is, so a
  /// quote inside it has its own bar and a list its bullets, the way the
  /// page they are on draws them. Drawn as one text, a quote showed a
  /// quote inside it as a paragraph and a list as its dashes. The pattern
  /// is the table cell's: the same engine, over the smaller text.
  Widget _quote(BuildContext context) {
    final bar = BoxDecoration(
      border: Border(
        left: BorderSide(color: theme.quoteBar, width: theme.quoteBarWidth),
      ),
    );
    final inner = quoteNesting < _maxQuoteNesting ? _quoteContent() : null;
    if (inner != null && inner.isNotEmpty) {
      final start = parsed.block.startLine;
      final toggle = onToggleTask;
      final width = availableWidth;
      return Container(
        decoration: bar,
        padding: EdgeInsets.only(left: theme.quoteIndentPerLevel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (var at = 0; at < inner.length; at++)
              BlockView(
                parsed: inner[at],
                theme: theme.quoted,
                mathCache: mathCache,
                availableWidth: width == null
                    ? null
                    : width - theme.quoteIndentPerLevel - theme.quoteBarWidth,
                onTapLink: onTapLink,
                onTapWikiLink: onTapWikiLink,
                embedResolver: embedResolver,
                // The content's lines are the quote's, one for one: its
                // marks were taken off each line, not the lines.
                onToggleTask: toggle == null
                    ? null
                    : (line) => toggle(start + line),
                scope: scope,
                spaced:
                    at < inner.length - 1 &&
                    spacedBefore(inner[at].block, inner[at + 1].block),
                quoteNesting: quoteNesting + 1,
              ),
          ],
        ),
      );
    }
    final style = theme.quote;
    return Container(
      decoration: bar,
      padding: EdgeInsets.only(left: theme.quoteIndentPerLevel),
      child: Text.rich(
        TextSpan(
          children: _InlineBuilder(
            visible: VisibleText.of(parsed),
            theme: theme,
            base: style,
            mathCache: mathCache,
            availableWidth: availableWidth,
            onTapLink: onTapLink,
            onTapWikiLink: onTapWikiLink,
            embedResolver: embedResolver,
          ).build(),
        ),
        style: style,
      ),
    );
  }

  /// The quote's content — its text, the marks already off it — as blocks
  /// of its own, the blank ones at its end left out.
  List<ParsedBlock> _quoteContent() {
    final buffer = SourceBuffer.fromText(parsed.text);
    final blocks = <Block>[...BlockScanner(buffer).index.blocks];
    while (blocks.isNotEmpty && blocks.last.kind == BlockKind.blank) {
      blocks.removeLast();
    }
    final parser = BlockParser();
    final definitions = scope ?? DocumentScope.scan(buffer, buffer.revision);
    return <ParsedBlock>[
      for (final block in blocks)
        parser.parseText(
          block,
          BlockParser.blockText(block, buffer),
          () => definitions,
        ),
    ];
  }

  /// A code block: a filled box of monospace lines, the fence taken out, the
  /// code coloured by the language the fence names.
  ///
  /// The tokens come from the same `highlight` core the preview's highlighter
  /// uses, one block at a time and only for the blocks a frame draws. The
  /// engine's own line-state lexer (§8.8.2) is the design's replacement when
  /// the whole-block regex stops being enough.
  Widget _code(BuildContext context, String? language) {
    final text = _fenceContent(parsed.text);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.codeBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: EdgeInsets.all(theme.codePadding),
      child: language == null || language.isEmpty
          ? Text(text, style: theme.code)
          : Text.rich(
              CodeHighlighter(
                language: language,
                theme: theme.codeHighlight,
              ).format(text),
              // A fence with no palette (the fallback theme, before the first
              // build) still gets the monospace metrics.
              style: theme.code,
            ),
    );
  }

  /// A display formula, centered like the preview's.
  ///
  /// The [Center] is load-bearing, not decoration. A block is laid out on the
  /// sliver's cross axis with a **tight** width, so a bare [BlockMathView] is
  /// stretched to the whole column — and the katex painter starts its ink at
  /// the canvas origin whatever size it is handed, which put every formula at
  /// the column's left edge (#252). Center hands the view its own width back.
  Widget _blockMath(BuildContext context) => Center(
    child: BlockMathView(
      cache: mathCache,
      maxWidth: availableWidth,
      tex: displayTexOf(parsed.text),
      style: mathStyleFor(theme.body),
    ),
  );

  /// A thematic break.
  Widget _rule(BuildContext context) =>
      Container(height: theme.ruleThickness, color: theme.rule);

  /// A table, its cells read from the source rows.
  Widget _table(BuildContext context) {
    final rows = _tableRows(parsed.text);
    if (rows.isEmpty) return const SizedBox.shrink();
    final border = TableBorder.all(color: theme.tableBorder, width: 0.5);
    return Table(
      border: border,
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: <TableRow>[
        for (var at = 0; at < rows.length; at++)
          TableRow(
            children: <Widget>[
              for (final cell in rows[at])
                Padding(
                  padding: theme.tableCellPadding,
                  child: _cell(
                    cell,
                    at == 0 ? theme.tableHeader : theme.tableCell,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// A table cell, with its own inline markup rendered.
  ///
  /// A cell is a block's worth of Markdown that the scanner never sees as one:
  /// it lives inside a line, between pipes, so it is parsed here, on its own,
  /// through the same engine everything else goes through. Doing it any other
  /// way — a second inline scanner inside the renderer — is how two surfaces
  /// start disagreeing about what `**bold**` means.
  ///
  /// The cost is a scan and a parse per cell, which matters only because a
  /// table can have many; a cell is one line, and a note's tables are small.
  /// Anything larger belongs in the block scanner, which is where a cell would
  /// become a block if it ever needs to.
  Widget _cell(String text, TextStyle style) {
    if (text.isEmpty) return Text('', style: style);
    final buffer = SourceBuffer.fromText(text);
    final scanner = BlockScanner(buffer);
    if (scanner.index.blocks.isEmpty) return Text(text, style: style);
    final cell = BlockParser().parse(scanner.index.blocks.first, buffer);
    final spans = _InlineBuilder(
      visible: VisibleText.of(cell),
      theme: theme,
      base: style,
      mathCache: mathCache,
      onTapLink: onTapLink,
      onTapWikiLink: onTapWikiLink,
      embedResolver: embedResolver,
    ).build();
    return Text.rich(TextSpan(children: spans, style: style));
  }

  /// What to draw in a list item's marker column.
  ///
  /// The `display` field is the text of the marker, and a task item has none:
  /// it draws a box. The indent the item was written at is not this function's
  /// business: the block carries it and the caller applies it.
  static ({String display, bool isTask, bool checked, bool ordered})
  _listMarker(String text, int ordinal) {
    final line = text.split('\n').first;
    var at = 0;
    while (at < line.length && (line[at] == ' ' || line[at] == '\t')) {
      at++;
    }
    final start = at;
    var ordered = false;
    if (at < line.length && '+-*'.contains(line[at])) {
      at++;
    } else {
      while (at < line.length &&
          line[at].compareTo('0') >= 0 &&
          line[at].compareTo('9') <= 0) {
        at++;
      }
      if (at < line.length && (line[at] == '.' || line[at] == ')')) {
        at++;
        ordered = true;
      }
    }
    if (at == start) {
      return (display: '', isTask: false, checked: false, ordered: false);
    }
    final rest = line.substring(at).trimLeft();
    if (rest.startsWith('[') && rest.length > 2 && rest[2] == ']') {
      return (
        display: '',
        isTask: true,
        checked: rest[1] == 'x' || rest[1] == 'X',
        ordered: false,
      );
    }
    // An ordered item shows its *position* in the list, not the number the note
    // happened to write: `1. 1. 1.` is a list of three. The delimiter the note
    // used is kept, because `.` and `)` are the author's choice and the number
    // is the list's.
    final delimiter = ordered && at > start ? line[at - 1] : '.';
    return (
      display: ordered
          ? '${ordinal > 0 ? ordinal : line.substring(start, at - 1)}$delimiter'
          : '\u2022',
      isTask: false,
      checked: false,
      ordered: ordered,
    );
  }

  /// The lines inside a fence, or the block's own text for indented code.
  static String _fenceContent(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return text;
    if (!lines.first.trimLeft().startsWith('```') &&
        !lines.first.trimLeft().startsWith('~~~')) {
      // Indented code: four spaces come off each line.
      return lines
          .map((line) => line.startsWith('    ') ? line.substring(4) : line)
          .join('\n');
    }
    final last = lines.length > 1 ? lines.last.trim() : '';
    final closed = last.startsWith('```') || last.startsWith('~~~');
    return lines
        .sublist(1, closed ? lines.length - 1 : lines.length)
        .join('\n');
  }

  /// The rows and cells of a GFM table, delimiter row dropped.
  static List<List<String>> _tableRows(String text) {
    final rows = <List<String>>[];
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.contains('|')) continue;
      if (RegExp(r'^[|\s:-]+$').hasMatch(trimmed) && trimmed.contains('-')) {
        continue; // the delimiter row
      }
      var body = trimmed;
      if (body.startsWith('|')) body = body.substring(1);
      if (body.endsWith('|')) body = body.substring(0, body.length - 1);
      rows.add(<String>[
        for (final cell in body.split(RegExp(r'(?<!\\)\|')))
          cell.replaceAll(r'\|', '|').trim(),
      ]);
    }
    return rows;
  }
}

/// Turns visible segments and drawn spans into an inline span tree.
final class _InlineBuilder {
  new({
    required this.visible,
    required this.theme,
    required this.base,
    required this.mathCache,
    this.availableWidth,
    this.onTapLink,
    this.onTapWikiLink,
    this.embedResolver,
  });

  final VisibleText visible;
  final MarkdownTheme theme;

  /// The style the block's text is drawn in — the body's, a heading's, a
  /// quote's, a table header's. Every run is this plus what the run adds:
  /// runs drawn in [MarkdownTheme.body] instead put a heading's words back at
  /// the body's size and weight, and the preview's `# Title` read as a
  /// paragraph.
  final TextStyle base;
  final MathCache mathCache;

  /// [accent]'s colour and decoration, on the block's own size and weight.
  TextStyle _tinted(TextStyle accent) => base.copyWith(
    color: accent.color,
    backgroundColor: accent.backgroundColor,
    decoration: accent.decoration,
    decorationColor: accent.decorationColor,
    decorationStyle: accent.decorationStyle,
  );

  /// The code face, scaled as the block is to the body.
  TextStyle get _code {
    final body = theme.body.fontSize;
    final size = base.fontSize;
    final code = theme.code.fontSize;
    if (body == null || size == null || code == null || size == body) {
      return theme.code;
    }
    return theme.code.copyWith(fontSize: code * size / body);
  }

  /// The pane's width, for a display formula that has to be broken (#257).
  final double? availableWidth;
  final void Function(String text, String? href)? onTapLink;
  final void Function(ExtensionSpan span)? onTapWikiLink;
  final Future<String?> Function(String target)? embedResolver;

  /// The spans of the block, in offset order.
  List<InlineSpan> build() {
    final spans = <InlineSpan>[];
    var drawn = 0;
    for (final segment in visible.segments) {
      while (drawn < visible.replaced.length &&
          visible.replaced[drawn].start < segment.start) {
        spans.add(_drawnSpan(visible.replaced[drawn]));
        drawn++;
      }
      spans.add(_textSpan(segment));
    }
    while (drawn < visible.replaced.length) {
      spans.add(_drawnSpan(visible.replaced[drawn]));
      drawn++;
    }
    return spans;
  }

  /// A visible run, styled by the construct it belongs to.
  InlineSpan _textSpan(VisibleSegment segment) {
    final text = visible.text.substring(segment.start, segment.end);
    final style = switch (segment.kind) {
      StyleKind.emphasis => base.copyWith(fontStyle: FontStyle.italic),
      StyleKind.strong => base.copyWith(fontWeight: FontWeight.w700),
      StyleKind.strikethrough => base.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
      StyleKind.underline => base.copyWith(
        decoration: TextDecoration.underline,
      ),
      // Smaller, and raised or lowered by the font's own glyphs where it has
      // them: a text style has no baseline shift of its own.
      StyleKind.superscript => base.copyWith(
        fontSize: (base.fontSize ?? 14) * 0.75,
        fontFeatures: const <FontFeature>[FontFeature.superscripts()],
      ),
      StyleKind.subscript => base.copyWith(
        fontSize: (base.fontSize ?? 14) * 0.75,
        fontFeatures: const <FontFeature>[FontFeature.subscripts()],
      ),
      StyleKind.code => _code,
      StyleKind.link => _tinted(theme.link),
      StyleKind.image => _tinted(theme.marker),
      StyleKind.heading => base,
      StyleKind.plain || StyleKind.hardBreak => base,
    };
    if (segment.kind == StyleKind.image && segment.href != null) {
      // A Markdown image is a picture, and its alt text is what stands in for
      // it when there is no picture — the same two rules the embed follows,
      // because they are the same problem. Without a resolver there is nothing
      // to resolve and the alt text is the honest thing to draw.
      if (embedResolver == null) {
        return TextSpan(text: text, style: _tinted(theme.marker));
      }
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: EmbedView(
          target: segment.href!,
          display: text,
          // The construct as the note wrote it. For the inline form this is
          // exact; a reference image shows the inline spelling instead, which
          // is a smaller lie than showing nothing.
          placeholder: '![$text](${segment.href})',
          onResolve: embedResolver,
        ),
      );
    }
    if (segment.kind == StyleKind.link && segment.href != null) {
      return TextSpan(
        text: text,
        style: style,
        recognizer: TapGestureRecognizer()
          ..onTap = () => onTapLink?.call(text, segment.href),
      );
    }
    return TextSpan(text: text, style: style);
  }

  /// A span that is drawn rather than typed.
  InlineSpan _drawnSpan(ExtensionSpan span) {
    switch (span.kind) {
      case ExtensionKind.inlineMath:
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: InlineMathView(
            cache: mathCache,
            tex: span.inner,
            style: mathStyleFor(base),
          ),
        );
      case ExtensionKind.wikilink:
        return TextSpan(
          text: _wikiDisplay(span),
          style: _tinted(theme.wikilink),
          recognizer: TapGestureRecognizer()
            ..onTap = () => onTapWikiLink?.call(span),
        );
      case ExtensionKind.tag:
        return TextSpan(text: span.text, style: _tinted(theme.tag));
      case ExtensionKind.codeSpan:
        return TextSpan(text: span.inner, style: _code);
      case ExtensionKind.embed:
        // An embed is a picture in the middle of a line, so it is a widget
        // span rather than text. Without a resolver there is nothing to
        // resolve, and the note's own words stand in for the picture.
        if (embedResolver == null) {
          return TextSpan(
            text: '![[${span.inner}]]',
            style: _tinted(theme.marker),
          );
        }
        // `![[target|alias]]`: the alias is what the reader asked to see, and
        // it is what the preview drew when a binary or a missing target had to
        // stand in for itself (`preview/wikilink.dart`). The read view passed
        // the raw inner instead, so the same note read `![[book.epub|The
        // book]]` in one surface and `![[The book]]` in the other.
        final pipe = span.inner.indexOf('|');
        final target = pipe >= 0 ? span.inner.substring(0, pipe) : span.inner;
        final alias = pipe >= 0 ? span.inner.substring(pipe + 1).trim() : '';
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: EmbedView(
            target: target,
            display: alias.isEmpty ? target : alias,
            onResolve: embedResolver,
          ),
        );
      case ExtensionKind.displayMath:
        // A display box inside a paragraph: the same typesetter, laid out as
        // its own line rather than inline.
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: BlockMathView(
            cache: mathCache,
            maxWidth: availableWidth,
            tex: span.inner,
            style: mathStyleFor(base),
          ),
        );
    }
  }

  /// What a wikilink shows: its alias, or its target.
  static String _wikiDisplay(ExtensionSpan span) {
    final inner = span.inner;
    final pipe = inner.indexOf('|');
    if (pipe >= 0) {
      final alias = inner.substring(pipe + 1).trim();
      if (alias.isNotEmpty) return alias;
    }
    final target = pipe >= 0 ? inner.substring(0, pipe) : inner;
    final hash = target.indexOf('#');
    return (hash >= 0 ? target.substring(0, hash) : target).trim().isEmpty
        ? inner
        : (hash >= 0 ? target.substring(0, hash) : target).trim();
  }
}

/// One piece of a code block too long to lay out whole (see
/// `MarkdownReadViewState.pieceLines`): its lines, in the block's box, with the
/// box's rounded ends, padding and spacing only where the block starts and
/// ends, so the pieces read as one block.
///
/// Each piece is highlighted on its own: a construct that spans two pieces
/// (a long string, a block comment) is coloured from where the piece
/// starts. Only blocks hundreds of lines long are cut, where that is the
/// price of drawing them at all.
final class CodePieceView extends StatelessWidget {
  /// Draws lines `[block.startLine, block.endLine)` of [buffer], a piece of
  /// a longer code block: the [first] carries its opening fence, the [last]
  /// its closing one.
  const new({
    required this.buffer,
    required this.block,
    required this.first,
    required this.last,
    required this.theme,
    super.key,
  });

  /// The note.
  final SourceBuffer buffer;

  /// The piece's line range and the block's kind and language.
  final Block block;

  /// Whether this piece starts the block.
  final bool first;

  /// Whether this piece ends the block.
  final bool last;

  /// The typography and metrics it is drawn with.
  final MarkdownTheme theme;

  @override
  Widget build(BuildContext context) {
    final language = block.fenceInfo;
    final radius = Radius.circular(first || last ? 4 : 0);
    final text = _text();
    return Padding(
      padding: EdgeInsets.only(bottom: last ? theme.blockSpacing : 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.codeBackground,
          borderRadius: BorderRadius.only(
            topLeft: first ? radius : Radius.zero,
            topRight: first ? radius : Radius.zero,
            bottomLeft: last ? radius : Radius.zero,
            bottomRight: last ? radius : Radius.zero,
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          theme.codePadding,
          first ? theme.codePadding : 0,
          theme.codePadding,
          last ? theme.codePadding : 0,
        ),
        child: language == null || language.isEmpty
            ? Text(text, style: theme.code)
            : Text.rich(
                CodeHighlighter(
                  language: language,
                  theme: theme.codeHighlight,
                ).format(text),
                style: theme.code,
              ),
      ),
    );
  }

  /// The piece's code: its lines, without a fence line, without an indented
  /// block's four spaces.
  String _text() {
    final fenced = block.kind == BlockKind.fencedCode;
    var from = block.startLine;
    var to = block.endLine;
    if (fenced && first) from++;
    if (fenced && last && to > from) {
      final closing = buffer.lineAt(to - 1).trim();
      if (closing.startsWith('```') || closing.startsWith('~~~')) to--;
    }
    final lines = <String>[];
    for (var at = from; at < to; at++) {
      final line = buffer.lineAt(at);
      lines.add(!fenced && line.startsWith('    ') ? line.substring(4) : line);
    }
    return lines.join('\n');
  }
}
