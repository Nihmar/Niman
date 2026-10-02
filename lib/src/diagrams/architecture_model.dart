/// The architecture diagram model (#530): services with their icons,
/// junctions, the groups they sit in, and edges that leave and reach a
/// given side of each.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// A side of a service, a junction or a group.
enum ArchSide {
  /// `L`.
  left,

  /// `R`.
  right,

  /// `T`.
  top,

  /// `B`.
  bottom;

  /// The side a letter names, or null when it names none.
  static ArchSide? parse(String letter) => switch (letter.toUpperCase()) {
    'L' => ArchSide.left,
    'R' => ArchSide.right,
    'T' => ArchSide.top,
    'B' => ArchSide.bottom,
    _ => null,
  };

  /// One step from a cell towards this side: (columns, rows).
  (int, int) get step => switch (this) {
    ArchSide.left => (-1, 0),
    ArchSide.right => (1, 0),
    ArchSide.top => (0, -1),
    ArchSide.bottom => (0, 1),
  };

  /// Whether an edge leaves this side across the drawing.
  bool get isHorizontal => this == ArchSide.left || this == ArchSide.right;
}

/// A service, or a junction when [isJunction]: a point edges meet at.
final class ArchService {
  /// Creates a service or a junction.
  const new({
    required this.id,
    required this.title,
    required this.icon,
    this.group,
    this.isJunction = false,
  });

  /// Its id, the name edges reach it by.
  final String id;

  /// What is written under its icon; empty for a junction.
  final String title;

  /// Its icon's name: `cloud`, `database`, `disk`, `internet`, `server`,
  /// or another one drawn as a plain box.
  final String icon;

  /// The id of the group it sits in, if any.
  final String? group;

  /// Whether it is a junction rather than a service.
  final bool isJunction;
}

/// A group of services, perhaps inside another group.
final class ArchGroup {
  /// Creates a group.
  const new({
    required this.id,
    required this.title,
    required this.icon,
    this.parent,
  });

  /// Its id.
  final String id;

  /// Its title.
  final String title;

  /// Its icon's name.
  final String icon;

  /// The id of the group it sits in, if any.
  final String? parent;
}

/// An edge between two sides.
final class ArchEdge {
  /// Creates an edge.
  const new({
    required this.from,
    required this.fromSide,
    required this.to,
    required this.toSide,
    this.fromGroup = false,
    this.toGroup = false,
    this.arrowAtFrom = false,
    this.arrowAtTo = false,
    this.label,
  });

  /// The id it leaves: a service's or a junction's, or a group's when
  /// [fromGroup].
  final String from;

  /// The side it leaves by.
  final ArchSide fromSide;

  /// The id it reaches, a group's when [toGroup].
  final String to;

  /// The side it reaches.
  final ArchSide toSide;

  /// Whether it leaves the group [from] sits in rather than [from] itself:
  /// `a{group}:R -- L:b`.
  final bool fromGroup;

  /// Whether it reaches the group [to] sits in.
  final bool toGroup;

  /// Whether it ends in an arrow at [from]: `a:R <-- L:b`.
  final bool arrowAtFrom;

  /// Whether it ends in an arrow at [to]: `a:R --> L:b`.
  final bool arrowAtTo;

  /// The text along it, if any.
  final String? label;
}

/// A parsed architecture diagram.
final class ArchitectureDiagram {
  /// Creates an architecture diagram.
  const new({
    required this.services,
    required this.groups,
    required this.edges,
  });

  /// The services and junctions, in the order they were written.
  final List<ArchService> services;

  /// The groups, in the order they were written.
  final List<ArchGroup> groups;

  /// The edges, in the order they were written.
  final List<ArchEdge> edges;
}
