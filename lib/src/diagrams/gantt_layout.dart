/// Laying a Gantt chart out (#530): a row a task, a band a section, time
/// across and its axis under them.
///
/// The plot is as wide as the chart's span needs, within bounds a note can
/// show — the read view shrinks a wider one to fit — and the axis takes
/// the smallest calendar step whose dates do not run into one another. A
/// task's label is written on its bar when it fits there, after the bar
/// when not, and before it when the chart ends first.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/gantt_dates.dart';
import 'package:niman/src/diagrams/gantt_geometry.dart';
import 'package:niman/src/diagrams/gantt_model.dart';
import 'package:niman/src/diagrams/gantt_ticks.dart';

const double _margin = 12;
const double _pad = 10;
const double _minPlot = 480;
const double _maxPlot = 960;

/// How wide a day is drawn when the plot is neither at its least nor at
/// its most.
const double _dayWidth = 28;

/// The format the axis writes a date in when the chart names none.
const String _defaultAxis = '%Y-%m-%d';

/// Lays [chart] out with [style].
GanttLayout layoutGantt(GanttChart chart, DiagramStyle style) {
  final tasks = [for (final section in chart.sections) ...section.tasks];
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final rowHeight = line + 10;
  var first = tasks.first.start;
  var last = tasks.first.end;
  for (final task in tasks) {
    if (task.start.isBefore(first)) first = task.start;
    if (task.end.isAfter(last)) last = task.end;
  }
  if (!last.isAfter(first)) last = first.add(const Duration(days: 1));
  final span = last.difference(first).inMilliseconds;
  final days = span / Duration.millisecondsPerDay;
  final plotWidth = (days * _dayWidth).clamp(_minPlot, _maxPlot);
  double xOf(DateTime date) =>
      date.difference(first).inMilliseconds / span * plotWidth;

  // The name column, as wide as the widest section name.
  var names = 0.0;
  for (final section in chart.sections) {
    names = math.max(names, DiagramMetrics.textWidth(section.name, fontSize));
  }
  final column = names == 0 ? 0.0 : names + 2 * _pad;
  final title = chart.title;
  final titleSize = fontSize * 1.2;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;
  final top = _margin + titleHeight;
  final left = _margin + column;
  final plot = Rect.fromLTWH(left, top, plotWidth, tasks.length * rowHeight);

  final bands = <LaidOutBand>[];
  final bars = <LaidOutBar>[];
  var right = plot.right;
  var y = top;
  for (var s = 0; s < chart.sections.length; s++) {
    final section = chart.sections[s];
    final height = section.tasks.length * rowHeight;
    bands.add(
      LaidOutBand(
        rect: Rect.fromLTWH(_margin, y, column + plotWidth, height),
        name: section.name,
        nameBox: Rect.fromLTWH(_margin + _pad, y, names, height),
        shaded: s.isOdd,
      ),
    );
    for (final task in section.tasks) {
      final bar = _bar(task, xOf, left, y, rowHeight);
      final label = _label(task, bar, plot, fontSize);
      bars.add(LaidOutBar(task: task, rect: bar, labelBox: label));
      right = math.max(right, label.right);
      y += rowHeight;
    }
  }

  // The axis: the step whose dates, written, keep apart.
  final format = chart.axisFormat ?? _defaultAxis;
  final sample = DiagramMetrics.textWidth(
    formatGanttDate(DateTime.utc(2000, 12, 28, 23, 59), format),
    fontSize,
  );
  final step = ganttStep(first, last, math.max(1, plotWidth ~/ (sample + 16)));
  final ticks = [
    for (final date in ganttTicks(first, last, step))
      _tick(left + xOf(date), formatGanttDate(date, format), plot, line, style),
  ];
  for (final tick in ticks) {
    right = math.max(right, tick.labelBox.right);
  }

  Rect? titleBox;
  var drawing = right + _margin;
  if (title != null) {
    final titleWidth = DiagramMetrics.textWidth(title, titleSize);
    drawing = math.max(drawing, titleWidth + 2 * _margin);
    titleBox = Rect.fromCenter(
      center: Offset(drawing / 2, _margin + (titleHeight - 12) / 2),
      width: titleWidth,
      height: titleHeight - 12,
    );
  }
  return GanttLayout(
    size: Size(drawing, plot.bottom + line + 12 + _margin),
    plot: plot,
    bands: List.unmodifiable(bands),
    bars: List.unmodifiable(bars),
    ticks: List.unmodifiable(ticks),
    title: title,
    titleBox: titleBox,
  );
}

/// The bar of [task] in the row from [top]: its span of time, or a
/// diamond at its start for a milestone.
Rect _bar(
  GanttTask task,
  double Function(DateTime date) xOf,
  double left,
  double top,
  double rowHeight,
) {
  final inset = rowHeight * 0.15;
  if (task.milestone) {
    final size = rowHeight - 2 * inset;
    return Rect.fromCenter(
      center: Offset(left + xOf(task.start), top + rowHeight / 2),
      width: size,
      height: size,
    );
  }
  final start = left + xOf(task.start);
  final end = math.max(left + xOf(task.end), start + 2);
  return Rect.fromLTRB(start, top + inset, end, top + rowHeight - inset);
}

/// Where [task]'s label goes: on its [bar] when it fits there, after it
/// when not, before it when the plot ends first.
Rect _label(GanttTask task, Rect bar, Rect plot, double fontSize) {
  final width = DiagramMetrics.textWidth(task.label, fontSize);
  if (!task.milestone && width + 2 * _pad <= bar.width) {
    return Rect.fromCenter(
      center: bar.center,
      width: width,
      height: bar.height,
    );
  }
  final after = Rect.fromLTWH(bar.right + 6, bar.top, width, bar.height);
  if (after.right <= plot.right || bar.left - 6 - width < plot.left) {
    return after;
  }
  return Rect.fromLTWH(bar.left - 6 - width, bar.top, width, bar.height);
}

LaidOutTick _tick(
  double x,
  String label,
  Rect plot,
  double line,
  DiagramStyle style,
) {
  final width = DiagramMetrics.textWidth(label, style.fontSize);
  return LaidOutTick(
    x: x,
    label: label,
    // Centred on its tick, but never out past the drawing's left edge.
    labelBox: Rect.fromLTWH(
      math.max(2, x - width / 2),
      plot.bottom + 6,
      width,
      line,
    ),
  );
}
