// An edge's label kept clear of what is drawn round it (#530): another
// edge's label, another edge's cap, a subgraph's outline. The cases are
// the ones renders showed — «satisfies» over the circled cross of a
// requirement's contains, "type" across a composite state's top.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/c4_parser.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flowchart_layout.dart';
import 'package:niman/src/diagrams/requirement_parser.dart';
import 'package:niman/src/diagrams/state_parser.dart';

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

const String _composite = '''
stateDiagram-v2
  [*] --> Idle
  Idle --> Editing : open
  Editing --> Saving : type
  Saving --> Editing : saved
  state Saving {
    [*] --> Writing
    Writing --> Indexing
    Indexing --> [*]
  }
  Editing --> Idle : close
  Idle --> [*]
  note right of Saving : off the UI isolate
''';

const String _c4 = '''
C4Context
  Person(writer, "Writer", "Writes notes on a phone and a desktop.")
  Enterprise_Boundary(home, "Home") {
    System(niman, "Niman", "Markdown notes, one file each, indexed for search.")
    System_Boundary(storage, "Storage") {
      SystemDb(disk, "Library folder", "One .md file per note.")
      SystemDb(index, "Search index", "SQLite FTS5, rebuilt from disk.")
    }
  }
  System_Ext(git, "Git remote", "Syncs the library between devices.")
  SystemQueue_Ext(mail, "Mail", "Sends exported notes.")
  Rel(writer, niman, "Writes and reads notes")
  Rel(niman, disk, "Saves", "dart:io")
  Rel(niman, index, "Queries", "FTS5")
  BiRel(niman, git, "Syncs", "HTTPS")
  Rel(niman, mail, "Shares")
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

  test('a label is wholly in a box or wholly out of it', () {
    // "type" sat where the edge into Saving crosses the composite's top;
    // "Saves" where a short edge crosses a boundary's title band.
    for (final chart in [parseStateDiagram(_composite), parseC4(_c4)]) {
      _wholly(layoutFlowchart(chart, const DiagramStyle()));
    }
  });
}

void _wholly(DiagramLayout layout) {
  for (final edge in layout.edges) {
    // The background the renderer draws round the label's box.
    final box = edge.labelBox?.inflate(
      const DiagramStyle().edgeLabelPadding.left,
    );
    if (box == null) continue;
    for (final sub in layout.subgraphs) {
      final inside =
          sub.rect.inflate(0.01).contains(box.topLeft) &&
          sub.rect.inflate(0.01).contains(box.bottomRight);
      expect(
        !box.overlaps(sub.rect) || inside,
        isTrue,
        reason: '${edge.label} across ${sub.title}',
      );
    }
  }
}
