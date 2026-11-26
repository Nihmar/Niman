# Flowchart layout: a compound layered layout after dagre

Written 2026-11-26, when the flowchart layout was replaced. It records why
the first layout could not draw a chart with subgraphs the way Mermaid does,
what replaced it, and the decisions taken on the way. The code is
`lib/src/diagrams/layered_*.dart` (the engine) and
`lib/src/diagrams/flow*.dart` (the flowchart side).

## The chart that showed it

`test/fixtures/mermaid/subgraph-pipeline.mmd`: seven subgraphs in a
`flowchart TB`, about forty nodes, edges between the subgraphs. Mermaid
(mermaid.live and the Claude chat, both dagre) stacks the subgraphs by
their edges: the console S6 on top, S1, S3, S4 and S5 down the page, the
legend a small box beside S6. Niman drew every subgraph in one row across
the top, S3 inside S4, nodes at the edge of their own box, and edges between
subgraphs as loops across the whole canvas.

## Why

1. **Membership.** The parser put a node in every subgraph whose body
   mentions it: `X3 --> X4` inside S4 made X3 a member of S3 and of S4, and
   S4's box was drawn round a node of S3. Mermaid (`flowDb` `makeUniq`)
   keeps a node in the first subgraph to close that holds it.
2. **Ranks.** Ranks were the longest path from the sources, so every node
   with no incoming edge was in rank 0. Each subgraph had such a node, so
   each subgraph began in the first rank: one row. The ranking knew nothing
   of subgraphs.
3. **Order.** Crossings were cut by barycentres over neighbours in any rank
   (no stand-ins for long edges, no crossing count, no best order kept), and
   the subgraphs were grouped afterwards, one order for every rank: the
   grouping ignored crossings and the crossing reduction ignored subgraphs.
4. **Placement.** Each rank was centred and packed on its own, then a sweep
   pushed nodes right out of boxes they were not in. No node was aligned
   with its neighbours, so edges were long diagonals, and the boxes were
   wherever the nodes ended up.
5. **Edges.** One cubic per edge, bent round the nodes of the ranks it
   passed but not round boxes; a cycle's way back bulged round everything
   it spanned. A label sat at the cubic's middle, with no room kept for it.
6. **A subgraph's `direction`** was parsed and ignored.

## What replaced it

A generic compound layered layout, written for Niman from the published
algorithms, with dagre's design as the behavioural reference:

- Gansner, Koutsofios, North, Vo, *A Technique for Drawing Directed
  Graphs* (1993) — network simplex ranking.
- Sander, *Layout of Compound Directed Graphs* (1996) — the nesting graph.
- Forster, *A Fast and Simple Heuristic for Constrained Two-Level Crossing
  Reduction* (2004) — ordering with clusters kept whole.
- Barth, Jünger, Mutzel, *Simple and Efficient Bilayer Cross Counting*
  (2002).
- Brandes, Köpf, *Fast and Simple Horizontal Coordinate Assignment* (2001).

The pipeline (`layOutLayered`), in canonical space — ranks down, order
right; the flowchart turns the result to its direction:

1. Cycles broken by a walk in the order the nodes were written, so the node
   written first stays on top.
2. A nesting graph: a top and a bottom node for each cluster, tied to its
   members by edges heavier than all the chart's together, so a cluster
   keeps one compact band of ranks. An edge that names a subgraph ties to
   its top or its bottom.
3. Ranks by network simplex: a source sits next to what it leads to.
4. A rank of room for every label: when an edge has one, the ranks double
   and the label is a stand-in of its size at the middle.
5. A chain of stand-ins for every edge longer than one rank, each in the
   cluster its part of the edge runs through; a left and a right side node
   for every cluster in every rank it spans.
6. Order: sweeps by barycentre with every cluster kept whole and sibling
   clusters on the same sides in every rank, the crossings counted, the
   best order kept. A last pass keeps each edge on one side of a cluster it
   passes, rather than through it.
7. Coordinates: y rank by rank, a rank of borders only taking no height; x
   by Brandes–Köpf, a cluster's sides kept straight, its top and bottom
   left out of the alignment; stand-ins drawn back towards their
   neighbours; each box drawn round what it holds.

The flowchart side (`flow_layered_graph.dart`, `flowchart_layout.dart`)
builds that graph, keeps a note tied to one node beside it as one box, and
draws each edge through its stand-ins as Mermaid does (a B-spline basis
curve), its label on it. A subgraph with no edge across its border and a
`direction` of its own is laid out on its own and placed as one box
(`flow_subgraph_direction.dart`); one with an edge across its border keeps
its parent's direction, as Mermaid does. A subgraph that declares no
direction keeps its parent's: mermaid.live draws
`subgraph A; a1 --> a2 --> a3; end` in a TB chart top to bottom, whatever
the `rankdir === 'TB' ? 'LR' : 'TB'` line in its source suggests.

## Decisions on the way

- **Ranking.** Initial ranks by the earliest rank (dagre uses the latest);
  the feasible tree is grown with two heaps instead of dagre's rescan; cut
  values are updated only in the subtree a pivot changes; pivots are capped
  so a layout can never hang. Proved against brute force on random graphs.
- **Order.** Constraints between sibling clusters are recorded from the
  first rank and followed through ranks a cluster is absent from (dagre
  loses them there). The sweeps stop after four without a strictly better
  count.
- **Edges round clusters.** Constraints alone could not keep edges out of
  clusters they pass: two edges leaving one cluster may need to go round
  another on opposite sides. A repair after the order moves such stand-ins
  to the side their edge keeps. Both fixtures have no edge through a
  cluster it is not in; on dense random graphs about 1% still have one
  (2.7% without the repair).
- **Vertical room.** dagre gives every rank its full gap, borders included;
  here a rank of borders and stand-ins only takes none, so nesting adds no
  tall empty bands.
- **Boxes.** A box is drawn round its content, inside the band its border
  ranks give: a tall neighbour in the same rank no longer makes it tall.

## Numbers

Laying a flowchart out, reference host, `NIMAN_PERF=1`: a 3000-node chain
25 ms, a 2000-node cycle 36 ms (ceiling 60 ms, the first layout's 60 ms
bar kept). The engine alone on 40 clusters of 25 nodes: about 60 ms.

## What is still open

- A label is not kept from overlapping a node beside its stand-in's rank
  when the slide along its curve finds no free place; it stays at the
  middle, as before.
- An edge leaving a diamond's side starts at the box's side, not on the
  diamond's outline (as before this change).
- A subgraph's title wider than its content is not yet a minimum width for
  its box.
