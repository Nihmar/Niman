/// A rectangle of the layered layout (#530), in canonical space: ranks run
/// down, the order runs right.
library;

/// A rectangle by its four sides.
final class LayeredBox {
  /// Creates a box.
  const new(this.left, this.top, this.right, this.bottom);

  /// The box of no size at the origin.
  static const LayeredBox zero = LayeredBox(0, 0, 0, 0);

  /// The left side.
  final double left;

  /// The top side.
  final double top;

  /// The right side.
  final double right;

  /// The bottom side.
  final double bottom;

  /// How wide it is.
  double get width => right - left;

  /// How tall it is.
  double get height => bottom - top;

  @override
  String toString() => 'LayeredBox($left, $top, $right, $bottom)';
}
