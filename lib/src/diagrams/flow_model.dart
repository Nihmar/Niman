/// The flowchart model (#530): the nodes, edges and subgraphs a Mermaid
/// `flowchart` (or `graph`) fence holds, once its source has been parsed.
///
/// It is the model of every diagram that is a graph of boxes: a mind map,
/// a class, a state and an entity-relationship diagram are parsed into it
/// too, which is why it has a class's box, a state's start and end, UML's
/// ends and crow's feet.
///
/// The model is what the layout and the two drawings (Flutter canvas and
/// exported SVG) share. It carries no geometry: where a node sits is the
/// layout's, so the same model is laid out at any size and in any
/// direction.
library;

/// The direction a flowchart is laid out in.
enum FlowDirection {
  /// Top to bottom (`TD`, `TB`): ranks run downwards.
  topDown,

  /// Bottom to top (`BT`): ranks run upwards.
  bottomUp,

  /// Left to right (`LR`): ranks run to the right.
  leftRight,

  /// Right to left (`RL`): ranks run to the left.
  rightLeft;

  /// The direction a keyword names, or null when it names none.
  static FlowDirection? parse(String word) => switch (word.toUpperCase()) {
    'TD' || 'TB' => FlowDirection.topDown,
    'BT' => FlowDirection.bottomUp,
    'LR' => FlowDirection.leftRight,
    'RL' => FlowDirection.rightLeft,
    _ => null,
  };

  /// Whether the ranks run down the drawing rather than across it.
  bool get isVertical =>
      this == FlowDirection.topDown || this == FlowDirection.bottomUp;

  /// Whether rank 0 sits at the far end (bottom or right) rather than the
  /// near one.
  bool get isReversed =>
      this == FlowDirection.bottomUp || this == FlowDirection.rightLeft;

  /// The word Mermaid writes for this direction.
  String get keyword => switch (this) {
    FlowDirection.topDown => 'TD',
    FlowDirection.bottomUp => 'BT',
    FlowDirection.leftRight => 'LR',
    FlowDirection.rightLeft => 'RL',
  };
}

/// The outline a Mermaid node is drawn with.
enum FlowNodeShape {
  /// `id[text]`, a plain rectangle.
  rect,

  /// `id(text)`, a rounded rectangle.
  round,

  /// `id([text])`, a stadium: a rectangle with semicircular ends.
  stadium,

  /// `id[[text]]`, a subroutine: a rectangle with a bar at each end.
  subroutine,

  /// `id[(text)]`, a database: a cylinder.
  database,

  /// `id((text))`, a circle.
  circle,

  /// `id{text}`, a diamond.
  diamond,

  /// `id{{text}}`, a hexagon.
  hexagon,

  /// `id>text]`, an asymmetric flag.
  asymmetric,

  /// `id[/text/]`, a parallelogram.
  parallelogram,

  /// `id[\text\]`, a parallelogram leaning the other way.
  parallelogramAlt,

  /// `id[/text\]`, a trapezoid.
  trapezoid,

  /// `id[\text/]`, a trapezoid the other way up.
  trapezoidAlt,

  /// A state diagram's start, `[*]` before an arrow: a filled dot.
  start,

  /// A state diagram's end, `[*]` after an arrow: a ringed dot.
  end,

  /// A state diagram's `<<fork>>` or `<<join>>`: a bar across the flow.
  bar,

  /// A note beside a state or a class.
  note,

  /// A class: its name, its attributes and its methods, one compartment
  /// each ([FlowNode.sections]).
  classBox;

  /// Whether the text sits inside a bounded box at all.
  bool get isClosed => this != FlowNodeShape.asymmetric;

  /// Whether the node is a mark with no text: a start, an end, a bar.
  bool get isMark =>
      this == FlowNodeShape.start ||
      this == FlowNodeShape.end ||
      this == FlowNodeShape.bar;
}

/// The stroke an edge is drawn with.
enum FlowEdgeStyle {
  /// A solid line (`-->`, `---`, `--x`).
  solid,

  /// A dotted line (`-.->`, `-.-`).
  dotted,

  /// A thick line (`==>`, `===`).
  thick;

  /// The line's thickness in logical pixels.
  double get width => this == FlowEdgeStyle.thick ? 3.5 : 2;
}

/// What an edge's end is capped with.
enum FlowEdgeEnd {
  /// No cap: the line simply stops at the node.
  none,

  /// A filled arrowhead (`>`).
  arrow,

  /// A small cross (`x`).
  cross,

  /// A small circle (`o`).
  circle,

  /// A hollow triangle: UML's inheritance and realization (`<|`, `|>`).
  triangle,

  /// A filled diamond: UML's composition (`*`).
  diamond,

  /// A hollow diamond: UML's aggregation (`o` in a class diagram).
  hollowDiamond,

  /// Crow's foot, exactly one (`||`): two bars.
  one,

  /// Crow's foot, zero or one (`|o`, `o|`): a bar and a circle.
  zeroOrOne,

  /// Crow's foot, one or more (`}|`, `|{`): the foot and a bar.
  oneOrMore,

  /// Crow's foot, zero or more (`}o`, `o{`): the foot and a circle.
  zeroOrMore;

  /// Whether the end carries any mark at all.
  bool get isMarked => this != FlowEdgeEnd.none;
}

/// One box of a flowchart.
final class FlowNode {
  /// Creates a node.
  const new({
    required this.id,
    required this.label,
    required this.shape,
    this.sections = const [],
  });

  /// The identifier that edges refer to it by.
  final String id;

  /// The text drawn inside it (line breaks still in `<br/>` form).
  final String label;

  /// The outline it is drawn with.
  final FlowNodeShape shape;

  /// A class box's compartments, each a list of lines: its name (with any
  /// stereotype above it), its attributes, its methods. Empty for every
  /// other shape, whose text is [label].
  final List<List<String>> sections;
}

/// One connection between two nodes.
final class FlowEdge {
  /// Creates an edge.
  const new({
    required this.from,
    required this.to,
    this.label,
    this.style = FlowEdgeStyle.solid,
    this.start = FlowEdgeEnd.none,
    this.end = FlowEdgeEnd.arrow,
    this.startLabel,
    this.endLabel,
  });

  /// The id of the node it leaves.
  final String from;

  /// The id of the node it reaches.
  final String to;

  /// The text drawn on it, or null when it carries none.
  final String? label;

  /// The stroke it is drawn with.
  final FlowEdgeStyle style;

  /// What its tail is capped with.
  final FlowEdgeEnd start;

  /// What its head is capped with.
  final FlowEdgeEnd end;

  /// The text at its tail — a class relation's cardinality — or null.
  final String? startLabel;

  /// The text at its head, or null.
  final String? endLabel;

  /// Whether both ends carry no mark: a plain connecting line.
  bool get isOpen => !start.isMarked && !end.isMarked;
}

/// One `subgraph … end` block.
final class FlowSubgraph {
  /// Creates a subgraph.
  const new({
    required this.id,
    required this.title,
    required this.nodeIds,
    this.direction,
    this.parent,
  });

  /// The identifier written after `subgraph`.
  final String id;

  /// The title drawn above the box.
  final String title;

  /// The ids of the nodes it contains, in declaration order.
  final List<String> nodeIds;

  /// Its own `direction`, when it declares one.
  final FlowDirection? direction;

  /// The id of the subgraph it is written inside, or null at the top.
  final String? parent;
}

/// A parsed flowchart.
final class Flowchart {
  /// Creates a flowchart.
  const new({
    required this.direction,
    required this.nodes,
    required this.edges,
    required this.subgraphs,
  });

  /// The direction ranks run in.
  final FlowDirection direction;

  /// Every node, in the order it was first mentioned.
  final List<FlowNode> nodes;

  /// Every edge, in the order it was written.
  final List<FlowEdge> edges;

  /// Every subgraph, in the order each is closed: one inside another comes
  /// before it.
  final List<FlowSubgraph> subgraphs;
}
