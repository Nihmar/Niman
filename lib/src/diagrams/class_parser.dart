/// The parser behind a `classDiagram` Mermaid fence (#530).
///
/// A class diagram is a graph of boxes, so it is parsed into the flowchart
/// model the engine lays out and draws: a class is a box of three
/// compartments, a relation an edge with UML's ends and its two
/// cardinalities, a note a box tied to its class, a `namespace` a subgraph.
/// What only colours a class (`style`, `cssClass`, `:::`) or links it
/// (`click`, `link`, `callback`) is stepped over.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// A class's name: a word, dots allowed, a `~generic~` after it, or any
/// text between backticks.
const String _name = r'(?:`[^`]+`|[\w.]+(?:~[^~]*~)?)';

/// `class Name`, a `["label"]`, a `:::style`, and a `{` opening its body.
final RegExp _declaration = RegExp(
  '^class\\s+($_name)\\s*(?:\\["([^"]*)"\\])?\\s*(?::::\\S+)?\\s*(\\{.*)?\$',
);

/// A relation: two names, the ends and line between them, a cardinality
/// beside each name, a label after a colon.
final RegExp _relation = RegExp(
  '^($_name)\\s*(?:"([^"]*)"\\s*)?'
  r'(<\||\*|o|<)?(--|\.\.)(\|>|\*|o|>)?'
  '\\s*(?:"([^"]*)"\\s*)?($_name)\\s*(?::\\s*(.*))?\$',
);

/// `Name : member`.
final RegExp _member = RegExp('^($_name)\\s*:\\s*(.+)\$');

/// `<<interface>> Name`.
final RegExp _annotation = RegExp('^<<([^>]+)>>\\s*($_name)\$');

/// `note "text"` and `note for Name "text"`.
final RegExp _note = RegExp('^note\\s+(?:for\\s+($_name)\\s+)?"(.*)"\$');

/// The words whose line carries nothing to draw.
const Set<String> _ignored = {
  'style',
  'cssclass',
  'classdef',
  'click',
  'link',
  'callback',
  'acctitle',
  'accdescr',
  'title',
};

/// Parses a class diagram (the fence's content, header included).
Flowchart parseClassDiagram(String source) => _ClassParser(source).parse();

/// One class while it is being read.
typedef _Class = ({
  String id,
  String name,
  List<String> annotations,
  List<String> attributes,
  List<String> methods,
});

/// One open `namespace`.
typedef _Namespace = ({String id, int line, String? parent, List<String> ids});

final class _ClassParser {
  new(this.source);

  final String source;
  final Map<String, _Class> _classes = {};
  final List<FlowNode> _notes = [];
  final List<FlowEdge> _edges = [];
  final List<FlowSubgraph> _subgraphs = [];
  final List<_Namespace> _namespaces = [];
  FlowDirection _direction = FlowDirection.topDown;

  /// Whether an `accDescr { … }` block is open.
  bool _description = false;

  /// The class whose `{ … }` body is open, and the line it opened on.
  _Class? _body;
  int _bodyLine = 0;

  Flowchart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    if (header != 'classdiagram' && header != 'classdiagram-v2') {
      throw MermaidParseException(index + 1, 'expected "classDiagram"');
    }
    for (index++; index < lines.length; index++) {
      final line = stripMermaidComment(lines[index]).trim();
      if (line.isNotEmpty) _line(line, index + 1);
    }
    if (_body != null) {
      throw MermaidParseException(_bodyLine, 'missing "}"');
    }
    if (_namespaces.isNotEmpty) {
      throw MermaidParseException(_namespaces.last.line, 'missing "}"');
    }
    return Flowchart(
      direction: _direction,
      nodes: [for (final build in _classes.values) _node(build), ..._notes],
      edges: List.unmodifiable(_edges),
      subgraphs: List.unmodifiable(_subgraphs),
    );
  }

  void _line(String line, int number) {
    final body = _body;
    if (body != null) {
      if (line == '}') {
        _body = null;
      } else {
        _memberOf(body, line);
      }
      return;
    }
    if (_description) {
      // An `accDescr { … }` block: words for a screen reader.
      _description = !line.contains('}');
      return;
    }
    if (line == '}') return _closeNamespace(number);
    final word = line.split(RegExp(r'[\s:{]')).first.toLowerCase();
    if (_ignored.contains(word)) {
      _description =
          word == 'accdescr' && line.contains('{') && !line.contains('}');
      return;
    }
    if (word == 'direction') {
      final direction = FlowDirection.parse(line.substring(9).trim());
      if (direction == null) {
        throw MermaidParseException(number, 'unknown direction');
      }
      _direction = direction;
      return;
    }
    if (word == 'namespace') return _openNamespace(line, number);
    final declaration = _declaration.firstMatch(line);
    if (declaration != null) return _declare(declaration, number);
    final annotation = _annotation.firstMatch(line);
    if (annotation != null) {
      _class(annotation.group(2)!).annotations.add(annotation.group(1)!);
      return;
    }
    final note = _note.firstMatch(line);
    if (note != null) return _noteOf(note);
    final relation = _relation.firstMatch(line);
    if (relation != null) return _relate(relation);
    final member = _member.firstMatch(line);
    if (member != null) return _memberOf(_class(member.group(1)!), member[2]!);
    throw MermaidParseException(
      number,
      'expected a class, a relation or a member, found "$line"',
    );
  }

  void _declare(RegExpMatch match, int number) {
    final build = _class(match.group(1)!, label: match.group(2));
    final body = match.group(3);
    if (body == null) return;
    // `{` opens the body; members may follow it, and `}` may close it, on
    // the same line.
    final inline = body.substring(1).trim();
    final closed = inline.endsWith('}');
    final members = closed ? inline.substring(0, inline.length - 1) : inline;
    for (final member in members.split(';')) {
      if (member.trim().isNotEmpty) _memberOf(build, member.trim());
    }
    if (!closed) {
      _body = build;
      _bodyLine = number;
    }
  }

  void _memberOf(_Class build, String member) {
    final annotation = RegExp(r'^<<([^>]+)>>$').firstMatch(member);
    if (annotation != null) {
      build.annotations.add(annotation.group(1)!);
      return;
    }
    // `$` (static) and `*` (abstract) after a member are UML's underline
    // and italics, which a box drawn in one face leaves out.
    var text = member.replaceAll(RegExp(r'[$*]$'), '').trim();
    text = text.replaceAllMapped(RegExp('~([^~]*)~'), (m) => '<${m[1]}>');
    (text.contains('(') ? build.methods : build.attributes).add(text);
  }

  void _relate(RegExpMatch match) {
    final from = _class(match.group(1)!).id;
    final to = _class(match.group(7)!).id;
    final label = match.group(8)?.trim();
    _edges.add(
      FlowEdge(
        from: from,
        to: to,
        style: match.group(4) == '..'
            ? FlowEdgeStyle.dotted
            : FlowEdgeStyle.solid,
        start: _end(match.group(3)),
        end: _end(match.group(5)),
        startLabel: match.group(2),
        endLabel: match.group(6),
        label: label == null || label.isEmpty ? null : label,
      ),
    );
  }

  static FlowEdgeEnd _end(String? mark) => switch (mark) {
    '<|' || '|>' => FlowEdgeEnd.triangle,
    '*' => FlowEdgeEnd.diamond,
    'o' => FlowEdgeEnd.hollowDiamond,
    '<' || '>' => FlowEdgeEnd.arrow,
    _ => FlowEdgeEnd.none,
  };

  void _noteOf(RegExpMatch match) {
    final id = 'note-${_notes.length}';
    _notes.add(
      FlowNode(
        id: id,
        label: match.group(2)!.replaceAll(r'\n', '\n'),
        shape: FlowNodeShape.note,
      ),
    );
    _join(id);
    final target = match.group(1);
    if (target == null) return;
    _edges.add(
      FlowEdge(
        from: id,
        to: _class(target).id,
        style: FlowEdgeStyle.dotted,
        end: FlowEdgeEnd.none,
      ),
    );
  }

  void _openNamespace(String line, int number) {
    final name = line.substring('namespace'.length).replaceAll('{', '').trim();
    if (name.isEmpty) {
      throw MermaidParseException(number, 'a namespace needs a name');
    }
    _namespaces.add((
      id: name,
      line: number,
      parent: _namespaces.isEmpty ? null : _namespaces.last.id,
      ids: <String>[],
    ));
  }

  void _closeNamespace(int number) {
    if (_namespaces.isEmpty) {
      throw MermaidParseException(number, 'unexpected "}"');
    }
    final open = _namespaces.removeLast();
    _subgraphs.add(
      FlowSubgraph(
        id: open.id,
        title: open.id,
        nodeIds: List.unmodifiable(open.ids),
        parent: open.parent,
      ),
    );
  }

  /// The class [written] names, made on first mention: its id is the name
  /// without backticks or generic, its drawn name has `<T>` for `~T~`.
  _Class _class(String written, {String? label}) {
    final plain = written.startsWith('`')
        ? written.substring(1, written.length - 1)
        : written;
    final id = plain.split('~').first;
    final existing = _classes[id];
    if (existing != null) {
      if (label == null && !plain.contains('~')) return existing;
      final named = (
        id: id,
        name: label ?? _generic(plain),
        annotations: existing.annotations,
        attributes: existing.attributes,
        methods: existing.methods,
      );
      return _classes[id] = named;
    }
    _join(id);
    return _classes[id] = (
      id: id,
      name: label ?? _generic(plain),
      annotations: <String>[],
      attributes: <String>[],
      methods: <String>[],
    );
  }

  /// Puts node [id] in every namespace open around it.
  void _join(String id) {
    for (final open in _namespaces) {
      open.ids.add(id);
    }
  }

  static String _generic(String name) =>
      name.replaceAllMapped(RegExp('~([^~]*)~'), (m) => '<${m[1]}>');

  static FlowNode _node(_Class build) => FlowNode(
    id: build.id,
    label: build.name,
    shape: FlowNodeShape.classBox,
    sections: [
      [for (final annotation in build.annotations) '«$annotation»', build.name],
      List.unmodifiable(build.attributes),
      List.unmodifiable(build.methods),
    ],
  );
}
