/// A cursor over one flowchart statement (#530): the node ids, shapes and
/// labels the parser reads off it.
library;

import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';

/// A position over one statement's text.
final class FlowCursor {
  /// A cursor at the start of [source].
  new(this.source);

  /// The statement.
  final String source;

  /// Where in [source] the next read starts.
  int position = 0;

  /// Whether every character has been read.
  bool get atEnd => position >= source.length;

  /// The character at [position], or null at the end.
  String? get peek => atEnd ? null : source[position];

  /// What is left to read.
  String get rest => source.substring(position);

  /// Steps over spaces and tabs.
  void skipSpaces() {
    while (!atEnd && (source[position] == ' ' || source[position] == '\t')) {
      position++;
    }
  }

  /// Reads a node id: letters, digits, `_` and anything past ASCII.
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

  /// Steps over a node's `:::class` shorthand: a class is a colour a note's
  /// diagram is drawn without, like a `classDef`.
  void skipClass() {
    if (!source.startsWith(':::', position)) return;
    position += 3;
    while (!atEnd && !_classEnds) {
      position++;
    }
  }

  /// Whether a `:::class` name ends at [position]: at a space, a `&`, or
  /// the edge after it (`A:::warn-->B`); a lone `-` is the name's own.
  bool get _classEnds {
    final ch = source[position];
    if (' \t&=<'.contains(ch)) return true;
    return source.startsWith('--', position) ||
        source.startsWith('-.', position);
  }

  /// Reads an edge's `|label|`, or null when none starts here.
  String? readPipeLabel() {
    if (peek != '|') return null;
    final end = source.indexOf('|', position + 1);
    if (end < 0) return null;
    final label = source.substring(position + 1, end).trim();
    position = end + 1;
    return label;
  }

  /// Reads the shape a node's brackets give it and the label inside them,
  /// at diagram line [number] for the error an unclosed one throws.
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
    return unquoteMermaid(found.text.trim());
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
    final text = unquoteMermaid(
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
