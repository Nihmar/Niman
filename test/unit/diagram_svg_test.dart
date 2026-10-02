// Diagrams as SVG, and the same drawing on a canvas (#530): one layout,
// two targets.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_svg.dart';
import 'package:niman/src/diagrams/svg_target.dart';

const DiagramStyle _style = DiagramStyle();

void main() {
  test('a flowchart becomes a standalone SVG', () {
    final svg = diagramSvg(
      'flowchart TD\n'
      'A[Start] --> B{Ok?}\n'
      'B -->|Yes| C(End)',
      _style,
    );
    expect(svg, isNotNull);
    expect(svg, startsWith('<svg '));
    expect(svg, endsWith('</svg>'));
    expect(svg, contains('viewBox='));
    expect(svg, contains('<polygon'));
    expect(svg, contains('<path'));
    expect(svg, contains('<text'));
    expect(svg, contains('Start'));
    expect(svg, contains('Yes'));
  });

  test('a flag node has its outline, as every other shape', () {
    final svg = diagramSvg('flowchart TD\nM>Flag]', _style)!;
    expect(RegExp('<polygon[^>]* stroke=').hasMatch(svg), isTrue);
  });

  test('a mind map becomes a standalone SVG (#530)', () {
    final svg = diagramSvg('mindmap\nroot((Central))\n  A\n  B\n', _style);
    expect(svg, isNotNull);
    expect(svg, contains('Central'));
    expect(svg, contains('>A<'));
    expect(svg, contains('>B<'));
  });

  test('a source that does not parse comes back null, for the fence', () {
    expect(diagramSvg('flowchart TD\nA -- B', _style), isNull);
    expect(
      diagramSvg('architecture-beta\nservice db(database)', _style),
      isNull,
    );
  });

  test('label text is escaped for XML', () {
    final svg = diagramSvg('flowchart TD\nA["a < b"]', _style);
    expect(svg, contains('a &lt; b'));
    expect(svg, isNot(contains('a < b')));
  });

  test('the SVG target frames a document and closes it', () {
    final target = SvgDiagramTarget(width: 10, height: 20);
    final svg = target.finish();
    expect(svg, startsWith('<svg '));
    expect(svg, contains('viewBox="0 0 10 20"'));
    expect(svg, endsWith('</svg>'));
  });

  test('the same layout paints on a canvas without throwing', () {
    final result = resolveDiagram(
      'flowchart TD\nA[Start] --> B{Ok?}\nB -->|Yes| C(End)',
      _style,
    );
    final drawing = (result as DiagramReady).drawing as FlowDrawing;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    DiagramRenderer(
      layout: drawing.layout,
      style: _style,
    ).paint(CanvasDiagramTarget(canvas));
    recorder.endRecording().dispose();
  });

  test('a control character in a label is dropped, not written', () {
    // XML has no such characters, outside a few: one in an EPUB's XHTML
    // makes the whole chapter ill-formed.
    final svg = diagramSvg(
      'flowchart TD\nA["form \u000Cfeed \u0007bell"] --> B',
      const DiagramStyle(),
    )!;
    expect(svg, contains('form feed bell'));
    expect(svg.codeUnits.where((unit) => unit < 0x20), isEmpty);
  });
}
