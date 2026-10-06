// Laying a Gantt chart out (#530), and drawing it: bars as long as their
// time, labels on them or beside, the axis's dates apart, the sections'
// bands, and the canvas and the SVG both drawing it.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/gantt_geometry.dart';
import 'package:niman/src/diagrams/gantt_layout.dart';
import 'package:niman/src/diagrams/gantt_parser.dart';
import 'package:niman/src/diagrams/gantt_renderer.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

const DiagramStyle _style = DiagramStyle();

GanttLayout _layout(String source) => layoutGantt(parseGantt(source), _style);

void main() {
  test('a bar is as long as its time, and starts where it starts', () {
    final layout = _layout(
      'gantt\nA :2024-01-01, 10d\nB :2024-01-11, 10d\nC :2024-01-01, 20d',
    );
    final a = layout.bars[0].rect;
    final b = layout.bars[1].rect;
    final c = layout.bars[2].rect;
    expect(a.width, closeTo(b.width, 0.01));
    expect(b.left, closeTo(a.right, 0.01));
    expect(c.width, closeTo(a.width * 2, 0.01));
    expect(a.left, closeTo(layout.plot.left, 0.01));
    expect(c.right, closeTo(layout.plot.right, 0.01));
  });

  test('a label goes on its bar when it fits, beside it when not', () {
    final layout = _layout(
      'gantt\nShort :2024-01-01, 30d\nA much longer task name :2024-01-01, 1d',
    );
    expect(layout.bars[0].labelInside, isTrue);
    expect(layout.bars[1].labelInside, isFalse);
    expect(
      layout.bars[1].labelBox.left,
      greaterThan(layout.bars[1].rect.right),
    );
    for (final bar in layout.bars) {
      expect(bar.labelBox.right, lessThanOrEqualTo(layout.size.width));
    }
  });

  test('a milestone is a diamond on its day', () {
    final layout = _layout(
      'gantt\nWork :2024-01-01, 10d\nShip :milestone, 2024-01-06, 0d',
    );
    final work = layout.bars[0].rect;
    final ship = layout.bars[1].rect;
    expect(ship.center.dx, closeTo(work.left + work.width / 2, 0.01));
    expect(ship.width, ship.height);
  });

  test("the axis's dates do not run into one another", () {
    for (final span in ['12h', '5d', '60d', '400d', '4000d']) {
      final layout = _layout('gantt\nA :2024-01-01, $span');
      expect(layout.ticks, isNotEmpty, reason: span);
      for (var i = 1; i < layout.ticks.length; i++) {
        final before = layout.ticks[i - 1];
        final tick = layout.ticks[i];
        expect(tick.x, greaterThan(before.x), reason: span);
        expect(
          tick.labelBox.left,
          greaterThan(before.labelBox.right),
          reason: span,
        );
      }
      for (final tick in layout.ticks) {
        expect(tick.x, inInclusiveRange(layout.plot.left, layout.plot.right));
      }
    }
  });

  test('the axis writes its dates in the chart axisFormat', () {
    final layout = _layout('gantt\naxisFormat %d/%m\nA :2024-03-01, 3d');
    expect(layout.ticks.first.label, '01/03');
  });

  test('every other section is shaded, and a band holds its rows', () {
    final layout = _layout(
      'gantt\nsection One\nA :2024-01-01, 1d\nB :1d\n'
      'section Two\nC :1d\nsection Three\nD :1d',
    );
    expect(layout.bands.map((b) => b.shaded), [false, true, false]);
    expect(layout.bands.map((b) => b.name), ['One', 'Two', 'Three']);
    expect(
      layout.bands.first.rect.contains(layout.bars[1].rect.center),
      isTrue,
    );
    expect(layout.bands.first.nameBox.right, lessThan(layout.plot.left));
  });

  test('a gantt fence resolves, paints and exports', () {
    const source =
        'gantt\ntitle Plan\nsection Work\nDesign :d, 2024-01-01, 5d\n'
        'Build <fast> :crit, after d, 5d\nDone :done, 2024-01-01, 2d';
    expect(parseMermaid(source), isA<MermaidGantt>());
    final drawing =
        (resolveDiagram(source, _style) as DiagramReady).drawing
            as GanttDrawing;
    final recorder = ui.PictureRecorder();
    GanttRenderer(
      layout: drawing.layout,
      style: _style,
    ).paint(CanvasDiagramTarget(ui.Canvas(recorder)));
    recorder.endRecording().dispose();
    final svg = diagramSvg(source, _style)!;
    expect(svg, contains('Build &lt;fast&gt;'));
    expect(svg, contains('2024-01-0'));
    expect(svg, contains('Plan'));
  });
}
