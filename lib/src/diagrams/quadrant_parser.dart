/// The parser behind a `quadrantChart` Mermaid fence (#530).
///
/// A quadrant chart is a `title`, its two axes (`x-axis Low --> High`),
/// the names of its four quadrants (`quadrant-1` top right, then counter
/// clockwise) and one point a line, `name: [x, y]`, both from 0 to 1, a
/// `radius:` after it if wanted. Colours and classes are drawn without.
/// Like the other parsers it reports a syntax error as a
/// [MermaidParseException] naming the line.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/quadrant_model.dart';

/// `name: [x, y]`, a `:::class` and a style after it allowed.
final RegExp _point = RegExp(
  r'^(.+?)(?::::[\w-]+)?\s*:\s*\[\s*([^,\]]+)\s*,\s*([^\]]+?)\s*\](.*)$',
);

/// Parses a quadrant chart (the fence's content, header included).
QuadrantChart parseQuadrant(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  if (index >= lines.length ||
      stripMermaidComment(lines[index]).trim().toLowerCase() !=
          'quadrantchart') {
    throw MermaidParseException(index + 1, 'expected "quadrantChart"');
  }
  String? title;
  (String?, String?) xAxis = (null, null);
  (String?, String?) yAxis = (null, null);
  final quadrants = List<String?>.filled(4, null);
  final points = <QuadrantPoint>[];
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    if (line.isEmpty) continue;
    final number = index + 1;
    final space = line.indexOf(' ');
    final word = (space < 0 ? line : line.substring(0, space)).toLowerCase();
    final rest = space < 0 ? '' : line.substring(space).trim();
    switch (word) {
      case 'title':
        title = rest;
      case 'x-axis':
        xAxis = _axis(rest);
      case 'y-axis':
        yAxis = _axis(rest);
      case 'quadrant-1' || 'quadrant-2' || 'quadrant-3' || 'quadrant-4':
        quadrants[int.parse(word.substring(9)) - 1] = decodeMermaidEntities(
          rest,
        );
      case 'classdef' || 'acctitle' || 'accdescr' || 'acctitle:':
        break;
      default:
        points.add(_pointOf(line, number));
    }
  }
  return QuadrantChart(
    title: title == null || title.isEmpty ? null : decodeMermaidEntities(title),
    quadrants: List.unmodifiable(quadrants),
    points: List.unmodifiable(points),
    xLow: xAxis.$1,
    xHigh: xAxis.$2,
    yLow: yAxis.$1,
    yHigh: yAxis.$2,
  );
}

/// An axis's two ends, `Low --> High` or `Low` alone.
(String?, String?) _axis(String written) {
  final parts = written.split('-->');
  String? clean(String text) {
    final trimmed = decodeMermaidEntities(unquoteMermaid(text.trim()));
    return trimmed.isEmpty ? null : trimmed;
  }

  return (clean(parts.first), parts.length > 1 ? clean(parts[1]) : null);
}

/// The point [line] (diagram line [number]) writes.
QuadrantPoint _pointOf(String line, int number) {
  final match = _point.firstMatch(line);
  if (match == null) {
    throw MermaidParseException(
      number,
      'expected a point ("name: [x, y]"), found "$line"',
    );
  }
  final x = double.tryParse(match.group(2)!);
  final y = double.tryParse(match.group(3)!);
  // Written the way round that refuses NaN, which no comparison holds.
  if (x == null || y == null || !(x >= 0 && x <= 1 && y >= 0 && y <= 1)) {
    throw MermaidParseException(
      number,
      'a point sits from 0 to 1 on each axis, '
      'found [${match.group(2)}, ${match.group(3)}]',
    );
  }
  final radius = RegExp(r'radius\s*:\s*([\d.]+)').firstMatch(match.group(4)!);
  return QuadrantPoint(
    label: decodeMermaidEntities(unquoteMermaid(match.group(1)!.trim())),
    x: x,
    y: y,
    radius: radius == null ? null : double.tryParse(radius.group(1)!),
  );
}
