/// Laying an architecture diagram out (#530): its services on a grid of
/// columns and rows, each an icon with its title under it, the groups'
/// boxes round their services, and every edge a run of straight lines
/// that leaves and reaches the sides it names.
///
/// A column is as wide as its widest service and a row as tall as its
/// tallest, every icon centred on its row's icon line, so an edge between
/// two services of a row is straight. The gaps between cells hold the
/// boxes of the groups nested there, so neighbouring groups do not touch.
/// An edge leaves its side, turns once or twice at right angles, and
/// reaches the other side; `{group}` makes it leave or reach the box of the
/// service's group, straight out from where the service sits.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/architecture_grid.dart';
import 'package:niman/src/diagrams/architecture_model.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/sequence_text.dart';

const double _margin = 12;

/// An icon's side.
const double archIconSize = 48;

/// A junction's dot's diameter.
const double _junction = 10;

/// The widest a service's title is before it wraps.
const double _titleWidth = 130;

/// The gap between an icon and its title.
const double _titleGap = 6;

/// The room between a group's box and what it holds, on every side.
const double _pad = 14;

/// The gap between cells with no group box between them.
const double _gap = 56;

/// One service or junction placed: its icon's box (a junction's dot) and
/// its title's box and lines (none for a junction).
typedef ArchNodeBox = ({
  ArchService service,
  Rect icon,
  Rect? titleBox,
  List<String> lines,
});

/// One group placed: its box, its title's box and its icon's.
typedef ArchGroupBox = ({ArchGroup group, Rect rect, Rect titleBox, Rect icon});

/// One edge placed: the corners of its run and its label's box.
typedef ArchEdgeLine = ({ArchEdge edge, List<Offset> points, Rect? labelBox});

/// An architecture diagram with every part placed. Its groups are outer
/// before inner, so drawing them in order stacks them right.
typedef ArchitectureLayout = ({
  Size size,
  List<ArchGroupBox> groups,
  List<ArchNodeBox> nodes,
  List<ArchEdgeLine> edges,
});

/// Lays [diagram] out with [style].
ArchitectureLayout layoutArchitecture(
  ArchitectureDiagram diagram,
  DiagramStyle style,
) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final band = line + 6;
  final cells = placeArchitecture(diagram);

  // How deep groups nest, which the gaps make room for.
  final parent = {for (final g in diagram.groups) g.id: g.parent};
  int depthOf(String? group) {
    var d = 0;
    for (var g = group; g != null; g = parent[g]) {
      d++;
    }
    return d;
  }

  final deepest = diagram.services.fold(
    0,
    (most, s) => math.max(most, depthOf(s.group)),
  );
  final across = _gap + 2 * _pad * deepest;
  final down = _gap + (2 * _pad + band) * deepest;

  final titles = {
    for (final s in diagram.services)
      s.id: s.isJunction
          ? const <String>[]
          : wrapLabel(s.title, _titleWidth, fontSize),
  };
  Size sizeOf(ArchService s) {
    if (s.isJunction) return const Size(_junction, archIconSize);
    final lines = titles[s.id]!;
    var widest = archIconSize;
    for (final text in lines) {
      widest = math.max(widest, DiagramMetrics.textWidth(text, fontSize));
    }
    return Size(widest, archIconSize + _titleGap + lines.length * line);
  }

  final columns = cells.values.fold(0, (most, c) => math.max(most, c.$1)) + 1;
  final rows = cells.values.fold(0, (most, c) => math.max(most, c.$2)) + 1;
  final widths = List<double>.filled(columns, 0);
  final heights = List<double>.filled(rows, 0);
  for (final s in diagram.services) {
    final (x, y) = cells[s.id]!;
    final size = sizeOf(s);
    widths[x] = math.max(widths[x], size.width);
    heights[y] = math.max(heights[y], size.height);
  }
  final lefts = <double>[];
  var x = 0.0;
  for (final w in widths) {
    lefts.add(x);
    x += w + across;
  }
  final tops = <double>[];
  var y = 0.0;
  for (final h in heights) {
    tops.add(y);
    y += h + down;
  }

  final nodes = <ArchNodeBox>[];
  final boxes = <String, Rect>{};
  for (final s in diagram.services) {
    final (cx, cy) = cells[s.id]!;
    final centre = Offset(
      lefts[cx] + widths[cx] / 2,
      tops[cy] + archIconSize / 2,
    );
    final icon = s.isJunction
        ? Rect.fromCircle(center: centre, radius: _junction / 2)
        : Rect.fromCenter(
            center: centre,
            width: archIconSize,
            height: archIconSize,
          );
    final lines = titles[s.id]!;
    final size = sizeOf(s);
    final titleBox = lines.isEmpty
        ? null
        : Rect.fromLTWH(
            centre.dx - size.width / 2,
            icon.bottom + _titleGap,
            size.width,
            lines.length * line,
          );
    nodes.add((service: s, icon: icon, titleBox: titleBox, lines: lines));
    boxes[s.id] = titleBox == null ? icon : icon.expandToInclude(titleBox);
  }

  // Groups, innermost first, each round its services and its groups.
  final groupRects = <String, Rect>{};
  final ordered = [...diagram.groups]
    ..sort((a, b) => depthOf(b.id).compareTo(depthOf(a.id)));
  for (final group in ordered) {
    Rect? bounds;
    for (final s in diagram.services) {
      if (s.group == group.id) {
        bounds = bounds?.expandToInclude(boxes[s.id]!) ?? boxes[s.id];
      }
    }
    for (final child in diagram.groups) {
      final rect = groupRects[child.id];
      if (child.parent == group.id && rect != null) {
        bounds = bounds?.expandToInclude(rect) ?? rect;
      }
    }
    if (bounds == null) continue;
    final padded = bounds.inflate(_pad);
    groupRects[group.id] = Rect.fromLTRB(
      padded.left,
      padded.top - band,
      padded.right,
      padded.bottom,
    );
  }
  final groups = <ArchGroupBox>[
    for (final group
        in diagram.groups.reversed.toList()
          ..sort((a, b) => depthOf(a.id).compareTo(depthOf(b.id))))
      if (groupRects[group.id] case final rect?)
        (
          group: group,
          rect: rect,
          icon: Rect.fromLTWH(rect.left + 8, rect.top + 5, line - 2, line - 2),
          // Past its icon, when it has one.
          titleBox: Rect.fromLTWH(
            rect.left + 8 + (group.icon.isEmpty ? 0 : line + 2),
            rect.top + 4,
            DiagramMetrics.textWidth(group.title, fontSize),
            line,
          ),
        ),
  ];

  final byId = {for (final node in nodes) node.service.id: node};
  final edges = [
    for (final edge in diagram.edges) _route(edge, byId, groupRects, style),
  ];

  var bounds = Rect.zero;
  for (final node in nodes) {
    bounds = bounds.expandToInclude(boxes[node.service.id]!);
  }
  for (final group in groups) {
    bounds = bounds.expandToInclude(group.rect).expandToInclude(group.titleBox);
  }
  for (final edge in edges) {
    for (final p in edge.points) {
      bounds = bounds.expandToInclude(Rect.fromCircle(center: p, radius: 6));
    }
    if (edge.labelBox case final box?) bounds = bounds.expandToInclude(box);
  }
  final shift = Offset(_margin - bounds.left, _margin - bounds.top);
  return (
    size: Size(bounds.width + 2 * _margin, bounds.height + 2 * _margin),
    groups: [
      for (final g in groups)
        (
          group: g.group,
          rect: g.rect.shift(shift),
          titleBox: g.titleBox.shift(shift),
          icon: g.icon.shift(shift),
        ),
    ],
    nodes: [
      for (final n in nodes)
        (
          service: n.service,
          icon: n.icon.shift(shift),
          titleBox: n.titleBox?.shift(shift),
          lines: n.lines,
        ),
    ],
    edges: [
      for (final e in edges)
        (
          edge: e.edge,
          points: [for (final p in e.points) p + shift],
          labelBox: e.labelBox?.shift(shift),
        ),
    ],
  );
}

/// [edge]'s run: out of its first side, at right angles, into its last.
ArchEdgeLine _route(
  ArchEdge edge,
  Map<String, ArchNodeBox> nodes,
  Map<String, Rect> groups,
  DiagramStyle style,
) {
  Offset end(String id, ArchSide side, {required bool group}) {
    final node = nodes[id]!;
    final icon = node.icon;
    if (group) {
      final box = groups[node.service.group]!;
      return switch (side) {
        ArchSide.left => Offset(box.left, icon.center.dy),
        ArchSide.right => Offset(box.right, icon.center.dy),
        ArchSide.top => Offset(icon.center.dx, box.top),
        ArchSide.bottom => Offset(icon.center.dx, box.bottom),
      };
    }
    if (node.service.isJunction) return icon.center;
    final bottom = node.titleBox?.bottom ?? icon.bottom;
    return switch (side) {
      ArchSide.left => icon.centerLeft,
      ArchSide.right => icon.centerRight,
      ArchSide.top => icon.topCenter,
      ArchSide.bottom => Offset(icon.center.dx, bottom),
    };
  }

  final a = end(edge.from, edge.fromSide, group: edge.fromGroup);
  final b = end(edge.to, edge.toSide, group: edge.toGroup);
  final List<Offset> points;
  if (edge.fromSide.isHorizontal && edge.toSide.isHorizontal) {
    final middle = (a.dx + b.dx) / 2;
    points = [a, Offset(middle, a.dy), Offset(middle, b.dy), b];
  } else if (!edge.fromSide.isHorizontal && !edge.toSide.isHorizontal) {
    final middle = (a.dy + b.dy) / 2;
    points = [a, Offset(a.dx, middle), Offset(b.dx, middle), b];
  } else if (edge.fromSide.isHorizontal) {
    points = [a, Offset(b.dx, a.dy), b];
  } else {
    points = [a, Offset(a.dx, b.dy), b];
  }
  // Corners only: a repeated point, or one in line with its neighbours,
  // goes.
  final run = <Offset>[];
  for (final p in points) {
    if (run.isNotEmpty && (run.last - p).distance <= 0.01) continue;
    if (run.length >= 2) {
      final a = run[run.length - 2];
      final b = run.last;
      final inLine =
          ((a.dx - b.dx).abs() < 0.01 && (b.dx - p.dx).abs() < 0.01) ||
          ((a.dy - b.dy).abs() < 0.01 && (b.dy - p.dy).abs() < 0.01);
      if (inLine) run.removeLast();
    }
    run.add(p);
  }

  Rect? labelBox;
  final label = edge.label;
  if (label != null && run.length > 1) {
    // On the run's longest straight piece, at its middle.
    var at = 0;
    for (var i = 1; i < run.length - 1; i++) {
      if ((run[i + 1] - run[i]).distance > (run[at + 1] - run[at]).distance) {
        at = i;
      }
    }
    labelBox = Rect.fromCenter(
      center: (run[at] + run[at + 1]) / 2,
      width:
          DiagramMetrics.textWidth(label, style.fontSize) +
          style.edgeLabelPadding.horizontal,
      height:
          style.fontSize * style.lineHeight + style.edgeLabelPadding.vertical,
    );
  }
  return (edge: edge, points: run, labelBox: labelBox);
}
