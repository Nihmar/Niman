/// The parser behind a `treemap-beta` Mermaid fence (#530).
///
/// A treemap is told by indentation: a line further right than the one
/// above it is inside it. A leaf is its name and its value, `"Leaf": 12`;
/// a section is its name alone, `"Section"`, and holds the lines indented
/// under it. A name is in double quotes when it holds a colon. A `:::class`
/// after a node is a colour drawn without, as in a flowchart. A leaf given
/// nodes under it, a section given none, or a value that is not a number at
/// least zero is a [MermaidParseException] naming its line.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/treemap_model.dart';

/// A node's `:::class` at the end of its line.
final RegExp _class = RegExp(r':::[\w-]+\s*$');

/// The columns a tab advances to the next multiple of.
const int _tabColumns = 4;

/// Parses a treemap (the fence's content, header included).
TreemapChart parseTreemap(String source) => _TreemapParser(source).parse();

final class _TreemapParser {
  new(this.source);

  final String source;
  final List<_Build> _roots = [];
  final List<(int, _Build)> _open = [];

  TreemapChart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    if (header != 'treemap-beta' && header != 'treemap') {
      throw MermaidParseException(index + 1, 'expected "treemap-beta"');
    }
    String? title;
    var description = false;
    for (index++; index < lines.length; index++) {
      final raw = stripMermaidComment(lines[index]);
      final line = raw.trim();
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
      if (lower.startsWith('title ')) {
        title = line.substring('title'.length).trim();
        continue;
      }
      if (lower.startsWith('classdef ') || lower.startsWith('class ')) {
        continue;
      }
      _node(raw, line, number);
    }
    if (_roots.isEmpty) {
      throw const MermaidParseException(1, 'a treemap needs a node');
    }
    return TreemapChart(
      roots: [for (final root in _roots) root.build()],
      title: title == null || title.isEmpty
          ? null
          : decodeMermaidEntities(title),
    );
  }

  void _node(String raw, String line, int number) {
    final indent = _indentOf(raw);
    final (label, value) = _read(line.replaceFirst(_class, '').trim(), number);
    final node = _Build(label, value, number);
    while (_open.isNotEmpty && _open.last.$1 >= indent) {
      _open.removeLast();
    }
    if (_open.isEmpty) {
      _roots.add(node);
    } else {
      final parent = _open.last.$2;
      if (parent.value != null) {
        throw MermaidParseException(
          number,
          '"${parent.label}" has a value, so it cannot hold "$label"',
        );
      }
      parent.children.add(node);
    }
    _open.add((indent, node));
  }

  /// A node's name and value: `"name": 12`, `name: 12`, or the name alone.
  (String, double?) _read(String text, int number) {
    String name;
    String rest;
    if (text.startsWith('"')) {
      final close = text.indexOf('"', 1);
      if (close < 0) {
        throw MermaidParseException(number, 'a quote is never closed');
      }
      name = text.substring(1, close);
      rest = text.substring(close + 1).trim();
    } else {
      final colon = text.lastIndexOf(':');
      name = colon < 0 ? text : text.substring(0, colon).trim();
      rest = colon < 0 ? '' : text.substring(colon).trim();
    }
    double? value;
    if (rest.isNotEmpty) {
      final written = rest.startsWith(':') ? rest.substring(1).trim() : null;
      value = written == null ? null : double.tryParse(written);
      if (value == null || !value.isFinite || value < 0) {
        throw MermaidParseException(
          number,
          'expected ": value" with a number of zero or more, found "$rest"',
        );
      }
    }
    final label = decodeMermaidEntities(name.trim());
    if (label.isEmpty) {
      throw MermaidParseException(number, 'a node needs a name');
    }
    return (label, value);
  }

  static int _indentOf(String line) {
    var columns = 0;
    for (final rune in line.runes) {
      if (rune == 0x20) {
        columns++;
      } else if (rune == 0x09) {
        columns = (columns ~/ _tabColumns + 1) * _tabColumns;
      } else {
        break;
      }
    }
    return columns;
  }
}

/// A node while the source is read.
final class _Build {
  new(this.label, this.value, this.line);

  final String label;
  final double? value;

  /// Its line, for the error a section with nothing in it gives.
  final int line;
  final List<_Build> children = [];

  TreemapNode build() {
    if (value == null && children.isEmpty) {
      throw MermaidParseException(
        line,
        '"$label" needs a value, or nodes indented under it',
      );
    }
    final node = TreemapNode(
      label: label,
      value: value,
      children: List.unmodifiable([
        for (final child in children) child.build(),
      ]),
    );
    // Values each a number may still add up past one: a section of
    // Infinity has no share of the whole to be drawn at.
    if (!node.total.isFinite) {
      throw MermaidParseException(
        line,
        'the values under "$label" add up past what a number holds',
      );
    }
    return node;
  }
}
