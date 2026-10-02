/// The parser behind Mermaid's C4 fences (#530): `C4Context`,
/// `C4Container`, `C4Component`, `C4Dynamic` and `C4Deployment`.
///
/// A C4 diagram is a graph of boxes, so it is parsed into the flowchart
/// model the engine lays out and draws. An element — `Person`, `System`,
/// `Container`, `Component`, each `_Ext`, `Db` and `Queue` — is a card: its
/// stereotype, its name in bold, its technology and its description; a
/// database is a cylinder, a queue a stadium. A boundary — `Boundary`,
/// `Enterprise_Boundary`, `System_Boundary`, `Container_Boundary`, a
/// deployment `Node` — is a subgraph titled with its name and its type,
/// nested as written; one holding nothing is drawn as a box. A
/// relationship is a dashed edge with an arrow, its label and technology
/// along it: `Rel`, its `_U`, `_D`, `_L`, `_R` forms (a direction the
/// layout's ranks decide instead), `BiRel` with an arrow at each end,
/// `Rel_Back` pointing the other way, and `RelIndex` numbered.
///
/// An argument may be named (`$descr="…"`, `$techn="…"`). What only
/// styles or arranges (`UpdateElementStyle`, `UpdateRelStyle`,
/// `UpdateLayoutConfig`, `AddElementTag`, …) is drawn without. A call
/// the engine does not know, a relationship to a name never declared or to
/// a boundary, or a boundary left open is a [MermaidParseException] naming
/// its line.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// The headers of a C4 fence, lower case.
const Set<String> c4Headers = {
  'c4context',
  'c4container',
  'c4component',
  'c4dynamic',
  'c4deployment',
};

/// A call: its name, its arguments, and a `{` opening a boundary.
final RegExp _call = RegExp(r'^(\w+)\s*\((.*)\)\s*(\{)?\s*$');

/// A named argument: `$name=value`.
final RegExp _named = RegExp(r'^\$(\w+)\s*=\s*(.*)$');

/// An element's kind, the positions of its technology and description
/// among its arguments (after the alias and the label), and its outline.
typedef _ElementKind = ({String family, int? techn, int? descr});

/// The elements, by the family their keyword names: `person`, `system`,
/// `container`, `component`.
const Map<String, _ElementKind> _families = {
  'person': (family: 'person', techn: null, descr: 0),
  'system': (family: 'system', techn: null, descr: 0),
  'container': (family: 'container', techn: 0, descr: 1),
  'component': (family: 'component', techn: 0, descr: 1),
};

/// The boundaries, by keyword, and the type their title shows when the
/// call gives none.
const Map<String, String?> _boundaries = {
  'boundary': null,
  'enterprise_boundary': 'Enterprise',
  'system_boundary': 'System',
  'container_boundary': 'Container',
  'deployment_node': null,
  'node': null,
  'node_l': null,
  'node_r': null,
};

/// The relationships, by keyword, and which way their arrows point.
enum _Arrows { forward, back, both }

const Map<String, _Arrows> _relations = {
  'rel': _Arrows.forward,
  'rel_u': _Arrows.forward,
  'rel_up': _Arrows.forward,
  'rel_d': _Arrows.forward,
  'rel_down': _Arrows.forward,
  'rel_l': _Arrows.forward,
  'rel_left': _Arrows.forward,
  'rel_r': _Arrows.forward,
  'rel_right': _Arrows.forward,
  'rel_back': _Arrows.back,
  'birel': _Arrows.both,
  'relindex': _Arrows.forward,
};

/// Parses a C4 diagram (the fence's content, header included).
Flowchart parseC4(String source) => _C4Parser(source).parse();

/// An open boundary.
typedef _Open = ({
  String id,
  String title,
  String? type,
  int line,
  String? parent,
  List<String> ids,
});

/// A relationship as written, checked once every element is known.
typedef _Written = ({
  String from,
  String to,
  String? label,
  _Arrows arrows,
  int line,
});

final class _C4Parser {
  new(this.source);

  final String source;
  final Map<String, FlowNode> _nodes = {};
  final List<_Written> _written = [];
  final List<_Open> _open = [];
  final List<FlowSubgraph> _subgraphs = [];
  final Set<String> _boundaryIds = {};
  bool _description = false;

  Flowchart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    if (!c4Headers.contains(header)) {
      throw MermaidParseException(index + 1, 'expected "C4Context"');
    }
    for (index++; index < lines.length; index++) {
      final line = stripMermaidComment(lines[index]).trim();
      if (line.isNotEmpty) _line(line, index + 1);
    }
    if (_open.isNotEmpty) {
      throw MermaidParseException(_open.last.line, 'missing "}"');
    }
    if (_nodes.isEmpty) {
      throw const MermaidParseException(1, 'a C4 diagram needs an element');
    }
    return Flowchart(
      direction: FlowDirection.topDown,
      nodes: List.unmodifiable(_nodes.values),
      edges: [for (final relation in _written) _edge(relation)],
      subgraphs: List.unmodifiable(_subgraphs),
    );
  }

  void _line(String line, int number) {
    if (_description) {
      // An `accDescr { … }` block: words for a screen reader.
      _description = !line.contains('}');
      return;
    }
    if (line == '}') return _close(number);
    final word = RegExp(r'^\w+').stringMatch(line)?.toLowerCase() ?? '';
    if (word == 'title' || word == 'acctitle') return;
    if (word == 'accdescr') {
      _description = line.contains('{') && !line.contains('}');
      return;
    }
    final call = _call.firstMatch(line);
    if (call == null) {
      throw MermaidParseException(
        number,
        'expected an element, a boundary or a relationship '
        '(Rel(a, b, "label")), found "$line"',
      );
    }
    final name = call.group(1)!.toLowerCase();
    // Styles, tags and layout settings: drawn without.
    if (name.startsWith('update') || name.startsWith('add')) return;
    final (positional, named) = _arguments(call.group(2)!, number);
    if (_boundaries.containsKey(name)) {
      if (call.group(3) == null) {
        throw MermaidParseException(number, 'expected "{" after ${call[1]}');
      }
      return _openBoundary(name, positional, named, number);
    }
    if (call.group(3) != null) {
      throw MermaidParseException(number, '${call[1]} cannot hold others');
    }
    final arrows = _relations[name];
    if (arrows != null) return _relate(name, arrows, positional, named, number);
    _element(call.group(1)!, name, positional, named, number);
  }

  void _element(
    String keyword,
    String name,
    List<String> positional,
    Map<String, String> named,
    int number,
  ) {
    final external = name.endsWith('_ext');
    final base = external ? name.substring(0, name.length - 4) : name;
    final variant = base.endsWith('db')
        ? 'db'
        : base.endsWith('queue')
        ? 'queue'
        : null;
    final familyName = variant == null
        ? base
        : base.substring(0, base.length - variant.length);
    final family = _families[familyName];
    if (family == null || (familyName == 'person' && variant != null)) {
      throw MermaidParseException(
        number,
        'expected Person, System, Container, Component (each with _Ext, Db '
        'or Queue) or a boundary, found "$keyword"',
      );
    }
    if (positional.length < 2) {
      throw MermaidParseException(
        number,
        '$keyword needs an alias and a label',
      );
    }
    final id = positional[0];
    if (_nodes.containsKey(id) || _boundaryIds.contains(id)) {
      throw MermaidParseException(number, '"$id" is declared twice');
    }
    String? at(int? index, String key) {
      final value =
          named[key] ?? (index == null ? null : _at(positional, 2 + index));
      return value == null || value.isEmpty ? null : value;
    }

    final techn = at(family.techn, 'techn');
    final descr = at(family.descr, 'descr');
    final stereotype = [
      if (external) 'external',
      familyName,
      ?variant,
    ].join('_');
    _nodes[id] = FlowNode(
      id: id,
      label: positional[1],
      shape: switch (variant) {
        'db' => FlowNodeShape.database,
        'queue' => FlowNodeShape.stadium,
        _ => FlowNodeShape.round,
      },
      sections: [
        ['«$stereotype»'],
        [positional[1]],
        [
          if (techn != null) '[$techn]',
          if (descr != null) ...wrapMermaidText(descr),
        ],
      ],
    );
    _join(id);
  }

  void _openBoundary(
    String name,
    List<String> positional,
    Map<String, String> named,
    int number,
  ) {
    if (positional.length < 2) {
      throw MermaidParseException(
        number,
        'a boundary needs an alias and a label',
      );
    }
    final id = positional[0];
    if (_nodes.containsKey(id) || !_boundaryIds.add(id)) {
      throw MermaidParseException(number, '"$id" is declared twice');
    }
    final type = named['type'] ?? _at(positional, 2) ?? _boundaries[name];
    _open.add((
      id: id,
      title: positional[1],
      type: type == null || type.isEmpty ? null : type,
      line: number,
      parent: _open.isEmpty ? null : _open.last.id,
      ids: <String>[],
    ));
  }

  void _close(int number) {
    if (_open.isEmpty) throw MermaidParseException(number, 'unexpected "}"');
    final open = _open.removeLast();
    final type = open.type;
    if (open.ids.isEmpty) {
      // A boundary holding nothing: a box of its own, which a
      // relationship may then reach.
      _boundaryIds.remove(open.id);
      _nodes[open.id] = FlowNode(
        id: open.id,
        label: open.title,
        shape: FlowNodeShape.rect,
        sections: [
          [if (type != null) '[$type]'],
          [open.title],
          const [],
        ],
      );
      _join(open.id);
      return;
    }
    _subgraphs.add(
      FlowSubgraph(
        id: open.id,
        title: type == null ? open.title : '${open.title} [$type]',
        nodeIds: List.unmodifiable(open.ids),
        parent: open.parent,
      ),
    );
  }

  void _relate(
    String name,
    _Arrows arrows,
    List<String> positional,
    Map<String, String> named,
    int number,
  ) {
    final indexed = name == 'relindex';
    final first = indexed ? 1 : 0;
    if (positional.length < first + 2) {
      throw MermaidParseException(number, 'a relationship needs two aliases');
    }
    final label = named['label'] ?? _at(positional, first + 2);
    final techn = named['techn'] ?? _at(positional, first + 3);
    final text = [
      if (indexed) '${positional[0]}:',
      if (label != null && label.isNotEmpty) label,
      if (techn != null && techn.isNotEmpty) '[$techn]',
    ].join(' ');
    _written.add((
      from: positional[first],
      to: positional[first + 1],
      label: text.isEmpty ? null : text,
      arrows: arrows,
      line: number,
    ));
  }

  FlowEdge _edge(_Written relation) {
    for (final id in [relation.from, relation.to]) {
      if (_boundaryIds.contains(id)) {
        throw MermaidParseException(
          relation.line,
          'a relationship joins elements; "$id" is a boundary',
        );
      }
      if (!_nodes.containsKey(id)) {
        throw MermaidParseException(
          relation.line,
          'no element is called "$id"',
        );
      }
    }
    return FlowEdge(
      from: relation.from,
      to: relation.to,
      label: relation.label,
      style: FlowEdgeStyle.dotted,
      start: relation.arrows == _Arrows.forward
          ? FlowEdgeEnd.none
          : FlowEdgeEnd.arrow,
      end: relation.arrows == _Arrows.back
          ? FlowEdgeEnd.none
          : FlowEdgeEnd.arrow,
    );
  }

  /// Puts [id] in every boundary open around it.
  void _join(String id) {
    for (final open in _open) {
      open.ids.add(id);
    }
  }

  static String? _at(List<String> values, int index) =>
      index < values.length ? values[index] : null;

  /// The arguments of a call: the positional ones in order and the named
  /// ones by name, each unquoted with its entities written out. A comma
  /// inside quotes is text.
  static (List<String>, Map<String, String>) _arguments(
    String text,
    int number,
  ) {
    final parts = <String>[];
    var quoted = false;
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '"') {
        quoted = !quoted;
      } else if (ch == ',' && !quoted) {
        parts.add(text.substring(start, i));
        start = i + 1;
      }
    }
    if (quoted) throw MermaidParseException(number, 'a quote is never closed');
    parts.add(text.substring(start));
    final positional = <String>[];
    final named = <String, String>{};
    String clean(String value) =>
        decodeMermaidEntities(unquoteMermaid(value.trim()));
    for (final part in parts) {
      final match = _named.firstMatch(part.trim());
      if (match != null) {
        named[match.group(1)!.toLowerCase()] = clean(match.group(2)!);
      } else {
        positional.add(clean(part));
      }
    }
    // `Person(a, "A")` and `Person(a, "A", )` read alike.
    while (positional.isNotEmpty && positional.last.isEmpty) {
      positional.removeLast();
    }
    return (positional, named);
  }
}
