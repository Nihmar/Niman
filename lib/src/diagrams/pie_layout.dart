/// Laying a pie chart out (#530): its slices, their shares, a legend and
/// the title.
///
/// The slices run clockwise from twelve o'clock in the order they were
/// written, each taking the palette's next colour. A palette has eight; a
/// pie with more keeps its first seven and folds the rest into an "Other"
/// slice, rather than hand a colour out twice. A share is written on its
/// slice when it fits there; the legend names every slice in any case.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/pie_geometry.dart';
import 'package:niman/src/diagrams/pie_model.dart';

const double _margin = 12;

/// The gap between the pie and its legend.
const double _legendGap = 28;

/// The largest step, in radians, between two points of a slice's arc.
const double _arcStep = math.pi / 90;

/// Where across the radius a slice's share is written.
const double _percentRadius = 0.66;

/// The legend's label for the slices folded into one.
const String _other = 'Other';

/// Lays [pie] out with [style].
PieLayout layoutPie(PieChart pie, DiagramStyle style) {
  final colours = style.palette.series.length;
  final slices = _folded(pie.slices, colours);
  final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
  final line = style.fontSize * style.lineHeight;
  final radius = style.fontSize * 8;
  final titleSize = style.fontSize * 1.2;
  final title = pie.title;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;

  // The legend: one row a slice, a swatch the size of the text.
  final rowHeight = line + 6;
  final legendHeight = slices.length * rowHeight;
  final top = _margin + titleHeight;
  final body = math.max(2 * radius, legendHeight);
  final center = Offset(_margin + radius, top + body / 2);
  final legendLeft = center.dx + radius + _legendGap;
  var legendTop = center.dy - legendHeight / 2;
  var right = legendLeft;
  final legend = <LaidOutLegendRow>[];
  for (var i = 0; i < slices.length; i++) {
    final slice = slices[i];
    final text = pie.showData
        ? '${slice.label} [${_number(slice.value)}]'
        : slice.label;
    final swatch = Rect.fromLTWH(
      legendLeft,
      legendTop + (rowHeight - style.fontSize) / 2,
      style.fontSize,
      style.fontSize,
    );
    final textBox = Rect.fromLTWH(
      swatch.right + 8,
      legendTop,
      DiagramMetrics.textWidth(text, style.fontSize),
      rowHeight,
    );
    legend.add(
      LaidOutLegendRow(swatch: swatch, textBox: textBox, text: text, colour: i),
    );
    right = math.max(right, textBox.right);
    legendTop += rowHeight;
  }

  // The slices, clockwise from twelve o'clock.
  final laid = <LaidOutSlice>[];
  var start = -math.pi / 2;
  for (var i = 0; i < slices.length; i++) {
    final share = slices[i].value / total;
    final sweep = share * 2 * math.pi;
    if (sweep <= 0) continue;
    final whole = share >= 1;
    final percent = _percent(share);
    final middle = start + sweep / 2;
    final at = whole
        ? center
        : center +
              Offset(math.cos(middle), math.sin(middle)) *
                  (radius * _percentRadius);
    // The share is written where the slice is wide enough to hold it.
    final room = whole ? 2 * radius : sweep * radius * _percentRadius;
    final fits =
        DiagramMetrics.textWidth(percent, style.fontSize) + 6 <= room &&
        (whole || sweep >= 0.3);
    laid.add(
      LaidOutSlice(
        outline: _outline(center, radius, start, sweep, whole: whole),
        colour: i,
        percent: fits ? percent : null,
        percentAt: fits ? at : null,
      ),
    );
    start += sweep;
  }

  var width = right + _margin;
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
  return PieLayout(
    size: Size(width, top + body + _margin),
    center: center,
    radius: radius,
    slices: List.unmodifiable(laid),
    legend: List.unmodifiable(legend),
    title: title,
    titleBox: titleBox,
  );
}

/// [slices], the ones past the [colours] the palette has folded into one.
List<PieSlice> _folded(List<PieSlice> slices, int colours) {
  if (slices.length <= colours) return slices;
  final kept = slices.sublist(0, colours - 1);
  final rest = slices
      .sublist(colours - 1)
      .fold<double>(0, (sum, slice) => sum + slice.value);
  return [...kept, PieSlice(label: _other, value: rest)];
}

/// The outline of a slice of [sweep] radians from [start]: the centre and
/// its arc, or the whole circle.
List<Offset> _outline(
  Offset center,
  double radius,
  double start,
  double sweep, {
  required bool whole,
}) {
  final steps = math.max(1, (sweep / _arcStep).ceil());
  return [
    if (!whole) center,
    for (var i = 0; i <= steps; i++)
      center +
          Offset(
                math.cos(start + sweep * i / steps),
                math.sin(start + sweep * i / steps),
              ) *
              radius,
  ];
}

/// A share as it is written: a whole percentage, "<1%" for a sliver.
String _percent(double share) {
  final percent = share * 100;
  if (percent > 0 && percent < 0.5) return '<1%';
  return '${percent.round()}%';
}

/// A value as `showData` writes it: whole numbers without a decimal point.
String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();
