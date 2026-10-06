/// Measuring and wrapping a sequence diagram's text (#530), with the one
/// estimate the layout and both drawings share.
library;

import 'dart:math' as math;

import 'package:niman/src/diagrams/diagram_metrics.dart';

/// The width of the widest of [lines] at [fontSize].
double widestLine(List<String> lines, double fontSize) {
  var widest = 0.0;
  for (final line in lines) {
    widest = math.max(widest, DiagramMetrics.textWidth(line, fontSize));
  }
  return widest;
}

/// [text] broken at its own line breaks and then at word boundaries, so
/// no line is wider than [maxWidth] at [fontSize] unless one word is.
List<String> wrapLabel(String text, double maxWidth, double fontSize) {
  final lines = <String>[];
  for (final part in DiagramMetrics.lines(text)) {
    var line = '';
    for (final word in part.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final candidate = line.isEmpty ? word : '$line $word';
      if (line.isNotEmpty &&
          DiagramMetrics.textWidth(candidate, fontSize) > maxWidth) {
        lines.add(line);
        line = word;
      } else {
        line = candidate;
      }
    }
    lines.add(line);
  }
  return lines;
}
