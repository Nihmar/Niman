/// The block diagram model (#530): the blocks a `block-beta` fence sets in
/// a grid of columns, the groups nesting a grid of their own, and the
/// edges between blocks.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

import 'package:niman/src/diagrams/flow_model.dart';

/// Where a block arrow points.
enum BlockArrowDirection {
  /// `(right)`.
  right,

  /// `(left)`.
  left,

  /// `(up)`.
  up,

  /// `(down)`.
  down,

  /// `(x)`: both ways across.
  x,

  /// `(y)`: both ways up and down.
  y;

  /// The direction a word names, or null when it names none.
  static BlockArrowDirection? parse(String word) {
    for (final value in values) {
      if (value.name == word.toLowerCase()) return value;
    }
    return null;
  }

  /// Whether the arrow runs up and down rather than across.
  bool get isVertical =>
      this == BlockArrowDirection.up ||
      this == BlockArrowDirection.down ||
      this == BlockArrowDirection.y;
}

/// One cell, or a run of cells, of a grid.
sealed class BlockItem {
  const new({required this.span});

  /// How many of its grid's columns it takes.
  final int span;
}

/// A block: a box with its text, or an arrow when [arrow] is set.
final class BlockNode extends BlockItem {
  /// Creates a block.
  const new({
    required this.id,
    required this.label,
    required this.shape,
    required super.span,
    this.arrow,
  });

  /// Its id, the name edges reach it by.
  final String id;

  /// Its text.
  final String label;

  /// Its outline; a block arrow's is drawn from [arrow] instead.
  final FlowNodeShape shape;

  /// Where a block arrow (`id<["text"]>(right)`) points; null for a box.
  final BlockArrowDirection? arrow;
}

/// Empty cells: `space` or `space:3`.
final class BlockSpace extends BlockItem {
  /// Creates empty cells.
  const new({required super.span});
}

/// A group, `block:id:3 … end`: a box with a grid of its own inside.
final class BlockGroup extends BlockItem {
  /// Creates a group.
  const new({
    required this.id,
    required super.span,
    required this.columns,
    required this.children,
  });

  /// Its id, the name edges reach it by; null when it was written without
  /// one.
  final String? id;

  /// How many columns its grid has; null for one row holding every child.
  final int? columns;

  /// What is inside, in the order the cells fill.
  final List<BlockItem> children;
}

/// An edge between two blocks or groups, by id.
final class BlockEdge {
  /// Creates an edge.
  const new({
    required this.from,
    required this.to,
    required this.style,
    required this.start,
    required this.end,
    this.label,
  });

  /// The id it leaves.
  final String from;

  /// The id it reaches.
  final String to;

  /// Its stroke.
  final FlowEdgeStyle style;

  /// The cap where it leaves.
  final FlowEdgeEnd start;

  /// The cap where it arrives.
  final FlowEdgeEnd end;

  /// The text along it, if any.
  final String? label;
}

/// A parsed block diagram.
final class BlockDiagram {
  /// Creates a block diagram.
  const new({required this.root, required this.edges});

  /// The whole grid: a group with no box of its own.
  final BlockGroup root;

  /// The edges, in the order they were written.
  final List<BlockEdge> edges;
}
