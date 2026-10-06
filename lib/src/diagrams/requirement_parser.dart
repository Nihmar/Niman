/// The parser behind a `requirementDiagram` Mermaid fence (#530).
///
/// A requirement diagram is a graph of boxes, so it is parsed into the
/// flowchart model the engine lays out and draws, as a class diagram is: a
/// requirement or an element is a box of two compartments — its kind and
/// name, then its attributes — and a relationship an edge labelled with
/// its kind. `A - satisfies -> B` and `B <- satisfies - A` say the same.
/// `contains` is a solid line with a circled cross at the one that
/// contains; the others are dashed with an arrow, as Mermaid draws them.
///
/// A requirement's text is wrapped at words, so a long one makes a taller
/// box rather than a wider one. An attribute a kind does not have, a risk
/// or a verification Mermaid does not know, a relationship to a name never
/// declared, or a block left open is a [MermaidParseException] naming its
/// line. What only colours (`style`, `classDef`, `class`, `:::`) is drawn
/// without, as in a flowchart.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// Each kind's keyword, lower case, and the stereotype its box shows.
const Map<String, String> _kinds = {
  'requirement': 'Requirement',
  'functionalrequirement': 'Functional Requirement',
  'interfacerequirement': 'Interface Requirement',
  'performancerequirement': 'Performance Requirement',
  'physicalrequirement': 'Physical Requirement',
  'designconstraint': 'Design Constraint',
  'element': 'Element',
};

/// The attributes a requirement has, and how its box writes each.
const Map<String, String> _requirementAttributes = {
  'id': 'ID',
  'text': 'Text',
  'risk': 'Risk',
  'verifymethod': 'Verification',
};

/// The attributes an element has, and how its box writes each.
const Map<String, String> _elementAttributes = {
  'type': 'Type',
  'docref': 'Doc Ref',
};

/// The values a risk and a verification take.
const Set<String> _risks = {'low', 'medium', 'high'};
const Set<String> _methods = {
  'analysis',
  'inspection',
  'test',
  'demonstration',
};

/// The kinds of relationship.
const Set<String> _relations = {
  'contains',
  'copies',
  'derives',
  'satisfies',
  'verifies',
  'refines',
  'traces',
};

/// The words whose line carries nothing to draw.
const Set<String> _ignored = {
  'style',
  'classdef',
  'class',
  'title',
  'acctitle',
  'accdescr',
};

/// A name: a word, or any text in double quotes.
const String _name = r'(?:"[^"]*"|[\w.]+)';

/// `kind Name {`, the `}` on the same line if the block is empty.
final RegExp _declaration = RegExp('^(\\w+)\\s+($_name)\\s*\\{\\s*(\\})?\$');

/// `A - kind -> B`.
final RegExp _forward = RegExp('^($_name)\\s*-\\s*(\\w+)\\s*->\\s*($_name)\$');

/// `B <- kind - A`.
final RegExp _backward = RegExp('^($_name)\\s*<-\\s*(\\w+)\\s*-\\s*($_name)\$');

/// `key: value` inside a block.
final RegExp _attribute = RegExp(r'^(\w+)\s*:\s*(.*)$');

/// Parses a requirement diagram (the fence's content, header included).
Flowchart parseRequirementDiagram(String source) =>
    _RequirementParser(source).parse();

/// A requirement or an element while its block is read.
typedef _Box = ({
  String name,
  String kind,
  Map<String, String> attributes,
  int line,
});

/// A relationship as written, checked once every box is known.
typedef _Relation = ({String from, String to, String kind, int line});

final class _RequirementParser {
  new(this.source);

  final String source;
  final Map<String, _Box> _boxes = {};
  final List<_Relation> _relationsWritten = [];
  FlowDirection _direction = FlowDirection.topDown;
  _Box? _open;
  bool _description = false;

  Flowchart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    if (header != 'requirementdiagram') {
      throw MermaidParseException(index + 1, 'expected "requirementDiagram"');
    }
    for (index++; index < lines.length; index++) {
      final line = stripMermaidComment(lines[index])
          .replaceAll(RegExp(r':::[\w-]+'), '')
          .trim();
      if (line.isNotEmpty) _line(line, index + 1);
    }
    final open = _open;
    if (open != null) throw MermaidParseException(open.line, 'missing "}"');
    if (_boxes.isEmpty) {
      throw const MermaidParseException(
        1,
        'a requirement diagram needs a requirement or an element',
      );
    }
    return Flowchart(
      direction: _direction,
      nodes: [for (final box in _boxes.values) _node(box)],
      edges: [for (final relation in _relationsWritten) _edge(relation)],
      subgraphs: const [],
    );
  }

  void _line(String line, int number) {
    final open = _open;
    if (open != null) {
      if (line == '}') {
        _open = null;
      } else {
        _attributeOf(open, line, number);
      }
      return;
    }
    if (_description) {
      // An `accDescr { … }` block: words for a screen reader.
      _description = !line.contains('}');
      return;
    }
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
    final declaration = _declaration.firstMatch(line);
    if (declaration != null) return _declare(declaration, number);
    final forward = _forward.firstMatch(line);
    final backward = _backward.firstMatch(line);
    if (forward != null || backward != null) {
      final match = (forward ?? backward)!;
      final kind = match.group(2)!.toLowerCase();
      if (!_relations.contains(kind)) {
        throw MermaidParseException(
          number,
          'a relationship is one of ${_relations.join(", ")}, found "$kind"',
        );
      }
      final a = _unquote(match.group(1)!);
      final b = _unquote(match.group(3)!);
      _relationsWritten.add((
        from: forward != null ? a : b,
        to: forward != null ? b : a,
        kind: kind,
        line: number,
      ));
      return;
    }
    throw MermaidParseException(
      number,
      'expected a requirement, an element or a relationship '
      '("A - satisfies -> B"), found "$line"',
    );
  }

  void _declare(RegExpMatch match, int number) {
    final keyword = match.group(1)!.toLowerCase();
    final kind = _kinds[keyword];
    if (kind == null) {
      throw MermaidParseException(
        number,
        'expected requirement, functionalRequirement, interfaceRequirement, '
        'performanceRequirement, physicalRequirement, designConstraint or '
        'element, found "${match.group(1)}"',
      );
    }
    final name = _unquote(match.group(2)!);
    if (_boxes.containsKey(name)) {
      throw MermaidParseException(number, '"$name" is declared twice');
    }
    final box = (
      name: name,
      kind: kind,
      attributes: <String, String>{},
      line: number,
    );
    _boxes[name] = box;
    if (match.group(3) == null) _open = box;
  }

  void _attributeOf(_Box box, String line, int number) {
    final match = _attribute.firstMatch(line);
    if (match == null) {
      throw MermaidParseException(
        number,
        'expected "key: value" or "}", found "$line"',
      );
    }
    final key = match.group(1)!.toLowerCase();
    final allowed = box.kind == 'Element'
        ? _elementAttributes
        : _requirementAttributes;
    if (!allowed.containsKey(key)) {
      throw MermaidParseException(
        number,
        '${box.kind == 'Element' ? 'an element' : 'a requirement'} has '
        '${allowed.keys.join(", ")}, not "${match.group(1)}"',
      );
    }
    final value = decodeMermaidEntities(unquoteMermaid(match.group(2)!.trim()));
    if (key == 'risk' && !_risks.contains(value.toLowerCase())) {
      throw MermaidParseException(
        number,
        'a risk is low, medium or high, found "$value"',
      );
    }
    if (key == 'verifymethod' && !_methods.contains(value.toLowerCase())) {
      throw MermaidParseException(
        number,
        'a verification is analysis, inspection, test or demonstration, '
        'found "$value"',
      );
    }
    box.attributes[key] = value;
  }

  FlowNode _node(_Box box) {
    final label = decodeMermaidEntities(box.name);
    final names = box.kind == 'Element'
        ? _elementAttributes
        : _requirementAttributes;
    final lines = <String>[
      for (final MapEntry(:key, value: written) in names.entries)
        if (box.attributes[key] case final value?)
          ...switch (key) {
            'text' => wrapMermaidText('$written: $value'),
            'risk' || 'verifymethod' => ['$written: ${_capital(value)}'],
            _ => ['$written: $value'],
          },
    ];
    return FlowNode(
      id: box.name,
      label: label,
      shape: FlowNodeShape.classBox,
      sections: [
        ['«${box.kind}»', label],
        if (lines.isNotEmpty) lines,
      ],
    );
  }

  FlowEdge _edge(_Relation relation) {
    for (final name in [relation.from, relation.to]) {
      if (!_boxes.containsKey(name)) {
        throw MermaidParseException(
          relation.line,
          'no requirement or element is called "$name"',
        );
      }
    }
    final contains = relation.kind == 'contains';
    return FlowEdge(
      from: relation.from,
      to: relation.to,
      label: '«${relation.kind}»',
      style: contains ? FlowEdgeStyle.solid : FlowEdgeStyle.dotted,
      start: contains ? FlowEdgeEnd.containment : FlowEdgeEnd.none,
      end: contains ? FlowEdgeEnd.none : FlowEdgeEnd.arrow,
    );
  }

  static String _unquote(String name) => unquoteMermaid(name.trim());

  static String _capital(String value) => value.isEmpty
      ? value
      : value[0].toUpperCase() + value.substring(1).toLowerCase();
}
