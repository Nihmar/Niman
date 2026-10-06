/// The one drawing of a git graph (#530): the lanes, the curves between
/// them, the commits by their type, their ids and tags, the branches'
/// names.
///
/// Like the other renderers it draws through a [DiagramTarget], so the
/// canvas and the exported SVG are the same picture.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_shapes.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/diagram_target.dart';
import 'package:niman/src/diagrams/flow_model.dart';
import 'package:niman/src/diagrams/git_graph_geometry.dart';
import 'package:niman/src/diagrams/git_graph_layout.dart';
import 'package:niman/src/diagrams/git_graph_model.dart';

/// Draws a [GitGraphLayout] through a [DiagramTarget].
final class GitGraphRenderer {
  /// Creates a renderer.
  const new({required this.layout, required this.style});

  /// What to draw.
  final GitGraphLayout layout;

  /// The sizes and colours to draw it with.
  final DiagramStyle style;

  DiagramPalette get _palette => style.palette;

  Color _colour(int? slot) =>
      slot == null ? _palette.nodeStroke : _palette.series[slot];

  /// Paints the lanes and curves, then the commits, their ids and tags,
  /// and the branches' names.
  void paint(DiagramTarget target) {
    for (final lane in layout.lanes) {
      target.line(
        lane.from,
        lane.to,
        color: _colour(lane.colour),
        strokeWidth: 3,
      );
    }
    for (final link in layout.links) {
      target.cubic(
        link.from,
        link.control1,
        link.control2,
        link.to,
        color: _colour(link.colour),
        strokeWidth: 3,
      );
    }
    for (final commit in layout.commits) {
      _commit(target, commit);
    }
    for (final lane in layout.lanes) {
      target.text(
        [lane.name],
        lane.labelBox,
        color: _palette.nodeText,
        fontSize: style.fontSize,
        weight: FontWeight.w600,
      );
    }
  }

  void _commit(DiagramTarget target, LaidOutCommit laid) {
    final commit = laid.commit;
    final colour = _colour(laid.colour);
    final dot = Rect.fromCircle(center: laid.centre, radius: gitCommitRadius);
    final surface = _palette.edgeLabelBackground;
    switch (commit.type) {
      case GitCommitType.highlight:
        target.polygon(
          DiagramShapes.polygonFor(FlowNodeShape.rect, dot.deflate(1)),
          fill: colour,
          stroke: _palette.edge,
          strokeWidth: 1.5,
        );
      case GitCommitType.normal || GitCommitType.reverse:
        target.polygon(_circle(dot), fill: colour, stroke: surface);
    }
    if (commit.type == GitCommitType.reverse) {
      const r = gitCommitRadius * 0.55;
      target
        ..line(
          laid.centre + const Offset(-r, -r),
          laid.centre + const Offset(r, r),
          color: surface,
          strokeWidth: 2,
        )
        ..line(
          laid.centre + const Offset(-r, r),
          laid.centre + const Offset(r, -r),
          color: surface,
          strokeWidth: 2,
        );
    }
    // A merge's ring, a cherry-pick's dot: the surface inside the commit.
    if (commit.merge) {
      target.polygon(_circle(dot.deflate(3)), stroke: surface, strokeWidth: 2);
    }
    if (commit.cherryPick) {
      target.polygon(_circle(dot.deflate(5)), fill: surface);
    }
    final label = laid.labelBox;
    if (label != null && commit.label != null) {
      target.text(
        [commit.label!],
        label,
        color: _palette.nodeText,
        fontSize: style.fontSize,
      );
    }
    final tagBox = laid.tagBox;
    final tag = commit.tag;
    if (tagBox != null && tag != null) {
      target
        ..polygon(
          DiagramShapes.polygonFor(FlowNodeShape.round, tagBox, radius: 4),
          fill: _palette.subgraphFill,
          stroke: _palette.subgraphStroke,
        )
        ..text(
          [tag],
          tagBox,
          color: _palette.subgraphTitle,
          fontSize: style.fontSize,
        );
    }
  }

  static List<Offset> _circle(Rect rect) =>
      DiagramShapes.polygonFor(FlowNodeShape.circle, rect);
}
