/// The one drawing of a treemap (#530): its sections, its leaves and their
/// names, and the title.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture. A box is a tint of
/// its colour, so the text over it reads in the theme's own ink; a leaf is
/// outlined in the surface, the gap that tells two neighbours apart.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/treemap_layout.dart';

/// How much of the colour a section's box and a leaf take.
const double _sectionOpacity = 0.12;
const double _leafOpacity = 0.45;

/// Draws a [TreemapLayout] through a [DiagramTarget].
final class TreemapRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final TreemapLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  Color _colour(int? slot) =>
      slot == null ? _palette.nodeStroke : _palette.series[slot];

  List<Offset> _corners(Rect r) => [
    r.topLeft,
    r.topRight,
    r.bottomRight,
    r.bottomLeft,
  ];

  /// Paints every part.
  void paint(DiagramTarget target) {
    for (final section in layout.sections) {
      final colour = _colour(section.colour);
      target.polygon(
        _corners(section.rect),
        fill: colour.withValues(alpha: _sectionOpacity),
        stroke: colour,
      );
      final box = section.labelBox;
      if (box != null) {
        target.text(
          [section.label],
          box,
          color: _palette.nodeText,
          fontSize: style.fontSize,
          alignLeft: true,
          weight: FontWeight.w600,
        );
      }
    }
    for (final leaf in layout.leaves) {
      target.polygon(
        _corners(leaf.rect),
        fill: _colour(leaf.colour).withValues(alpha: _leafOpacity),
        stroke: _palette.edgeLabelBackground,
      );
      if (leaf.lines.isNotEmpty) {
        target.text(
          leaf.lines,
          leaf.rect,
          color: _palette.nodeText,
          fontSize: style.fontSize,
        );
      }
    }
    final title = layout.title;
    final box = layout.titleBox;
    if (title != null && box != null) {
      target.text(
        [title],
        box,
        color: _palette.nodeText,
        fontSize: style.fontSize * 1.2,
        weight: FontWeight.w600,
      );
    }
  }
}
