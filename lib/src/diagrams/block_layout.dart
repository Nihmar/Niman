/// Laying a block diagram out (#530): every grid's columns as wide as its
/// widest block needs, its rows as tall as their tallest, each block
/// filling its cells, a group its own grid inside its box, and an edge a
/// straight line from one outline to the other.
///
/// Sizes go up from the blocks (a group is as big as its grid needs), then
/// room comes down (a group wider than its grid needs widens its columns),
/// so a grid's columns line up whatever a cell holds. The gaps between
/// cells hold an edge's caps, and an edge's label between the blocks it
/// joins: a second pass widens them when a label needs it.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/block_geometry.dart';
import 'package:niman/src/diagrams/block_model.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/flow_node_size.dart';

const double _margin = 12;

/// The room between a group's box and its grid.
const double _pad = 8;

/// The gap between cells when no edge has to pass.
const double _gap = 12;

/// An arrowhead's length (the edge caps') and the line left showing
/// beside it, at each end of an edge.
const double _capRoom = 11 + 6;

/// The height of a row holding only empty cells.
const double _emptyRow = 28;

/// One block placed: its box and its text, line by line.
typedef BlockBox = ({BlockNode node, Rect rect, List<String> lines});

/// One edge placed: where it leaves, where it arrives, and its label's box.
typedef BlockEdgeLine = ({
  BlockEdge edge,
  Offset start,
  Offset end,
  Rect? labelBox,
});

/// A block diagram with every part placed. Its groups are outer before inner,
/// so drawing them in order stacks them right.
typedef BlockLayout = ({
  Size size,
  List<Rect> groups,
  List<BlockBox> blocks,
  List<BlockEdgeLine> edges,
});

/// Lays [diagram] out with [style].
BlockLayout layoutBlock(BlockDiagram diagram, DiagramStyle style) {
  final grid = _Grid(style);
  var gaps = (across: _gap, down: _gap);
  if (diagram.edges.isNotEmpty) {
    gaps = (across: 2 * _capRoom, down: 2 * _capRoom);
  }
  var placed = grid.place(diagram.root, gaps);
  var edges = _edges(diagram, placed, style);
  // A label lies between the blocks it joins: when it does not fit the
  // gap with the caps either side, widen that way's gaps and place again.
  var across = gaps.across;
  var down = gaps.down;
  for (final edge in edges) {
    final box = edge.labelBox;
    if (box == null) continue;
    final run = edge.end - edge.start;
    if (run.dx.abs() >= run.dy.abs()) {
      across = math.max(across, box.width + 2 * _capRoom);
    } else {
      down = math.max(down, box.height + 2 * _capRoom);
    }
  }
  if (across > gaps.across || down > gaps.down) {
    placed = grid.place(diagram.root, (across: across, down: down));
    edges = _edges(diagram, placed, style);
  }
  return (
    size: placed.size,
    groups: placed.groups,
    blocks: placed.blocks,
    edges: edges,
  );
}

typedef _Gaps = ({double across, double down});

typedef _Placed = ({
  Size size,
  List<Rect> groups,
  List<BlockBox> blocks,
  Map<String, List<Offset>> outlines,
});

/// The grid of one group: its children, row by row, at their columns.
typedef _Cell = ({BlockItem item, int row, int column, int span});

/// Sizes and places the grids.
final class _Grid {
  new(this.style);

  final DiagramStyle style;
  final Map<BlockItem, Size> _natural = Map.identity();
  final Map<BlockGroup, (int, List<_Cell>)> _cells = Map.identity();

  double get _line => style.fontSize * style.lineHeight;

  _Placed place(BlockGroup root, _Gaps gaps) {
    _natural.clear();
    final size = _size(root, gaps, _margin);
    final groups = <Rect>[];
    final blocks = <BlockBox>[];
    final outlines = <String, List<Offset>>{};
    void lay(BlockGroup group, Rect rect, double pad) {
      final (columns, cells) = _grid(group);
      final rows = cells.isEmpty ? 0 : cells.last.row + 1;
      final heights = List<double>.filled(rows, _emptyRow);
      for (final cell in cells) {
        heights[cell.row] = math.max(heights[cell.row], _of(cell.item).height);
      }
      final natural =
          heights.fold<double>(0, (t, h) => t + h) +
          gaps.down * math.max(0, rows - 1);
      final extra = rows == 0
          ? 0.0
          : math.max<double>(0, rect.height - 2 * pad - natural) / rows;
      final unit =
          (rect.width - 2 * pad - gaps.across * (columns - 1)) / columns;
      final tops = <double>[];
      var y = rect.top + pad;
      for (final h in heights) {
        tops.add(y);
        y += h + extra + gaps.down;
      }
      for (final cell in cells) {
        final box = Rect.fromLTWH(
          rect.left + pad + cell.column * (unit + gaps.across),
          tops[cell.row],
          cell.span * unit + (cell.span - 1) * gaps.across,
          heights[cell.row] + extra,
        );
        switch (cell.item) {
          case final BlockNode node:
            final fitted = _fit(node, box);
            blocks.add((node: node, rect: fitted, lines: _lines(node)));
            outlines[node.id] = _outline(node, fitted);
          case final BlockGroup inner:
            groups.add(box);
            if (inner.id != null) {
              outlines[inner.id!] = DiagramShapes.polygonFor(
                FlowNodeShape.round,
                box,
                radius: style.cornerRadius,
              );
            }
            lay(inner, box, _pad);
          case BlockSpace():
            break;
        }
      }
    }

    lay(root, Offset.zero & size, _margin);
    return (size: size, groups: groups, blocks: blocks, outlines: outlines);
  }

  Size _of(BlockItem item) => _natural[item]!;

  /// The natural size of [item], its grid's with [pad] around it for a
  /// group; every item under it is sized on the way.
  Size _size(BlockItem item, _Gaps gaps, double pad) {
    final size = switch (item) {
      BlockSpace() => Size.zero,
      final BlockNode node => _nodeSize(node),
      final BlockGroup group => _groupSize(group, gaps, pad),
    };
    _natural[item] = size;
    return size;
  }

  Size _groupSize(BlockGroup group, _Gaps gaps, double pad) {
    final (columns, cells) = _grid(group);
    var unit = 0.0;
    final heights = <int, double>{};
    for (final cell in cells) {
      final size = _size(cell.item, gaps, _pad);
      unit = math.max(
        unit,
        (size.width - gaps.across * (cell.span - 1)) / cell.span,
      );
      heights[cell.row] = math.max(heights[cell.row] ?? _emptyRow, size.height);
    }
    final rows = heights.length;
    return Size(
      columns * unit + gaps.across * (columns - 1) + 2 * pad,
      heights.values.fold<double>(0, (t, h) => t + h) +
          gaps.down * math.max(0, rows - 1) +
          2 * pad,
    );
  }

  /// [group]'s column count and its cells: left to right, a row down when
  /// the next one does not fit what is left of the row.
  (int, List<_Cell>) _grid(BlockGroup group) => _cells.putIfAbsent(group, () {
    final columns = math.max(
      1,
      group.columns ??
          group.children.fold<int>(0, (total, item) => total + item.span),
    );
    final cells = <_Cell>[];
    var row = 0;
    var column = 0;
    for (final item in group.children) {
      final span = math.min(item.span, columns);
      if (column + span > columns) {
        row++;
        column = 0;
      }
      cells.add((item: item, row: row, column: column, span: span));
      column += span;
    }
    return (columns, cells);
  });

  List<String> _lines(BlockNode node) => DiagramMetrics.lines(node.label);

  Size _nodeSize(BlockNode node) {
    final lines = _lines(node);
    final arrow = node.arrow;
    if (arrow == null) {
      return flowNodeSize(
        FlowNode(id: node.id, label: node.label, shape: node.shape),
        lines,
        style,
      );
    }
    var text = 0.0;
    for (final line in lines) {
      text = math.max(text, DiagramMetrics.textWidth(line, style.fontSize));
    }
    return blockArrowSize(
      Size(
        text + style.nodePadding.horizontal,
        lines.length * _line + style.nodePadding.vertical,
      ),
      arrow,
    );
  }

  /// [node]'s box in its [cell]: the whole of it, but a circle stays round
  /// and an arrow grows only along itself — as thick across a wide cell,
  /// its head stays the size its text gave it.
  Rect _fit(BlockNode node, Rect cell) {
    final arrow = node.arrow;
    if (arrow != null) {
      final natural = _of(node);
      return arrow.isVertical
          ? Rect.fromCenter(
              center: cell.center,
              width: math.min(natural.width, cell.width),
              height: cell.height,
            )
          : Rect.fromCenter(
              center: cell.center,
              width: cell.width,
              height: math.min(natural.height, cell.height),
            );
    }
    if (node.shape == FlowNodeShape.circle) {
      return Rect.fromCenter(
        center: cell.center,
        width: math.min(cell.width, cell.height),
        height: math.min(cell.width, cell.height),
      );
    }
    return cell;
  }

  List<Offset> _outline(BlockNode node, Rect rect) {
    final arrow = node.arrow;
    if (arrow != null) return blockArrowOutline(rect, arrow);
    return DiagramShapes.polygonFor(
      node.shape,
      rect,
      radius: style.cornerRadius,
    );
  }
}

/// The edges between the outlines of [placed], their labels at the middle
/// of the line between them.
List<BlockEdgeLine> _edges(
  BlockDiagram diagram,
  _Placed placed,
  DiagramStyle style,
) {
  final line = style.fontSize * style.lineHeight;
  return [
    for (final edge in diagram.edges)
      if ((placed.outlines[edge.from], placed.outlines[edge.to]) case (
        final from?,
        final to?,
      ))
        () {
          final a = _centre(from);
          final b = _centre(to);
          final start = Offset.lerp(a, b, lastCrossing(from, a, b))!;
          final end = Offset.lerp(b, a, lastCrossing(to, b, a))!;
          final label = edge.label;
          Rect? labelBox;
          if (label != null) {
            final lines = DiagramMetrics.lines(label);
            var width = 0.0;
            for (final text in lines) {
              width = math.max(
                width,
                DiagramMetrics.textWidth(text, style.fontSize),
              );
            }
            labelBox = Rect.fromCenter(
              center: (start + end) / 2,
              width: width + style.edgeLabelPadding.horizontal,
              height: lines.length * line + style.edgeLabelPadding.vertical,
            );
          }
          return (edge: edge, start: start, end: end, labelBox: labelBox);
        }(),
  ];
}

/// The middle of [outline]'s bounds.
Offset _centre(List<Offset> outline) {
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final p in outline) {
    left = math.min(left, p.dx);
    top = math.min(top, p.dy);
    right = math.max(right, p.dx);
    bottom = math.max(bottom, p.dy);
  }
  return Offset((left + right) / 2, (top + bottom) / 2);
}
