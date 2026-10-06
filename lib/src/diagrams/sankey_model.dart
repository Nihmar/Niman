/// The Sankey model (#530): its nodes and the flows between them.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// One flow: how much goes from one node to another.
final class SankeyLink {
  /// Creates a flow.
  const new({required this.source, required this.target, required this.value});

  /// Where it comes from, by its place in [SankeyChart.nodes].
  final int source;

  /// Where it goes, by its place in [SankeyChart.nodes].
  final int target;

  /// How much flows.
  final double value;
}

/// A parsed Sankey diagram.
final class SankeyChart {
  /// Creates a Sankey diagram.
  const new({required this.nodes, required this.links});

  /// The nodes' names, in the order they first appear.
  final List<String> nodes;

  /// The flows, in the order they were written.
  final List<SankeyLink> links;
}
