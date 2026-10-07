// A subgraph's box holds its own nodes and no other (#530): the members
// side by side in every rank, and a node outside the subgraph kept out of
// its box even where the box is wider in another rank. The case is the one
// a render showed: an external system inside the enterprise boundary.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/c4_parser.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';

/// Every node a subgraph's box covers without owning it.
List<String> _intruders(Flowchart chart, DiagramLayout layout) => [
  for (final box in layout.subgraphs)
    for (final node in layout.nodes)
      if (!box.subgraph.nodeIds.contains(node.node.id) &&
          node.rect.overlaps(box.rect))
        '${node.node.id} in ${box.subgraph.id}',
];

void main() {
  test('an external system is drawn outside the boundary it is not in', () {
    final chart = parseC4(
      'C4Context\nPerson(w, "Writer")\nEnterprise_Boundary(h, "Home") {\n'
      '  System(n, "Niman")\n  System_Boundary(s, "Storage") {\n'
      '    SystemDb(d, "Disk")\n    SystemDb(i, "Index")\n  }\n}\n'
      'System_Ext(g, "Git")\nSystemQueue_Ext(m, "Mail")\n'
      'Rel(w, n, "Uses")\nRel(n, d, "Saves")\nRel(n, i, "Queries")\n'
      'BiRel(n, g, "Syncs")\nRel(n, m, "Shares")',
    );
    final layout = layoutFlowchart(chart, const DiagramStyle());
    expect(_intruders(chart, layout), isEmpty);
  });

  // The case a note showed: a chain of subgraphs joined by their names,
  // each name mentioned before its subgraph was written. Taken for nodes,
  // the names were pushed out of every box and the chart drawn 42 000 px
  // wide and 600 high.
  test('subgraphs joined by their names stack, each box after the last', () {
    final chart = (parseMermaid(
      'flowchart TD\nM[Start] --> F1\n'
      'subgraph F1\na1 --> a2\na2 --> a3\nend\nF1 --> F2\n'
      'subgraph F2\nb1 --> b2\nend\nF2 --> F3\n'
      'subgraph F3\nc1 --> c2\nend',
    ) as MermaidFlowchart).chart;
    final layout = layoutFlowchart(chart, const DiagramStyle());
    expect(layout.size.height, greaterThan(layout.size.width));
    final box = {for (final s in layout.subgraphs) s.subgraph.id: s.rect};
    final start = layout.nodes.firstWhere((n) => n.node.id == 'M').rect;
    // Each comes wholly below the last, with the style's gap between:
    // room for the arrow joining them.
    final gap = const DiagramStyle().rankGap;
    expect(box['F1']!.top - start.bottom, moreOrLessEquals(gap));
    expect(box['F2']!.top - box['F1']!.bottom, moreOrLessEquals(gap));
    expect(box['F3']!.top - box['F2']!.bottom, moreOrLessEquals(gap));
    // The edges run from outline to outline.
    final joining = layout.edges.firstWhere(
      (e) => e.edge.from == 'F1' && e.edge.to == 'F2',
    );
    expect(joining.start.dy, moreOrLessEquals(box['F1']!.bottom));
    expect(joining.end.dy, moreOrLessEquals(box['F2']!.top));
    expect(_intruders(chart, layout), isEmpty);
  });

  // Subgraphs side by side with a node among them: pushing the node out of
  // one box widened the next, box after box, and the chart came out over
  // 3 000 px wide for nine nodes.
  test('a node among subgraphs side by side is placed once, clear of all', () {
    final chart = (parseMermaid(
      'flowchart TD\nsubgraph A\na1 --> a2\nend\n'
      'subgraph B\nb1 --> b2\nb2 --> b3\nb3 --> b4\nend\nX\n'
      'subgraph C\nc1 --> c2\nc2 --> c3\nend\na2 --> X\nX --> c3',
    ) as MermaidFlowchart).chart;
    final layout = layoutFlowchart(chart, const DiagramStyle());
    expect(_intruders(chart, layout), isEmpty);
    // No box lies on another: the three stand side by side.
    final boxes = [for (final s in layout.subgraphs) s.rect];
    for (var i = 0; i < boxes.length; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        expect(boxes[i].overlaps(boxes[j]), isFalse);
      }
    }
    // And no wider than every node in one row, with its gaps and boxes.
    const style = DiagramStyle();
    final row = layout.nodes.fold<double>(
      0,
      (sum, node) => sum + node.rect.width + style.nodeGap,
    );
    expect(
      layout.size.width,
      lessThan(row + boxes.length * 2 * style.subgraphPadding),
    );
  });
}
