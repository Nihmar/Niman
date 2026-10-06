/// The parser behind an `architecture-beta` Mermaid fence (#530).
///
/// An architecture diagram is its groups, `group api(cloud)[API]`, its
/// services, `service db(database)[Database] in api`, its junctions,
/// `junction hub in api`, and its edges, each from a side of one to a side
/// of another: `db:L -- R:server`, with an arrow at either end (`-->`,
/// `<--`, `<-->`), a label inside the dashes (`-[reads]-`), and `{group}`
/// after an id to leave or reach the group it sits in rather than itself.
/// An id written twice, a group or an edge naming one never declared, or a
/// line that does not read is a [MermaidParseException] naming its line.
library;

import 'package:niman/src/diagrams/architecture_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// `group id(icon)[title] in parent` and `service id(icon)[title] in group`.
final RegExp _node = RegExp(
  r'^(group|service)\s+([\w-]+)\s*(?:\(([^)]*)\))?\s*(?:\[([^\]]*)\])?'
  r'(?:\s+in\s+([\w-]+))?$',
  caseSensitive: false,
);

/// `junction id in group`.
final RegExp _junction = RegExp(
  r'^junction\s+([\w-]+)(?:\s+in\s+([\w-]+))?$',
  caseSensitive: false,
);

/// `a{group}:R <-[label]-> L:b{group}`.
final RegExp _edge = RegExp(
  r'^([\w-]+)(\{group\})?\s*:\s*([A-Za-z])\s*(<)?-(?:\[([^\]]*)\])?-(>)?'
  r'\s*([A-Za-z])\s*:\s*([\w-]+)(\{group\})?$',
);

/// Parses an architecture diagram (the fence's content, header included).
ArchitectureDiagram parseArchitecture(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  final header = index < lines.length
      ? stripMermaidComment(lines[index]).trim().toLowerCase()
      : '';
  if (header != 'architecture-beta' && header != 'architecture') {
    throw MermaidParseException(index + 1, 'expected "architecture-beta"');
  }
  final services = <ArchService>[];
  final groups = <ArchGroup>[];
  final edges = <(ArchEdge, int)>[];
  final declared = <String, int>{};
  final inGroup = <(String, int)>[];
  var description = false;

  void declare(String id, int number) {
    if (declared.containsKey(id)) {
      throw MermaidParseException(number, '"$id" is declared twice');
    }
    declared[id] = number;
  }

  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    final number = index + 1;
    if (description) {
      // An `accDescr { … }` block: words for a screen reader.
      description = !line.contains('}');
      continue;
    }
    if (line.isEmpty) continue;
    final lower = line.toLowerCase();
    if (lower.startsWith('acctitle') || lower.startsWith('accdescr')) {
      description = line.contains('{') && !line.contains('}');
      continue;
    }
    if (lower.startsWith('title ')) continue;
    final node = _node.firstMatch(line);
    if (node != null) {
      final id = node.group(2)!;
      declare(id, number);
      final icon = (node.group(3) ?? '').trim();
      final title = _text(node.group(4)) ?? id;
      final parent = node.group(5);
      if (parent != null) inGroup.add((parent, number));
      if (node.group(1)!.toLowerCase() == 'group') {
        groups.add(ArchGroup(id: id, title: title, icon: icon, parent: parent));
      } else {
        services.add(
          ArchService(id: id, title: title, icon: icon, group: parent),
        );
      }
      continue;
    }
    final junction = _junction.firstMatch(line);
    if (junction != null) {
      final id = junction.group(1)!;
      declare(id, number);
      final group = junction.group(2);
      if (group != null) inGroup.add((group, number));
      services.add(
        ArchService(
          id: id,
          title: '',
          icon: '',
          group: group,
          isJunction: true,
        ),
      );
      continue;
    }
    final edge = _edge.firstMatch(line);
    if (edge != null) {
      ArchSide side(String letter) =>
          ArchSide.parse(letter) ??
          (throw MermaidParseException(
            number,
            'a side is L, R, T or B, found "$letter"',
          ));
      edges.add((
        ArchEdge(
          from: edge.group(1)!,
          fromGroup: edge.group(2) != null,
          fromSide: side(edge.group(3)!),
          arrowAtFrom: edge.group(4) != null,
          label: _text(edge.group(5)),
          arrowAtTo: edge.group(6) != null,
          toSide: side(edge.group(7)!),
          to: edge.group(8)!,
          toGroup: edge.group(9) != null,
        ),
        number,
      ));
      continue;
    }
    throw MermaidParseException(
      number,
      'expected a group, a service, a junction or an edge '
      '("a:R -- L:b"), found "$line"',
    );
  }
  if (services.isEmpty) {
    throw const MermaidParseException(
      1,
      'an architecture diagram needs a service',
    );
  }
  final groupIds = {for (final group in groups) group.id};
  for (final (group, number) in inGroup) {
    if (!groupIds.contains(group)) {
      throw MermaidParseException(number, 'no group is called "$group"');
    }
  }
  final byId = {for (final service in services) service.id: service};
  for (final (edge, number) in edges) {
    for (final (id, wantsGroup) in [
      (edge.from, edge.fromGroup),
      (edge.to, edge.toGroup),
    ]) {
      final service = byId[id];
      if (service == null) {
        throw MermaidParseException(
          number,
          'no service or junction is called "$id"',
        );
      }
      if (wantsGroup && service.group == null) {
        throw MermaidParseException(number, '"$id" is in no group');
      }
    }
    if (edge.from == edge.to) {
      throw MermaidParseException(
        number,
        'an edge cannot join "${edge.from}" to itself',
      );
    }
  }
  return ArchitectureDiagram(
    services: List.unmodifiable(services),
    groups: List.unmodifiable(groups),
    edges: List.unmodifiable([for (final (edge, _) in edges) edge]),
  );
}

String? _text(String? written) {
  if (written == null) return null;
  final text = decodeMermaidEntities(unquoteMermaid(written.trim()));
  return text.isEmpty ? null : text;
}
