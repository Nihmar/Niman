/// Laying a treemap out (#530): each node a rectangle whose area is its
/// share of the whole, a section's nodes inside it under its name.
///
/// The rectangles are squarified (Bruls, Huizing and van Wijk): the
/// largest nodes first, each row of them laid along the shorter side for
/// as long as that keeps them closer to squares, so a value reads as an
/// area rather than as a sliver. A node worth nothing takes no room. A
/// top-level node takes the palette's next series colour and everything
/// inside it the same, in the order they were written; past the palette's
/// eight, neutral rather than a colour handed out twice.
///
/// A leaf too small for its name is drawn without it, never with text
/// spilling over its neighbours.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_values.dart';
import 'package:niman/src/diagrams/sequence_text.dart';
import 'package:niman/src/diagrams/treemap_model.dart';

const double _margin = 12;
const double _width = 600;
const double _height = 400;

/// The room between a box's edge and what is inside it.
const double _pad = 4;

/// Half the surface gap left between neighbouring boxes.
const double _gap = 1;

/// One section placed: its box, its name's box (null when the box is too
/// small to name), and its colour slot.
typedef TreemapSection = ({
  Rect rect,
  Rect? labelBox,
  String label,
  int? colour,
});

/// One leaf placed: its box, its name and value line by line (empty when
/// they do not fit), and its colour slot.
typedef TreemapLeaf = ({Rect rect, List<String> lines, int? colour});

/// A treemap with every part placed. Its sections are outer before inner,
/// so drawing them in order stacks them right.
typedef TreemapLayout = ({
  Size size,
  List<TreemapSection> sections,
  List<TreemapLeaf> leaves,
  Rect? titleBox,
  String? title,
});

/// Lays [chart] out with [style].
TreemapLayout layoutTreemap(TreemapChart chart, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final title = chart.title;
  final titleSize = fontSize * 1.2;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;
  final area = Rect.fromLTWH(_margin, _margin + titleHeight, _width, _height);
  final sections = <TreemapSection>[];
  final leaves = <TreemapLeaf>[];

  void place(List<TreemapNode> nodes, Rect rect, int? Function(int) colourOf) {
    final boxes = squarify([for (final node in nodes) node.total], rect);
    for (var i = 0; i < nodes.length; i++) {
      final box = boxes[i];
      if (box == null) continue;
      final node = nodes[i];
      final colour = colourOf(i);
      final inner = box.deflate(_gap);
      if (node.value != null) {
        leaves.add((
          rect: inner,
          lines: _leafLines(node, inner, style),
          colour: colour,
        ));
        continue;
      }
      final header = line + _pad;
      final fits =
          inner.height > header + 3 * _pad &&
          inner.width > 3 * _pad &&
          DiagramMetrics.textWidth(node.label, fontSize) <=
              inner.width - 2 * _pad;
      sections.add((
        rect: inner,
        labelBox: fits
            ? Rect.fromLTWH(
                inner.left + _pad,
                inner.top + _pad / 2,
                inner.width - 2 * _pad,
                line,
              )
            : null,
        label: node.label,
        colour: colour,
      ));
      final body = Rect.fromLTRB(
        inner.left + _pad,
        inner.top + (fits ? header : _pad),
        inner.right - _pad,
        inner.bottom - _pad,
      );
      if (body.width > 2 * _gap && body.height > 2 * _gap) {
        place(node.children, body, (_) => colour);
      }
    }
  }

  final slots = style.palette.series.length;
  place(chart.roots, area, (i) => i < slots ? i : null);

  return (
    size: Size(_width + 2 * _margin, area.bottom + _margin),
    sections: sections,
    leaves: leaves,
    titleBox: title == null
        ? null
        : Rect.fromCenter(
            center: Offset(
              _margin + _width / 2,
              _margin + (titleHeight - 12) / 2,
            ),
            width: DiagramMetrics.textWidth(title, titleSize),
            height: titleHeight - 12,
          ),
    title: title,
  );
}

/// A leaf's name and value wrapped to [box], or its name alone, or nothing
/// when even that does not fit.
List<String> _leafLines(TreemapNode leaf, Rect box, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final width = box.width - 2 * _pad;
  final height = box.height - 2 * _pad;
  final name = wrapLabel(leaf.label, width, fontSize);
  bool fits(List<String> lines) =>
      lines.length * line <= height &&
      lines.every((l) => DiagramMetrics.textWidth(l, fontSize) <= width);
  final withValue = [...name, diagramValue(leaf.value!)];
  if (fits(withValue)) return withValue;
  if (fits(name)) return name;
  return const [];
}

/// The rectangles [values] take in [rect], each as large as its share of
/// the sum, squarified; null for a value of zero, which takes no room.
List<Rect?> squarify(List<double> values, Rect rect) {
  final result = List<Rect?>.filled(values.length, null);
  if (rect.isEmpty) return result;
  // Each value as a share of the largest: values near a double's limit add
  // up to Infinity, which left every box an area of nothing.
  final largest = values.fold<double>(0, math.max);
  if (largest <= 0) return result;
  final shares = [for (final v in values) (v > 0 ? v : 0) / largest];
  final order = [
    for (var i = 0; i < shares.length; i++)
      if (shares[i] > 0) i,
  ]..sort((a, b) => shares[b].compareTo(shares[a]));
  if (order.isEmpty) return result;

  var free = rect;
  var remaining = order.fold<double>(0, (sum, i) => sum + shares[i]);
  var left = order.length;
  final scale = rect.width * rect.height / remaining;
  final row = <int>[];
  double area(int i) => shares[i] * scale;

  /// The worst aspect ratio of [items] laid along a side [side] long.
  double worst(List<int> items, double side) {
    final sum = items.fold<double>(0, (s, i) => s + area(i));
    var largest = 0.0;
    var smallest = double.infinity;
    for (final i in items) {
      largest = math.max(largest, area(i));
      smallest = math.min(smallest, area(i));
    }
    return math.max(
      side * side * largest / (sum * sum),
      sum * sum / (side * side * smallest),
    );
  }

  /// Lays the row out across what is free. Its thickness is its part of
  /// what is left to lay, of the free rectangle's — never its area divided
  /// by that rectangle's side, which rounding wears to nothing beside a
  /// value a million million times larger, and a row's area divided by
  /// nothing is Infinity. The last row takes all that is free.
  void lay() {
    final sum = row.fold<double>(0, (s, i) => s + shares[i]);
    left -= row.length;
    final part = left == 0 ? 1 : math.min(1, sum / remaining);
    if (free.width >= free.height) {
      // A column down the left of what is free.
      final width = free.width * part;
      var y = free.top;
      for (final i in row) {
        final h = free.height * shares[i] / sum;
        result[i] = Rect.fromLTWH(free.left, y, width, h);
        y += h;
      }
      free = Rect.fromLTRB(
        free.left + width,
        free.top,
        free.right,
        free.bottom,
      );
    } else {
      // A row across the top.
      final height = free.height * part;
      var x = free.left;
      for (final i in row) {
        final w = free.width * shares[i] / sum;
        result[i] = Rect.fromLTWH(x, free.top, w, height);
        x += w;
      }
      free = Rect.fromLTRB(
        free.left,
        free.top + height,
        free.right,
        free.bottom,
      );
    }
    remaining -= sum;
    row.clear();
  }

  for (final i in order) {
    final side = math.min(free.width, free.height);
    if (row.isEmpty || worst([...row, i], side) <= worst(row, side)) {
      row.add(i);
    } else {
      lay();
      row.add(i);
    }
  }
  if (row.isNotEmpty) lay();
  return result;
}
