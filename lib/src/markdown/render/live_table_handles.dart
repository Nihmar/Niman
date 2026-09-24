/// The two `+` beside a table in `live`: a column at its right edge, a row
/// at its foot (#261).
library;

import 'package:flutter/material.dart';

/// Draws the handles round [grid], a table's grid in the coordinates of
/// the overlay it is drawn in, kept inside [clip] — the note's own box, so
/// a table half scrolled away does not grow handles over the toolbar.
///
/// They take no room in the note: drawn over it, beside and under the
/// grid, so the page is the read view's whether they show or not. A
/// pointer on them keeps them up ([onHover]), since the note under them is
/// no longer the table.
final class LiveTableHandles extends StatelessWidget {
  /// Creates the handles.
  const new({
    required this.grid,
    required this.clip,
    required this.color,
    required this.addRowLabel,
    required this.addColumnLabel,
    required this.onAddRow,
    required this.onAddColumn,
    required this.onHover,
    super.key,
  });

  /// The table's grid.
  final Rect grid;

  /// Where the handles may be drawn.
  final Rect clip;

  /// The grid's colour: the handles are drawn in it.
  final Color color;

  /// The row handle's tooltip.
  final String addRowLabel;

  /// The column handle's tooltip.
  final String addColumnLabel;

  /// Adds a row at the table's foot.
  final VoidCallback onAddRow;

  /// Adds a column at the table's right edge.
  final VoidCallback onAddColumn;

  /// Whether the pointer is over a handle.
  final ValueChanged<bool> onHover;

  /// How thick a handle is, and how far from the grid it stands.
  static const double thickness = 16;
  static const double _gap = 2;

  @override
  Widget build(BuildContext context) {
    final column = Rect.fromLTWH(
      grid.right + _gap,
      grid.top,
      thickness,
      grid.height,
    );
    final row = Rect.fromLTWH(
      grid.left,
      grid.bottom + _gap,
      grid.width,
      thickness,
    );
    return Stack(
      children: [
        Positioned.fromRect(
          rect: clip,
          child: ClipRect(
            child: Stack(
              children: [
                _handle(
                  column.shift(-clip.topLeft),
                  addColumnLabel,
                  onAddColumn,
                  const Key('table-add-column'),
                ),
                _handle(
                  row.shift(-clip.topLeft),
                  addRowLabel,
                  onAddRow,
                  const Key('table-add-row'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _handle(Rect rect, String label, VoidCallback onTap, Key key) =>
      Positioned.fromRect(
        rect: rect,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => onHover(true),
          onExit: (_) => onHover(false),
          child: Tooltip(
            message: label,
            child: Material(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                key: key,
                borderRadius: BorderRadius.circular(4),
                onTap: onTap,
                child: Icon(Icons.add, size: 14, color: color),
              ),
            ),
          ),
        ),
      );
}
