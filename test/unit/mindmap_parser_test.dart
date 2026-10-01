// The Mermaid mind map parser (#530): indentation is the tree.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

Flowchart _chart(String source) =>
    (parseMermaid(source) as MermaidFlowchart).chart;

void main() {
  test('indentation is the tree', () {
    final chart = _chart(
      'mindmap\n'
      'root((Central))\n'
      '  Origins\n'
      '  Research\n'
      '    Papers\n',
    );
    expect(chart.direction, FlowDirection.leftRight);
    expect(chart.nodes.map((n) => n.label), [
      'Central',
      'Origins',
      'Research',
      'Papers',
    ]);
    final ids = chart.nodes.map((n) => n.id).toList();
    expect(chart.edges.map((e) => '${e.from}->${e.to}'), [
      '${ids[0]}->${ids[1]}',
      '${ids[0]}->${ids[2]}',
      '${ids[2]}->${ids[3]}',
    ]);
    // A mind map's branches carry no arrowheads.
    expect(chart.edges.every((e) => e.end == FlowEdgeEnd.none), isTrue);
  });

  test('node shapes are read, the id before them ignored', () {
    final chart = _chart(
      'mindmap\n'
      'root((Circle))\n'
      '  A[Square]\n'
      '  B{{Hex}}\n'
      '  C(Round)\n'
      '  Bare\n',
    );
    expect(chart.nodes[0].shape, FlowNodeShape.circle);
    expect(chart.nodes[1].shape, FlowNodeShape.rect);
    expect(chart.nodes[2].shape, FlowNodeShape.hexagon);
    expect(chart.nodes[3].shape, FlowNodeShape.round);
    expect(chart.nodes[4].shape, FlowNodeShape.round);
    expect(chart.nodes[4].label, 'Bare');
  });

  test('an icon line is skipped', () {
    final chart = _chart(
      'mindmap\n'
      'root\n'
      '  A\n'
      '    ::icon(fa fa-book)\n',
    );
    expect(chart.nodes.map((n) => n.label), ['root', 'A']);
  });

  test('a second root is refused', () {
    expect(
      () => parseMermaid('mindmap\nroot\nother\n'),
      throwsA(
        isA<MermaidParseException>().having(
          (e) => e.message,
          'message',
          contains('only one root'),
        ),
      ),
    );
  });

  test('a mind map with no root is refused', () {
    expect(
      () => parseMermaid('mindmap\n'),
      throwsA(
        isA<MermaidParseException>().having(
          (e) => e.message,
          'message',
          contains('root'),
        ),
      ),
    );
  });

  test('the header is required', () {
    expect(
      () => parseMermaid('root\n  child\n'),
      throwsA(
        isA<MermaidParseException>().having(
          (e) => e.message,
          'message',
          contains('"flowchart" or "graph"'),
        ),
      ),
    );
  });
}
