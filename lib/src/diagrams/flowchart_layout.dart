/// Laying a flowchart out (#530): ranks, order, coordinates and curves.
///
/// The algorithm is a small Sugiyama: nodes are ranked by longest path,
/// ordered within a rank by barycentre to cut crossings, then placed and
/// joined by cubic curves. It runs in canonical space (ranks downwards,
/// cross axis to the right) and the result is turned to the chart's
/// direction at the end, so the four directions share one implementation.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// The room kept round the whole drawing.
const double _margin = 12;

/// The curve's straight run before it reaches a node, as a share of the gap.
const double _curveBend = 0.45;

/// Lays [chart] out with [style].
DiagramLayout layoutFlowchart(Flowchart chart, DiagramStyle style) {
  if (chart.nodes.isEmpty) {
    return const DiagramLayout(
      size: Size.zero,
      nodes: [],
      edges: [],
      subgraphs: [],
      lines: {},
    );
  }
  final sizes = <String, Size>{};
  final lines = <String, List<String>>{};
  for (final node in chart.nodes) {
    final labelLines = DiagramMetrics.lines(node.label);
    lines[node.id] = labelLines;
    sizes[node.id] = _nodeSize(node, labelLines, style);
  }

  final ranks = _ranks(chart);
  final layers = _orderedLayers(chart, ranks);

  // Main-axis (y) positions, one band per rank.
  final rankMain = List<double>.filled(layers.length, 0);
  for (var r = 0; r < layers.length; r++) {
    var tallest = 0.0;
    for (final id in layers[r]) {
      tallest = math.max(tallest, sizes[id]!.height);
    }
    rankMain[r] = tallest;
  }
  final rankTop = List<double>.filled(layers.length, 0);
  var cursor = 0.0;
  for (var r = 0; r < layers.length; r++) {
    rankTop[r] = cursor;
    cursor += rankMain[r] + style.rankGap;
  }

  // Cross-axis (x) positions: each rank centred and packed.
  final rects = <String, Rect>{};
  for (var r = 0; r < layers.length; r++) {
    final ids = layers[r];
    var width = 0.0;
    for (final id in ids) {
      width += sizes[id]!.width;
    }
    width += style.nodeGap * (ids.length - 1);
    var x = -width / 2;
    final centreY = rankTop[r] + rankMain[r] / 2;
    for (final id in ids) {
      final size = sizes[id]!;
      rects[id] = Rect.fromLTWH(
        x,
        centreY - size.height / 2,
        size.width,
        size.height,
      );
      x += size.width + style.nodeGap;
    }
  }

  final edges = [for (final edge in chart.edges) _edge(edge, rects, style)];
  final subgraphs = _subgraphs(chart, rects, lines, style);

  // The drawing's own bounds, then the direction's turn.
  var minX = 0.0;
  var minY = 0.0;
  var maxX = 0.0;
  var maxY = 0.0;
  void include(Rect rect) {
    minX = math.min(minX, rect.left);
    minY = math.min(minY, rect.top);
    maxX = math.max(maxX, rect.right);
    maxY = math.max(maxY, rect.bottom);
  }

  rects.values.forEach(include);
  for (final sub in subgraphs) {
    include(sub.rect);
  }
  for (final edge in edges) {
    if (edge.labelBox != null) include(edge.labelBox!);
  }
  minX -= _margin;
  minY -= _margin;
  maxX += _margin;
  maxY += _margin;

  final transformer = _Transformer(
    direction: chart.direction,
    minX: minX,
    minY: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
  return DiagramLayout(
    size: transformer.size,
    nodes: [
      for (final node in chart.nodes)
        LaidOutNode(node: node, rect: transformer.rect(rects[node.id]!)),
    ],
    edges: [for (final edge in edges) transformer.edge(edge)],
    subgraphs: [for (final sub in subgraphs) transformer.subgraph(sub)],
    lines: lines,
  );
}

/// The size of one node's box, text plus padding, widened for its shape.
Size _nodeSize(FlowNode node, List<String> lines, DiagramStyle style) {
  var text = 0.0;
  for (final line in lines) {
    text = math.max(text, DiagramMetrics.textWidth(line, style.fontSize));
  }
  var width = text + style.nodePadding.horizontal;
  var height =
      lines.length * style.fontSize * style.lineHeight +
      style.nodePadding.vertical;
  switch (node.shape) {
    case FlowNodeShape.circle:
      final diameter = math.max(width, height) * 1.3;
      width = diameter;
      height = diameter;
    case FlowNodeShape.diamond:
      width *= 1.7;
      height *= 1.9;
    case FlowNodeShape.hexagon:
      width *= 1.35;
    case FlowNodeShape.stadium:
      width += height * 0.4;
    case FlowNodeShape.subroutine:
      width += 12;
    case FlowNodeShape.database:
      height += 10;
    case FlowNodeShape.asymmetric:
    case FlowNodeShape.rect:
    case FlowNodeShape.round:
    case FlowNodeShape.parallelogram:
    case FlowNodeShape.parallelogramAlt:
    case FlowNodeShape.trapezoid:
    case FlowNodeShape.trapezoidAlt:
      break;
  }
  return Size(math.max(width, 34), math.max(height, 28));
}

/// The rank of every node, cycle-safe.
Map<String, int> _ranks(Flowchart chart) {
  final order = [for (final node in chart.nodes) node.id];
  final out = <String, Set<String>>{for (final id in order) id: <String>{}};
  final incoming = <String, Set<String>>{
    for (final id in order) id: <String>{},
  };
  for (final edge in chart.edges) {
    if (edge.from == edge.to) continue;
    if (out[edge.from]!.add(edge.to)) incoming[edge.to]!.add(edge.from);
  }

  final rank = <String, int>{for (final id in order) id: 0};
  final indegree = <String, int>{
    for (final id in order) id: incoming[id]!.length,
  };
  final queue = [
    for (final id in order)
      if (indegree[id] == 0) id,
  ];
  final processed = <String>{};
  for (var head = 0; head < queue.length; head++) {
    final id = queue[head];
    processed.add(id);
    for (final next in out[id]!) {
      rank[next] = math.max(rank[next]!, rank[id]! + 1);
      indegree[next] = indegree[next]! - 1;
      if (indegree[next] == 0) queue.add(next);
    }
  }
  final remaining = [
    for (final id in order)
      if (!processed.contains(id)) id,
  ];
  if (remaining.isNotEmpty) {
    final rest = remaining.toSet();
    for (final id in remaining) {
      var best = 0;
      for (final pred in incoming[id]!) {
        if (!rest.contains(pred)) best = math.max(best, rank[pred]! + 1);
      }
      rank[id] = best;
    }
    for (var pass = 0; pass < remaining.length; pass++) {
      var changed = false;
      for (final id in remaining) {
        for (final next in out[id]!) {
          if (!rest.contains(next)) continue;
          if (rank[next]! <= rank[id]!) {
            rank[next] = rank[id]! + 1;
            changed = true;
          }
        }
      }
      if (!changed) break;
    }
  }

  final distinct = rank.values.toSet().toList()..sort();
  final index = <int, int>{
    for (var i = 0; i < distinct.length; i++) distinct[i]: i,
  };
  return {for (final id in order) id: index[rank[id]]!};
}

/// The nodes grouped by rank, ordered to cut crossings.
List<List<String>> _orderedLayers(Flowchart chart, Map<String, int> ranks) {
  final depth = ranks.values.fold(0, math.max) + 1;
  final layers = List.generate(depth, (_) => <String>[]);
  for (final node in chart.nodes) {
    layers[ranks[node.id]!].add(node.id);
  }
  final incoming = <String, List<String>>{};
  final outgoing = <String, List<String>>{};
  for (final node in chart.nodes) {
    incoming[node.id] = [];
    outgoing[node.id] = [];
  }
  for (final edge in chart.edges) {
    if (edge.from == edge.to) continue;
    outgoing[edge.from]!.add(edge.to);
    incoming[edge.to]!.add(edge.from);
  }

  final position = <String, int>{};
  void reindex() {
    for (final layer in layers) {
      for (var i = 0; i < layer.length; i++) {
        position[layer[i]] = i;
      }
    }
  }

  reindex();
  for (var pass = 0; pass < 4; pass++) {
    for (var r = 1; r < depth; r++) {
      _sortBy(layers[r], incoming, position);
      reindex();
    }
    for (var r = depth - 2; r >= 0; r--) {
      _sortBy(layers[r], outgoing, position);
      reindex();
    }
  }
  return layers;
}

void _sortBy(
  List<String> layer,
  Map<String, List<String>> neighbours,
  Map<String, int> position,
) {
  final base = {for (var i = 0; i < layer.length; i++) layer[i]: i};
  layer.sort((a, b) {
    final cmp = _barycentre(
      a,
      neighbours,
      position,
    ).compareTo(_barycentre(b, neighbours, position));
    return cmp != 0 ? cmp : base[a]!.compareTo(base[b]!);
  });
}

double _barycentre(
  String id,
  Map<String, List<String>> neighbours,
  Map<String, int> position,
) {
  final list = neighbours[id]!;
  if (list.isEmpty) return -1;
  var sum = 0;
  for (final other in list) {
    sum += position[other] ?? 0;
  }
  return sum / list.length;
}

/// The curve joining two placed nodes.
LaidOutEdge _edge(FlowEdge edge, Map<String, Rect> rects, DiagramStyle style) {
  final from = rects[edge.from];
  final to = rects[edge.to];
  if (from == null || to == null) {
    return LaidOutEdge(
      edge: edge,
      start: Offset.zero,
      control1: Offset.zero,
      control2: Offset.zero,
      end: Offset.zero,
    );
  }
  Offset start;
  Offset control1;
  Offset control2;
  Offset end;

  if (edge.from == edge.to) {
    final dy = from.height * 0.22;
    start = Offset(from.right, from.center.dy - dy);
    end = Offset(from.right, from.center.dy + dy);
    control1 = Offset(from.right + 40, from.center.dy - 34);
    control2 = Offset(from.right + 40, from.center.dy + 34);
  } else if ((to.center.dy - from.center.dy).abs() < 1) {
    final right = to.center.dx >= from.center.dx;
    start = Offset(right ? from.right : from.left, from.center.dy);
    end = Offset(right ? to.left : to.right, to.center.dy);
    final bend = (end.dx - start.dx) * _curveBend;
    control1 = Offset(start.dx + bend, start.dy);
    control2 = Offset(end.dx - bend, end.dy);
  } else {
    final down = to.center.dy > from.center.dy;
    start = Offset(from.center.dx, down ? from.bottom : from.top);
    end = Offset(to.center.dx, down ? to.top : to.bottom);
    final bend = (end.dy - start.dy) * _curveBend;
    control1 = Offset(start.dx, start.dy + bend);
    control2 = Offset(end.dx, end.dy - bend);
  }

  final label = edge.label == null || edge.label!.isEmpty ? null : edge.label;
  Rect? labelBox;
  if (label != null) {
    final size = Size(
      DiagramMetrics.textWidth(label, style.fontSize) +
          style.edgeLabelPadding.horizontal,
      style.fontSize * style.lineHeight + style.edgeLabelPadding.vertical,
    );
    final mid = _cubicMidpoint(start, control1, control2, end);
    labelBox = Rect.fromCenter(
      center: mid,
      width: size.width,
      height: size.height,
    );
  }
  return LaidOutEdge(
    edge: edge,
    start: start,
    control1: control1,
    control2: control2,
    end: end,
    label: label,
    labelBox: labelBox,
  );
}

Offset _cubicMidpoint(Offset p0, Offset c1, Offset c2, Offset p1) {
  const t = 0.5;
  const u = 1 - t;
  final x =
      u * u * u * p0.dx +
      3 * u * u * t * c1.dx +
      3 * u * t * t * c2.dx +
      t * t * t * p1.dx;
  final y =
      u * u * u * p0.dy +
      3 * u * u * t * c1.dy +
      3 * u * t * t * c2.dy +
      t * t * t * p1.dy;
  return Offset(x, y);
}

/// The box drawn round each subgraph, outermost first.
List<LaidOutSubgraph> _subgraphs(
  Flowchart chart,
  Map<String, Rect> rects,
  Map<String, List<String>> lines,
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
    boxes.add(_SubgraphBox(subgraph, bounds));
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
          boxes[i] = _SubgraphBox(
            boxes[i].subgraph,
            outer.expandToInclude(inner),
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
final class _SubgraphBox {
  const new(this.subgraph, this.rect);

  final FlowSubgraph subgraph;
  final Rect rect;
}

/// Turns canonical geometry into the chart's direction.
final class _Transformer {
  new({
    required this.direction,
    required this._minX,
    required this._minY,
    required this.width,
    required this.height,
  });

  final FlowDirection direction;
  final double _minX;
  final double _minY;
  final double width;
  final double height;

  Size get size =>
      direction.isVertical ? Size(width, height) : Size(height, width);

  Offset point(Offset p) {
    final x = p.dx - _minX;
    final y = p.dy - _minY;
    return switch (direction) {
      FlowDirection.topDown => Offset(x, y),
      FlowDirection.bottomUp => Offset(x, height - y),
      FlowDirection.leftRight => Offset(y, x),
      FlowDirection.rightLeft => Offset(height - y, x),
    };
  }

  Rect rect(Rect r) {
    final a = point(r.topLeft);
    final b = point(r.bottomRight);
    return Rect.fromLTRB(
      math.min(a.dx, b.dx),
      math.min(a.dy, b.dy),
      math.max(a.dx, b.dx),
      math.max(a.dy, b.dy),
    );
  }

  LaidOutEdge edge(LaidOutEdge edge) => LaidOutEdge(
    edge: edge.edge,
    start: point(edge.start),
    control1: point(edge.control1),
    control2: point(edge.control2),
    end: point(edge.end),
    label: edge.label,
    labelBox: edge.labelBox == null ? null : rect(edge.labelBox!),
  );

  LaidOutSubgraph subgraph(LaidOutSubgraph sub) => LaidOutSubgraph(
    subgraph: sub.subgraph,
    rect: rect(sub.rect),
    titleRect: rect(sub.titleRect),
    title: sub.title,
  );
}
