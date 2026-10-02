// An edge's label kept clear of what is drawn round it (#530): another
// edge's label, another edge's cap. The case is the one a render showed —
// «satisfies» over the circled cross of a requirement's contains.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/requirement_parser.dart';

const String _source = '''
requirementDiagram
requirement notes_on_disk {
  id: 1
  text: Every note is one Markdown file on disk; the index can be rebuilt from it.
  risk: high
  verifymethod: test
}
functionalRequirement search {
  id: 1.1
  text: Full-text search answers in under 100 ms.
  risk: medium
  verifymethod: demonstration
}
performanceRequirement scale {
  id: 1.2
  text: A library of one million notes stays usable.
  risk: high
  verifymethod: analysis
}
element fts_index {
  type: SQLite FTS5
  docref: lib/src/search
}
notes_on_disk - contains -> search
notes_on_disk - contains -> scale
fts_index - satisfies -> search
scale <- verifies - fts_index
''';

/// Where [edge]'s caps are drawn: a box round each marked end.
List<Rect> _caps(LaidOutEdge edge) => [
  if (edge.edge.start.isMarked) Rect.fromCircle(center: edge.start, radius: 14),
  if (edge.edge.end.isMarked) Rect.fromCircle(center: edge.end, radius: 14),
];

void main() {
  test("no label covers another's, nor another edge's cap", () {
    final layout = layoutFlowchart(
      parseRequirementDiagram(_source),
      const DiagramStyle(),
    );
    final edges = layout.edges;
    for (var i = 0; i < edges.length; i++) {
      final box = edges[i].labelBox!;
      for (var j = 0; j < edges.length; j++) {
        if (i == j) continue;
        expect(
          box.overlaps(edges[j].labelBox!),
          isFalse,
          reason: '${edges[i].label} over ${edges[j].label}',
        );
        for (final cap in _caps(edges[j])) {
          expect(
            box.overlaps(cap),
            isFalse,
            reason: '${edges[i].label} over the cap of ${edges[j].label}',
          );
        }
      }
      for (final node in layout.nodes) {
        expect(box.overlaps(node.rect), isFalse, reason: edges[i].label);
      }
    }
  });
}
