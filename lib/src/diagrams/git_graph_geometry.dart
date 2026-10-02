/// Where a git graph's parts sit once laid out (#530).
///
/// Geometry only, in logical pixels: the canvas and the SVG both draw from
/// it, so neither keeps a measurement of its own.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/git_graph_model.dart';

/// A git graph with every part placed.
final class GitGraphLayout {
  /// Creates a layout.
  const new({
    required this.size,
    required this.lanes,
    required this.links,
    required this.commits,
  });

  /// The drawing's size.
  final Size size;

  /// The branches' lanes.
  final List<LaidOutLane> lanes;

  /// The curves from a lane to another: a branch made, a merge.
  final List<LaidOutLink> links;

  /// The commits, in the order they were made.
  final List<LaidOutCommit> commits;
}

/// One branch's lane: its line and its name.
final class LaidOutLane {
  /// Creates a placed lane.
  const new({
    required this.name,
    required this.labelBox,
    required this.from,
    required this.to,
    required this.colour,
  });

  /// The branch's name.
  final String name;

  /// Where the name sits, at the lane's start.
  final Rect labelBox;

  /// Where the lane's line starts.
  final Offset from;

  /// Where it ends.
  final Offset to;

  /// The branch's slot in the palette's series, or null for the neutral.
  final int? colour;
}

/// One curve from a commit on a lane to a commit on another.
final class LaidOutLink {
  /// Creates a placed curve.
  const new({
    required this.from,
    required this.control1,
    required this.control2,
    required this.to,
    required this.colour,
  });

  /// The parent's centre.
  final Offset from;

  /// The first control point.
  final Offset control1;

  /// The second control point.
  final Offset control2;

  /// The child's centre.
  final Offset to;

  /// The slot of the branch it is drawn in, or null for the neutral.
  final int? colour;
}

/// One commit: its dot, its id and its tag.
final class LaidOutCommit {
  /// Creates a placed commit.
  const new({
    required this.commit,
    required this.centre,
    required this.colour,
    this.labelBox,
    this.tagBox,
  });

  /// The model.
  final GitCommit commit;

  /// Its dot's centre.
  final Offset centre;

  /// Its branch's slot in the palette's series, or null for the neutral.
  final int? colour;

  /// Where its id is written, or null.
  final Rect? labelBox;

  /// Where its tag is written, or null.
  final Rect? tagBox;
}
