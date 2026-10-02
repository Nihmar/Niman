/// The boxes drawn round a flowchart's subgraphs (#530).
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// The box drawn round each subgraph of [chart], whose nodes sit at
/// [rects], outermost first.
List<LaidOutSubgraph> flowSubgraphBoxes(
  Flowchart chart,
  Map<String, Rect> rects,
  DiagramStyle style,
) {
  final boxes = <_SubgraphBox>[];
  for (final subgraph in chart.subgraphs) {
    var bounds = _union([
      for (final id in subgraph.nodeIds)
        if (rects[id] != null) rects[id]!,
    ]);
    if (bounds == null) continue;
    final titleHeight = style.fontSize * style.lineHeight + 8;
    bounds = Rect.fromLTRB(
      bounds.left - style.subgraphPadding,
      bounds.top - style.subgraphPadding - titleHeight,
      bounds.right + style.subgraphPadding,
      bounds.bottom + style.subgraphPadding,
    );
    boxes.add((subgraph: subgraph, rect: bounds));
  }
  // A subgraph that holds another must contain its box too.
  for (var pass = 0; pass < boxes.length; pass++) {
    var changed = false;
    for (var i = 0; i < boxes.length; i++) {
      for (var j = 0; j < boxes.length; j++) {
        if (i == j) continue;
        final outer = boxes[i].rect;
        final inner = boxes[j].rect;
        if (outer.contains(inner.topLeft) &&
            !outer.contains(inner.bottomRight)) {
          boxes[i] = (
            subgraph: boxes[i].subgraph,
            rect: outer.expandToInclude(inner),
          );
          changed = true;
        }
      }
    }
    if (!changed) break;
  }
  // Outer boxes are the larger ones; painting order is big to small.
  boxes.sort(
    (a, b) =>
        (b.rect.width * b.rect.height).compareTo(a.rect.width * a.rect.height),
  );
  return [
    for (final box in boxes)
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
