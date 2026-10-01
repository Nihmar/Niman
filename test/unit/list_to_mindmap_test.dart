// Converting a list to a mind map (#530): pure text out, and it parses.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/editor/list_to_mindmap.dart';

/// The source between the first pair of fences.
String _body(String text) {
  final lines = text.split('\n');
  final open = lines.indexWhere((line) => line.startsWith('```'));
  final close = lines.lastIndexOf('```');
  return lines.sublist(open + 1, close).join('\n');
}

void main() {
  test('a single outermost item is the root', () {
    const note = '- A\n  - B\n  - C\n';
    final edit = convertListToMindMap(
      text: note,
      selection: const TextSelection.collapsed(offset: 6),
    )!;
    expect(edit.text, '```mermaid\nmindmap\n  A\n    B\n    C\n```\n');
    final chart = parseMermaid(_body(edit.text)) as MermaidFlowchart;
    expect(chart.chart.nodes.map((n) => n.label), ['A', 'B', 'C']);
    expect(chart.chart.edges, hasLength(2));
  });

  test('several outermost items get a root to hang from', () {
    const note = '- A\n- B\n';
    final edit = convertListToMindMap(
      text: note,
      selection: const TextSelection.collapsed(offset: 2),
    )!;
    expect(edit.text, '```mermaid\nmindmap\n  root\n    A\n    B\n```\n');
    final chart = parseMermaid(_body(edit.text)) as MermaidFlowchart;
    expect(chart.chart.nodes.map((n) => n.label), ['root', 'A', 'B']);
    expect(chart.chart.edges, hasLength(2));
  });

  test('the caret lands at the start of the block', () {
    const note = 'Intro\n\n- A\n  - B\n';
    final offset = note.indexOf('- A');
    final edit = convertListToMindMap(
      text: note,
      selection: TextSelection.collapsed(offset: offset + 2),
    )!;
    expect(edit.text.startsWith('Intro\n\n```mermaid'), isTrue);
    expect(edit.selection.baseOffset, 'Intro\n\n'.length);
  });

  test('a line that is not a list item converts nothing', () {
    expect(
      convertListToMindMap(
        text: 'Just prose\n',
        selection: const TextSelection.collapsed(offset: 2),
      ),
      isNull,
    );
  });

  test('only the contiguous list around the caret is taken', () {
    const note = 'para\n- A\n  - B\npara\n- C\n';
    final edit = convertListToMindMap(
      text: note,
      selection: const TextSelection.collapsed(offset: 7),
    )!;
    expect(edit.text.contains('  A'), isTrue);
    expect(edit.text.contains('    B'), isTrue);
    // The list after the paragraph is left alone.
    expect(edit.text.endsWith('para\n- C\n'), isTrue);
  });
}
