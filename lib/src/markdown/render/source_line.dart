/// One source line: its gutter number, its styled runs, and its caret
/// (split out of `source_view.dart` for #710).
///
/// The line is the source view's unit of layout: the windowing sliver
/// builds one of these per visible row, and the surface asks the line's
/// own paragraph for caret offsets and rectangles. [SourcePiece] is what
/// a row laid out in fitted columns is drawn as, and [SourceFoldMark] what
/// its gutter shows for folding.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/editor/highlight_style.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/live_inlines.dart';
import 'package:niman/src/markdown/render/caret_painters.dart';
import 'package:niman/src/markdown/render/live_blocks.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/live_inline_math.dart';
import 'package:niman/src/markdown/render/live_table_grid.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/note_margins.dart';
import 'package:niman/src/markdown/render/squiggle_painter.dart';
import 'package:niman/src/preview/code_highlight.dart';
import 'package:niman/src/preview/math_cache.dart';

/// One source line: its gutter number, its styled runs, and its caret.
final class SourceLine extends StatelessWidget {
  /// Creates a line drawn from the fields below.
  const new({
    required this.paragraphKey,
    required this.shape,
    required this.pictures,
    required this.embedResolver,
    required this.formula,
    required this.mathCache,
    required this.diagram,
    required this.codeRuns,
    required this.definition,
    required this.tableRow,
    required this.tableHeader,
    required this.pieceKey,
    required this.pieceShift,
    required this.styled,
    required this.number,
    required this.gutterWidth,
    required this.theme,
    required this.syntax,
    required this.dark,
    required this.hideMarkers,
    required this.selected,
    required this.composing,
    required this.width,
    required this.misspelled,
    required this.misspelledColor,
    required this.templateProblems,
    required this.found,
    required this.rowColor,
    required this.fold,
    required this.onFold,
    required this.onFoldDown,
    required this.onDiagramDown,
    required this.onDiagramLine,
    required this.index,
    required this.spot,
    required this.caret,
    required this.caretOn,
    super.key,
  });

  /// The key of the line's own paragraph, so the surface can ask it for a caret
  /// offset or a caret rectangle.
  final GlobalKey paragraphKey;

  /// What `live` draws beside the line's text: a bullet, a number, a
  /// checkbox, a quote's bar, a rule.
  final LineShape shape;

  /// The pictures on the line, which `live` draws under it.
  final List<LinePicture> pictures;

  /// Resolves an embed target to the text the line draws, or null.
  final Future<String?> Function(String target)? embedResolver;

  /// The display formula the line belongs to, which `live` draws in place of
  /// its lines while the caret is out of it.
  final LiveFormula? formula;

  /// The cache the line's formulas are typeset through.
  final MathCache? mathCache;

  /// The Mermaid block the line belongs to, which `live` draws in place of
  /// its lines while the caret is out of it (#530).
  final LiveDiagram? diagram;

  /// The colours of the line's code, as the read view colours its block;
  /// null for a line that is not code the read view colours.
  final List<CodeRun>? codeRuns;

  /// The lines `[start, end)` of the definitions this line is one of — link
  /// references or footnotes, which the read view does not draw where they
  /// stand — or null. Out of the caret's reach they take no room, as a
  /// typeset formula's lines do; the caret anywhere in them shows them all.
  final (int, int)? definition;

  /// How the line is laid out in its table with the caret at a spot, for a
  /// table's line in `live`: its cells on their columns, as the read view
  /// draws them.
  final LiveTableRow? Function(CaretSpot at)? tableRow;

  /// Whether the line is its table's header.
  final bool tableHeader;

  /// The key of one piece of a line drawn as several paragraphs — a table
  /// row laid out in fitted columns, whose pieces are numbered from its
  /// first — or null for a line drawn as one.
  final GlobalKey Function(int at)? pieceKey;

  /// Where the caret's piece stands in the line's box, for a row laid out in
  /// fitted columns: the caret is measured in the piece's own coordinates,
  /// and this is what the painter shifts them by. Zero elsewhere.
  final ValueListenable<Offset> pieceShift;

  /// The line's styled runs.
  final StyledLine styled;

  /// The line's gutter number, or null where it has none.
  final int? number;

  /// How wide the gutter is, computed from the numbers the note has.
  final double gutterWidth;

  /// The Markdown theme the line paints with.
  final MarkdownTheme theme;

  /// The code colours the line paints with.
  final SyntaxColors syntax;

  /// Whether the theme is the dark one.
  final bool dark;

  /// Whether the structural markers are drawn invisibly.
  final bool hideMarkers;

  /// The selected range, as offsets local to this line, or null.
  final (int, int)? selected;

  /// The range the IME is composing, as offsets local to this line, or null.
  final (int, int)? composing;

  /// The words the spelling flags, as offsets local to this line.
  final List<TextRange> misspelled;

  /// The colour their wavy underline is drawn in.
  final Color misspelledColor;

  /// The template checker's problems on this line, as offsets local to it
  /// (T-TPL-09). Drawn in the same wavy shape as the spelling's, on its own
  /// layer, so the two never overwrite each other on a line that has both.
  final List<TextRange> templateProblems;

  /// The find bar's matches on this line, local, and whether each is the
  /// current one.
  final List<(int, int, bool)> found;

  /// The light behind the caret's row (typewriter mode), or null.
  final Color? rowColor;

  /// The fold arrow beside the line, if it has one.
  final SourceFoldMark fold;

  /// Folds or unfolds the line's section.
  final VoidCallback onFold;

  /// A pointer went down on the arrow (before the note hears it).
  final VoidCallback onFoldDown;

  /// A pointer went down on the line's diagram (before the note hears it).
  final void Function(PointerDownEvent event) onDiagramDown;

  /// The line's diagram, or its parse error, was tapped: the note line to
  /// put the caret on.
  final void Function(int line) onDiagramLine;

  /// The width the line's text wraps at (the pane minus the gutter).
  final double width;

  /// This line's index, to compare with [spot].
  final int index;

  /// Where the caret is: its line, and the run it sits in on that line.
  final ValueListenable<CaretSpot> spot;

  /// The caret rectangle, in the caret line's coordinates.
  final ValueListenable<Rect?> caret;

  /// Whether the caret blinks on right now.
  final ValueListenable<bool> caretOn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // The gutter is there whenever it has a width, numbers or not: with
          // them off it is the note column's own indentation, and leaving it
          // out put the text at the pane's edge while the right side still
          // kept the column's room.
          // The gutter is no text: the arrow, not the text's pointer.
          if (gutterWidth > 0)
            SizedBox(
              width: gutterWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.basic,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: number == null
                          ? const SizedBox.shrink()
                          : ValueListenableBuilder<CaretSpot>(
                              valueListenable: spot,
                              builder: (context, at, _) => _takesNoRoom(at)
                                  ? const SizedBox.shrink()
                                  : _number()!,
                            ),
                    ),
                    // The gap between the numbers and the text is where the
                    // fold arrows live, as in the legacy gutter.
                    SizedBox(width: _gutterGap, child: _foldArrow(context)),
                  ],
                ),
              ),
            ),
          Expanded(child: _caretBox(_listeningToFormulas())),
        ],
      ),
    );
  }

  /// The line as [spot] says to draw it, rebuilt when a formula the line
  /// waits for is typeset.
  Widget _listeningToFormulas() {
    Widget line() => ValueListenableBuilder<CaretSpot>(
      valueListenable: spot,
      builder: (context, at, _) => _content(context, at),
    );
    final cache = mathCache;
    if (!hideMarkers ||
        cache == null ||
        !styled.tokens.any((token) => token.kind == TokenKind.mathInline)) {
      return line();
    }
    // A new widget each time: the same instance handed back is one the
    // framework does not build again, and the typeset formula never landed.
    return ListenableBuilder(listenable: cache, builder: (_, _) => line());
  }

  /// The line with the caret at [at]: its text, and in `live` what stands in
  /// for the source it hides.
  /// Whether the line takes no room with the caret at [at]: a typeset
  /// formula's lines past its first (the formula is drawn under that one),
  /// definitions out of the caret's reach, a table's delimiter row. Its
  /// number takes none either, or the row would stay open around nothing.
  bool _takesNoRoom(CaretSpot at) {
    final math = formula;
    if (math != null &&
        mathCache != null &&
        (at.line < math.start || at.line >= math.end) &&
        index != math.start) {
      return true;
    }
    final drawing = diagram;
    if (drawing != null &&
        (at.line < drawing.start || at.line >= drawing.end) &&
        index != drawing.start) {
      return true;
    }
    final defined = definition;
    if (defined != null && (at.line < defined.$1 || at.line >= defined.$2)) {
      return true;
    }
    return tableRow?.call(at)?.delimiter ?? false;
  }

  Widget _content(BuildContext context, CaretSpot at) {
    final mine = at.line == index;
    final math = formula;
    // A formula is edited as a block: the caret anywhere in it shows all of
    // its source, and out of it none.
    final typeset =
        math != null &&
        mathCache != null &&
        (at.line < math.start || at.line >= math.end);
    final drawing = diagram;
    final drawn =
        drawing != null && (at.line < drawing.start || at.line >= drawing.end);
    final defined = definition;
    final table = tableRow?.call(at);
    // A table's row stays on the grid under the caret, as the read view
    // draws it, its marks showing only in the run the caret is in; and the
    // delimiter row takes no room, as the read view leaves it out.
    final revealed = mine && table == null;
    final folded =
        (defined != null && (at.line < defined.$1 || at.line >= defined.$2)) ||
        (table != null && table.delimiter);
    final inline = typeset || drawn || folded
        ? const <InlineFormula>[]
        : _inlineFormulas(run: mine ? (at.runStart, at.runEnd) : null);
    // A callout's mark (#279), where the caret is not: as wide as the icon
    // drawn in its place.
    final callout = hideMarkers && !mine ? shape.callout : null;
    final calloutMark =
        callout != null && callout.title && callout.markEnd > callout.markStart
        ? callout
        : null;
    final concealed = <_Concealed>[
      if (typeset || drawn || folded)
        (0, styled.text.length, _hiddenMarker, whole: false),
      if (hideMarkers && !mine)
        for (final picture in pictures)
          (picture.start, picture.end, _hiddenMarker, whole: false),
      for (final formula in inline)
        (
          formula.start,
          formula.end,
          spacerStyleFor(formula, theme.lineHeight),
          whole: true,
        ),
      if (calloutMark != null)
        (
          calloutMark.markStart,
          calloutMark.markEnd,
          LiveTables.gapStyle(
            calloutIconSlot(
                  MediaQuery.textScalerOf(context).scale(theme.body.fontSize!),
                ) /
                (calloutMark.markEnd - calloutMark.markStart),
          ),
          whole: true,
        ),
      // A table's pipes, and the spaces round its cells' text, as wide as
      // it takes to put each cell's text on its column.
      if (table != null)
        for (final gap in table.gaps)
          (
            gap.start,
            gap.end,
            LiveTables.gapStyle(gap.width / (gap.end - gap.start)),
            whole: true,
          ),
    ];
    final indent = _indent(context, revealed: revealed);
    // A table too wide for the pane is drawn as the read view draws one: its
    // columns fitted to the pane, each cell wrapped inside its own, the row
    // taking as many visual lines as its tallest cell does. It is several
    // paragraphs then, one per piece (`_piecesOf`), which is what lets the
    // caret, a tap and the key table find the piece they are in.
    if (table != null && table.wrapped.isNotEmpty) {
      return _wrappedRow(
        context,
        table,
        indent,
        concealed: concealed,
        formulas: inline,
      );
    }
    Widget paragraph = Text.rich(
      _span(
        revealed: revealed,
        run: mine ? (at.runStart, at.runEnd) : null,
        concealed: concealed,
      ),
      key: paragraphKey,
      // A typeset formula's lines take no room: the formula is drawn under
      // its first one instead. Nor do definitions out of the caret's reach:
      // the read view does not draw them there, and ends the note with the
      // footnotes, as `live` does.
      style: typeset || drawn || folded
          ? _lineStyle(revealed: revealed).copyWith(fontSize: 0.01, height: 1)
          : _lineStyle(revealed: revealed),
      // A table row is at least a line of its text tall. A row of empty
      // cells is all room between cells, drawn in glyphs of no size, and
      // without a floor it closed to nothing: no row to click into, where
      // the read view draws a line's height.
      strutStyle: table != null && !folded
          ? StrutStyle.fromTextStyle(_lineStyle(revealed: revealed))
          : null,
      // A table's row is laid out as the row it is: the cells are put where
      // they belong by the room between them, and a row that soft-wrapped
      // carried the cells after the break onto the next line — they landed
      // wherever the wrap left the pen, in the wrong columns. A table wider
      // than the pane is clipped instead, as it was already.
      softWrap: table == null,
    );
    if (folded) return paragraph;
    if (inline.isNotEmpty) {
      paragraph = CustomPaint(
        foregroundPainter: InlineMathPainter(
          paragraph: paragraphKey,
          formulas: inline,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        ),
        child: paragraph,
      );
    }
    final line = Padding(
      padding: EdgeInsets.only(left: indent),
      child: _withSquiggles(paragraph),
    );
    if (table != null) {
      // A cell's padding above and below its text, and the grid behind.
      return CustomPaint(
        painter: LiveTableGridPainter(
          row: table,
          left: indent,
          color: theme.tableBorder,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: theme.tableCellPadding.top),
          child: line,
        ),
      );
    }
    if (typeset) {
      if (index != math.start) return line;
      return liveFormulaUnder(
        line,
        cache: mathCache!,
        tex: math.tex,
        theme: theme,
        maxWidth: width,
      );
    }
    if (drawn) {
      if (index != drawing.start) return line;
      return liveDiagramUnder(
        line,
        // The block's first line is the one that carries its source.
        source: drawing.source!,
        theme: theme,
        onPointerDown: onDiagramDown,
        onTapSource: (inner) => onDiagramLine(drawing.start + inner),
      );
    }
    final resolver = embedResolver;
    final pictured = resolver == null || pictures.isEmpty
        ? line
        : livePicturesUnder(line, pictures, resolver);
    if (!hideMarkers || shape == LineShape.none) return pictured;
    // A row whose text is all hidden — a fence, a rule, a quote's empty
    // line — is laid out as nothing, while the list still gives it a row:
    // its part of the box, the rule across its middle and the quote's bar
    // were drawn on no height at all.
    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.textScalerOf(context).scale(theme.lineHeight),
      ),
      child: pictured,
    );
    return CustomPaint(
      painter: LiveDecorationPainter(
        shape: shape,
        theme: theme,
        paragraph: paragraphKey,
        textLeft: indent,
        restingLeft: mine ? _indent(context) : indent,
        revealed: mine,
        color: theme.markerDim,
      ),
      child: row,
    );
  }

  /// The inline formulas `live` typesets on this line: all of them but the
  /// one the caret is in ([run]), whose source is shown as written.
  ///
  /// The test is overlap, not containment: a formula's own source may hold
  /// spaces — `$a \sim b$` — so the caret's run is one word *inside* it,
  /// and a run that has to contain the formula never matches (#290).
  List<InlineFormula> _inlineFormulas({(int, int)? run}) {
    final cache = mathCache;
    if (!hideMarkers || cache == null) return const <InlineFormula>[];
    final sources = inlineFormulasOf(styled.text, styled.tokens);
    if (sources.isEmpty) return const <InlineFormula>[];
    return typesetInline(
      <InlineFormulaSource>[
        for (final source in sources)
          if (run == null || run.$2 <= source.start || run.$1 >= source.end)
            source,
      ],
      cache,
      _lineStyle(revealed: false),
    );
  }

  /// The line's number, dimmed, or nothing.
  Widget? _number() => number == null
      ? null
      : Text(
          '$number',
          textAlign: TextAlign.right,
          // One row, whatever the measurement said: a number
          // that wraps makes its line two rows tall and every
          // number below it sits beside the wrong text.
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
          // The text's own face and size, dimmed: what the
          // legacy editor's `DefaultCodeLineNumber` does, so the
          // numbers line up with the characters they count
          // instead of drifting from them.
          style: theme.body.copyWith(color: theme.markerDim),
        );

  /// The fold arrow: pointing down over a section that can fold, right over
  /// one that is folded, nothing elsewhere.
  Widget? _foldArrow(BuildContext context) {
    if (fold == SourceFoldMark.none) return null;
    final row = MediaQuery.textScalerOf(context).scale(theme.lineHeight);
    return Listener(
      onPointerDown: (_) => onFoldDown(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: ValueKey<String>('fold-$index'),
          behavior: HitTestBehavior.opaque,
          onTap: onFold,
          child: SizedBox(
            height: row,
            child: Center(
              child: Icon(
                fold == SourceFoldMark.closed
                    ? Icons.chevron_right
                    : Icons.expand_more,
                size: foldArrowSize,
                color: theme.markerDim,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [child] with the caret painted over it.
  ///
  /// A `foregroundPainter` rather than a `Stack`: a sliver lays its children
  /// out
  /// with unbounded main-axis constraints — that is what makes it measure them
  /// —
  /// and a `Stack` needs a bound it cannot have here. The painter draws on top
  /// of
  /// the text it belongs to, which is also what a caret is.
  ///
  /// Every line listens to *which* line holds the caret, so a tap that moves
  /// it to another line repaints the two lines involved at once — without
  /// that, the caret stayed drawn on its old line until something else rebuilt
  /// the note. The rectangle and the blink repaint the painter only, never the
  /// line, and the tree keeps its shape either way so the paragraph is never
  /// re-mounted.
  Widget _caretBox(Widget child) => ValueListenableBuilder<CaretSpot>(
    valueListenable: spot,
    builder: (context, at, child) => CustomPaint(
      painter: at.line == index && rowColor != null
          ? CaretRowPainter(
              rect: caret,
              color: rowColor!,
              pieceShift: pieceShift,
            )
          : null,
      foregroundPainter: at.line == index
          ? CaretPainter(
              rect: caret,
              on: caretOn,
              shift: Offset(_indent(context, revealed: true), 0),
              pieceShift: pieceShift,
            )
          : null,
      child: child,
    ),
    child: child,
  );

  /// The style the line is set in.
  ///
  /// In live mode a heading is drawn at its own size, which is the difference
  /// between hiding a hash and *being* a heading; a source view shows the note
  /// as
  /// written and keeps one size for everything, so the markers keep their own
  /// advance there.
  TextStyle _lineStyle({required bool revealed}) {
    // The line's own size is the *hiding*'s, not the reveal's: a heading is
    // drawn as a heading whether its hashes are shown or not, because what the
    // mode is about is reading the note with the syntax out of the way — and
    // revealing a marker is not a reason to restyle the line under the caret
    // (`docs/records/unified-surface.md` §8.6.2, and the test that holds it).
    if (!hideMarkers) return theme.body;
    // A table's cells are set as the read view sets them.
    if (tableRow != null) {
      return tableHeader ? theme.tableHeader : theme.tableCell;
    }
    // Code reads as the read view draws it: in monospace, fences and all.
    if (shape.code != null) return theme.code;
    // A callout's title, as the read view sets it (#279) — the caret on it
    // or not: revealing the mark is no reason to restyle the line.
    final callout = shape.callout;
    if (callout != null && callout.title) {
      return theme.body.copyWith(
        color: callout.style.color,
        fontWeight: FontWeight.w600,
      );
    }
    // A heading inside a quote is set at its size, as the read view sets it.
    if (shape.heading > 0) return theme.heading(shape.heading);
    // Quoted prose reads as the read view draws it: in the quote's own style.
    if (shape.quoteDepth > 0) return theme.body.merge(theme.quote);
    final text = styled.text;
    var level = 0;
    while (level < text.length && level < 6 && text[level] == '#') {
      level++;
    }
    if (level == 0 || (level < text.length && text[level] != ' ')) {
      return theme.body;
    }
    return switch (level) {
      1 => theme.heading1,
      2 => theme.heading2,
      3 => theme.heading3,
      4 => theme.heading4,
      5 => theme.heading5,
      _ => theme.heading6,
    };
  }

  /// How far the line is indented, in live mode.
  ///
  /// A list item's text is set one column in per level, as the read view
  /// sets it, and a quote's a step in past each bar. The line's prefix —
  /// the written indent, the quote marks, the marker, the box and the
  /// spaces between them — is hidden whole ([_span]), so the text lands on
  /// the column and a wrapped item's next row starts under it, where it
  /// hung out to the left by the prefix's width. Live nested by the spaces
  /// the note was written with before: a sublist sat a few pixels in. A
  /// code block's rows are set a padding into its box, as the read view
  /// sets its code.
  ///
  /// It is pure layout: no offset moves, because the text underneath is
  /// still the note's own text, character for character.
  ///
  /// On the caret's line ([revealed]) the prefix is drawn as written, and
  /// it is set *into* the indent rather than before it: otherwise the text
  /// jumped right by the marks' width each time the caret came onto the
  /// line, and back when it left (device screenshot 2026-09-23, a list
  /// being typed). Marks wider than the column — a task's `- [ ] `, a
  /// `10. `, a heading's `# ` over its zero column — move the line right by
  /// what is left over; they start at the note's left margin, never hung
  /// out into the field left of the text (#288).
  double _indent(BuildContext context, {bool revealed = false}) {
    if (!hideMarkers) return 0;
    final listed = shape.listed
        ? (shape.listDepth + 1) * theme.listIndentPerLevel
        : 0.0;
    final base =
        listed +
        shape.quoteDepth * theme.quoteIndentPerLevel +
        (shape.code == null ? 0 : theme.codePadding);
    if (base == 0 && _prefixEnd == 0) return 0;
    final marks =
        _textStart(context, revealed: revealed) -
        _glyphLeft(context, const <InlineSpan>[]);
    return math.max<double>(0, base - marks);
  }

  /// Whether the line is a heading's: its hashes and the spaces after them
  /// are its prefix, hidden whole, where the space was left behind and set
  /// the title a space's width in.
  bool get _heading =>
      styled.tokens.any((token) => token.kind == TokenKind.headingMarker);

  /// Where the line's prefix ends: past its leading spaces, its quote
  /// marks, its list marker, its task box, a heading's hashes and the spaces
  /// between them. Zero for a line that is none of these, whose leading
  /// spaces are its own.
  int get _prefixEnd {
    if (shape.code != null) {
      // A code line's prefix is its quote's marks and, in an indented
      // block, the block's indent: the spaces past them are the code's.
      final text = styled.text;
      final marks = shape.quoteDepth > 0
          ? BlockParser.quotePrefixLength(
              text,
              shape.quoteDepth,
              shape.quoteIndent,
            )
          : 0;
      return shape.codeIndented
          ? marks + _codeIndentEnd(text.substring(marks))
          : marks;
    }
    if (!shape.listed && shape.quoteDepth == 0 && !_heading) return 0;
    final text = styled.text;
    var at = 0;
    var tokens = 0;
    while (true) {
      while (at < text.length &&
          (text.codeUnitAt(at) == 0x20 || text.codeUnitAt(at) == 0x09)) {
        at++;
      }
      while (tokens < styled.tokens.length &&
          styled.tokens[tokens].start < at) {
        tokens++;
      }
      if (tokens == styled.tokens.length) return at;
      final token = styled.tokens[tokens];
      if (token.start != at ||
          (token.kind != TokenKind.blockquote &&
              token.kind != TokenKind.listMarker &&
              token.kind != TokenKind.taskBox &&
              token.kind != TokenKind.headingMarker)) {
        return at;
      }
      at = token.end;
    }
  }

  /// Where an indented code line's indent ends: four columns in, a tab
  /// being all four, and no further — the spaces past them are the code's.
  static int _codeIndentEnd(String text) {
    var at = 0;
    var columns = 0;
    while (at < text.length && columns < 4) {
      final unit = text.codeUnitAt(at);
      if (unit == 0x09) {
        columns = 4;
      } else if (unit == 0x20) {
        columns++;
      } else {
        break;
      }
      at++;
    }
    return at;
  }

  /// Where the line's text is drawn from, past its prefix — hidden whole,
  /// or on the caret's line as written — in the paragraph's own shaping.
  ///
  /// Measured to the first glyph of the text, not to the end of the
  /// prefix: under an ambient letter spacing a paragraph's first glyph is
  /// drawn half a spacing in, and one after a hidden mark (which has none)
  /// is not, so a lazy line's text stood an eighth of a pixel right of its
  /// item's.
  double _textStart(BuildContext context, {required bool revealed}) {
    final end = _prefixEnd;
    final text = styled.text;
    final spans = <InlineSpan>[];
    if (!revealed) {
      if (end > 0) {
        spans.add(TextSpan(text: text.substring(0, end), style: _hiddenMarker));
      }
      return _glyphLeft(context, spans);
    }
    var at = 0;
    for (final token in styled.tokens) {
      if (token.start >= end) break;
      if (token.start > at) {
        spans.add(TextSpan(text: text.substring(at, token.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(token.start, token.end),
          style: nestedTokenStyle(token, syntax, dark: dark),
        ),
      );
      at = token.end;
    }
    if (at < end) spans.add(TextSpan(text: text.substring(at, end)));
    return _glyphLeft(context, spans);
  }

  /// Where a glyph set after [spans] is drawn, as the line's paragraph sets
  /// them: the paragraph's style is the line's over the ambient one, whose
  /// letter spacing moves a glyph as the paragraph moves it. The glyph is a
  /// probe — where it starts is the spacing's, not its own shape's.
  double _glyphLeft(BuildContext context, List<InlineSpan> spans) {
    final style = DefaultTextStyle.of(context).style
        .merge(_lineStyle(revealed: false));
    var length = 0;
    for (final span in spans) {
      length += (span as TextSpan).text?.length ?? 0;
    }
    final painter = TextPainter(
      text: TextSpan(
        children: <InlineSpan>[
          ...spans,
          const TextSpan(text: 'x'),
        ],
        style: style,
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: length, extentOffset: length + 1),
    );
    painter.dispose();
    return boxes.isEmpty ? 0 : boxes.first.left;
  }

  /// A table row too wide for the pane: its columns fitted to it, each cell
  /// wrapped inside its own, drawn as the read view draws the row — a
  /// paragraph per piece of every visual line, at its column's edge, behind
  /// the same grid, so every column shows and nothing is clipped.
  ///
  /// The pieces are fixed by the pane's width, so a piece is drawn at rest,
  /// its marks hidden: a mark that showed would stand the piece wider than
  /// the column it was fitted into. Editing is unchanged — the caret, a tap
  /// and the key table all work on the source, and the pieces' keys are what
  /// they are found through.
  Widget _wrappedRow(
    BuildContext context,
    LiveTableRow row,
    double indent, {
    required List<_Concealed> concealed,
    required List<InlineFormula> formulas,
  }) {
    final pad = theme.tableCellPadding;
    final style = _lineStyle(revealed: false);
    final strut = StrutStyle.fromTextStyle(style);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final children = <Widget>[];
    var y = pad.top;
    var at = 0;
    for (final visual in row.wrapped) {
      for (final piece in visual.pieces) {
        final key = pieceKey?.call(at) ?? GlobalKey();
        Widget paragraph = Text.rich(
          _pieceSpan(
            piece.start,
            piece.end,
            concealed: concealed,
            formulas: formulas,
          ),
          key: key,
          style: style,
          strutStyle: strut,
          // The piece is one visual line already: wrapping it again would
          // carry its remainder under the wrong column, as the row's own
          // paragraph did before it was fitted.
          softWrap: false,
        );
        final mine = <InlineFormula>[
          for (final formula in formulas)
            if (formula.start >= piece.start && formula.end <= piece.end)
              (
                start: formula.start - piece.start,
                end: formula.end - piece.start,
                box: formula.box,
                fontSize: formula.fontSize,
                color: formula.color,
              ),
        ];
        if (mine.isNotEmpty) {
          paragraph = CustomPaint(
            foregroundPainter: InlineMathPainter(
              paragraph: key,
              formulas: mine,
              devicePixelRatio: ratio,
            ),
            child: paragraph,
          );
        }
        final squiggles = _misspelledInPiece(piece.start, piece.end);
        if (squiggles.isNotEmpty) {
          paragraph = CustomPaint(
            foregroundPainter: SquigglePainter(
              paragraph: key,
              ranges: squiggles,
              color: misspelledColor,
            ),
            child: paragraph,
          );
        }
        final problems = _templateProblemsInPiece(piece.start, piece.end);
        if (problems.isNotEmpty) {
          paragraph = CustomPaint(
            foregroundPainter: SquigglePainter(
              paragraph: key,
              ranges: problems,
              color: misspelledColor,
            ),
            child: paragraph,
          );
        }
        children.add(
          Positioned(left: indent + piece.x, top: y, child: paragraph),
        );
        at++;
      }
      y += visual.height;
    }
    return CustomPaint(
      painter: LiveTableGridPainter(
        row: row,
        left: indent,
        color: theme.tableBorder,
      ),
      child: SizedBox(
        width: double.infinity,
        height: y + pad.bottom,
        child: Stack(children: children),
      ),
    );
  }

  /// The words of [start, end) of the line the spelling flags, as offsets
  /// from the piece's own start: the line's ranges, clipped to the piece.
  List<TextRange> _misspelledInPiece(int start, int end) => <TextRange>[
    for (final range in _unjudged())
      if (range.end > start && range.start < end)
        TextRange(
          start: range.start < start ? 0 : range.start - start,
          end: range.end > end ? end - start : range.end - start,
        ),
  ];

  /// The template problems of `[start, end)` of the line, as offsets from the
  /// piece's own start: the line's ranges, clipped to the piece.
  List<TextRange> _templateProblemsInPiece(int start, int end) => <TextRange>[
    for (final range in templateProblems)
      if (range.end > start && range.start < end)
        TextRange(
          start: range.start < start ? 0 : range.start - start,
          end: range.end > end ? end - start : range.end - start,
        ),
  ];

  /// The span of `[start, end)` of the line's source, for one piece of a
  /// table row laid out in fitted columns: the line's own runs and what is
  /// drawn in place of them, cut to the piece.
  TextSpan _pieceSpan(
    int start,
    int end, {
    required List<_Concealed> concealed,
    required List<InlineFormula> formulas,
  }) {
    final spans = <InlineSpan>[];
    if (end <= start) return TextSpan(children: spans);
    final marks = <_Concealed>[
      for (final hidden in concealed)
        if (hidden.$2 > start && hidden.$1 < end)
          (
            hidden.$1 < start ? start : hidden.$1,
            hidden.$2 > end ? end : hidden.$2,
            hidden.$3,
            whole: hidden.whole,
          ),
    ];
    final ink = (
      start: start,
      end: end,
      selected: _clipTo(selected, start, end),
      composing: _clipTo(composing, start, end),
      found: <(int, int, bool)>[
        for (final match in found)
          if (match.$2 > start && match.$1 < end)
            (
              match.$1 < start ? start : match.$1,
              match.$2 > end ? end : match.$2,
              match.$3,
            ),
      ],
    );
    var at = start;
    for (final token in styled.tokens) {
      if (token.end <= at || token.start >= end) continue;
      final from = token.start < at ? at : token.start;
      final to = token.end > end ? end : token.end;
      if (from > at) _add(spans, at, from, null, marks, ink);
      _add(
        spans,
        from,
        to,
        hidden(token, revealed: false)
            ? _hiddenMarker
            : nestedTokenStyle(token, syntax, dark: dark),
        marks,
        ink,
      );
      at = to;
    }
    if (at < end) _add(spans, at, end, null, marks, ink);
    return TextSpan(children: spans);
  }

  /// [range] clipped to `[start, end)`, or null when it falls outside.
  static (int, int)? _clipTo((int, int)? range, int start, int end) {
    if (range == null || range.$2 <= start || range.$1 >= end) return null;
    return (
      range.$1 < start ? start : range.$1,
      range.$2 > end ? end : range.$2,
    );
  }

  /// The line's tokens as styled runs. A token's override never changes the
  /// size
  /// or the height, so a line keeps the surface's metrics whatever it contains
  /// (`highlight_style.dart`).
  TextSpan _span({
    required bool revealed,
    (int, int)? run,
    List<_Concealed> concealed = const <_Concealed>[],
  }) {
    if (hideMarkers && shape.code != null && shape.quoteDepth > 0) {
      return _quotedCode(revealed: revealed, concealed: concealed);
    }
    final spans = <InlineSpan>[];
    // A hidden line's prefix is hidden whole, its spaces with its marks: the
    // text then starts at the indent, where its wrapped rows start too.
    final prefix = hideMarkers && !revealed ? _prefixEnd : 0;
    if (prefix > 0) _add(spans, 0, prefix, _hiddenMarker, concealed);
    var at = prefix;
    // The runs are the tokenizer's; the selection cuts them where it starts and
    // ends, so a highlighted range is the same text with a background.
    for (final token in styled.tokens) {
      if (token.end <= prefix) continue;
      if (token.start > at) {
        _add(spans, at, token.start, null, concealed);
      }
      // A token the prefix cuts into — an indented code line's, which is
      // the whole line — is drawn from where the prefix ends.
      final from = token.start < at ? at : token.start;
      // Code, in `live`, is coloured as the read view colours it: by its
      // block's language, or not at all.
      if (hideMarkers && token.kind == TokenKind.codeBlock) {
        final runs = codeRuns;
        if (runs == null) {
          _add(spans, from, token.end, null, concealed);
        } else {
          var cursor = from;
          for (final run in runs) {
            final start = run.start < cursor ? cursor : run.start;
            final end = run.end > token.end ? token.end : run.end;
            if (end <= start) continue;
            if (start > cursor) _add(spans, cursor, start, null, concealed);
            _add(spans, start, end, run.style, concealed);
            cursor = end;
          }
          if (cursor < token.end) {
            _add(spans, cursor, token.end, null, concealed);
          }
        }
        at = token.end;
        continue;
      }
      _add(
        spans,
        from,
        token.end,
        hidden(token, revealed: revealed, run: run)
            ? _hiddenMarker
            : nestedTokenStyle(token, syntax, dark: dark),
        concealed,
      );
      at = token.end;
    }
    if (at < styled.text.length) {
      _add(spans, at, styled.text.length, null, concealed);
    }
    return TextSpan(children: spans);
  }

  /// A line of a code block inside a quote.
  ///
  /// The styler reads a quote's lines as the quote's prose, so their tokens
  /// say nothing of the code in it: the quote's marks are drawn as its
  /// marks, and the rest as code — a fence hidden as a fence is, the code
  /// in its block's colours ([codeRuns], whose offsets start past the
  /// marks).
  TextSpan _quotedCode({
    required bool revealed,
    required List<_Concealed> concealed,
  }) {
    final text = styled.text;
    final spans = <InlineSpan>[];
    final marks = BlockParser.quotePrefixLength(
      text,
      shape.quoteDepth,
      shape.quoteIndent,
    );
    var at = 0;
    if (!revealed) {
      final hidden = shape.codeFence ? text.length : _prefixEnd;
      _add(spans, 0, hidden, _hiddenMarker, concealed);
      at = hidden;
    } else {
      for (final token in styled.tokens) {
        if (token.start >= marks) break;
        if (token.start > at) _add(spans, at, token.start, null, concealed);
        final end = token.end > marks ? marks : token.end;
        _add(
          spans,
          token.start,
          end,
          nestedTokenStyle(token, syntax, dark: dark),
          concealed,
        );
        at = end;
      }
      if (at < marks) _add(spans, at, marks, null, concealed);
      at = marks;
    }
    for (final run in codeRuns ?? const <CodeRun>[]) {
      final start = marks + run.start < at ? at : marks + run.start;
      final end = marks + run.end > text.length ? text.length : marks + run.end;
      if (end <= start) continue;
      if (start > at) _add(spans, at, start, null, concealed);
      _add(spans, start, end, run.style, concealed);
      at = end;
    }
    if (at < text.length) _add(spans, at, text.length, null, concealed);
    return TextSpan(children: spans);
  }

  /// Whether [token]'s marker is hidden rather than drawn.
  ///
  /// Policy A of `docs/records/unified-surface.md` §8.6.2 — the markers are hidden
  /// everywhere except where the writer is — with the per-word refinement D9
  /// asks for. The two granularities are the two things a marker can be the
  /// shape of:
  ///
  /// * **a structural mark** — a quote's `>`, a list's `-`, a heading's hashes,
  ///   a fence — is the shape of the *line*, so it is drawn when the caret is
  ///   anywhere on that line ([revealed]). A writer in a heading's title has to
  ///   see the hashes, or a heading is indistinguishable from a bold line.
  /// * **an inline mark** — a `**`, a backtick, a link's brackets — is the
  ///   shape of one *word*, so it is drawn only when it is inside the run the
  ///   caret is in ([run]). The run is the caret's non-whitespace run, markers
  ///   and all (`runAround`), so `**bold**` reveals *both* of its pairs and not
  ///   just the one the caret stands next to, and a plain word in a paragraph
  ///   full of links reveals none of them.
  ///
  /// The reveal is a **style**, never the text: the marker keeps its offset and
  /// its string, so the caret, the hit test and the selection know nothing
  /// about it, and the paragraph's cache key does not move when the caret does.
  bool hidden(Token token, {required bool revealed, (int, int)? run}) {
    if (!hideMarkers) return false;
    if (!token.marker && !isSourceMarker(token.kind)) return false;
    if (isSourceMarker(token.kind)) return !revealed;
    if (run == null) return true;
    return token.start < run.$1 || token.end > run.$2;
  }

  /// The misspelled words to underline: all of them but the one being
  /// composed, which is not judged yet — its underline is the IME's.
  List<TextRange> _unjudged() {
    final typing = composing;
    if (typing == null) return misspelled;
    return <TextRange>[
      for (final word in misspelled)
        if (word.end <= typing.$1 || word.start >= typing.$2) word,
    ];
  }

  /// The paragraph with the wavy marks painted over it rather than written
  /// into its runs: a style has one decoration, and a wavy underline there
  /// took a struck word's strike.
  ///
  /// The template checker's problems and the spelling's words are two layers
  /// of the same shape, so a line that has both shows both — the checker's
  /// mark is not lost under the spelling's, nor the other way round
  /// (T-TPL-09).
  Widget _withSquiggles(Widget paragraph) {
    var marked = paragraph;
    if (templateProblems.isNotEmpty) {
      marked = CustomPaint(
        foregroundPainter: SquigglePainter(
          paragraph: paragraphKey,
          ranges: templateProblems,
          color: misspelledColor,
        ),
        child: marked,
      );
    }
    if (misspelled.isNotEmpty) {
      marked = CustomPaint(
        foregroundPainter: SquigglePainter(
          paragraph: paragraphKey,
          ranges: _unjudged(),
          color: misspelledColor,
        ),
        child: marked,
      );
    }
    return marked;
  }

  /// Adds `[start, end)` to [spans], cut at the selection's and the composing
  /// range's edges: the selected part carries the highlight, the composed part
  /// the underline, and the rest keeps the run's own style.
  void _add(
    List<InlineSpan> spans,
    int start,
    int end,
    TextStyle? style, [
    List<_Concealed> concealed = const <_Concealed>[],
    _Ink? ink,
  ]) {
    // A piece of a table row laid out in fitted columns draws the line's
    // selection, its composition and the find bar's matches clipped to the
    // piece; every other line draws them as they are.
    final chosen = ink == null ? selected : ink.selected;
    final written = ink == null ? composing : ink.composing;
    final matches = ink == null ? found : ink.found;
    final cuts = <int>{start, end};
    for (final range in <(int, int)?>[
      chosen,
      written,
      for (final match in matches) (match.$1, match.$2),
      for (final hidden in concealed) (hidden.$1, hidden.$2),
    ]) {
      if (range == null) continue;
      if (range.$1 > start && range.$1 < end) cuts.add(range.$1);
      if (range.$2 > start && range.$2 < end) cuts.add(range.$2);
    }
    final points = cuts.toList()..sort();
    for (var at = 0; at < points.length - 1; at++) {
      final from = points[at];
      final to = points[at + 1];
      bool inside((int, int)? range) =>
          range != null && from >= range.$1 && to <= range.$2;
      // What `live` draws instead of its source — a picture, a formula — is
      // hidden as a marker is: there, taking no room.
      var piece = style;
      var whole = false;
      for (final hidden in concealed) {
        if (inside((hidden.$1, hidden.$2))) {
          piece = hidden.$3;
          whole = hidden.whole;
        }
      }
      if (inside(chosen)) {
        piece = (piece ?? const TextStyle()).copyWith(
          background: Paint()..color = _selectionColor,
        );
      }
      // A match is drawn over the selection: the current one *is* the
      // selection, and it has to read as the one the bar is on.
      for (final match in matches) {
        if (from >= match.$1 && to <= match.$2) {
          piece = (piece ?? const TextStyle()).copyWith(
            background: Paint()
              ..color = match.$3 ? _currentMatchColor : _matchColor,
          );
        }
      }
      if (inside(written)) {
        piece = (piece ?? const TextStyle()).copyWith(
          decoration: TextDecoration.underline,
        );
      }
      spans.add(
        TextSpan(
          text: whole
              ? unbrokenSource(to - from)
              : styled.text.substring(from, to),
          style: piece,
        ),
      );
    }
  }
}

/// A stretch of a line `live` draws something else in place of: its range,
/// the style that hides it, and whether it has to stay on one row — the room
/// a formula is painted over does.

typedef _Concealed = (int, int, TextStyle, {bool whole});

/// The ranges a piece of a table row laid out in fitted columns draws its
/// selection, its composition and the find bar's matches in: the line's own,
/// clipped to the piece's source.
typedef _Ink = ({
  int start,
  int end,
  (int, int)? selected,
  (int, int)? composing,
  List<(int, int, bool)> found,
});

/// One paragraph a line is drawn in: the key it is built with, where its
/// source starts on the line, and where it stands in the line's box — away
/// from the left edge and below the first visual line for a fragment of a
/// table row laid out in fitted columns.
typedef SourcePiece = ({GlobalKey key, int start, int end, double x, double y});

/// What a line's gutter shows for folding.
enum SourceFoldMark {
  /// Nothing: not a heading, or nothing under it to fold.
  none,

  /// A section that can fold.
  open,

  /// A folded section.
  closed,
}

/// The style a hidden marker is drawn with ([liveHiddenMarker]).
const TextStyle _hiddenMarker = liveHiddenMarker;

/// Whether [kind] is a *structural* marker: a mark that is the shape of the
/// line rather than of a word.
///
/// A quote's `>`, a list's `-`, a heading's hashes, a fence and its language,
/// a task's box — the marks `SourceStyler._structure` lays down at the start of
/// a line. They are revealed with the line. Everything else the surface hides
/// is an *inline* mark, carried by `Token.marker` and revealed with the
/// caret's own run (`hidden`).
bool isSourceMarker(TokenKind kind) => switch (kind) {
  TokenKind.headingMarker ||
  TokenKind.listMarker ||
  TokenKind.blockquote ||
  TokenKind.codeFence ||
  TokenKind.codeLanguage ||
  // A thematic break is all marker: `live` draws its rule instead.
  TokenKind.horizontalRule ||
  TokenKind.taskBox => true,
  _ => false,
};

/// The colour a selected run is painted with.
const Color _selectionColor = Color(0x553B82F6);

/// The colours the find bar's matches are painted with: every match, and the
/// one the bar is on.
const Color _matchColor = Color(0x55FFB300);
const Color _currentMatchColor = Color(0xAAFF8F00);

/// The gap between the line numbers and the text ([lineNumbersGap]).
const double _gutterGap = lineNumbersGap;
