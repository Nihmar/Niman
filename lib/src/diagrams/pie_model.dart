/// The pie-chart model (#530): a title, its slices and whether their values
/// are written beside them.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// One slice: its label and its value.
final class PieSlice {
  /// Creates a slice.
  const new({required this.label, required this.value});

  /// The text in the legend.
  final String label;

  /// Its size, relative to the others; never negative.
  final double value;
}

/// A parsed pie chart.
final class PieChart {
  /// Creates a pie chart.
  const new({required this.slices, this.title, this.showData = false});

  /// The slices, in the order they were written.
  final List<PieSlice> slices;

  /// The title drawn above the pie, or null.
  final String? title;

  /// Whether the legend writes each slice's value after its label
  /// (`pie showData`).
  final bool showData;
}
