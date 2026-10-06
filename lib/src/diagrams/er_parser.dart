/// The parser behind an `erDiagram` Mermaid fence (#530).
///
/// An entity-relationship diagram is a graph of boxes, so it is parsed into
/// the flowchart model the engine lays out and draws: an entity is a box —
/// its name, then its attributes, one a line — and a relationship an edge
/// ending in the crow's feet of its two cardinalities, solid when it
/// identifies (`--`) and dashed when it does not (`..`), its label on it.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// An entity's name: a word, dashes allowed (`LINE-ITEM`), or any text
/// between double quotes.
const String _name = r'(?:"[^"]+"|[A-Za-z_][\w-]*)';

/// A relationship: an entity, its cardinality, the line, the other
/// cardinality, the other entity, a colon and the label.
final RegExp _relationship = RegExp(
  '^($_name)\\s*(\\|o|\\|\\||\\}o|\\}\\|)(--|\\.\\.)(o\\||\\|\\||o\\{|\\|\\{)'
  '\\s*($_name)\\s*:\\s*(.*)\$',
);

/// An entity on its own: its name, an alias in brackets, a `{` opening its
/// attributes.
final RegExp _entity = RegExp(
  '^($_name)\\s*(?:\\[\\s*"?([^"\\]]*)"?\\s*\\])?\\s*(\\{)?\\s*(\\})?\$',
);

/// An attribute: its type, its name, its keys and a comment.
final RegExp _attribute = RegExp(
  r'^(\S+)\s+(\S+)(?:\s+((?:PK|FK|UK)(?:\s*,\s*(?:PK|FK|UK))*))?'
  r'(?:\s+"([^"]*)")?$',
);

/// The words whose line carries nothing to draw.
const Set<String> _ignored = {
  'style',
  'classdef',
  'class',
  'title',
  'acctitle',
  'accdescr',
};

/// Parses an entity-relationship diagram (the fence's content, header
/// included).
Flowchart parseErDiagram(String source) => _ErParser(source).parse();

/// An entity while it is being read: its drawn name and its attributes.
typedef _Entity = ({String label, List<String> attributes});

final class _ErParser {
  new(this.source);

  final String source;
  final Map<String, _Entity> _entities = {};
  final List<FlowEdge> _edges = [];
  FlowDirection _direction = FlowDirection.topDown;

  /// The entity whose `{ … }` attributes are open, and its line.
  String? _open;
  int _openLine = 0;

  Flowchart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    if (header != 'erdiagram') {
      throw MermaidParseException(index + 1, 'expected "erDiagram"');
    }
    for (index++; index < lines.length; index++) {
      final line = stripMermaidComment(lines[index])
          .replaceAll(RegExp(r':::[\w-]+'), '')
          .trim();
      if (line.isNotEmpty) _line(line, index + 1);
    }
    if (_open != null) throw MermaidParseException(_openLine, 'missing "}"');
    return Flowchart(
      direction: _direction,
      nodes: [
        for (final MapEntry(key: id, value: entity) in _entities.entries)
          FlowNode(
            id: id,
            label: decodeMermaidEntities(entity.label),
            shape: FlowNodeShape.classBox,
            sections: [
              [decodeMermaidEntities(entity.label)],
              if (entity.attributes.isNotEmpty)
                [
                  for (final text in entity.attributes)
                    decodeMermaidEntities(text),
                ],
            ],
          ),
      ],
      edges: List.unmodifiable(_edges),
      subgraphs: const [],
    );
  }

  void _line(String line, int number) {
    final open = _open;
    if (open != null) {
      if (line == '}') {
        _open = null;
        return;
      }
      final attribute = _attribute.firstMatch(line);
      if (attribute == null) {
        throw MermaidParseException(
          number,
          'expected an attribute ("type name"), found "$line"',
        );
      }
      _entities[open]!.attributes.add(_attributeText(attribute));
      return;
    }
    final word = line.split(RegExp(r'[\s:{]')).first.toLowerCase();
    if (_ignored.contains(word)) return;
    if (word == 'direction') {
      final direction = FlowDirection.parse(line.substring(9).trim());
      if (direction == null) {
        throw MermaidParseException(number, 'unknown direction');
      }
      _direction = direction;
      return;
    }
    final relationship = _relationship.firstMatch(line);
    if (relationship != null) return _relate(relationship);
    final entity = _entity.firstMatch(line);
    if (entity != null) {
      final id = _entityOf(entity.group(1)!, alias: entity.group(2));
      if (entity.group(3) != null && entity.group(4) == null) {
        _open = id;
        _openLine = number;
      }
      return;
    }
    throw MermaidParseException(
      number,
      'expected a relationship ("A ||--o{ B : label") or an entity, '
      'found "$line"',
    );
  }

  void _relate(RegExpMatch match) {
    _edges.add(
      FlowEdge(
        from: _entityOf(match.group(1)!),
        to: _entityOf(match.group(5)!),
        start: _cardinality(match.group(2)!),
        end: _cardinality(match.group(4)!),
        style: match.group(3) == '..'
            ? FlowEdgeStyle.dotted
            : FlowEdgeStyle.solid,
        label: _label(match.group(6)!),
      ),
    );
  }

  /// The crow's foot a cardinality draws, whichever side it is written on.
  static FlowEdgeEnd _cardinality(String mark) => switch (mark) {
    '||' => FlowEdgeEnd.one,
    '|o' || 'o|' => FlowEdgeEnd.zeroOrOne,
    '}|' || '|{' => FlowEdgeEnd.oneOrMore,
    _ => FlowEdgeEnd.zeroOrMore,
  };

  static String? _label(String written) {
    final label = decodeMermaidEntities(unquoteMermaid(written.trim()));
    return label.isEmpty ? null : label;
  }

  static String _attributeText(RegExpMatch match) {
    final keys = match.group(3);
    final comment = match.group(4);
    return [
      match.group(1)!,
      match.group(2)!,
      if (keys != null) keys.replaceAll(RegExp(r'\s*,\s*'), ', '),
      if (comment != null && comment.isNotEmpty) '"$comment"',
    ].join(' ');
  }

  /// The id of entity [written], made on first mention; an [alias] is the
  /// name drawn for it.
  String _entityOf(String written, {String? alias}) {
    final id = written.startsWith('"')
        ? written.substring(1, written.length - 1)
        : written;
    final existing = _entities[id];
    final label = alias == null || alias.trim().isEmpty ? null : alias.trim();
    if (existing == null) {
      _entities[id] = (label: label ?? id, attributes: <String>[]);
    } else if (label != null) {
      _entities[id] = (label: label, attributes: existing.attributes);
    }
    return id;
  }
}
