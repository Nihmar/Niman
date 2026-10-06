/// Laying a timeline out (#530): a column a period, its events stacked
/// under it, the time line running left to right between them, and the
/// sections' headers above.
///
/// A named section takes the palette's next series colour, its periods and
/// events with it; the periods outside a section, and the sections past
/// the palette's eight colours, are drawn in the neutral fill rather than
/// in a colour handed out twice.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/sequence_text.dart';
import 'package:niman/src/diagrams/timeline_geometry.dart';
import 'package:niman/src/diagrams/timeline_model.dart';

const double _margin = 12;
const double _padX = 10;
const double _padY = 7;
const double _columnGap = 16;
const double _maxText = 150;
const double _minColumn = 90;
const double _rowGap = 10;

/// Lays [chart] out with [style].
TimelineLayout layoutTimeline(TimelineChart chart, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  List<String> wrap(String text) => wrapLabel(text, _maxText, fontSize);
  double height(List<String> lines) => lines.length * line + 2 * _padY;

  // Each period's column: as wide as its widest text, wrapped.
  final columns = [
    for (final section in chart.sections)
      for (final period in section.periods)
        (
          period: period,
          section: section,
          label: wrap(period.label),
          events: [for (final event in period.events) wrap(event)],
        ),
  ];
  final widths = [
    for (final column in columns)
      math.max(
        _minColumn,
        [
              widestLine(column.label, fontSize),
              for (final event in column.events) widestLine(event, fontSize),
            ].reduce(math.max) +
            2 * _padX,
      ),
  ];
  final colours = _colours(chart, style.palette.series.length);

  final title = chart.title;
  final titleSize = fontSize * 1.2;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;
  final named = chart.sections.any((s) => s.name != null);
  final headerHeight = named ? line + 2 * _padY : 0.0;
  final periodTop =
      _margin + titleHeight + (named ? headerHeight + _rowGap : 0);
  var periodHeight = 0.0;
  for (final column in columns) {
    periodHeight = math.max(periodHeight, height(column.label));
  }
  final axisY = periodTop + periodHeight + 18;

  final sections = <LaidOutTimelineBox>[];
  final boxes = <LaidOutTimelineBox>[];
  final connectors = <(Offset, Offset)>[];
  var x = _margin;
  var bottom = axisY;
  var i = 0;
  for (final section in chart.sections) {
    final start = x;
    for (final _ in section.periods) {
      final column = columns[i];
      final width = widths[i];
      final colour = colours[section];
      final period = Rect.fromLTWH(x, periodTop, width, periodHeight);
      boxes.add(
        LaidOutTimelineBox(rect: period, lines: column.label, colour: colour),
      );
      var y = axisY + 18;
      for (final event in column.events) {
        final box = Rect.fromLTWH(x, y, width, height(event));
        boxes.add(
          LaidOutTimelineBox(
            rect: box,
            lines: event,
            colour: colour,
            event: true,
          ),
        );
        y = box.bottom + _rowGap;
      }
      if (column.events.isNotEmpty) {
        connectors.add((
          Offset(period.center.dx, period.bottom),
          Offset(period.center.dx, y - _rowGap - height(column.events.last)),
        ));
      }
      bottom = math.max(bottom, y - _rowGap);
      x += width + _columnGap;
      i++;
    }
    final name = section.name;
    if (name != null && section.periods.isNotEmpty) {
      sections.add(
        LaidOutTimelineBox(
          rect: Rect.fromLTRB(
            start,
            _margin + titleHeight,
            x - _columnGap,
            _margin + titleHeight + headerHeight,
          ),
          lines: [name],
          colour: colours[section],
        ),
      );
    }
  }
  final axis = (Offset(_margin, axisY), Offset(x - _columnGap + 14, axisY));
  var width = axis.$2.dx + _margin;
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
  return TimelineLayout(
    size: Size(width, bottom + _margin),
    sections: List.unmodifiable(sections),
    boxes: List.unmodifiable(boxes),
    connectors: List.unmodifiable(connectors),
    axis: axis,
    title: title,
    titleBox: titleBox,
  );
}

/// The series slot of each named section, in order, while the palette has
/// one to give; null for the rest.
Map<TimelineSection, int?> _colours(TimelineChart chart, int slots) {
  var next = 0;
  return {
    for (final section in chart.sections)
      section: section.name != null && next < slots ? next++ : null,
  };
}
