/// The curves an edge is drawn along (#530), in canonical space, as chains
/// of cubic Béziers: `[p0, c1, c2, p1, c1, c2, p2, ...]`.
library;

import 'package:flutter/painting.dart';

/// The curve's straight run before it reaches a node, as a share of the gap.
const double _curveBend = 0.45;

/// One cubic from [start] to [end] that leaves and arrives straight along
/// the ranks, a share of the way between them: the curve of an edge with
/// nothing in between. It runs up as well as down.
List<Offset> flowCubic(Offset start, Offset end) {
  final bend = (end.dy - start.dy) * _curveBend;
  return [start, start + Offset(0, bend), end - Offset(0, bend), end];
}

/// One cubic from [start] to [end] that leaves and arrives along the row
/// they are in: the curve of an edge between two nodes side by side.
List<Offset> flowFlatCubic(Offset start, Offset end) {
  final bend = (end.dx - start.dx) * _curveBend;
  return [start, start + Offset(bend, 0), end - Offset(bend, 0), end];
}

/// The smooth curve through [points], three or more, as Mermaid draws an
/// edge (d3's `curveBasis`): a B-spline that starts at the first point and
/// ends at the last, with a straight first piece and a straight last one,
/// and cubic pieces between, each from the 1:4:1 rule over three
/// neighbours. It leaves and arrives towards the next point and the one
/// before the end, which is the direction a cap points in.
List<Offset> flowBasisPath(List<Offset> points) {
  final path = <Offset>[points.first];
  void line(Offset to) {
    final from = path.last;
    path
      ..add(from + (to - from) / 3)
      ..add(from + (to - from) * 2 / 3)
      ..add(to);
  }

  void piece(Offset before, Offset at, Offset after) {
    path
      ..add((before * 2 + at) / 3)
      ..add((before + at * 2) / 3)
      ..add((before + at * 4 + after) / 6);
  }

  final last = points.length - 1;
  line((points[0] * 5 + points[1]) / 6);
  for (var i = 2; i <= last; i++) {
    piece(points[i - 2], points[i - 1], points[i]);
  }
  // The last piece runs on to the last point, and the line to it.
  piece(points[last - 1], points[last], points[last]);
  line(points[last]);
  return path;
}

/// The point on [path] nearest to [target], by sampling each piece.
Offset flowNearestOnPath(List<Offset> path, Offset target) {
  const steps = 24;
  final pieces = (path.length - 1) ~/ 3;
  var best = path.first;
  var bestDistance = double.infinity;
  for (var piece = 0; piece < pieces; piece++) {
    final i = piece * 3;
    for (var step = 0; step <= steps; step++) {
      final t = step / steps;
      final u = 1 - t;
      final point =
          path[i] * (u * u * u) +
          path[i + 1] * (3 * u * u * t) +
          path[i + 2] * (3 * u * t * t) +
          path[i + 3] * (t * t * t);
      final distance = (point - target).distanceSquared;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = point;
      }
    }
  }
  return best;
}
