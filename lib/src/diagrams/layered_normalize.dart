/// Cutting long edges into one-rank pieces (#530): ordering and placing
/// look at two ranks at a time, so an edge that spans more has a stand-in
/// on every rank it crosses.
///
/// After dagre's `normalize`. The edge stays in the graph, whole, with its
/// stand-ins in [LayeredEdge.chain], and the pieces are not edges of their
/// own: [LayeredSegments](layered_segments.dart) reads them off the chains
/// when a stage wants them. The stand-ins are what the ordering moves and
/// the placing aligns, so a long edge keeps clear of the boxes it passes and
/// runs as straight as it can.
library;

import 'package:niman/src/diagrams/layered_edge.dart' show LayeredEdge;
import 'package:niman/src/diagrams/layered_graph.dart';
import 'package:niman/src/diagrams/layered_node.dart';

/// Gives every ranked edge of [graph] that spans more than one rank a
/// stand-in on each rank between its ends.
///
/// The stand-in on the edge's label rank has the label's size, and is of
/// kind [LayeredNodeKind.edgeLabel]; the rest are 0 by 0. An edge is
/// followed in the direction it was ranked in, so one turned round to break
/// a ring has its chain from top to bottom, and a later stage turns the
/// points back. A labelled edge must span two ranks at least, which the
/// ranking sees to; one that does not is a bug, and this throws.
void normalizeEdges(LayeredGraph graph) {
  for (final edge in graph.edges) {
    if (!edge.ranked || edge.chain.isNotEmpty) continue;
    final span = edge.to.rank - edge.from.rank;
    if (span < 0) {
      throw StateError('${edge.fromId} > ${edge.toId} points upwards.');
    }
    if (edge.hasLabel && span < 2) {
      throw StateError(
        '${edge.fromId} > ${edge.toId} has no rank for its label.',
      );
    }
    if (span < 2) continue;
    final labelRank = edge.hasLabel && edge.labelRank > edge.from.rank
        ? edge.labelRank
        : (edge.from.rank + edge.to.rank) >> 1;
    for (var rank = edge.from.rank + 1; rank < edge.to.rank; rank++) {
      final isLabel = edge.hasLabel && rank == labelRank;
      final stand =
          graph.addAuxiliary(
              isLabel ? LayeredNodeKind.edgeLabel : LayeredNodeKind.dummy,
              width: isLabel ? edge.labelWidth : 0,
              height: isLabel ? edge.labelHeight : 0,
            )
            ..rank = rank
            ..edge = edge
            ..chainIndex = edge.chain.length;
      edge.chain.add(stand);
    }
    if (edge.hasLabel) {
      edge
        ..labelRank = labelRank
        ..labelNode = edge.chain[labelRank - edge.from.rank - 1];
    }
  }
}
