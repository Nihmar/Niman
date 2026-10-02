// Converting a list to a mind map (#530): the list's lines, the fence that
// replaces them, and a fence that parses back to the list's words.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/editor/list_to_mindmap.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The conversion of the list on the line holding [marker] in [note].
ListMindMap? _convert(String note, String marker) {
  final buffer = SourceBuffer.fromText(note);
  return listToMindMap(
    buffer: buffer,
    line: buffer.lineOf(note.indexOf(marker)),
  );
}

/// The chart the fence's body parses to.
Flowchart _parse(ListMindMap map) {
  final body = map.fence.sublist(1, map.fence.length - 1).join('\n');
  return (parseMermaid(body) as MermaidFlowchart).chart;
}

void main() {
  test('a single outermost item is the root', () {
    final map = _convert('- A\n  - B\n  - C\n', 'B')!;
    expect(map.fence, [
      '```mermaid',
      'mindmap',
      '  A',
      '    B',
      '    C',
      '```',
    ]);
    expect((map.startLine, map.endLine), (0, 3));
    expect(_parse(map).edges, hasLength(2));
  });

  test('several outermost items get a root to hang from', () {
    final map = _convert('- A\n- B\n', 'A')!;
    expect(map.fence, [
      '```mermaid',
      'mindmap',
      '  root',
      '    A',
      '    B',
      '```',
    ]);
    expect(_parse(map).nodes.map((n) => n.label), ['root', 'A', 'B']);
  });

  test('a line that is not a list item converts nothing', () {
    expect(_convert('Just prose\n', 'prose'), isNull);
  });

  test('only the list around the caret is taken', () {
    // The blank line ends the list: without it, `para` would be a lazy
    // continuation of B and `- C` the list going on, as CommonMark reads it.
    final map = _convert('para\n- A\n  - B\n\npara\n- C\n', 'B')!;
    expect((map.startLine, map.endLine), (1, 3));
  });

  test('a note with CRLF line ends converts', () {
    final map = _convert('Intro\r\n\r\n- A\r\n  - B\r\n', 'B')!;
    expect((map.startLine, map.endLine), (2, 4));
    expect(_parse(map).nodes.map((n) => n.label), ['A', 'B']);
  });

  test('a list item inside a code fence or a front matter is not a list', () {
    expect(_convert('```yaml\n- x\n- y\n```\n', '- x'), isNull);
    expect(_convert('---\ntags:\n  - a\n---\n', '- a'), isNull);
    expect(_convert('> - quoted\n', 'quoted'), isNull);
  });

  test('a loose list and its continuation lines are one list', () {
    final map = _convert('- A\n  more of A\n\n- B\n\n  - C\n', 'C')!;
    expect((map.startLine, map.endLine), (0, 6));
    expect(_parse(map).nodes.map((n) => n.label), [
      'root',
      'A more of A',
      'B',
      'C',
    ]);
  });

  test('what an item holds past its first line is its, the list going on', () {
    // A paragraph or a fence an item holds is a block of its own: the list
    // stopped at it, and the items after it were left a list.
    const held =
        '- A\n'
        '\n'
        '  more about A\n'
        '\n'
        '  ```\n'
        '  code of A\n'
        '  ```\n'
        '- B\n'
        '\n'
        'after\n';
    for (final marker in ['A\n', 'more', 'code of', 'B\n']) {
      final map = _convert(held, marker)!;
      expect((map.startLine, map.endLine), (0, 8), reason: marker);
      expect(_parse(map).nodes.map((n) => n.label), [
        'root',
        'A more about A code of A',
        'B',
      ]);
    }
    expect(_convert(held, 'after'), isNull);
    // A paragraph goes to the item as deep as it, not to the one before.
    const nested = '- A\n  - B\n\n    more about B\n- C\n';
    final map = _convert(nested, 'more')!;
    expect((map.startLine, map.endLine), (0, 5));
    expect(_parse(map).nodes.map((n) => n.label), [
      'root',
      'A',
      'B more about B',
      'C',
    ]);
  });

  test('asking whether a line has a list answers as converting it does', () {
    // The Tools sheet asks with one block read; the command converts.
    for (final note in [
      'para\n- A\n  - B\n\npara\n- C\n',
      '- A\n\n  more about A\n\n  ```\n  code\n  ```\n- B\n\nafter\n',
      '```yaml\n- x\n```\n> - quoted\n---\n',
      '1. one\n2. two\n- A\n',
    ]) {
      final buffer = SourceBuffer.fromText(note);
      for (var line = 0; line < buffer.lineCount; line++) {
        expect(
          hasListAt(buffer: buffer, line: line),
          listToMindMap(buffer: buffer, line: line) != null,
          reason: 'line $line of $note',
        );
      }
    }
  });

  test('depth is the list nesting, not the count of spaces', () {
    // One space is not a level in CommonMark: B is A's sibling.
    final map = _convert('- A\n - B\n   - C\n', 'C')!;
    expect(_parse(map).nodes.map((n) => n.label), ['root', 'A', 'B', 'C']);
    expect(_parse(map).edges.map((e) => '${e.from}>${e.to}'), [
      'n0>n1',
      'n0>n2',
      'n2>n3',
    ]);
  });

  test('another marker starts another list', () {
    final map = _convert('- A\n- B\n1. one\n2. two\n', 'two')!;
    expect((map.startLine, map.endLine), (2, 4));
  });

  test('an item keeps its words whatever Mermaid would read in them', () {
    final map = _convert(
      '- Buy milk (2 litres)\n  - f(x) [urgent]\n  - 50%% "off"\n  - ::icon\n',
      'Buy',
    )!;
    expect(_parse(map).nodes.map((n) => n.label), [
      'Buy milk (2 litres)',
      'f(x) [urgent]',
      '50%% "off"',
      '::icon',
    ]);
    expect(_parse(map).nodes.map((n) => n.shape).toSet(), {
      FlowNodeShape.round,
    });
  });
}
