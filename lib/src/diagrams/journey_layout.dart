/// Laying a user journey out (#530): a column a task, the sections'
/// headers above, and under each task a face — the higher, the better the
/// task went — with the actors' legend at the left.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/journey_geometry.dart';
import 'package:niman/src/diagrams/journey_model.dart';
import 'package:niman/src/diagrams/sequence_text.dart';

const double _margin = 12;
const double _padX = 10;
const double _padY = 7;
const double _gap = 12;
const double _maxText = 120;
const double _minColumn = 90;

/// The height a point of score lifts a face.
const double _step = 14;

/// A face's radius.
const double _face = 12;

/// An actor's dot's radius, and the room between two.
const double _dot = 5;
const double _dotGap = 14;

/// Lays [journey] out with [style].
JourneyLayout layoutJourney(JourneyChart journey, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  List<String> wrap(String text) => wrapLabel(text, _maxText, fontSize);

  // The legend at the left: a dot and a name a row.
  final hasActors = journey.actors.isNotEmpty;
  final legendWidth = hasActors
      ? 2 * _dot + 8 + widestLine(journey.actors, fontSize) + 2 * _gap
      : 0.0;

  final title = journey.title;
  final titleSize = fontSize * 1.2;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;
  final named = journey.sections.any((s) => s.name != null);
  final headerHeight = named ? line + 2 * _padY : 0.0;
  final taskTop = _margin + titleHeight + (named ? headerHeight + _gap : 0);
  final columns = [
    for (final section in journey.sections)
      for (final task in section.tasks) (task: task, lines: wrap(task.label)),
  ];
  var textHeight = line;
  for (final column in columns) {
    textHeight = math.max(textHeight, column.lines.length * line);
  }
  final dotRow = hasActors ? 2 * _dot + 6 : 0.0;
  final taskHeight = textHeight + 2 * _padY + dotRow;
  final faceTop = taskTop + taskHeight + 20;

  final sections = <LaidOutJourneySection>[];
  final tasks = <LaidOutJourneyTask>[];
  var x = _margin + legendWidth;
  var i = 0;
  for (final section in journey.sections) {
    final start = x;
    for (final _ in section.tasks) {
      final column = columns[i++];
      final task = column.task;
      final width = math.max(
        _minColumn,
        math.max(
              widestLine(column.lines, fontSize),
              task.actors.length * _dotGap,
            ) +
            2 * _padX,
      );
      final box = Rect.fromLTWH(x, taskTop, width, taskHeight);
      final dotsY = box.bottom - _padY - _dot;
      final firstDot = box.center.dx - (task.actors.length - 1) * _dotGap / 2;
      final centreY = faceTop + _face + (5 - task.score) * _step;
      tasks.add(
        LaidOutJourneyTask(
          box: box,
          textBox: Rect.fromLTWH(box.left, box.top + _padY, width, textHeight),
          lines: column.lines,
          dots: [
            for (var a = 0; a < task.actors.length; a++)
              (Offset(firstDot + a * _dotGap, dotsY), task.actors[a]),
          ],
          face: Rect.fromCircle(
            center: Offset(box.center.dx, centreY),
            radius: _face,
          ),
          mood: task.score > 3 ? 1 : (task.score < 3 ? -1 : 0),
        ),
      );
      x += width + _gap;
    }
    final name = section.name;
    if (name != null && section.tasks.isNotEmpty) {
      sections.add(
        LaidOutJourneySection(
          rect: Rect.fromLTRB(
            start,
            _margin + titleHeight,
            x - _gap,
            _margin + titleHeight + headerHeight,
          ),
          lines: [name],
        ),
      );
    }
  }

  final legend = [
    for (var a = 0; a < journey.actors.length; a++)
      LaidOutJourneyActor(
        dot: Offset(_margin + _dot, taskTop + a * (line + 4) + line / 2),
        textBox: Rect.fromLTWH(
          _margin + 2 * _dot + 8,
          taskTop + a * (line + 4),
          DiagramMetrics.textWidth(journey.actors[a], fontSize),
          line,
        ),
        name: journey.actors[a],
      ),
  ];

  var width = x - _gap + _margin;
  Rect? titleBox;
  if (title != null) {
    final titleWidth = DiagramMetrics.textWidth(title, titleSize);
    width = math.max(width, titleWidth + 2 * _margin);
    titleBox = Rect.fromCenter(
      center: Offset(width / 2, _margin + (titleHeight - 12) / 2),
      width: titleWidth,
      height: titleHeight - 12,
    );
  }
  final legendBottom = legend.isEmpty ? 0.0 : legend.last.textBox.bottom;
  final facesBottom = faceTop + 5 * _step + 2 * _face;
  return JourneyLayout(
    size: Size(width, math.max(facesBottom, legendBottom) + _margin),
    sections: List.unmodifiable(sections),
    tasks: List.unmodifiable(tasks),
    legend: legend,
    title: title,
    titleBox: titleBox,
  );
}
