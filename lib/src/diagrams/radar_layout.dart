/// Laying a radar chart out (#530): its axes as spokes clockwise from the
/// top, the scale's rings round the centre, each curve a polygon through
/// its values, the axes' labels outside the rim and a legend beside it.
///
/// A value is placed from the centre (min) to the rim (max); one outside
/// that range stops at the centre or at the rim, so a curve never leaves
/// the chart. Each curve takes the palette's next series colour, in the
/// order it was written; past the palette's eight, neutral rather than a
/// colour handed out twice.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/radar_model.dart';

const double _margin = 12;
const double _radius = 140;

/// The room between the rim and an axis's label.
const double _labelGap = 8;

/// The points a circular ring is drawn with.
const int _circleSamples = 72;

/// A legend's colour swatch and the gaps round it.
const double _swatch = 12;
const double _legendGap = 24;

/// A text and the box it is drawn in.
typedef RadarText = ({String text, Rect box});

/// One curve placed: its points, axis by axis, and its colour slot.
typedef RadarCurveLine = ({List<Offset> points, int? colour});

/// One legend row: its swatch, its label and the curve's colour slot.
typedef RadarLegendRow = ({Rect swatch, RadarText label, int? colour});

/// A radar chart with every part placed.
typedef RadarLayout = ({
  Size size,
  List<List<Offset>> rings,
  List<(Offset, Offset)> spokes,
  List<RadarText> axisLabels,
  List<RadarCurveLine> curves,
  List<RadarLegendRow> legend,
  RadarText? title,
});

/// Lays [chart] out with [style].
RadarLayout layoutRadar(RadarChart chart, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final n = chart.axes.length;
  // Laid out round the origin, then moved so everything fits.
  Offset direction(int axis) {
    final angle = -math.pi / 2 + 2 * math.pi * axis / n;
    return Offset(math.cos(angle), math.sin(angle));
  }

  final rings = <List<Offset>>[
    for (var k = 1; k <= chart.ticks; k++)
      () {
        final r = _radius * k / chart.ticks;
        if (chart.graticule == RadarGraticule.polygon && n >= 3) {
          return [for (var a = 0; a < n; a++) direction(a) * r];
        }
        return [
          for (var s = 0; s < _circleSamples; s++)
            Offset(
                  math.cos(2 * math.pi * s / _circleSamples),
                  math.sin(2 * math.pi * s / _circleSamples),
                ) *
                r,
        ];
      }(),
  ];
  final spokes = [
    for (var a = 0; a < n; a++) (Offset.zero, direction(a) * _radius),
  ];

  // An axis's label just outside the rim, on the side its spoke points to.
  final axisLabels = <RadarText>[
    for (var a = 0; a < n; a++)
      () {
        final label = chart.axes[a].label;
        final w = DiagramMetrics.textWidth(label, fontSize);
        final d = direction(a);
        final anchor = d * (_radius + _labelGap);
        return (
          text: label,
          box: Rect.fromCenter(
            center: anchor + Offset(d.dx * w / 2, d.dy * line / 2),
            width: w,
            height: line,
          ),
        );
      }(),
  ];

  final span = chart.max - chart.min;
  final curves = <RadarCurveLine>[
    for (var c = 0; c < chart.curves.length; c++)
      (
        points: [
          for (var a = 0; a < n; a++)
            direction(a) *
                (_radius *
                    ((chart.curves[c].values[a] - chart.min) / span).clamp(
                      0,
                      1,
                    )),
        ],
        colour: c < style.palette.series.length ? c : null,
      ),
  ];

  var bounds = Rect.fromCircle(center: Offset.zero, radius: _radius);
  for (final label in axisLabels) {
    bounds = bounds.expandToInclude(label.box);
  }

  final legend = <RadarLegendRow>[];
  if (chart.showLegend) {
    final rows = chart.curves.length;
    var top = -rows * line / 2;
    final left = bounds.right + _legendGap;
    for (var c = 0; c < rows; c++) {
      final label = chart.curves[c].label;
      final w = DiagramMetrics.textWidth(label, fontSize);
      final swatch = Rect.fromLTWH(
        left,
        top + (line - _swatch) / 2,
        _swatch,
        _swatch,
      );
      final box = Rect.fromLTWH(swatch.right + 8, top, w, line);
      legend.add((
        swatch: swatch,
        label: (text: label, box: box),
        colour: c < style.palette.series.length ? c : null,
      ));
      bounds = bounds.expandToInclude(swatch).expandToInclude(box);
      top += line;
    }
  }

  RadarText? title;
  final written = chart.title;
  if (written != null) {
    final titleSize = fontSize * 1.2;
    final w = DiagramMetrics.textWidth(written, titleSize);
    final h = titleSize * style.lineHeight;
    final box = Rect.fromCenter(
      center: Offset(bounds.center.dx, bounds.top - 12 - h / 2),
      width: w,
      height: h,
    );
    title = (text: written, box: box);
    bounds = bounds.expandToInclude(box);
  }

  final shift = Offset(_margin - bounds.left, _margin - bounds.top);
  RadarText moved(RadarText text) =>
      (text: text.text, box: text.box.shift(shift));
  return (
    size: Size(bounds.width + 2 * _margin, bounds.height + 2 * _margin),
    rings: [
      for (final ring in rings) [for (final p in ring) p + shift],
    ],
    spokes: [for (final (a, b) in spokes) (a + shift, b + shift)],
    axisLabels: [for (final label in axisLabels) moved(label)],
    curves: [
      for (final curve in curves)
        (
          points: [for (final p in curve.points) p + shift],
          colour: curve.colour,
        ),
    ],
    legend: [
      for (final row in legend)
        (
          swatch: row.swatch.shift(shift),
          label: moved(row.label),
          colour: row.colour,
        ),
    ],
    title: title == null ? null : moved(title),
  );
}
