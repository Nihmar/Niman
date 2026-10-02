/// The parser behind a `radar-beta` Mermaid fence (#530).
///
/// A radar chart is its axes, `axis m["Math"], s["Science"]`, and its
/// curves, `curve a["Alice"]{85, 90}` with a value for each axis in their
/// order or `curve b{ s: 70, m: 80 }` by the axes' ids. `min`, `max`,
/// `ticks`, `graticule circle|polygon`, `showLegend` and `title` set the
/// rest; with no `max` the outer ring is the largest value. A curve whose
/// values do not match the axes, or a line that does not read, is a
/// [MermaidParseException] naming its line.
library;

import 'dart:math' as math;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/radar_model.dart';

/// An axis: an id, then a label in brackets if it has one.
final RegExp _axis = RegExp(r'^([\w-]+)\s*(?:\[(.*)\])?$');

/// A curve: an id, a label in brackets if it has one, its values in
/// braces.
final RegExp _curve = RegExp(r'^([\w-]+)\s*(?:\[(.*)\])?\s*\{(.*)\}$');

/// A curve's value by an axis's id: `id: 70`.
final RegExp _keyed = RegExp(r'^([\w-]+)\s*:\s*(.+)$');

/// A curve as written, read once every axis is known.
typedef _Written = ({String label, List<String> values, int line});

/// The most rings a scale is drawn with.
const int _maxTicks = 50;

/// Parses a radar chart (the fence's content, header included).
RadarChart parseRadar(String source) {
  final lines = source.split('\n');
  var index = mermaidBodyStart(lines);
  final header = index < lines.length
      ? stripMermaidComment(lines[index]).trim().toLowerCase()
      : '';
  if (header != 'radar-beta' && header != 'radar') {
    throw MermaidParseException(index + 1, 'expected "radar-beta"');
  }
  String? title;
  double? min;
  double? max;
  var maxLine = 0;
  var ticks = 5;
  var graticule = RadarGraticule.circle;
  var showLegend = true;
  final axes = <RadarAxis>[];
  final written = <_Written>[];
  var description = false;
  for (index++; index < lines.length; index++) {
    final line = stripMermaidComment(lines[index]).trim();
    final number = index + 1;
    if (description) {
      // An `accDescr { … }` block: words for a screen reader.
      description = !line.contains('}');
      continue;
    }
    if (line.isEmpty) continue;
    final space = line.indexOf(RegExp(r'\s'));
    final word = (space < 0 ? line : line.substring(0, space)).toLowerCase();
    final rest = space < 0 ? '' : line.substring(space).trim();
    switch (word) {
      case 'title':
        title = rest;
      case 'axis':
        for (final item in _items(rest, number)) {
          final axis = _axisOf(item, number);
          if (axes.any((a) => a.id == axis.id)) {
            throw MermaidParseException(
              number,
              'the axis "${axis.id}" is written twice',
            );
          }
          axes.add(axis);
        }
      case 'curve':
        for (final item in _items(rest, number)) {
          written.add(_curveOf(item, number));
        }
      case 'min':
        min = _number(rest, number);
      case 'max':
        max = _number(rest, number);
        maxLine = number;
      case 'ticks':
        final count = int.tryParse(rest);
        if (count == null || count < 1 || count > _maxTicks) {
          throw MermaidParseException(
            number,
            'expected from 1 to $_maxTicks ticks, found "$rest"',
          );
        }
        ticks = count;
      case 'graticule':
        graticule = switch (rest.toLowerCase()) {
          'circle' => RadarGraticule.circle,
          'polygon' => RadarGraticule.polygon,
          _ => throw MermaidParseException(
            number,
            'expected "circle" or "polygon", found "$rest"',
          ),
        };
      case 'showlegend':
        showLegend = rest.toLowerCase() != 'false';
      case _ when word.startsWith('acctitle') || word.startsWith('accdescr'):
        description = line.contains('{') && !line.contains('}');
      default:
        throw MermaidParseException(
          number,
          'expected axis, curve, min, max, ticks, graticule, showLegend or '
          'title, found "$line"',
        );
    }
  }
  if (axes.isEmpty) {
    throw const MermaidParseException(1, 'a radar chart needs an axis');
  }
  if (written.isEmpty) {
    throw const MermaidParseException(1, 'a radar chart needs a curve');
  }
  final curves = [for (final curve in written) _resolve(curve, axes)];
  final low = min ?? 0;
  if (max != null && max <= low) {
    throw MermaidParseException(maxLine, 'max ($max) must be above min ($low)');
  }
  final high =
      max ??
      curves.fold<double>(
        low,
        (most, curve) => curve.values.fold(most, math.max),
      );
  return RadarChart(
    axes: List.unmodifiable(axes),
    curves: List.unmodifiable(curves),
    min: low,
    // Every value at min, with no max written: a scale one wide, so the
    // curves sit at the centre rather than across nothing.
    max: high > low ? high : low + 1,
    ticks: ticks,
    graticule: graticule,
    showLegend: showLegend,
    title: title == null || title.isEmpty ? null : decodeMermaidEntities(title),
  );
}

RadarAxis _axisOf(String item, int number) {
  final match = _axis.firstMatch(item);
  if (match == null) {
    throw MermaidParseException(
      number,
      'expected an axis (id or id["label"]), found "$item"',
    );
  }
  final id = match.group(1)!;
  return RadarAxis(id: id, label: _label(match.group(2)) ?? id);
}

_Written _curveOf(String item, int number) {
  final match = _curve.firstMatch(item);
  if (match == null) {
    throw MermaidParseException(
      number,
      'expected a curve (id["label"]{1, 2, 3}), found "$item"',
    );
  }
  final id = match.group(1)!;
  return (
    label: _label(match.group(2)) ?? id,
    values: [
      for (final value in match.group(3)!.split(','))
        if (value.trim().isNotEmpty) value.trim(),
    ],
    line: number,
  );
}

/// [curve]'s values in the order of [axes]: as written, or by axis id.
RadarCurve _resolve(_Written curve, List<RadarAxis> axes) {
  final number = curve.line;
  final keyed = [for (final value in curve.values) _keyed.firstMatch(value)];
  final List<double> values;
  if (keyed.every((match) => match == null)) {
    if (curve.values.length != axes.length) {
      throw MermaidParseException(
        number,
        'the curve "${curve.label}" has ${curve.values.length} values '
        'for ${axes.length} axes',
      );
    }
    values = [for (final value in curve.values) _number(value, number)];
  } else {
    if (keyed.any((match) => match == null)) {
      throw MermaidParseException(
        number,
        'a curve gives its values all in order or all by axis',
      );
    }
    final byAxis = <String, double>{
      for (final match in keyed)
        match!.group(1)!: _number(match.group(2)!, number),
    };
    for (final id in byAxis.keys) {
      if (!axes.any((axis) => axis.id == id)) {
        throw MermaidParseException(number, 'no axis is called "$id"');
      }
    }
    values = [
      for (final axis in axes)
        byAxis[axis.id] ??
            (throw MermaidParseException(
              number,
              'the curve "${curve.label}" has no value for "${axis.id}"',
            )),
    ];
  }
  return RadarCurve(label: curve.label, values: List.unmodifiable(values));
}

double _number(String text, int number) {
  final value = double.tryParse(text.trim());
  if (value == null || !value.isFinite) {
    throw MermaidParseException(number, 'expected a number, found "$text"');
  }
  return value;
}

String? _label(String? written) {
  if (written == null) return null;
  final label = decodeMermaidEntities(unquoteMermaid(written.trim()));
  return label.isEmpty ? null : label;
}

/// [text] split at the commas between items, not those inside quotes,
/// brackets or braces.
List<String> _items(String text, int number) {
  final items = <String>[];
  var depth = 0;
  var quoted = false;
  var start = 0;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '"') {
      quoted = !quoted;
    } else if (!quoted && (ch == '[' || ch == '{')) {
      depth++;
    } else if (!quoted && (ch == ']' || ch == '}')) {
      depth--;
    } else if (!quoted && depth == 0 && ch == ',') {
      items.add(text.substring(start, i).trim());
      start = i + 1;
    }
  }
  items.add(text.substring(start).trim());
  final kept = [
    for (final item in items)
      if (item.isNotEmpty) item,
  ];
  if (kept.isEmpty) {
    throw MermaidParseException(number, 'expected an id after the keyword');
  }
  return kept;
}
