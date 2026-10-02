/// Laying an xy chart out (#530): a slot a category along one axis, the
/// values along the other in round steps, a bar a series in each slot and
/// a point a series joined across the slots.
///
/// The layout works on two axes — categories and values — and places them
/// across or down by the chart's orientation, so a horizontal chart is the
/// same layout turned. A series takes the palette's next series colour;
/// the series past its eight are drawn neutral rather than in a colour
/// handed out twice.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/xy_chart_model.dart';

const double _margin = 12;
const double _valueLength = 260;
const double _minCategoryLength = 360;

/// A text placed: where it sits and what it says.
typedef XyText = ({Rect box, String text});

/// An xy chart with every part placed.
typedef XyLayout = ({
  Size size,
  Rect plot,
  bool horizontal,
  List<({Offset from, Offset to})> grid,
  List<XyText> valueLabels,
  List<XyText> categoryLabels,
  List<({Rect rect, int series})> bars,
  List<({List<Offset> points, int series})> lines,
  List<({Rect swatch, XyText name, int series})> legend,
  XyText? title,
  List<XyText> axisTitles,
});

/// Lays [chart] out with [style].
XyLayout layoutXyChart(XyChart chart, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  double width(String text) => DiagramMetrics.textWidth(text, fontSize);
  final horizontal = chart.horizontal;
  final n = chart.categories.length;

  // The values' range, in round steps; bars stand on zero.
  var low = double.infinity;
  var high = double.negativeInfinity;
  for (final series in chart.series) {
    for (final value in series.values) {
      low = math.min(low, value);
      high = math.max(high, value);
    }
  }
  if (chart.series.any((s) => s.kind == XySeriesKind.bar)) {
    low = math.min(low, 0);
    high = math.max(high, 0);
  }
  final step = _niceStep(chart.yRange, low, high);
  final (bottom, top) =
      chart.yRange ??
      (
        (low / step).floorToDouble() * step,
        (high / step).ceilToDouble() * step,
      );
  final span = top == bottom ? 1.0 : top - bottom;
  // The ticks counted, not added up: at a value whose precision is coarser
  // than the step — every value 1e17, a step of 1 — `v += step` leaves `v`
  // where it is and never reaches the top. The step is a fifth of the
  // range or more, so there are a handful of them.
  final firstTick = (bottom / step).ceilToDouble();
  final tickCount = ((top / step + 1e-9).floorToDouble() - firstTick).round();
  final ticks = [for (var i = 0; i <= tickCount; i++) (firstTick + i) * step];
  final tickTexts = [for (final v in ticks) _format(v, step)];

  // Room for the texts beside each axis.
  var widestCategory = 0.0;
  for (final category in chart.categories) {
    widestCategory = math.max(widestCategory, width(category));
  }
  var widestTick = 0.0;
  for (final text in tickTexts) {
    widestTick = math.max(widestTick, width(text));
  }
  final slot = horizontal
      ? math.max<double>(line + 12, 28)
      : math.max<double>(48, widestCategory + 10);
  final categoryLength = math.max(_minCategoryLength, n * slot);
  final title = chart.title;
  final titleSize = fontSize * 1.2;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;
  final valueTitle = chart.yTitle;
  final categoryTitle = chart.xTitle;
  // Over the plot, the title of the axis that runs up it.
  final over0 = horizontal ? categoryTitle : valueTitle;
  final top0 = _margin + titleHeight + (over0 != null ? line + 6 : 0);
  final left = _margin + (horizontal ? widestCategory : widestTick) + 8;
  final plot = horizontal
      ? Rect.fromLTWH(left, top0, _valueLength * 1.4, categoryLength)
      : Rect.fromLTWH(left, top0, categoryLength, _valueLength);

  // Where a category's slot and a value fall.
  final slotLength = (horizontal ? plot.height : plot.width) / n;
  double along(int i) =>
      (horizontal ? plot.top : plot.left) + slotLength * (i + 0.5);
  double at(double value) => horizontal
      ? plot.left + (value - bottom) / span * plot.width
      : plot.bottom - (value - bottom) / span * plot.height;
  Offset point(double category, double value) =>
      horizontal ? Offset(value, category) : Offset(category, value);

  final grid = [
    for (final v in ticks)
      (
        from: horizontal ? Offset(at(v), plot.top) : Offset(plot.left, at(v)),
        to: horizontal ? Offset(at(v), plot.bottom) : Offset(plot.right, at(v)),
      ),
  ];
  final valueLabels = [
    for (var t = 0; t < ticks.length; t++)
      (
        box: horizontal
            ? Rect.fromCenter(
                center: Offset(at(ticks[t]), plot.bottom + 6 + line / 2),
                width: width(tickTexts[t]),
                height: line,
              )
            : Rect.fromLTWH(
                plot.left - 8 - width(tickTexts[t]),
                at(ticks[t]) - line / 2,
                width(tickTexts[t]),
                line,
              ),
        text: tickTexts[t],
      ),
  ];
  final categoryLabels = [
    for (var i = 0; i < n; i++)
      (
        box: horizontal
            ? Rect.fromLTWH(
                plot.left - 8 - width(chart.categories[i]),
                along(i) - line / 2,
                width(chart.categories[i]),
                line,
              )
            : Rect.fromCenter(
                center: Offset(along(i), plot.bottom + 6 + line / 2),
                width: width(chart.categories[i]),
                height: line,
              ),
        text: chart.categories[i],
      ),
  ];

  // The bars of a slot side by side in its middle seven tenths; the lines
  // through the slots' middles.
  final barSeries = [
    for (var s = 0; s < chart.series.length; s++)
      if (chart.series[s].kind == XySeriesKind.bar) s,
  ];
  final group = slotLength * 0.7;
  final bars = <({Rect rect, int series})>[];
  for (var i = 0; i < n; i++) {
    for (var k = 0; k < barSeries.length; k++) {
      final s = barSeries[k];
      final thickness = group / barSeries.length;
      final start = along(i) - group / 2 + k * thickness;
      final base = at(math.max(bottom, math.min(0, top)));
      final end = at(chart.series[s].values[i]);
      bars.add((
        rect: Rect.fromPoints(
          point(start, base),
          point(start + thickness - 1, end),
        ),
        series: s,
      ));
    }
  }
  final lines = [
    for (var s = 0; s < chart.series.length; s++)
      if (chart.series[s].kind == XySeriesKind.line)
        (
          points: [
            for (var i = 0; i < n; i++)
              point(along(i), at(chart.series[s].values[i])),
          ],
          series: s,
        ),
  ];

  // The axes' titles: the categories' under or beside their labels, the
  // values' over the plot or under its labels.
  Rect over(String text) =>
      Rect.fromLTWH(_margin, top0 - line - 6, width(text), line);
  Rect under(String text) => Rect.fromCenter(
    center: Offset(plot.center.dx, plot.bottom + 2 * line + 10),
    width: width(text),
    height: line,
  );
  final axisTitles = <XyText>[
    if (categoryTitle != null)
      (
        box: horizontal ? over(categoryTitle) : under(categoryTitle),
        text: categoryTitle,
      ),
    if (valueTitle != null)
      (
        box: horizontal ? under(valueTitle) : over(valueTitle),
        text: valueTitle,
      ),
  ];

  // A legend under everything, when the series have names.
  final named = chart.series.any((s) => s.name != null);
  // It starts under the lowest text under the plot: a value axis's title
  // drawn over the plot takes no room down here.
  var y = plot.bottom;
  for (final text in [...valueLabels, ...categoryLabels, ...axisTitles]) {
    y = math.max(y, text.box.bottom);
  }
  y += 6;
  final legend = <({Rect swatch, XyText name, int series})>[];
  if (named) {
    var x = plot.left;
    for (var s = 0; s < chart.series.length; s++) {
      final name = chart.series[s].name ?? 'Series ${s + 1}';
      final swatch = Rect.fromLTWH(
        x,
        y + (line - fontSize) / 2,
        fontSize,
        fontSize,
      );
      final box = Rect.fromLTWH(swatch.right + 6, y, width(name), line);
      legend.add((swatch: swatch, name: (box: box, text: name), series: s));
      x = box.right + 18;
    }
    y += line + 6;
  }

  var right = plot.right + _margin;
  for (final label in valueLabels) {
    right = math.max(right, label.box.right + _margin);
  }
  for (final entry in legend) {
    right = math.max(right, entry.name.box.right + _margin);
  }
  XyText? titleText;
  if (title != null) {
    final titleWidth = DiagramMetrics.textWidth(title, titleSize);
    right = math.max(right, titleWidth + 2 * _margin);
    titleText = (
      box: Rect.fromCenter(
        center: Offset(right / 2, _margin + (titleHeight - 12) / 2),
        width: titleWidth,
        height: titleHeight - 12,
      ),
      text: title,
    );
  }
  return (
    size: Size(right, y + _margin),
    plot: plot,
    horizontal: horizontal,
    grid: grid,
    valueLabels: valueLabels,
    categoryLabels: categoryLabels,
    bars: bars,
    lines: lines,
    legend: legend,
    title: titleText,
    axisTitles: axisTitles,
  );
}

/// A round step — 1, 2 or 5 times a power of ten — that puts about five
/// ticks over the values, or over the [range] the chart fixes.
double _niceStep((double, double)? range, double low, double high) {
  final (from, to) = range ?? (low, high);
  final rough = (to - from).abs() / 5;
  if (rough == 0) return 1;
  final power = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  for (final factor in [1, 2, 5, 10]) {
    if (rough <= factor * power) return factor * power;
  }
  return 10 * power;
}

/// [value] written with as many decimals as [step] needs.
String _format(double value, double step) {
  if (step >= 1) return value.toStringAsFixed(0);
  final decimals = (-math.log(step) / math.ln10).ceil();
  return value.toStringAsFixed(decimals);
}
