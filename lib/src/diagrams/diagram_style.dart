/// The look of a rendered diagram (#530): sizes, gaps and colours, taken
/// from the app's theme by the read view and from fixed sets for an export.
///
/// It is the one place the two drawings (Flutter canvas and exported SVG)
/// get their numbers from, so the picture on screen and the picture in a
/// PDF agree.
library;

import 'dart:ui' show Brightness;

import 'package:flutter/painting.dart';

/// The colours one drawing uses.
final class DiagramPalette {
  /// Creates a palette.
  const new({
    required this.nodeFill,
    required this.nodeStroke,
    required this.nodeText,
    required this.edge,
    required this.edgeLabelBackground,
    required this.subgraphFill,
    required this.subgraphStroke,
    required this.subgraphTitle,
  });

  /// The default light palette, close to Mermaid's own.
  static const DiagramPalette light = DiagramPalette(
    nodeFill: Color(0xFFECECFF),
    nodeStroke: Color(0xFF9370DB),
    nodeText: Color(0xFF333333),
    edge: Color(0xFF333333),
    edgeLabelBackground: Color(0xFFFFFFFF),
    subgraphFill: Color(0xFFFFF8DD),
    subgraphStroke: Color(0xFFAAAA33),
    subgraphTitle: Color(0xFF333333),
  );

  /// The dark palette, for a dark theme.
  static const DiagramPalette dark = DiagramPalette(
    nodeFill: Color(0xFF31334A),
    nodeStroke: Color(0xFF8A8FD6),
    nodeText: Color(0xFFE6E6F0),
    edge: Color(0xFFB4B7CC),
    edgeLabelBackground: Color(0xFF1E1F2E),
    subgraphFill: Color(0xFF262838),
    subgraphStroke: Color(0xFF5F6288),
    subgraphTitle: Color(0xFFCFD1E4),
  );

  /// The fill inside a node.
  final Color nodeFill;

  /// The outline of a node.
  final Color nodeStroke;

  /// The text inside a node.
  final Color nodeText;

  /// The lines and caps between nodes.
  final Color edge;

  /// The plate behind an edge's label.
  final Color edgeLabelBackground;

  /// The fill of a subgraph box.
  final Color subgraphFill;

  /// The outline of a subgraph box.
  final Color subgraphStroke;

  /// The text of a subgraph's title.
  final Color subgraphTitle;

  /// The palette for a [brightness].
  static DiagramPalette of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// The geometry and colours one drawing is made with.
final class DiagramStyle {
  /// Creates a style.
  const new({
    this.fontSize = 14,
    this.lineHeight = 1.25,
    this.fontFamily,
    this.nodePadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.rankGap = 48,
    this.nodeGap = 28,
    this.subgraphPadding = 18,
    this.edgeLabelPadding = const EdgeInsets.symmetric(
      horizontal: 4,
      vertical: 2,
    ),
    this.nodeStrokeWidth = 1.5,
    this.cornerRadius = 6,
    this.palette = DiagramPalette.light,
  });

  /// The style for a [brightness], at the given [fontSize].
  factory forBrightness(Brightness brightness, {double fontSize = 14}) =>
      DiagramStyle(fontSize: fontSize, palette: DiagramPalette.of(brightness));

  /// The size of a node's and an edge label's text.
  final double fontSize;

  /// The line box, as a multiple of [fontSize].
  final double lineHeight;

  /// The typeface, or null for the ambient one.
  final String? fontFamily;

  /// The room kept round a node's text.
  final EdgeInsets nodePadding;

  /// The gap between two ranks.
  final double rankGap;

  /// The gap between two nodes in the same rank.
  final double nodeGap;

  /// The room between a subgraph's box and the nodes it holds.
  final double subgraphPadding;

  /// The room round an edge's label.
  final EdgeInsets edgeLabelPadding;

  /// The width of a node's outline.
  final double nodeStrokeWidth;

  /// The radius of a rounded rectangle.
  final double cornerRadius;

  /// The colours.
  final DiagramPalette palette;

  /// A key that changes whenever a number or colour a laid-out drawing
  /// depends on changes, so a cache can tell two styles apart.
  String get cacheKey => [
    fontSize,
    lineHeight,
    nodePadding,
    rankGap,
    nodeGap,
    subgraphPadding,
    edgeLabelPadding,
    nodeStrokeWidth,
    cornerRadius,
    palette.nodeFill.toARGB32(),
    palette.nodeStroke.toARGB32(),
    palette.nodeText.toARGB32(),
    palette.edge.toARGB32(),
    palette.edgeLabelBackground.toARGB32(),
    palette.subgraphFill.toARGB32(),
    palette.subgraphStroke.toARGB32(),
    palette.subgraphTitle.toARGB32(),
  ].join(',');
}
