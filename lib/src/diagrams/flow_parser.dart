/// The parser behind a `flowchart` (or `graph`) Mermaid fence (#530).
///
/// It is hand-written, so a syntax error is not a null: every failure is a
/// [MermaidParseException] naming the line and what was expected, which the
/// read view underlines and the live view can move the caret to.
///
/// The supported grammar is Mermaid's own where it matters for a note:
/// directions, the node shapes, subgraphs, the edge spellings and their
/// labels. A directive is skipped; an unsupported shape or edge is reported,
/// never silently mis-drawn.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

/// Parses a flowchart body (the fence's content, header included).
Flowchart parseFlowchart(String source) => _FlowParser(source).parse();

/// What an edge spelling means: its stroke, tail cap and head cap.
typedef _EdgeMeaning = (FlowEdgeStyle, FlowEdgeEnd, FlowEdgeEnd);

/// The edge spellings that carry no label, longest first.
const Map<String, _EdgeMeaning> _edgeTokens = {
  '<-->': (FlowEdgeStyle.solid, FlowEdgeEnd.arrow, FlowEdgeEnd.arrow),
  'x--x': (FlowEdgeStyle.solid, FlowEdgeEnd.cross, FlowEdgeEnd.cross),
  'o--o': (FlowEdgeStyle.solid, FlowEdgeEnd.circle, FlowEdgeEnd.circle),
  'o--x': (FlowEdgeStyle.solid, FlowEdgeEnd.circle, FlowEdgeEnd.cross),
  'x--o': (FlowEdgeStyle.solid, FlowEdgeEnd.cross, FlowEdgeEnd.circle),
  '-.->': (FlowEdgeStyle.dotted, FlowEdgeEnd.none, FlowEdgeEnd.arrow),
  '<--': (FlowEdgeStyle.solid, FlowEdgeEnd.arrow, FlowEdgeEnd.none),
  'x--': (FlowEdgeStyle.solid, FlowEdgeEnd.cross, FlowEdgeEnd.none),
  'o--': (FlowEdgeStyle.solid, FlowEdgeEnd.circle, FlowEdgeEnd.none),
  '-->': (FlowEdgeStyle.solid, FlowEdgeEnd.none, FlowEdgeEnd.arrow),
  '---': (FlowEdgeStyle.solid, FlowEdgeEnd.none, FlowEdgeEnd.none),
  '--x': (FlowEdgeStyle.solid, FlowEdgeEnd.none, FlowEdgeEnd.cross),
  '--o': (FlowEdgeStyle.solid, FlowEdgeEnd.none, FlowEdgeEnd.circle),
  '-.-': (FlowEdgeStyle.dotted, FlowEdgeEnd.none, FlowEdgeEnd.none),
  '-.x': (FlowEdgeStyle.dotted, FlowEdgeEnd.none, FlowEdgeEnd.cross),
  '-.o': (FlowEdgeStyle.dotted, FlowEdgeEnd.none, FlowEdgeEnd.circle),
  '==>': (FlowEdgeStyle.thick, FlowEdgeEnd.none, FlowEdgeEnd.arrow),
  '===': (FlowEdgeStyle.thick, FlowEdgeEnd.none, FlowEdgeEnd.none),
  '==x': (FlowEdgeStyle.thick, FlowEdgeEnd.none, FlowEdgeEnd.cross),
  '==o': (FlowEdgeStyle.thick, FlowEdgeEnd.none, FlowEdgeEnd.circle),
};

/// An edge with an inline label: `-- text -->`, `-. text .->`, `== text ==>`.
final RegExp _inlineLabeled = RegExp(
  r'(--|==|-\.)\s*(.+?)\s*'
  r'(-->|---|--x|--o|==>|===|==x|==o|-\.->|-\.-|-\.x|-\.o)',
);

/// The opening runs that must be followed by an edge spelling, with the
/// spellings to suggest when they are not (the error a dangling `--` gives).
const List<(String, List<String>)> _dangling = [
  ('--', ['-->', '--x', '--o', '---']),
  ('==', ['==>', '==x', '==o', '===']),
  ('-.', ['-.->', '-.x', '-.o', '-.-']),
];

/// The keywords that open a directive a note draws nothing for; skipped.
const Set<String> _directives = {
  'classdef',
  'class',
  'style',
  'linkstyle',
  'click',
  'link',
  'callback',
};

/// One scanned edge: where it ends in the statement and what it means.
typedef _EdgeScan = ({
  int end,
  FlowEdgeStyle style,
  FlowEdgeEnd start,
  FlowEdgeEnd endCap,
  String? label,
});

/// Parses one flowchart source.
final class _FlowParser {
  new(this.source);

  /// The diagram body being parsed.
  final String source;
  final List<FlowNode> _nodes = [];
  final Map<String, FlowNode> _byId = {};
  final List<FlowEdge> _edges = [];
  final List<FlowSubgraph> _subgraphs = [];
  final List<_SubgraphBuild> _stack = [];
  int? _subgraphStartLine;

  /// Runs the parse and returns the chart.
  Flowchart parse() {
    final lines = source.split('\n');
    var index = 0;

    // An optional YAML frontmatter block (mermaid allows one) is skipped.
    if (_trim(lines, 0) == '---') {
      index = 1;
      while (index < lines.length && _trim(lines, index) != '---') {
        index++;
      }
      if (index >= lines.length) {
        throw const MermaidParseException(1, 'unterminated frontmatter');
      }
      index++;
    }

    FlowDirection? direction;
    var sawHeader = false;
    for (; index < lines.length; index++) {
      final line = _stripComment(lines[index]).trim();
      if (line.isEmpty) continue;
      if (!sawHeader) {
        final word = _firstWord(line);
        if (word == 'flowchart' || word == 'graph') {
          final rest = line.substring(word.length).trim();
          final parsed = FlowDirection.parse(_firstWord(rest));
          if (parsed == null) {
            throw MermaidParseException(
              index + 1,
              rest.isEmpty
                  ? 'expected a direction (TD, TB, BT, LR or RL)'
                  : 'unknown direction "$rest"',
            );
          }
          direction = parsed;
          sawHeader = true;
          continue;
        }
        throw MermaidParseException(
          index + 1,
          'expected "flowchart" or "graph"',
        );
      }
      _statement(line, index + 1);
    }
    if (!sawHeader) {
      throw const MermaidParseException(1, 'expected "flowchart" or "graph"');
    }
    if (_stack.isNotEmpty) {
      throw MermaidParseException(_subgraphStartLine ?? 1, 'missing "end"');
    }
    return Flowchart(
      direction: direction ?? FlowDirection.topDown,
      nodes: List.unmodifiable(_nodes),
      edges: List.unmodifiable(_edges),
      subgraphs: List.unmodifiable(_subgraphs),
    );
  }

  // -- statements --------------------------------------------------------

  void _statement(String line, int number) {
    final word = _firstWord(line).toLowerCase();
    if (word == 'subgraph') {
      _openSubgraph(line, number);
      return;
    }
    if (line == 'end') {
      _closeSubgraph(number);
      return;
    }
    if (word == 'direction') {
      final dir = FlowDirection.parse(
        _firstWord(line.substring('direction'.length).trim()),
      );
      if (dir == null) {
        throw MermaidParseException(number, 'unknown direction');
      }
      if (_stack.isNotEmpty) _stack.last.direction = dir;
      return;
    }
    if (_directives.contains(word)) return;
    _chain(line, number);
  }

  void _openSubgraph(String line, int number) {
    final rest = line.substring('subgraph'.length).trim();
    String id;
    String? title;
    if (rest.contains('[')) {
      final bracket = rest.indexOf('[');
      id = rest.substring(0, bracket).trim();
      final close = rest.indexOf(']', bracket);
      if (close < 0) {
        throw MermaidParseException(number, 'expected "]" to close the title');
      }
      title = rest.substring(bracket + 1, close).trim();
    } else {
      id = rest;
    }
    if (id.isEmpty) id = 'subgraph-${_subgraphs.length + 1}';
    _subgraphStartLine ??= number;
    _stack.add(
      _SubgraphBuild(
        id: id,
        title: (title == null || title.isEmpty) ? id : title,
      ),
    );
  }

  void _closeSubgraph(int number) {
    if (_stack.isEmpty) {
      throw MermaidParseException(number, 'unexpected "end"');
    }
    final build = _stack.removeLast();
    _subgraphStartLine = _stack.isEmpty ? null : _subgraphStartLine;
    _subgraphs.add(
      FlowSubgraph(
        id: build.id,
        title: build.title,
        nodeIds: List.unmodifiable(build.nodeIds),
        direction: build.direction,
      ),
    );
  }

  // -- nodes and edges ---------------------------------------------------

  void _chain(String s, int number) {
    final cursor = _Cursor(s);
    var sources = _nodeList(cursor, number);
    while (true) {
      cursor.skipSpaces();
      if (cursor.atEnd) return;
      final scan = _scanEdge(cursor, number);
      if (scan == null) {
        throw MermaidParseException(
          number,
          'expected an edge or the end of the statement, found '
          '"${cursor.rest}"',
        );
      }
      cursor
        ..position = scan.end
        ..skipSpaces();
      var label = cursor.readPipeLabel() ?? scan.label;
      if (label != null && label.isEmpty) label = null;
      final targets = _nodeList(cursor, number);
      for (final from in sources) {
        for (final to in targets) {
          _edges.add(
            FlowEdge(
              from: from,
              to: to,
              label: label,
              style: scan.style,
              start: scan.start,
              end: scan.endCap,
            ),
          );
        }
      }
      sources = targets;
    }
  }

  List<String> _nodeList(_Cursor cursor, int number) {
    final ids = <String>[];
    while (true) {
      ids.add(_nodeRef(cursor, number));
      cursor.skipSpaces();
      if (cursor.peek != '&') return ids;
      cursor.position++;
    }
  }

  String _nodeRef(_Cursor cursor, int number) {
    cursor.skipSpaces();
    final id = cursor.readId();
    if (id.isEmpty) {
      throw MermaidParseException(
        number,
        'expected a node id, found "${cursor.rest}"',
      );
    }
    var shape = FlowNodeShape.rect;
    String? label;
    final open = cursor.peek;
    if (open == '[' || open == '(' || open == '{' || open == '>') {
      final shaped = cursor.readShape(number);
      shape = shaped.shape;
      label = shaped.label;
    }
    return _declare(id, shape, label);
  }

  String _declare(String id, FlowNodeShape shape, String? label) {
    final existing = _byId[id];
    final text = (label == null || label.isEmpty) ? id : label;
    final node = FlowNode(id: id, label: text, shape: shape);
    if (existing == null) {
      _nodes.add(node);
      _byId[id] = node;
      for (final build in _stack) {
        if (!build.nodeIds.contains(id)) build.nodeIds.add(id);
      }
    } else {
      _byId[id] = node;
      _nodes[_nodes.indexOf(existing)] = node;
    }
    return id;
  }

  _EdgeScan? _scanEdge(_Cursor cursor, int number) {
    // An unlabelled spelling wins: without this, `A --> B --> C` would read
    // the second arrow as the close of an inline label on the first.
    for (final entry in _edgeTokens.entries) {
      if (cursor.source.startsWith(entry.key, cursor.position)) {
        final (style, start, endCap) = entry.value;
        return (
          end: cursor.position + entry.key.length,
          style: style,
          start: start,
          endCap: endCap,
          label: null,
        );
      }
    }
    final labelMatch = _inlineLabeled.matchAsPrefix(
      cursor.source,
      cursor.position,
    );
    if (labelMatch != null) {
      final open = labelMatch.group(1)!;
      final close = labelMatch.group(3)!;
      final meaning = _edgeTokens[close]!;
      return (
        end: labelMatch.end,
        style: switch (open) {
          '==' => FlowEdgeStyle.thick,
          '-.' => FlowEdgeStyle.dotted,
          _ => meaning.$1,
        },
        start: FlowEdgeEnd.none,
        endCap: meaning.$3,
        label: _unquote(labelMatch.group(2)!.trim()),
      );
    }
    for (final (prefix, options) in _dangling) {
      if (cursor.source.startsWith(prefix, cursor.position)) {
        throw MermaidParseException(
          number,
          'expected ${options.join(", ")} after "$prefix"',
        );
      }
    }
    return null;
  }

  // -- small helpers -----------------------------------------------------

  static String _firstWord(String s) {
    final match = RegExp('^[A-Za-z_][A-Za-z0-9_-]*').firstMatch(s);
    return match?.group(0) ?? '';
  }

  static String _stripComment(String line) {
    final at = line.indexOf('%%');
    return at < 0 ? line : line.substring(0, at);
  }

  static String _trim(List<String> lines, int index) =>
      index < lines.length ? lines[index].trim() : '';

  static String _unquote(String text) {
    if (text.length >= 2 &&
        ((text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith("'") && text.endsWith("'")))) {
      return text.substring(1, text.length - 1);
    }
    return text;
  }
}

/// The mutable state of one open `subgraph`.
final class _SubgraphBuild {
  new({required this.id, required this.title});

  final String id;
  final String title;
  final List<String> nodeIds = [];
  FlowDirection? direction;
}

/// A position over one statement's text.
final class _Cursor {
  new(this.source);

  final String source;
  int position = 0;

  bool get atEnd => position >= source.length;
  String? get peek => atEnd ? null : source[position];
  String get rest => source.substring(position);

  void skipSpaces() {
    while (!atEnd && (source[position] == ' ' || source[position] == '\t')) {
      position++;
    }
  }

  String readId() {
    final start = position;
    while (!atEnd) {
      final ch = source.codeUnitAt(position);
      final isId =
          (ch >= 0x41 && ch <= 0x5A) ||
          (ch >= 0x61 && ch <= 0x7A) ||
          (ch >= 0x30 && ch <= 0x39) ||
          ch == 0x5F ||
          ch > 0x7F;
      if (!isId) break;
      position++;
    }
    return source.substring(start, position);
  }

  String? readPipeLabel() {
    if (peek != '|') return null;
    final end = source.indexOf('|', position + 1);
    if (end < 0) return null;
    final label = source.substring(position + 1, end).trim();
    position = end + 1;
    return label;
  }

  ({FlowNodeShape shape, String label}) readShape(int number) {
    final open = peek!;
    if (open == '>') {
      position++;
      return (
        shape: FlowNodeShape.asymmetric,
        label: _readUntil(']', number, '">"'),
      );
    }
    if (open == '[') {
      if (source.startsWith('[[', position)) {
        position += 2;
        return (
          shape: FlowNodeShape.subroutine,
          label: _readUntil(']]', number, '"[["'),
        );
      }
      if (source.startsWith('[(', position)) {
        position += 2;
        return (
          shape: FlowNodeShape.database,
          label: _readUntil(')]', number, '"[("'),
        );
      }
      if (source.startsWith('[/', position)) {
        position += 2;
        final found = _scanAny(['/]', r'\]'], number, '"[/"');
        return (
          shape: found.close == '/]'
              ? FlowNodeShape.parallelogram
              : FlowNodeShape.trapezoid,
          label: found.text,
        );
      }
      if (source.startsWith(r'[\', position)) {
        position += 2;
        final found = _scanAny([r'\]', '/]'], number, r'"[\"');
        return (
          shape: found.close == r'\]'
              ? FlowNodeShape.parallelogramAlt
              : FlowNodeShape.trapezoidAlt,
          label: found.text,
        );
      }
      position++;
      return (shape: FlowNodeShape.rect, label: _readUntil(']', number, '"["'));
    }
    if (open == '(') {
      if (source.startsWith('((', position)) {
        position += 2;
        return (
          shape: FlowNodeShape.circle,
          label: _readUntil('))', number, '"(("'),
        );
      }
      if (source.startsWith('([', position)) {
        position += 2;
        return (
          shape: FlowNodeShape.stadium,
          label: _readUntil('])', number, '"(["'),
        );
      }
      position++;
      return (
        shape: FlowNodeShape.round,
        label: _readUntil(')', number, '"("'),
      );
    }
    // open == '{'
    if (source.startsWith('{{', position)) {
      position += 2;
      return (
        shape: FlowNodeShape.hexagon,
        label: _readUntil('}}', number, '"{{"'),
      );
    }
    position++;
    return (
      shape: FlowNodeShape.diamond,
      label: _readUntil('}', number, '"{"'),
    );
  }

  String _readUntil(String close, int number, String what) {
    final found = _scan(close);
    if (found == null) {
      throw MermaidParseException(number, 'expected "$close" after $what');
    }
    position = found.end;
    return _FlowParser._unquote(found.text.trim());
  }

  ({String text, String close}) _scanAny(
    List<String> closes,
    int number,
    String what,
  ) {
    var best = -1;
    String? bestClose;
    for (final close in closes) {
      final found = _scan(close);
      if (found != null && (best < 0 || found.end < best)) {
        best = found.end;
        bestClose = close;
      }
    }
    if (bestClose == null) {
      throw MermaidParseException(
        number,
        'expected one of ${closes.join(", ")} after $what',
      );
    }
    final text = _FlowParser._unquote(
      source.substring(position, best - bestClose.length).trim(),
    );
    position = best;
    return (text: text, close: bestClose);
  }

  ({String text, int end})? _scan(String close) {
    var i = position;
    String? quote;
    while (i < source.length) {
      final ch = source[i];
      if (quote != null) {
        if (ch == quote) quote = null;
        i++;
        continue;
      }
      if (ch == '"' || ch == "'") {
        quote = ch;
        i++;
        continue;
      }
      if (source.startsWith(close, i)) {
        return (text: source.substring(position, i), end: i + close.length);
      }
      i++;
    }
    return null;
  }
}
