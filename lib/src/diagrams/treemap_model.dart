/// The treemap model (#530): a tree of sections whose leaves carry values.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// One node: a leaf with its value, or a section holding others.
final class TreemapNode {
  /// Creates a node.
  const new({required this.label, this.value, this.children = const []});

  /// Its name.
  final String label;

  /// A leaf's value; null for a section.
  final double? value;

  /// A section's nodes, in the order they were written.
  final List<TreemapNode> children;

  /// What it weighs: a leaf's value, a section's leaves' sum.
  double get total =>
      value ?? children.fold<double>(0, (sum, child) => sum + child.total);
}

/// A parsed treemap.
final class TreemapChart {
  /// Creates a treemap.
  const new({required this.roots, this.title});

  /// The top-level nodes.
  final List<TreemapNode> roots;

  /// The title, if any.
  final String? title;
}
