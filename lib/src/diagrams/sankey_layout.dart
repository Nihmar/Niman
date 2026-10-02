/// Laying a Sankey diagram out (#530): a column a step of the flow, each
/// node a bar as tall as what passes through it, and a band a flow, as
/// wide as its value, from the one bar to the other.
///
/// The columns go by longest path from the sources, and the nodes that
/// send nothing on line up in the last. A source takes the palette's next
/// series colour and a node downstream the colour of its largest inflow,
/// so the colours follow where the flow comes from and there are only as
/// many as there are sources — past the palette's eight, neutral rather
/// than a colour handed out twice.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/sankey_model.dart';

const double _margin = 12;
const double _height = 360;
const double _nodeWidth = 12;
const double _gap = 10;
const double _columnWidth = 150;

/// How many points draw each edge of a band.
const int _samples = 16;

/// One node placed: its bar, its colour slot and its label.
typedef SankeyNodeBox = ({Rect rect, int? colour, Rect labelBox, String label});

/// One flow placed: the outline of its band and its colour slot.
typedef SankeyBand = ({List<Offset> outline, int? colour});

/// A Sankey diagram with every part placed.
typedef SankeyLayout = ({
  Size size,
  List<SankeyNodeBox> nodes,
  List<SankeyBand> bands,
});

/// Lays [chart] out with [style].
SankeyLayout layoutSankey(SankeyChart chart, DiagramStyle style) {
  final n = chart.nodes.length;
  final incoming = List.generate(n, (_) => <SankeyLink>[]);
  final outgoing = List.generate(n, (_) => <SankeyLink>[]);
  for (final link in chart.links) {
    outgoing[link.source].add(link);
    incoming[link.target].add(link);
  }
  double sum(List<SankeyLink> links) =>
      links.fold<double>(0, (total, link) => total + link.value);
  final values = [
    for (var i = 0; i < n; i++) math.max(sum(incoming[i]), sum(outgoing[i])),
  ];

  // Columns by longest path from the sources; the sinks in the last.
  final column = List.filled(n, 0);
  for (final i in _order(n, outgoing)) {
    for (final link in outgoing[i]) {
      column[link.target] = math.max(column[link.target], column[i] + 1);
    }
  }
  final last = column.fold(0, math.max);
  for (var i = 0; i < n; i++) {
    if (outgoing[i].isEmpty && incoming[i].isNotEmpty) column[i] = last;
  }
  final columns = List.generate(last + 1, (_) => <int>[]);
  for (var i = 0; i < n; i++) {
    columns[column[i]].add(i);
  }

  // One scale for every column, so a value is as tall wherever it is.
  var scale = double.infinity;
  for (final ids in columns) {
    final total = ids.fold<double>(0, (t, i) => t + values[i]);
    if (total > 0) {
      scale = math.min(scale, (_height - _gap * (ids.length - 1)) / total);
    }
  }
  if (!scale.isFinite) scale = 1;

  // Each column under the last one's order, by where its inflows come
  // from, then stacked and centred.
  final top = List<double>.filled(n, 0);
  final heights = [for (final v in values) math.max<double>(2, v * scale)];
  final position = List<double>.filled(n, 0);
  for (final ids in columns) {
    ids.sort((a, b) {
      double centre(int i) {
        final ins = incoming[i];
        if (ins.isEmpty) return i.toDouble();
        var weight = 0.0;
        var total = 0.0;
        for (final link in ins) {
          weight += position[link.source] * link.value;
          total += link.value;
        }
        return total == 0 ? i.toDouble() : weight / total;
      }

      return centre(a).compareTo(centre(b));
    });
    final total =
        ids.fold<double>(0, (t, i) => t + heights[i]) + _gap * (ids.length - 1);
    var y = _margin + (_height - total) / 2;
    for (final i in ids) {
      top[i] = y;
      position[i] = y + heights[i] / 2;
      y += heights[i] + _gap;
    }
  }

  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final width = math.max<double>(480, last * _columnWidth);
  double xOf(int i) =>
      _margin + (last == 0 ? 0 : column[i] / last * (width - _nodeWidth));

  // Colours: a source its own, a node downstream its largest inflow's.
  final colour = List<int?>.filled(n, null);
  var sources = 0;
  for (final i in _order(n, outgoing)) {
    if (incoming[i].isEmpty) {
      colour[i] = sources < style.palette.series.length ? sources : null;
      sources++;
    } else {
      final main = incoming[i].reduce((a, b) => a.value >= b.value ? a : b);
      colour[i] = colour[main.source];
    }
  }

  var right = width + 2 * _margin;
  var left = 0.0;
  final nodes = <SankeyNodeBox>[];
  for (var i = 0; i < n; i++) {
    final rect = Rect.fromLTWH(xOf(i), top[i], _nodeWidth, heights[i]);
    final label = '${chart.nodes[i]} ${_number(values[i])}';
    final labelWidth = DiagramMetrics.textWidth(label, fontSize);
    // Beside the bar, towards the middle: right of the first columns,
    // left of the last.
    final after = column[i] < last || last == 0;
    final labelBox = Rect.fromLTWH(
      after ? rect.right + 6 : rect.left - 6 - labelWidth,
      rect.center.dy - line / 2,
      labelWidth,
      line,
    );
    right = math.max(right, labelBox.right + _margin);
    left = math.min(left, labelBox.left - _margin);
    nodes.add((
      rect: rect,
      colour: colour[i],
      labelBox: labelBox,
      label: label,
    ));
  }

  // Bands: each node's outflows from its top in the order their targets
  // sit, its inflows likewise by their sources.
  final outAt = [for (var i = 0; i < n; i++) top[i]];
  final inAt = [for (var i = 0; i < n; i++) top[i]];
  final bands = <SankeyBand>[];
  for (var i = 0; i < n; i++) {
    outgoing[i].sort((a, b) => top[a.target].compareTo(top[b.target]));
    incoming[i].sort((a, b) => top[a.source].compareTo(top[b.source]));
  }
  // Where each flow arrives, by flow.
  final arrives = <SankeyLink, double>{};
  for (var i = 0; i < n; i++) {
    for (final link in incoming[i]) {
      arrives[link] = inAt[i];
      inAt[i] += link.value * scale;
    }
  }
  for (var i = 0; i < n; i++) {
    for (final link in outgoing[i]) {
      final thickness = link.value * scale;
      final from = Offset(xOf(i) + _nodeWidth, outAt[i]);
      final to = Offset(xOf(link.target), arrives[link]!);
      outAt[i] += thickness;
      bands.add((
        outline: [
          ..._curve(from, to),
          ..._curve(to + Offset(0, thickness), from + Offset(0, thickness)),
        ],
        colour: colour[i],
      ));
    }
  }

  // A label left of the first column moves everything right.
  final shift = -left;
  return (
    size: Size(right + shift, _height + 2 * _margin),
    nodes: [
      for (final node in nodes)
        (
          rect: node.rect.translate(shift, 0),
          colour: node.colour,
          labelBox: node.labelBox.translate(shift, 0),
          label: node.label,
        ),
    ],
    bands: [
      for (final band in bands)
        (
          outline: [for (final p in band.outline) p.translate(shift, 0)],
          colour: band.colour,
        ),
    ],
  );
}

/// The nodes in an order where every flow runs forward.
List<int> _order(int n, List<List<SankeyLink>> outgoing) {
  final indegree = List.filled(n, 0);
  for (final links in outgoing) {
    for (final link in links) {
      indegree[link.target]++;
    }
  }
  final queue = [
    for (var i = 0; i < n; i++)
      if (indegree[i] == 0) i,
  ];
  for (var head = 0; head < queue.length; head++) {
    for (final link in outgoing[queue[head]]) {
      if (--indegree[link.target] == 0) queue.add(link.target);
    }
  }
  return queue;
}

/// The points of the band's edge from [from] to [to]: a curve leaving and
/// arriving level.
List<Offset> _curve(Offset from, Offset to) {
  final middle = (from.dx + to.dx) / 2;
  return [
    for (var s = 0; s <= _samples; s++)
      () {
        final t = s / _samples;
        final u = 1 - t;
        final x =
            u * u * u * from.dx +
            3 * u * u * t * middle +
            3 * u * t * t * middle +
            t * t * t * to.dx;
        final y =
            u * u * u * from.dy +
            3 * u * u * t * from.dy +
            3 * u * t * t * to.dy +
            t * t * t * to.dy;
        return Offset(x, y);
      }(),
  ];
}

/// A value as a label writes it: two decimals at most, none when whole.
String _number(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
