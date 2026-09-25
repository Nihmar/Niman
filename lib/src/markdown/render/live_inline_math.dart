/// Inline formulas in `live` mode — `$x^2$` in a sentence, typeset — without a
/// widget in the paragraph.
///
/// A `WidgetSpan` is one code unit the source does not have, so every offset
/// after it would be off by one: the caret, the hit test, the selection, the
/// spelling, the IME. §8.6.0 point 3 of `docs/records/unified-surface.md` accepted
/// that and called for a correction table. This keeps the source instead,
/// every character where it was, and makes the formula's *source* take the
/// formula's room: its characters are hidden, and spaced so that together
/// they are exactly as wide as the typeset formula and, where it is taller
/// than the line, as tall. The formula is painted over that room. Nothing
/// measures anything but text, so nothing needs correcting.
///
/// With the caret in the formula's word, the source is shown as written — the
/// reveal every other construct follows.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:katex/katex.dart' show boxSizePx;
import 'package:katex_dart/katex_dart.dart' show BoxNode;
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_raster.dart';

/// An inline formula on a line: its source range, markers included, and its
/// TeX.
typedef InlineFormulaSource = ({int start, int end, String tex, bool display});

/// The inline formulas on a line whose text is [text] and whose tokens are
/// [tokens]: each `$…$` (or `$$…$$` inside prose), markers and all.
List<InlineFormulaSource> inlineFormulasOf(String text, List<Token> tokens) {
  final out = <InlineFormulaSource>[];
  var at = 0;
  while (at < tokens.length) {
    final open = tokens[at];
    if (open.kind != TokenKind.mathInline || !open.marker) {
      at++;
      continue;
    }
    // A formula is its opening marker, its TeX and its closing marker, one
    // run after the other.
    var end = at + 1;
    while (end < tokens.length &&
        tokens[end].kind == TokenKind.mathInline &&
        tokens[end].start == tokens[end - 1].end &&
        !tokens[end].marker) {
      end++;
    }
    if (end >= tokens.length ||
        tokens[end].kind != TokenKind.mathInline ||
        !tokens[end].marker ||
        end == at + 1) {
      at++;
      continue;
    }
    final close = tokens[end];
    final tex = text.substring(open.end, close.start).trim();
    if (tex.isNotEmpty) {
      out.add((
        start: open.start,
        end: close.end,
        tex: tex,
        display: open.end - open.start >= 2,
      ));
    }
    at = end + 1;
  }
  return out;
}

/// An inline formula ready to draw: where its source is, its box, and the
/// size and colour it is set in.
typedef InlineFormula = ({
  int start,
  int end,
  BoxNode box,
  double fontSize,
  Color? color,
});

/// The formulas of [sources] that [cache] has typeset, set among [text];
/// the others are asked for, and stay their source until they land.
List<InlineFormula> typesetInline(
  List<InlineFormulaSource> sources,
  MathCache cache,
  TextStyle text,
) {
  final style = mathStyleFor(text);
  final out = <InlineFormula>[];
  for (final source in sources) {
    final box = cache.boxFor(source.tex, displayMode: source.display);
    if (box == null) {
      if (!cache.isError(source.tex, displayMode: source.display)) {
        cache.ensure(source.tex, displayMode: source.display).ignore();
      }
      continue;
    }
    out.add((
      start: source.start,
      end: source.end,
      box: box,
      fontSize: style.fontSize,
      color: style.color,
    ));
  }
  return out;
}

/// The style of [formula]'s source characters: invisible, and spaced so that
/// together they are as wide as the formula and at least as tall as
/// [lineHeight] — taller when the formula is.
TextStyle spacerStyleFor(InlineFormula formula, double lineHeight) {
  final size = boxSizePx(formula.box, formula.fontSize);
  final ascent = formula.box.height * formula.fontSize;
  final depth = formula.box.depth * formula.fontSize;
  final count = formula.end - formula.start;
  // Room split evenly above and below the baseline, so the taller of the
  // formula's two halves decides it.
  final tall = math.max(lineHeight, 2 * math.max(ascent, depth));
  return TextStyle(
    fontSize: _tiny,
    color: const Color(0x00000000),
    letterSpacing: count == 0 ? 0 : size.width / count,
    height: tall / _tiny,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

const double _tiny = 0.01;

/// What a formula's source of [length] code units is laid out as: as many
/// code units, none of them a place a row may end at.
///
/// The source has spaces, and a row that ended at one split the room in two
/// while the formula was painted whole where the room starts — past the
/// margin, with a gap where the rest of the room went. Its characters are
/// invisible, so which ones they are is the layout's business alone; every
/// offset stays where it was.
String unbrokenSource(int length) => 'x' * length;

/// Paints [formulas] over the room their source takes in [paragraph]'s
/// layout, each on the baseline its room sits on.
final class InlineMathPainter extends CustomPainter {
  /// Creates the painter.
  const new({
    required this.paragraph,
    required this.formulas,
    this.devicePixelRatio = 1,
  });

  /// The key of the text whose paragraph holds the formulas' source.
  final GlobalKey paragraph;

  /// The formulas to draw.
  final List<InlineFormula> formulas;

  /// The screen's pixels per logical pixel, for a formula drawn through an
  /// image (`paintMath`).
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final box = paragraph.currentContext?.findRenderObject();
    if (box is! RenderParagraph || !box.hasSize) return;
    for (final formula in formulas) {
      final boxes = box.getBoxesForSelection(
        TextSelection(baseOffset: formula.start, extentOffset: formula.end),
      );
      if (boxes.isEmpty) continue;
      final room = boxes.first;
      // The spacer's glyphs are a hundredth of a pixel tall: their tight box
      // is the baseline.
      final baseline = (room.top + room.bottom) / 2;
      final ascent = formula.box.height * formula.fontSize;
      canvas
        ..save()
        ..translate(room.left, baseline - ascent);
      paintMath(
        canvas,
        boxSizePx(formula.box, formula.fontSize),
        formula.box,
        fontSize: formula.fontSize,
        color: formula.color ?? const Color(0xFF000000),
        devicePixelRatio: devicePixelRatio,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(InlineMathPainter oldDelegate) =>
      oldDelegate.paragraph != paragraph ||
      oldDelegate.devicePixelRatio != devicePixelRatio ||
      !_same(oldDelegate.formulas, formulas);

  static bool _same(List<InlineFormula> a, List<InlineFormula> b) {
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at].start != b[at].start ||
          a[at].end != b[at].end ||
          !identical(a[at].box, b[at].box) ||
          a[at].fontSize != b[at].fontSize ||
          a[at].color != b[at].color) {
        return false;
      }
    }
    return true;
  }
}
