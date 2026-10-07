// A Mermaid `style` statement: the colours it spells, the properties it
// sets, and the node or subgraph drawn in them. Ignored, a node the note
// had marked in amber came out like every other.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/css_color.dart';
import 'package:niman/src/diagrams/diagram_renderer.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_style.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/svg_target.dart';

Flowchart _chart(String source) =>
    (parseMermaid(source) as MermaidFlowchart).chart;

String _svg(Flowchart chart) {
  const style = DiagramStyle();
  final layout = layoutFlowchart(chart, style);
  final svg = SvgDiagramTarget(
    width: layout.size.width,
    height: layout.size.height,
  );
  DiagramRenderer(layout: layout, style: style).paint(svg);
  return svg.finish();
}

void main() {
  test('a colour is read in every way CSS spells one', () {
    expect(parseCssColor('#fef3c7'), const Color(0xFFFEF3C7));
    expect(parseCssColor('#F9F'), const Color(0xFFFF99FF));
    expect(parseCssColor('#ff99ff80'), const Color(0x80FF99FF));
    expect(parseCssColor('#f9f8'), const Color(0x88FF99FF));
    expect(parseCssColor('rgb(217, 119, 6)'), const Color(0xFFD97706));
    expect(parseCssColor('rgba(217,119,6,0.5)'), const Color(0x80D97706));
    expect(parseCssColor(' Orange '), const Color(0xFFFFA500));
    expect(parseCssColor('none'), const Color(0x00000000));
    expect(parseCssColor('#12'), isNull);
    expect(parseCssColor('#ggg'), isNull);
    expect(parseCssColor('rebeccapurple-ish'), isNull);
  });

  test('a style reads the properties it draws and leaves the rest', () {
    final style = FlowNodeStyle.parse(
      'fill:#fef3c7, stroke: rgb(217, 119, 6),stroke-width:3px, '
      'color:#000,stroke-dasharray: 5 5,fill:nonsense',
    );
    expect(style.fill, const Color(0xFFFEF3C7));
    expect(style.stroke, const Color(0xFFD97706));
    expect(style.strokeWidth, 3);
    expect(style.color, const Color(0xFF000000));
  });

  test('text on a styled fill stands out from it', () {
    expect(
      const FlowNodeStyle(fill: Color(0xFFFEF3C7)).textColor!
          .computeLuminance(),
      lessThan(0.1),
    );
    expect(
      const FlowNodeStyle(fill: Color(0xFF1E3A8A)).textColor!
          .computeLuminance(),
      greaterThan(0.9),
    );
    expect(
      const FlowNodeStyle(
        fill: Color(0xFFFEF3C7),
        color: Color(0xFFFF0000),
      ).textColor,
      const Color(0xFFFF0000),
    );
    expect(const FlowNodeStyle(stroke: Color(0xFF000000)).textColor, isNull);
  });

  test('a style statement styles its node, written before it or after', () {
    final chart = _chart(
      'flowchart TD\nstyle A fill:#fef3c7\nA --> B\n'
      'style B stroke:#d97706\nstyle A stroke-width:2px',
    );
    final a = chart.nodes.firstWhere((n) => n.id == 'A').style!;
    expect(a.fill, const Color(0xFFFEF3C7));
    expect(a.strokeWidth, 2);
    expect(
      chart.nodes.firstWhere((n) => n.id == 'B').style!.stroke,
      const Color(0xFFD97706),
    );
  });

  test('a style statement styles a subgraph', () {
    final chart = _chart(
      'flowchart TD\nsubgraph S\nA\nend\nstyle S fill:#e0f2fe',
    );
    expect(chart.subgraphs.single.style!.fill, const Color(0xFFE0F2FE));
  });

  test('a style without properties is an error on its line', () {
    expect(
      () => _chart('flowchart TD\nA --> B\nstyle A'),
      throwsA(isA<MermaidParseException>().having((e) => e.line, 'line', 3)),
    );
  });

  test('a styled node and subgraph are drawn in their own colours', () {
    final svg = _svg(
      _chart(
        'flowchart TD\nsubgraph S\nA --> B\nend\n'
        'style B fill:#fef3c7,stroke:#d97706,stroke-width:3px\n'
        'style S fill:#e0f2fe',
      ),
    );
    expect(svg, contains('fill="#fef3c7"'));
    expect(svg, contains('stroke="#d97706"'));
    expect(svg, contains('stroke-width="3"'));
    expect(svg, contains('fill="#e0f2fe"'));
  });
}
