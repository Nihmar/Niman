// Laying a pie chart out (#530), and drawing it: the shares, a colour
// per slice never handed out twice, the legend, and the canvas and the SVG
// both drawing it.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/pie_geometry.dart';
import 'package:niman/src/diagrams/pie_layout.dart';
import 'package:niman/src/diagrams/pie_parser.dart';
import 'package:niman/src/diagrams/pie_renderer.dart';

const DiagramStyle _style = DiagramStyle();

PieLayout _layout(String source) => layoutPie(parsePie(source), _style);

void main() {
  test('each slice is written with its share', () {
    final layout = _layout('pie\n"A" : 1\n"B" : 1\n"C" : 2');
    expect(layout.slices.map((s) => s.percent), ['25%', '25%', '50%']);
    // Clockwise from twelve o'clock: the first slice's arc starts at the
    // top of the pie.
    final top = layout.center - Offset(0, layout.radius);
    expect((layout.slices.first.outline[1] - top).distance, lessThan(0.01));
  });

  test('a pie of one slice is the whole circle, its share in the middle', () {
    final layout = _layout('pie\n"Only" : 3');
    final slice = layout.slices.single;
    expect(slice.percent, '100%');
    expect(slice.percentAt, layout.center);
    expect(slice.outline.contains(layout.center), isFalse);
  });

  test('a sliver has no room for its share, the legend still names it', () {
    final layout = _layout('pie\n"Big" : 999\n"Sliver" : 1');
    expect(layout.slices.last.percent, isNull);
    expect(layout.legend.map((r) => r.text), ['Big', 'Sliver']);
  });

  test('a colour is never handed out twice: the ninth slice on is Other', () {
    final source = StringBuffer('pie\n');
    for (var i = 1; i <= 11; i++) {
      source.writeln('"S$i" : $i');
    }
    final layout = _layout(source.toString());
    expect(layout.legend, hasLength(8));
    expect(layout.legend.last.text, 'Other');
    expect(layout.legend.map((r) => r.colour).toSet(), hasLength(8));
    expect(layout.slices.map((s) => s.colour).toSet(), hasLength(8));
  });

  test('showData writes each value after its label', () {
    final layout = _layout('pie showData\n"Dogs" : 386\n"Cats" : 85.5');
    expect(layout.legend.map((r) => r.text), ['Dogs [386]', 'Cats [85.5]']);
  });

  test('the legend sits right of the pie and all of it in the drawing', () {
    final layout = _layout(
      'pie title A rather long title for a small pie\n"A" : 1\n"B" : 2',
    );
    final bounds = Offset.zero & layout.size;
    for (final row in layout.legend) {
      expect(row.swatch.left, greaterThan(layout.center.dx + layout.radius));
      expect(bounds.contains(row.textBox.bottomRight), isTrue);
    }
    final title = layout.titleBox!;
    expect(title.bottom, lessThan(layout.center.dy - layout.radius));
    expect(bounds.contains(title.topLeft), isTrue);
    expect(bounds.contains(title.bottomRight), isTrue);
  });

  test('a pie fence resolves, paints and exports', () {
    const source = 'pie title Pets\n"Dogs <3" : 3\n"Cats" : 1';
    expect(parseMermaid(source), isA<MermaidPie>());
    final drawing =
        (resolveDiagram(source, _style) as DiagramReady).drawing as PieDrawing;
    final recorder = ui.PictureRecorder();
    PieRenderer(
      layout: drawing.layout,
      style: _style,
    ).paint(CanvasDiagramTarget(ui.Canvas(recorder)));
    recorder.endRecording().dispose();
    final svg = diagramSvg(source, _style)!;
    expect(svg, contains('Dogs &lt;3'));
    expect(svg, contains('75%'));
    expect(svg, contains('Pets'));
  });
}
