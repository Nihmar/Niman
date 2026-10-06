/// The calls of a Mermaid C4 fence (#530): which keyword is an element, a
/// boundary or a relationship, and how a call's arguments read.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// A call: its name, its arguments, and a `{` opening a boundary.
final RegExp c4Call = RegExp(r'^(\w+)\s*\((.*)\)\s*(\{)?\s*$');

/// A named argument: `$name=value`.
final RegExp _named = RegExp(r'^\$(\w+)\s*=\s*(.*)$');

/// An element's kind, the positions of its technology and description
/// among its arguments (after the alias and the label), and its outline.
typedef C4ElementKind = ({String family, int? techn, int? descr});

/// The elements, by the family their keyword names: `person`, `system`,
/// `container`, `component`.
const Map<String, C4ElementKind> c4Families = {
  'person': (family: 'person', techn: null, descr: 0),
  'system': (family: 'system', techn: null, descr: 0),
  'container': (family: 'container', techn: 0, descr: 1),
  'component': (family: 'component', techn: 0, descr: 1),
};

/// The boundaries, by keyword, and the type their title shows when the
/// call gives none.
const Map<String, String?> c4Boundaries = {
  'boundary': null,
  'enterprise_boundary': 'Enterprise',
  'system_boundary': 'System',
  'container_boundary': 'Container',
  'deployment_node': null,
  'node': null,
  'node_l': null,
  'node_r': null,
};

/// Which way a relationship's arrows point.
enum C4Arrows {
  /// From the first alias to the second.
  forward,

  /// From the second to the first: `Rel_Back`.
  back,

  /// Both ways: `BiRel`.
  both,
}

/// The relationships, by keyword, and which way their arrows point.
const Map<String, C4Arrows> c4Relations = {
  'rel': C4Arrows.forward,
  'rel_u': C4Arrows.forward,
  'rel_up': C4Arrows.forward,
  'rel_d': C4Arrows.forward,
  'rel_down': C4Arrows.forward,
  'rel_l': C4Arrows.forward,
  'rel_left': C4Arrows.forward,
  'rel_r': C4Arrows.forward,
  'rel_right': C4Arrows.forward,
  'rel_back': C4Arrows.back,
  'birel': C4Arrows.both,
  'relindex': C4Arrows.forward,
};

/// The value at [index] of [values], or null past its end.
String? c4ArgumentAt(List<String> values, int index) =>
    index < values.length ? values[index] : null;

/// The arguments of a call: the positional ones in order and the named
/// ones by name, each unquoted with its entities written out. A comma
/// inside quotes is text.
(List<String>, Map<String, String>) readC4Arguments(String text, int number) {
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
