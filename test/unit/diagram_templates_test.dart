// The blocks the Insert commands drop (#530) parse, so a writer who asks for
// a diagram or a mind map sees one instead of an error.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/editor/diagram_templates.dart';

/// The source between the fences of [fence].
String _body(String fence) {
  final lines = fence.split('\n');
  return lines.sublist(1, lines.length - 1).join('\n');
}

void main() {
  test('the diagram template is a valid flowchart', () {
    expect(
      parseMermaid(_body(mermaidDiagramTemplate)),
      isA<MermaidFlowchart>(),
    );
  });

  test('the mind map template is a valid mind map', () {
    expect(
      parseMermaid(_body(mermaidMindMapTemplate)),
      isA<MermaidFlowchart>(),
    );
  });
}
