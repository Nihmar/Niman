import 'package:flutter/painting.dart';

/// Per-row text metrics over the exact string a visual row renders (M2a
/// round-4 R2).
///
/// The editor's historical model maps x ↔ column through one measured
/// `charWidth` (`x / charWidth`), which is only exact while the rendered
/// glyphs match the measurement. Two things break that on device: a system
/// text scaler ≠ 1.0 (rows inherit it; the measurement does not), and
/// fallback fonts for math/Unicode spans (advances ≠ the monospace grid).
/// These helpers measure the row slice itself, so they agree with the
/// painted glyphs by construction.
///
/// Tap-only cost: one short-string layout per call (O(row length)), never
/// on the per-frame paint path — the selection/composing spans stay on the
/// monospace grid (see `CaretGeometry.selectionRects`).
final class RowTextMetrics {
  /// Creates metrics over rows painted in [style] (the view's row style,
  /// unscaled — the grid owns its metrics, so rows pin
  /// `TextScaler.noScaling` and the painter matches it here).
  const RowTextMetrics({required this.style});

  /// The row style the metrics measure in.
  final TextStyle style;

  /// The x (from the row's first glyph) of the caret before column
  /// [colInRow] of [rowText] — the painter's own caret measure, so the
  /// drawn caret lands on the glyphs, not between them.
  double caretX(String rowText, int colInRow) {
    final clamped = colInRow.clamp(0, rowText.length);
    return _painter(rowText)
        .getOffsetForCaret(TextPosition(offset: clamped), Rect.zero)
        .dx;
  }

  /// The column of [rowText] under pixel [x] (from the row's first glyph),
  /// clamped to the row length [maxCol]: the caret boundary nearest [x].
  ///
  /// Measured from the same caret boundaries [caretX] paints, on one layout
  /// — so a tap and the caret it places agree by construction. (The previous
  /// `getPositionForOffset(...).offset` is a *character* index, not a caret
  /// boundary: at a row's trailing edge it resolves to the last character
  /// instead of past it, parking the caret behind the last char of long
  /// rows on device.)
  int columnForX(String rowText, double x, int maxCol) {
    final clampedMax = maxCol.clamp(0, rowText.length);
    if (clampedMax <= 0 || x <= 0) return 0;
    final painter = _painter(rowText);
    var best = 0;
    var bestDist = (painter
            .getOffsetForCaret(const TextPosition(offset: 0), Rect.zero)
            .dx -
        x)
        .abs();
    for (var col = 1; col <= clampedMax; col++) {
      final dist = (painter
                  .getOffsetForCaret(
                    TextPosition(offset: col),
                    Rect.zero,
                  )
                  .dx -
              x)
          .abs();
      // Ties (an exact mid-glyph tap) round up, like the grid's
      // `(x / charWidth).round()`.
      if (dist <= bestDist) {
        bestDist = dist;
        best = col;
      }
    }
    return best;
  }

  TextPainter _painter(String rowText) {
    return TextPainter(
        text: TextSpan(text: rowText, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )
      ..layout();
  }
}
