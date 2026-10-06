// A Mermaid treemap (#530): its tree read from indentation, each node a
// squarified rectangle as large as its share, a section's nodes inside it,
// and drawn on the canvas and in the SVG.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/treemap_layout.dart';
import 'package:niman/src/diagrams/treemap_parser.dart';

const DiagramStyle _style = DiagramStyle();

const String _notes = '''
treemap-beta
"Work"
    "Projects"
        "Niman": 180
        "Web: site": 45 :::big
    "Meetings": 90
"Personal #38; home"
    Recipes: 96
"Misc": 0.5
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

TreemapLayout _layout(String source) =>
    layoutTreemap(parseTreemap(source), _style);

double _area(Rect r) => r.width * r.height;

void main() {
  test('the tree is read from indentation, a leaf by its value', () {
    final roots = parseTreemap(_notes).roots;
    expect(
      [for (final r in roots) r.label],
      ['Work', 'Personal & home', 'Misc'],
    );
    final work = roots.first;
    expect(work.value, isNull);
    expect(work.total, 315);
    final projects = work.children.first;
    expect(
      [for (final c in projects.children) (c.label, c.value)],
      [('Niman', 180), ('Web: site', 45)],
    );
    expect(roots[1].children.single.label, 'Recipes');
    expect(roots.last.value, 0.5);
  });

  test('a node that cannot be what it says names its line', () {
    expect(
      () => parseTreemap('treemap-beta\n"A": 1\n  "B": 2'),
      _error(3, 'cannot hold'),
    );
    expect(
      () => parseTreemap('treemap-beta\n"A"\n"B": 2'),
      _error(2, 'needs a value'),
    );
    expect(() => parseTreemap('treemap-beta\n"A": lots'), _error(2, 'number'));
    expect(() => parseTreemap('treemap-beta\n"A": -1'), _error(2, 'number'));
    expect(
      () => parseTreemap('treemap-beta\n"S"\n  "A": 1e308\n  "B": 1e308'),
      _error(2, 'add up past'),
    );
    expect(() => parseTreemap('treemap-beta\n"A: 1'), _error(2, 'quote'));
    expect(() => parseTreemap('treemap-beta\n"": 1'), _error(2, 'a name'));
    expect(() => parseTreemap('treemap-beta'), _error(1, 'needs a node'));
  });

  test('each rectangle is its share of the whole, none overlapping', () {
    const rect = Rect.fromLTWH(0, 0, 300, 200);
    final values = <double>[6, 6, 4, 3, 2, 2, 1];
    final boxes = squarify(values, rect).cast<Rect>();
    for (var i = 0; i < values.length; i++) {
      expect(_area(boxes[i]) / _area(rect), closeTo(values[i] / 24, 1e-9));
      expect(rect.inflate(1e-9).contains(boxes[i].topLeft), isTrue);
      expect(rect.inflate(1e-9).contains(boxes[i].bottomRight), isTrue);
      for (var j = i + 1; j < values.length; j++) {
        final overlap = boxes[i].intersect(boxes[j]);
        expect(overlap.width <= 1e-9 || overlap.height <= 1e-9, isTrue);
      }
    }
  });

  test("values near a double's limit, or far apart, still share the area", () {
    const rect = Rect.fromLTWH(0, 0, 300, 200);
    // Their sum is Infinity, which made every share nothing.
    final huge = squarify([1e308, 1e308], rect).cast<Rect>();
    for (final box in huge) {
      expect(_area(box) / _area(rect), closeTo(0.5, 1e-9));
    }
    // Rounding wore the free room beside 1e17 to nothing, and a row's area
    // divided by it was Infinity.
    for (final values in [
      <double>[100000000000000000, 180, 0.5],
      <double>[1e40, 90, 180],
    ]) {
      final boxes = squarify(values, rect).cast<Rect>();
      for (final box in boxes) {
        for (final edge in [box.left, box.top, box.right, box.bottom]) {
          expect(edge.isFinite, isTrue, reason: '$values: $box');
        }
        expect(rect.inflate(1e-9).contains(box.topLeft), isTrue);
        expect(rect.inflate(1e-9).contains(box.bottomRight), isTrue);
      }
      expect(_area(boxes.first) / _area(rect), closeTo(1, 1e-9));
    }
  });

  test('equal values in a square come out square, a zero takes no room', () {
    final boxes = squarify([
      1,
      1,
      0,
      1,
      1,
    ], const Rect.fromLTWH(0, 0, 100, 100));
    expect(boxes[2], isNull);
    for (final box in boxes.whereType<Rect>()) {
      expect(box.width, closeTo(50, 1e-9));
      expect(box.height, closeTo(50, 1e-9));
    }
  });

  test("a section's nodes lie inside it, under its name", () {
    final layout = _layout(_notes);
    final work = layout.sections.first;
    final projects = layout.sections[1];
    expect(projects.label, 'Projects');
    expect(work.rect.contains(projects.rect.topLeft), isTrue);
    expect(work.rect.contains(projects.rect.bottomRight), isTrue);
    expect(projects.rect.top, greaterThan(work.labelBox!.bottom));
    final niman = layout.leaves.first;
    expect(projects.rect.contains(niman.rect.topLeft), isTrue);
    expect(niman.lines, ['Niman', '180']);
  });

  test('a top-level node takes the next colour, and its nodes the same', () {
    final layout = _layout(_notes);
    expect([for (final s in layout.sections) s.colour], [0, 0, 1]);
    expect([for (final l in layout.leaves) l.colour], [0, 0, 0, 1, 2]);
    final nine = [for (var i = 0; i < 9; i++) '"n$i": ${9 - i}'].join('\n');
    final many = _layout('treemap-beta\n$nine');
    expect(many.leaves.last.colour, isNull, reason: 'past eight, neutral');
  });

  test('a name is never wider than its box: a tiny leaf has none', () {
    final layout = _layout(_notes);
    for (final leaf in layout.leaves) {
      for (final line in leaf.lines) {
        expect(
          DiagramMetrics.textWidth(line, _style.fontSize),
          lessThanOrEqualTo(leaf.rect.width),
        );
      }
    }
    expect(layout.leaves.last.lines, isEmpty, reason: 'Misc, 0.5 of 411');
  });

  test('a treemap fence dispatches and exports', () {
    expect(parseMermaid(_notes), isA<MermaidTreemap>());
    expect(parseMermaid('treemap\n"a": 1'), isA<MermaidTreemap>());
    final svg = diagramSvg(_notes, _style)!;
    expect(svg, contains('Personal &amp; home'));
    expect(svg, contains('>180<'));
  });
}
