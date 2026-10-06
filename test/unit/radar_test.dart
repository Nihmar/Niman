// A Mermaid radar chart (#530): its axes and curves read, by position or
// by axis, laid out as spokes clockwise from the top with each value
// between the centre and the rim, and drawn on the canvas and in the SVG.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/radar_layout.dart';
import 'package:niman/src/diagrams/radar_model.dart';
import 'package:niman/src/diagrams/radar_parser.dart';

const DiagramStyle _style = DiagramStyle();

const String _grades = '''
radar-beta
  title Grades #38; marks
  axis m["Math"], s["Science"]
  axis e["English"], h
  curve a["Alice"]{85, 90, 80, 70}
  curve b{ h: 60, e: 50, s: 40, m: 30 }
  max 100
  ticks 4
  graticule polygon
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

RadarLayout _layout(String source) => layoutRadar(parseRadar(source), _style);

/// The centre of a laid-out chart: where every spoke starts.
Offset _centre(RadarLayout layout) => layout.spokes.first.$1;

void main() {
  test('axes and curves are read, a curve by position or by axis', () {
    final chart = parseRadar(_grades);
    expect(chart.title, 'Grades & marks');
    expect(
      [for (final a in chart.axes) a.label],
      ['Math', 'Science', 'English', 'h'],
    );
    expect(chart.curves[0].label, 'Alice');
    expect(chart.curves[0].values, [85, 90, 80, 70]);
    expect(chart.curves[1].label, 'b');
    expect(chart.curves[1].values, [30, 40, 50, 60]);
    expect((chart.min, chart.max, chart.ticks), (0, 100, 4));
    expect(chart.graticule, RadarGraticule.polygon);
    expect(chart.showLegend, isTrue);
  });

  test('with no max the rim is the largest value', () {
    final chart = parseRadar('radar-beta\naxis a, b, c\ncurve x{1, 7, 3}');
    expect(chart.max, 7);
    expect(chart.min, 0);
  });

  test('a curve or a setting that does not fit names its line', () {
    const axes = 'radar-beta\naxis a, b\n';
    expect(() => parseRadar('${axes}curve x{1}'), _error(3, '1 values'));
    expect(() => parseRadar('${axes}curve x{a: 1, 2}'), _error(3, 'all in'));
    expect(() => parseRadar('${axes}curve x{a: 1, z: 2}'), _error(3, '"z"'));
    expect(() => parseRadar('${axes}curve x{a: 1}'), _error(3, 'for "b"'));
    expect(() => parseRadar('${axes}curve x{1, two}'), _error(3, 'number'));
    expect(
      () => parseRadar('${axes}curve x{1, 2}\nmin 5\nmax 5'),
      _error(5, 'above min'),
    );
    expect(() => parseRadar('${axes}ticks 0'), _error(3, 'ticks'));
    expect(() => parseRadar('${axes}graticule star'), _error(3, 'circle'));
    expect(() => parseRadar('${axes}axis a'), _error(3, 'twice'));
    expect(() => parseRadar('${axes}spin 3'), _error(3, 'expected axis'));
    expect(() => parseRadar('radar-beta\ncurve x{1}'), _error(1, 'an axis'));
    expect(() => parseRadar(axes), _error(1, 'a curve'));
  });

  test('the first axis points up, the next ones clockwise', () {
    final layout = _layout(_grades);
    final centre = _centre(layout);
    final up = layout.spokes[0].$2;
    final right = layout.spokes[1].$2;
    final down = layout.spokes[2].$2;
    expect(up.dx, closeTo(centre.dx, 1e-9));
    expect(up.dy, lessThan(centre.dy));
    expect(right.dx, greaterThan(centre.dx));
    expect(right.dy, closeTo(centre.dy, 1e-9));
    expect(down.dy, greaterThan(centre.dy));
  });

  test('a value sits between the centre and the rim, never past them', () {
    final layout = _layout(
      'radar-beta\naxis a, b, c, d\ncurve x{0, 50, 100, 150}\n'
      'curve y{-20, 0, 0, 0}\nmax 100',
    );
    final centre = _centre(layout);
    final rim = (layout.spokes.first.$2 - centre).distance;
    double from(Offset p) => (p - centre).distance;
    final x = layout.curves[0].points;
    expect(from(x[0]), closeTo(0, 1e-9));
    expect(from(x[1]), closeTo(rim / 2, 1e-9));
    expect(from(x[2]), closeTo(rim, 1e-9));
    expect(from(x[3]), closeTo(rim, 1e-9), reason: '150 stops at the rim');
    expect(from(layout.curves[1].points[0]), closeTo(0, 1e-9));
  });

  test("an axis's label sits outside the rim", () {
    final layout = _layout(_grades);
    final centre = _centre(layout);
    final rim = (layout.spokes.first.$2 - centre).distance;
    for (final label in layout.axisLabels) {
      final box = label.box;
      final nearest = Offset(
        centre.dx.clamp(box.left, box.right),
        centre.dy.clamp(box.top, box.bottom),
      );
      expect((nearest - centre).distance, greaterThan(rim), reason: label.text);
    }
  });

  test('the scale is drawn with as many rings as ticks, shaped as asked', () {
    final polygon = _layout(_grades);
    expect(polygon.rings, hasLength(4));
    expect(polygon.rings.first, hasLength(4), reason: 'one corner an axis');
    final circle = _layout('radar-beta\naxis a, b, c\ncurve x{1, 2, 3}');
    expect(circle.rings, hasLength(5));
    expect(circle.rings.first.length, greaterThan(3));
  });

  test('each curve its own colour, in order, and none handed out twice', () {
    final curves = [for (var i = 0; i < 9; i++) 'curve c$i{${i + 1}, 1, 1}']
        .join('\n');
    final layout = _layout('radar-beta\naxis a, b, c\n$curves');
    expect(
      [for (final c in layout.curves) c.colour],
      [0, 1, 2, 3, 4, 5, 6, 7, null],
    );
    expect(
      [for (final r in layout.legend) r.colour],
      [for (final c in layout.curves) c.colour],
    );
  });

  test('the legend names every curve, unless it is turned off', () {
    expect(_layout(_grades).legend.map((r) => r.label.text), ['Alice', 'b']);
    expect(_layout('$_grades\nshowLegend false').legend, isEmpty);
  });

  test('the drawing holds every part', () {
    final layout = _layout(_grades);
    final bounds = (Offset.zero & layout.size).inflate(1e-9);
    final boxes = [
      for (final l in layout.axisLabels) l.box,
      for (final r in layout.legend) r.label.box,
      layout.title!.box,
    ];
    for (final box in boxes) {
      expect(bounds.contains(box.topLeft), isTrue);
      expect(bounds.contains(box.bottomRight), isTrue);
    }
    for (final ring in layout.rings) {
      for (final p in ring) {
        expect(bounds.contains(p), isTrue);
      }
    }
    expect(math.min(layout.size.width, layout.size.height), greaterThan(0));
  });

  test('a radar fence dispatches and exports', () {
    expect(parseMermaid(_grades), isA<MermaidRadar>());
    expect(parseMermaid('radar\naxis a\ncurve x{1}'), isA<MermaidRadar>());
    final svg = diagramSvg(_grades, _style)!;
    expect(svg, contains('Science'));
    expect(svg, contains('Alice'));
  });
}
