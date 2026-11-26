/// The gaps of the layered layout (#530).
library;

/// How far apart things are put.
final class LayeredOptions {
  /// Creates options; the gaps are those dagre starts from.
  const new({this.rankGap = 50, this.nodeGap = 50, this.edgeGap = 20});

  /// The gap between two rows of nodes. With labels on the edges it is
  /// shared between the two ranks of an edge, so a rank holding labels does
  /// not make the drawing taller than one without them.
  final double rankGap;

  /// The gap between two real nodes in a row, and between the outlines of two
  /// clusters side by side.
  final double nodeGap;

  /// The gap beside a stand-in, which an edge runs through, or a label's
  /// stand-in: smaller, so edges do not push the nodes apart.
  final double edgeGap;
}
