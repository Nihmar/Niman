import 'dart:ui' show BoxHeightStyle;

import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:copist/src/editor/row_text_metrics.dart';
import 'package:copist/src/editor/styled_runs.dart';
import 'package:flutter/material.dart';

/// Read-only, virtualized text view over a [RowModel].
///
/// Renders only the visual rows inside the viewport (plus a little sliver
/// cache): a frame's build cost is O(visible rows), flat in the buffer size.
/// When [highlight] is given, each visible row is painted with the styled
/// runs of its tokens (M2a E7); otherwise the row's text is plain.
final class VirtualizedTextView extends StatelessWidget {
  /// Creates the view over [model], optionally highlighting with [highlight].
  const VirtualizedTextView({
    required this.model,
    this.highlight,
    this.scrollController,
    this.physics,
    super.key,
  });

  /// The wrapped buffer this view renders.
  final RowModel model;

  /// The styled document to paint from, or null for plain text. The caller
  /// keeps it in sync with the buffer; this view only reads the visible
  /// lines (never the whole document).
  final HighlightDocument? highlight;

  /// Optional scroll controller (scroll sync and caret jumps).
  final ScrollController? scrollController;

  /// Optional scroll physics: the editor passes a non-scrollable physics
  /// while a select-drag is locked, so the list cannot scroll under the
  /// extending selection (M2a round-5 S1). Null keeps the default behavior.
  final ScrollPhysics? physics;

  /// Row height in px. Integer on purpose: 12 * 1.75 is exactly 21.0 in
  /// double, so `itemExtent * rowCount` stays exact at any buffer size
  /// (fractional extents trip the sliver's even-multiple assertion).
  static const double rowHeight = 21;

  /// Left inset of each row's text, in px. The caret geometry must use the
  /// same value so the caret lands on the glyphs.
  static const double leftPadding = 12;

  /// The row text style. Public so the tap hit test and the caret
  /// geometry measure in exactly what the rows paint (M2a round-4 R2).
  static const TextStyle rowTextStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.75,
  );


  /// The advance width of one character in [rowTextStyle], measured with
  /// the same painter the [Text] rows use, so a caret computed from it
  /// aligns with the glyphs. Monospace: every character has this width.
  /// (Still used for the viewport→column-width fit; per-glyph x comes
  /// from [RowTextMetrics], which measures the row slice itself.)
  static double measureCharWidth() {
    final painter = TextPainter(
      text: const TextSpan(text: '0', style: rowTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  /// The caret height for [rowTextStyle]: one glyph's strut box (the font's
  /// ascent + descent, no line-height leading) — the same measure the
  /// platform's own caret uses (`BoxHeightStyle.strut`). The caret spans
  /// that, centered in the row, not the full [rowHeight] (which read as too
  /// tall on device, M2a on-device round 3).
  static double measureCaretHeight() {
    final painter = TextPainter(
      text: const TextSpan(text: 'M', style: rowTextStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final box = painter.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 1),
      boxHeightStyle: BoxHeightStyle.strut,
    ).single;
    return box.bottom - box.top;
  }

  @override
  Widget build(BuildContext context) {
    final columns = model.columns;
    final highlight = this.highlight;
    return CustomScrollView(
      controller: scrollController,
      physics: physics,
      slivers: [
        SliverFixedExtentList(
          itemExtent: rowHeight,
          delegate: SliverChildBuilderDelegate(
            (context, row) {
              final (line, startCol) = model.lineAndStartColumn(row);
              final end = startCol + columns;
              // The grid owns its metrics: rows ignore the system text
              // scaler (M2a round-4 R2 — a minimum-size scaler shrank the
              // glyphs under the fixed 21 px grid, parking the caret
              // mid-glyph and drifting taps). App chrome outside the
              // editor keeps respecting the scaler.
              const scaler = TextScaler.noScaling;
              return Padding(
                padding: const EdgeInsets.only(left: leftPadding),
                child: highlight == null
                    ? Text(
                        model.rowSliceText(row),
                        style: rowTextStyle,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                        textScaler: scaler,
                      )
                    : Text.rich(
                        TextSpan(
                          style: rowTextStyle,
                          children: styledRuns(
                            highlight.lineAt(line),
                            startCol,
                            end,
                          ),
                        ),
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                        textScaler: scaler,
                      ),
              );
            },
            childCount: model.rowCount,
          ),
        ),
      ],
    );
  }
}
