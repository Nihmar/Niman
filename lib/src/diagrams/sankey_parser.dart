/// The parser behind a `sankey-beta` Mermaid fence (#530).
///
/// A Sankey diagram is CSV, one flow a line: `source,target,value`, a
/// field in double quotes when it holds a comma (`""` for a quote in it).
/// Flows run one way: a flow that would close a loop, one from a node to
/// itself and a value that is not a number at least zero are errors on
/// their line, a [MermaidParseException].
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/sankey_model.dart';

/// Parses a Sankey diagram (the fence's content, header included).
SankeyChart parseSankey(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  final header = index < lines.length
      ? stripMermaidComment(lines[index]).trim().toLowerCase()
      : '';
  if (header != 'sankey-beta' && header != 'sankey') {
    throw MermaidParseException(index + 1, 'expected "sankey-beta"');
  }
  final nodes = <String>[];
  final byName = <String, int>{};
  final out = <List<int>>[];
  final links = <SankeyLink>[];
  int node(String name) => byName.putIfAbsent(name, () {
    nodes.add(name);
    out.add([]);
    return nodes.length - 1;
  });
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    if (line.isEmpty) continue;
    final number = index + 1;
    final fields = _fields(line, number);
    if (fields.length != 3) {
      throw MermaidParseException(
        number,
        'expected "source,target,value", found ${fields.length} fields',
      );
    }
    final value = double.tryParse(fields[2]);
    if (value == null || value < 0) {
      throw MermaidParseException(
        number,
        'expected a value of zero or more, found "${fields[2]}"',
      );
    }
    final from = node(fields[0]);
    final to = node(fields[1]);
    if (from == to || _reaches(out, to, from)) {
      throw MermaidParseException(
        number,
        'a flow cannot come back to "${fields[0]}"',
      );
    }
    out[from].add(to);
    links.add(SankeyLink(source: from, target: to, value: value));
  }
  if (links.isEmpty) {
    throw const MermaidParseException(1, 'a Sankey diagram needs a flow');
  }
  return SankeyChart(
    nodes: List.unmodifiable(nodes),
    links: List.unmodifiable(links),
  );
}

/// The fields of the CSV [line] (diagram line [number]).
List<String> _fields(String line, int number) {
  final fields = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (quoted) {
      if (ch == '"' && i + 1 < line.length && line[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (ch == '"') {
        quoted = false;
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      fields.add(field.toString().trim());
      field.clear();
    } else {
      field.write(ch);
    }
  }
  if (quoted) throw MermaidParseException(number, 'a quote is never closed');
  fields.add(field.toString().trim());
  return fields;
}

/// Whether [to] is reached from [from] along the flows so far.
bool _reaches(List<List<int>> out, int from, int to) {
  final seen = <int>{from};
  final stack = [from];
  while (stack.isNotEmpty) {
    final at = stack.removeLast();
    if (at == to) return true;
    for (final next in out[at]) {
      if (seen.add(next)) stack.add(next);
    }
  }
  return false;
}
