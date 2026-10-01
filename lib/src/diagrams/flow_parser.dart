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

import 'package:niman/src/diagrams/flow_edge_scanner.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';

/// Parses a flowchart body (the fence's content, header included).
Flowchart parseFlowchart(String source) => _FlowParser(source).parse();

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

/// Parses one flowchart source.
final class _FlowParser {
  new(this.source);

  /// The diagram body being parsed.
  final String source;
  final List<FlowNode> _nodes = [];
  final Map<String, FlowNode> _byId = {};
  final Map<String, int> _indexOf = {};
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
      for (final line in _statements(_stripComment(lines[index]))) {
        if (!sawHeader) {
          final word = _firstWord(line);
          if (word == 'flowchart' || word == 'graph') {
            final rest = line.substring(word.length).trim();
            // No direction is top-down, as Mermaid draws it.
            final parsed = rest.isEmpty
                ? FlowDirection.topDown
                : FlowDirection.parse(_firstWord(rest));
            if (parsed == null) {
              throw MermaidParseException(
                index + 1,
                'unknown direction "$rest" (TD, TB, BT, LR or RL)',
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
      final scan = scanFlowEdge(cursor.source, cursor.position, number);
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
      var label = cursor.readPipeLabel() ?? _unquoteOrNull(scan.label);
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
    final open = cursor.peek;
    if (open == '[' || open == '(' || open == '{' || open == '>') {
      final shaped = cursor.readShape(number);
      return _declare(id, shaped.shape, shaped.label);
    }
    // A bare mention names a node; it does not redraw one already given a
    // shape and a label (`B{Decide}` then `B --> C`).
    if (_byId.containsKey(id)) return _mention(id);
    return _declare(id, FlowNodeShape.rect, null);
  }

  /// Puts [id] in every subgraph open around the statement naming it: a
  /// node belongs to the subgraph it is mentioned in, as in Mermaid, not
  /// only to the one around its first mention.
  String _mention(String id) {
    for (final build in _stack) {
      if (build.members.add(id)) build.nodeIds.add(id);
    }
    return id;
  }

  /// Declares node [id], or redraws it with the [shape] and [label] a later
  /// statement wrote for it.
  String _declare(String id, FlowNodeShape shape, String? label) {
    final at = _indexOf[id];
    final text = (label == null || label.isEmpty) ? id : label;
    final node = FlowNode(id: id, label: text, shape: shape);
    _byId[id] = node;
    if (at == null) {
      _indexOf[id] = _nodes.length;
      _nodes.add(node);
    } else {
      _nodes[at] = node;
    }
    return _mention(id);
  }

  // -- small helpers -----------------------------------------------------

  static String _firstWord(String s) {
    final match = RegExp('^[A-Za-z_][A-Za-z0-9_-]*').firstMatch(s);
    return match?.group(0) ?? '';
  }

  /// [line] without its `%%` comment; a `%%` inside quotes is text.
  static String _stripComment(String line) {
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        quoted = !quoted;
      } else if (!quoted && line.startsWith('%%', i)) {
        return line.substring(0, i);
      }
    }
    return line;
  }

  /// The statements on [line], trimmed and not empty: Mermaid ends one at
  /// a `;` as well as at the end of the line (`graph TD;`, `A-->B;C`). A
  /// `;` inside quotes, a node's brackets or an edge's `|label|` is text.
  static Iterable<String> _statements(String line) sync* {
    var start = 0;
    var depth = 0;
    var quoted = false;
    var piped = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (quoted) {
        if (ch == '"') quoted = false;
        continue;
      }
      switch (ch) {
        case '"':
          quoted = true;
        case '[' || '(' || '{':
          depth++;
        case ']' || ')' || '}':
          if (depth > 0) depth--;
        case '|' when depth == 0:
          piped = !piped;
        case ';' when depth == 0 && !piped:
          final statement = line.substring(start, i).trim();
          if (statement.isNotEmpty) yield statement;
          start = i + 1;
      }
    }
    final last = line.substring(start).trim();
    if (last.isNotEmpty) yield last;
  }

  static String _trim(List<String> lines, int index) =>
      index < lines.length ? lines[index].trim() : '';

  static String? _unquoteOrNull(String? text) =>
      text == null ? null : _unquote(text);

  /// [text] without the double quotes around it. Only `"` quotes in
  /// Mermaid: an apostrophe is a letter (`Don't`, `l'utente`).
  static String _unquote(String text) {
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
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
  final Set<String> members = {};
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
      if (ch == '"') {
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
