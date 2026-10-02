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
}
