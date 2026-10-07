/// The parser behind a `flowchart` (or `graph`) Mermaid fence (#530).
///
/// It is hand-written, so a syntax error is not a null: every failure is a
/// [MermaidParseException] naming the line and what was expected, which the
/// read view underlines and the live view can move the caret to.
///
/// The supported grammar is Mermaid's own where it matters for a note:
/// directions, the node shapes, subgraphs, the edge spellings and their
/// labels, and the look `style` gives a node or a subgraph. Any other
/// directive is skipped; an unsupported shape or edge is reported,
/// never silently mis-drawn.
library;

import 'package:niman/src/diagrams/flow_cursor.dart';
import 'package:niman/src/diagrams/flow_edge_scanner.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_style.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// Parses a flowchart body (the fence's content, header included).
Flowchart parseFlowchart(String source) => _FlowParser(source).parse();

/// The keywords that open a directive: `style` is drawn, the rest a note
/// draws nothing for and skips. Mermaid's own spelling, case and all:
/// `Class` or `link` is a node.
const Set<String> _directives = {
  'classDef',
  'class',
  'style',
  'linkStyle',
  'click',
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

  /// The ids written with a shape (`A[Text]`), not only mentioned bare.
  final Set<String> _shaped = {};

  /// The look each `style` statement gave a node or a subgraph, by id.
  final Map<String, FlowNodeStyle> _styles = {};

  /// Runs the parse and returns the chart.
  Flowchart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);

    FlowDirection? direction;
    var sawHeader = false;
    for (; index < lines.length; index++) {
      for (final line in _statements(stripMermaidComment(lines[index]))) {
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
    // An id only ever mentioned bare that names a subgraph with nodes is
    // that subgraph, as in Mermaid (`A --> S`, `S1 --> S2`): its edges join
    // the box, and no node of that name is drawn. Mentioned before the
    // subgraph was written, it was taken for a node — one the layout then
    // pushed out of every box, which spread the chart thousands of pixels
    // wide.
    final boxes = {
      for (final subgraph in _subgraphs)
        if (subgraph.nodeIds.isNotEmpty) subgraph.id,
    };
    bool isBox(String id) => boxes.contains(id) && !_shaped.contains(id);
    return Flowchart(
      direction: direction ?? FlowDirection.topDown,
      nodes: List.unmodifiable([
        for (final node in _nodes)
          if (!isBox(node.id))
            if (_styles[node.id] case final style?)
              FlowNode(
                id: node.id,
                label: node.label,
                shape: node.shape,
                sections: node.sections,
                style: style,
              )
            else
              node,
      ]),
      edges: List.unmodifiable(_edges),
      subgraphs: List.unmodifiable([
        for (final subgraph in _subgraphs)
          FlowSubgraph(
            id: subgraph.id,
            title: subgraph.title,
            nodeIds: List.unmodifiable(
              subgraph.nodeIds.where((id) => !isBox(id)),
            ),
            direction: subgraph.direction,
            parent: subgraph.parent,
            style: _styles[subgraph.id],
          ),
      ]),
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
    if (_isDirective(line)) {
      if (word == 'style') _style(line, number);
      return;
    }
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
      title = decodeMermaidEntities(
        unquoteMermaid(rest.substring(bracket + 1, close).trim()),
      );
    } else {
      id = rest;
    }
    if (id.isEmpty) id = 'subgraph-${_subgraphs.length + 1}';
    _subgraphStartLine ??= number;
    _stack.add(
      _SubgraphBuild(
        id: id,
        title: (title == null || title.isEmpty) ? id : title,
        parent: _stack.isEmpty ? null : _stack.last.id,
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
        parent: build.parent,
      ),
    );
  }

  /// `style <id> fill:…,stroke:…`: the look of one node or subgraph,
  /// written before it or after it.
  void _style(String line, int number) {
    final rest = line.substring('style'.length).trim();
    final space = rest.indexOf(RegExp(r'\s'));
    if (space < 0) {
      throw MermaidParseException(
        number,
        'expected the properties after "style $rest"',
      );
    }
    final id = rest.substring(0, space);
    final style = FlowNodeStyle.parse(rest.substring(space + 1));
    _styles[id] = _styles[id]?.overlaid(style) ?? style;
  }

  // -- nodes and edges ---------------------------------------------------

  void _chain(String s, int number) {
    final cursor = FlowCursor(s);
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
      var label = _unquoteOrNull(cursor.readPipeLabel() ?? scan.label);
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

  List<String> _nodeList(FlowCursor cursor, int number) {
    final ids = <String>[];
    while (true) {
      ids.add(_nodeRef(cursor, number));
      cursor.skipSpaces();
      if (cursor.peek != '&') return ids;
      cursor.position++;
    }
  }

  String _nodeRef(FlowCursor cursor, int number) {
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
      cursor.skipClass();
      _shaped.add(id);
      return _declare(id, shaped.shape, shaped.label);
    }
    cursor.skipClass();
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

  /// Whether [line] is a directive: its keyword, then a space and an
  /// argument — not an edge or a shape, which make the word a node's id
  /// (`click --> B`).
  static bool _isDirective(String line) {
    final word = _firstWord(line);
    if (!_directives.contains(word)) return false;
    final rest = line.substring(word.length);
    if (rest.isEmpty || (rest[0] != ' ' && rest[0] != '\t')) return false;
    final argument = rest.trimLeft();
    return argument.isNotEmpty && !'-=.&[({>:'.contains(argument[0]);
  }

  static String _firstWord(String s) {
    final match = RegExp('^[A-Za-z_][A-Za-z0-9_-]*').firstMatch(s);
    return match?.group(0) ?? '';
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

  static String? _unquoteOrNull(String? text) =>
      text == null ? null : decodeMermaidEntities(unquoteMermaid(text));
}

/// The mutable state of one open `subgraph`.
final class _SubgraphBuild {
  new({required this.id, required this.title, this.parent});

  final String id;
  final String title;
  final String? parent;
  final List<String> nodeIds = [];
  final Set<String> members = {};
  FlowDirection? direction;
}
