/// The boxes drawn round a flowchart's subgraphs (#530).
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// The box drawn round each subgraph of [chart], whose nodes sit at
/// [rects], outermost first.
///
/// A subgraph's box holds its nodes and the boxes of the subgraphs written
/// inside it, title bands and all, so nested boxes nest rather than lie on
/// one another. The chart lists a subgraph after those inside it, so each
/// child's box is ready when its parent's is drawn round it.
List<LaidOutSubgraph> flowSubgraphBoxes(
  Flowchart chart,
  Map<String, Rect> rects,
  DiagramStyle style,
) {
  final boxes = <_SubgraphBox>[];
  final children = <String, List<Rect>>{};
  for (final subgraph in chart.subgraphs) {
    var bounds = _union([
      for (final id in subgraph.nodeIds)
        if (rects[id] != null) rects[id]!,
      ...?children[subgraph.id],
    ]);
    if (bounds == null) continue;
    bounds = _withTitleBand(
      bounds.inflate(style.subgraphPadding),
      chart.direction,
      style.fontSize * style.lineHeight + 8,
    );
    boxes.add((subgraph: subgraph, rect: bounds));
    final parent = subgraph.parent;
    if (parent != null) (children[parent] ??= []).add(bounds);
  }
  // Painted parents first, so a child's box lies over its parent's.
  return [
    for (final box in boxes.reversed)
      LaidOutSubgraph(
        subgraph: box.subgraph,
        rect: box.rect,
        title: box.subgraph.title,
        titleRect: Rect.fromLTWH(
          box.rect.left + 8,
          box.rect.top + 4,
          DiagramMetrics.textWidth(box.subgraph.title, style.fontSize),
          style.fontSize * style.lineHeight,
        ),
      ),
  ];
}

/// [box] grown by a [band] for the title on the side that the turn to
/// [direction] puts at the top: the canonical top, but the bottom for a
/// chart drawn upwards and the left for one drawn across.
Rect _withTitleBand(Rect box, FlowDirection direction, double band) =>
    switch (direction) {
      FlowDirection.topDown => Rect.fromLTRB(
        box.left,
        box.top - band,
        box.right,
        box.bottom,
      ),
      FlowDirection.bottomUp => Rect.fromLTRB(
        box.left,
        box.top,
        box.right,
        box.bottom + band,
      ),
      FlowDirection.leftRight || FlowDirection.rightLeft => Rect.fromLTRB(
        box.left - band,
        box.top,
        box.right,
        box.bottom,
      ),
    };

Rect? _union(List<Rect> rects) {
  if (rects.isEmpty) return null;
  var result = rects.first;
  for (final rect in rects.skip(1)) {
    result = result.expandToInclude(rect);
  }
  return result;
}

/// A subgraph's box while it is being expanded.
typedef _SubgraphBox = ({FlowSubgraph subgraph, Rect rect});
