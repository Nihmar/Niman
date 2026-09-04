import 'package:copist/src/editor/row_model.dart';
import 'package:flutter/material.dart';

/// Read-only, virtualized text view over a [RowModel].
///
/// Renders only the visual rows inside the viewport (plus a little sliver
/// cache): a frame's build cost is O(visible rows), flat in the buffer size.
/// This is the baseline the line-based editor is built on (M2a E2); caret,
/// selection and highlighting land on top in later milestones.
final class VirtualizedTextView extends StatelessWidget {
  /// Creates the view over [model].
  const VirtualizedTextView({
    required this.model,
    this.scrollController,
    super.key,
  });

  /// The wrapped buffer this view renders.
  final RowModel model;

  /// Optional scroll controller (scroll sync and caret jumps).
  final ScrollController? scrollController;

  /// Row height in px. Integer on purpose: 12 * 1.75 is exactly 21.0 in
  /// double, so `itemExtent * rowCount` stays exact at any buffer size
  /// (fractional extents trip the sliver's even-multiple assertion).
  static const double rowHeight = 21;

  static const TextStyle _style = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.75,
  );

  @override
  Widget build(BuildContext context) {
    final buffer = model.buffer;
    final columns = model.columns;
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
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  text.substring(
                    startCol,
                    end > text.length ? text.length : end,
                  ),
                  style: _style,
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
