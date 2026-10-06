// A node's outline sampled into points (#530): a curve stays a curve at
// any size, its straight pieces a few pixels long.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/flow_model.dart';

/// The longest straight piece of the closed outline [points], leaving out
/// the ones along a box's flat sides.
double _longestCurved(List<Offset> points, Rect rect) {
  var longest = 0.0;
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    final flat =
        (a.dy - b.dy).abs() < 1e-9 &&
            ((a.dy - rect.top).abs() < 1e-9 ||
                (a.dy - rect.bottom).abs() < 1e-9) ||
        (a.dx - b.dx).abs() < 1e-9;
    if (!flat && (a - b).distance > longest) longest = (a - b).distance;
  }
  return longest;
}

void main() {
  test("a tall stadium's ends and a wide cylinder's caps stay round", () {
    for (final (shape, rect) in [
      (FlowNodeShape.stadium, const Rect.fromLTWH(0, 0, 300, 160)),
      (FlowNodeShape.database, const Rect.fromLTWH(0, 0, 400, 120)),
      (FlowNodeShape.circle, const Rect.fromLTWH(0, 0, 200, 200)),
    ]) {
      final points = DiagramShapes.polygonFor(shape, rect);
      expect(_longestCurved(points, rect), lessThan(12), reason: '$shape');
    }
  });

  test('a small corner is still a few points, not a long list', () {
    final points = DiagramShapes.polygonFor(
      FlowNodeShape.round,
      const Rect.fromLTWH(0, 0, 80, 30),
    );
    expect(points.length, lessThan(40));
  });
}
