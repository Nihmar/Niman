/// One line of a table as `live` measured it.
library;

/// A cell's text as it is drawn: how wide its glyphs are, how wide its widest
/// unbreakable run is (the floor a fitted column keeps), how many characters
/// of hidden marks it has, and how many of them come before its first glyph.
typedef LiveTableMeasured = ({
  double visible,
  double least,
  int hidden,
  int lead,
});

/// One line of a table as measured: its cells, and each one's width.
///
/// A line's measurements are a function of its text and of what the tables
/// are measured with (the theme, the scaler, the tokenizer), so they are kept
/// under the text and outlive the revision that measured them: an edit
/// somewhere else in the note, or in one cell, finds every other row already
/// measured (#494). Only a row at rest is shared — the caret's row shows a
/// run's marks and is measured on its own.
final class LiveTableRowWork {
  /// Creates a line's measurements: its [cells] and their [widths].
  new(this.cells, this.widths, {required this.delimiter});

  /// The cells' text ranges, trimmed as `cellsOf` trims them.
  final List<(int, int)> cells;

  /// Whether the line is the delimiter row.
  final bool delimiter;

  /// Per cell, how wide its text draws.
  final List<LiveTableMeasured> widths;
}
