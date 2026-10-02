/// The parser behind an `xychart-beta` Mermaid fence (#530).
///
/// An xy chart is a `title`, its axes — `x-axis "title" [a, b, c]` names
/// the categories, `x-axis 1 --> 12` numbers them, `y-axis "title" 0 -->
/// 100` fixes the values' range — and its series, `bar [1, 2, 3]` and
/// `line "name" [1, 2, 3]`, one value a category. Like the other parsers
/// it reports a syntax error as a [MermaidParseException] naming the line.
library;

import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_lines.dart';
import 'package:niman/src/diagrams/xy_chart_model.dart';

/// An axis: an optional title, then a list or a range.
final RegExp _axis = RegExp(
  r'^(?:"([^"]*)"|([^\["\-\d][^\[]*?))?\s*'
  r'(?:\[(.*)\]|(-?[\d.]+)\s*-->\s*(-?[\d.]+))?$',
);

/// A series: an optional name, then its values.
final RegExp _seriesData = RegExp(r'^(?:"([^"]*)"\s*)?\[(.*)\]$');

/// Parses an xy chart (the fence's content, header included).
XyChart parseXyChart(String source) => _XyParser(source).parse();

final class _XyParser {
  new(this.source);

  final String source;
  String? _title;
  String? _xTitle;
  String? _yTitle;
  List<String>? _categories;
  (double, double)? _xRange;
  (double, double)? _yRange;
  final List<XySeries> _series = [];
  final List<int> _seriesLines = [];

  XyChart parse() {
    final lines = source.split('\n');
    var index = mermaidBodyStart(lines);
    final header = index < lines.length
        ? stripMermaidComment(lines[index]).trim().toLowerCase()
        : '';
    final head = RegExp(r'^xychart-beta(?:\s+(horizontal|vertical))?$')
        .firstMatch(header);
    if (head == null) {
      throw MermaidParseException(index + 1, 'expected "xychart-beta"');
    }
    for (index++; index < lines.length; index++) {
      final line = stripMermaidComment(lines[index]).trim();
      if (line.isNotEmpty) _line(line, index + 1);
    }
    if (_series.isEmpty) {
      throw const MermaidParseException(1, 'an xy chart needs a bar or a line');
    }
    final count = _series
        .map((s) => s.values.length)
        .reduce((a, b) => a > b ? a : b);
    final categories = _categories ?? _numbered(count);
    for (var i = 0; i < _series.length; i++) {
      if (_series[i].values.length != categories.length) {
        throw MermaidParseException(
          _seriesLines[i],
          'expected ${categories.length} values, one a category',
        );
      }
    }
    return XyChart(
      categories: categories,
      series: List.unmodifiable(_series),
      horizontal: head.group(1) == 'horizontal',
      title: _title,
      xTitle: _xTitle,
      yTitle: _yTitle,
      yRange: _yRange,
    );
  }

  void _line(String line, int number) {
    final space = line.indexOf(RegExp(r'\s'));
    final word = (space < 0 ? line : line.substring(0, space)).toLowerCase();
    final rest = space < 0 ? '' : line.substring(space).trim();
    switch (word) {
      case 'title':
        _title = decodeMermaidEntities(unquoteMermaid(rest));
      case 'x-axis' || 'y-axis':
        final axis = _axis.firstMatch(rest);
        if (axis == null) {
          throw MermaidParseException(
            number,
            'expected an axis title, then [a, b] or "min --> max"',
          );
        }
        final written = (axis.group(1) ?? axis.group(2))?.trim();
        final title = written == null ? null : decodeMermaidEntities(written);
        final range = axis.group(4) == null
            ? null
            : (
                _number(axis.group(4)!, number),
                _number(axis.group(5)!, number),
              );
        if (word == 'x-axis') {
          _xTitle = title;
          _xRange = range;
          final list = axis.group(3);
          if (list != null) {
            _categories = [
              for (final item in list.split(','))
                if (item.trim().isNotEmpty)
                  decodeMermaidEntities(unquoteMermaid(item.trim())),
            ];
          }
        } else {
          _yTitle = title;
          _yRange = range;
        }
      case 'bar' || 'line':
        final match = _seriesData.firstMatch(rest);
        if (match == null) {
          throw MermaidParseException(
            number,
            'expected $word [values], a "name" before them if wanted',
          );
        }
        _series.add(
          XySeries(
            kind: word == 'bar' ? XySeriesKind.bar : XySeriesKind.line,
            name: match.group(1),
            values: [
              for (final item in match.group(2)!.split(','))
                if (item.trim().isNotEmpty) _number(item, number),
            ],
          ),
        );
        _seriesLines.add(number);
      case 'acctitle' || 'accdescr' || 'acctitle:' || 'accdescr:':
        break;
      default:
        throw MermaidParseException(
          number,
          'expected title, x-axis, y-axis, bar or line, found "$line"',
        );
    }
  }

  /// The categories when none are named: the x axis's range in even steps,
  /// or the numbers from 1.
  List<String> _numbered(int count) {
    final range = _xRange;
    if (range == null || count < 2) {
      return [for (var i = 1; i <= count; i++) '$i'];
    }
    final (low, high) = range;
    return [
      for (var i = 0; i < count; i++)
        _format(low + (high - low) * i / (count - 1)),
    ];
  }

  static String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  static double _number(String text, int number) =>
      double.tryParse(text.trim()) ??
      (throw MermaidParseException(
        number,
        'expected a number, found "${text.trim()}"',
      ));
}
