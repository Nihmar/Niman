/// The parser behind a `mindmap` Mermaid fence (#530).
///
/// A mind map is a tree, and the tree is expressed by indentation: the first
/// line is the root, a deeper line is a child of the nearest shallower one.
/// It is turned into the flowchart model — the same nodes, the one drawing —
/// with branches left to right and no arrowheads, so a mind map and a
/// flowchart share their layout and their painter.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// The columns a tab counts as when indentation is measured.
const int _tabColumns = 4;

/// Parses a mind map body (the fence's content, `mindmap` line included).
Flowchart parseMindmap(String source) => _MindmapParser(source).parse();

/// The text and outline one mind-map line names.
typedef _MindNode = ({String label, FlowNodeShape shape});

/// Parses one mind map.
final class _MindmapParser {
  new(this.source);

  final String source;
  final List<FlowNode> _nodes = [];
  final List<FlowEdge> _edges = [];
  final List<({int indent, String id})> _open = [];
  var _declared = 0;

  /// Runs the parse and returns the tree as a left-to-right chart.
  Flowchart parse() {
    final lines = source.split('\n');
    var sawHeader = false;
    for (var index = mermaidBodyStart(lines); index < lines.length; index++) {
      final raw = stripMermaidComment(lines[index]);
      if (raw.trim().isEmpty) continue;
      if (!sawHeader) {
        if (_firstWord(raw) != 'mindmap') {
          throw MermaidParseException(index + 1, 'expected "mindmap"');
        }
        sawHeader = true;
        continue;
      }
      if (raw.trimLeft().startsWith('::')) continue;
      _line(raw, index + 1);
    }
    if (!sawHeader) {
      throw const MermaidParseException(1, 'expected "mindmap"');
    }
    if (_nodes.isEmpty) {
      throw const MermaidParseException(1, 'a mind map needs a root');
    }
    return Flowchart(
      direction: FlowDirection.leftRight,
      nodes: List.unmodifiable(_nodes),
      edges: List.unmodifiable(_edges),
      subgraphs: const [],
    );
  }

  void _line(String raw, int number) {
    final indent = _indentOf(raw);
    final node = _nodeOf(raw.trim());
    final id = 'n${_declared++}';
    _nodes.add(FlowNode(id: id, label: node.label, shape: node.shape));
    // The root's own indentation is whatever the first line carries; every
    // later line no deeper than it is a second root, which a mind map has
    // not.
    final rootIndent = _open.isEmpty ? indent : _open.first.indent;
    while (_open.isNotEmpty && _open.last.indent >= indent) {
      _open.removeLast();
    }
    if (_open.isEmpty) {
      if (_nodes.length > 1 || indent > rootIndent) {
        throw MermaidParseException(number, 'only one root is allowed');
      }
    } else {
      _edges.add(FlowEdge(from: _open.last.id, to: id, end: FlowEdgeEnd.none));
    }
    _open.add((indent: indent, id: id));
  }

  static int _indentOf(String line) {
    var columns = 0;
    for (final rune in line.runes) {
      if (rune == 0x20) {
        columns++;
      } else if (rune == 0x09) {
        columns = (columns ~/ _tabColumns + 1) * _tabColumns;
      } else {
        break;
      }
    }
    return columns;
  }

  /// The label and shape a line carries.
  ///
  /// A line with no delimiters is its own label in a rounded box, as Mermaid
  /// draws a bare mind-map node. The `id` before a delimiter is ignored: a
  /// mind map names its nodes by their text.
  static _MindNode _nodeOf(String text) {
    final body = _fromDelimiter(text);
    _MindNode? shaped;
    if (body.startsWith('((') && body.endsWith('))')) {
      shaped = (label: _inner(body, 2, 2), shape: FlowNodeShape.circle);
    } else if (body.startsWith('))') && body.endsWith('((')) {
      shaped = (label: _inner(body, 2, 2), shape: FlowNodeShape.circle);
    } else if (body.startsWith('{{') && body.endsWith('}}')) {
      shaped = (label: _inner(body, 2, 2), shape: FlowNodeShape.hexagon);
    } else if (body.startsWith('[') && body.endsWith(']')) {
      shaped = (label: _inner(body, 1, 1), shape: FlowNodeShape.rect);
    } else if (body.startsWith('(') && body.endsWith(')')) {
      shaped = (label: _inner(body, 1, 1), shape: FlowNodeShape.round);
    } else if (body.startsWith(')') && body.endsWith('(')) {
      shaped = (label: _inner(body, 1, 1), shape: FlowNodeShape.round);
    }
    if (shaped == null || shaped.label.isEmpty) {
      return (label: text, shape: shaped?.shape ?? FlowNodeShape.round);
    }
    return shaped;
  }

  static String _fromDelimiter(String text) {
    final at = text.indexOf(RegExp(r'[\(\[\{]'));
    return at <= 0 ? text : text.substring(at);
  }

  static String _inner(String body, int open, int close) {
    final label = body.substring(open, body.length - close).trim();
    return label;
  }

  static String _firstWord(String line) {
    final match = RegExp('^[A-Za-z_][A-Za-z0-9_-]*')
        .firstMatch(line.trimLeft());
    return match?.group(0) ?? '';
  }
}
