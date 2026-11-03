/// One line of a table as `live` lays it out, and the pieces it is drawn in.
library;

/// A stretch of a row's source drawn as nothing `width` wide: the pipes and
/// the spaces between two cells' text.
typedef LiveTableGap = ({int start, int end, double width});

/// One cell's text on one visual line of a row laid out in fitted columns:
/// the stretch of the row's source it holds, and where its left edge stands
/// from the row's text's left edge.
typedef LiveTablePiece = ({int start, int end, double x});

/// One visual line of a row laid out in fitted columns: the cells' pieces on
/// it, left to right, and how tall it is.
typedef LiveTableLine = ({List<LiveTablePiece> pieces, double height});

/// One line of a table, as `live` lays it out.
final class LiveTableRow {
  /// Creates a row; [_wrapped] is worked out the first time a frame asks for
  /// its pieces, so a row no frame draws is never measured.
  new(
    this._wrapped, {
    required this.edges,
    required this.gaps,
    required this.header,
    required this.delimiter,
    required this.last,
  });

  /// Where each column starts, from the text's left edge, and where the
  /// table ends: one more than there are columns.
  final List<double> edges;

  /// The stretches of the line drawn as nothing, and how wide.
  final List<LiveTableGap> gaps;

  final List<LiveTableLine> Function() _wrapped;
  List<LiveTableLine>? _wrappedValue;

  /// The line's visual lines when the table was too wide for the pane and
  /// its columns were fitted to it: one entry a visual line, top to bottom.
  /// Empty for a line drawn as one paragraph — a table that fits, or the
  /// delimiter row, which takes no room either way.
  ///
  /// Worked out the first time a frame draws the row: a row scrolled out of
  /// view, whose pieces no frame needs, is not measured at all (#494).
  List<LiveTableLine> get wrapped => _wrappedValue ??= _wrapped();

  /// Whether the line is the table's header, set as the read view sets it.
  final bool header;

  /// Whether the line is the delimiter row, which takes no room.
  final bool delimiter;

  /// Whether the line is the table's last: the grid's bottom is under it.
  final bool last;
}
