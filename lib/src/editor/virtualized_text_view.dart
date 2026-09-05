import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/editor/row_model.dart';
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

  /// Row height in px. Integer on purpose: 12 * 1.75 is exactly 21.0 in
  /// double, so `itemExtent * rowCount` stays exact at any buffer size
  /// (fractional extents trip the sliver's even-multiple assertion).
  static const double rowHeight = 21;

  /// Left inset of each row's text, in px. The caret geometry must use the
  /// same value so the caret lands on the glyphs.
  static const double leftPadding = 12;

  static const TextStyle _style = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.75,
  );

  /// The advance width of one character in [_style], measured with the same
  /// painter the [Text] rows use, so a caret computed from it aligns with the
  /// glyphs. Monospace: every character has this width.
  static double measureCharWidth() {
    final painter = TextPainter(
      text: const TextSpan(text: '0', style: _style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final buffer = model.buffer;
    final columns = model.columns;
    final highlight = this.highlight;
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverFixedExtentList(
          itemExtent: rowHeight,
          delegate: SliverChildBuilderDelegate(
            (context, row) {
              final (line, startCol) = model.lineAndStartColumn(row);
              final text = buffer.lineAt(line);
              final end = startCol + columns;
              return Padding(
                padding: const EdgeInsets.only(left: leftPadding),
                child: highlight == null
                    ? Text(
                        text.substring(
                          startCol,
                          end > text.length ? text.length : end,
                        ),
                        style: _style,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      )
                    : Text.rich(
                        TextSpan(
                          style: _style,
                          children: styledRuns(
                            highlight.lineAt(line),
                            startCol,
                            end,
                          ),
                        ),
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        maxLines: 1,
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
