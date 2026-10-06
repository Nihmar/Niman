/// Laying a git graph out (#530): a lane a branch, a step of time a
/// commit, and the curves where a branch is made or merged.
///
/// Everything is placed on two axes — time, and the lanes across it — and
/// turned to the graph's direction at the end, so left-to-right and the
/// two vertical directions share one layout. A branch takes the palette's
/// next series colour, in the order it was made; the branches past the
/// palette's eight are drawn neutral rather than in a colour handed out
/// twice.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/git_graph_geometry.dart';
import 'package:niman/src/diagrams/git_graph_model.dart';

const double _margin = 12;

/// A commit dot's radius.
const double gitCommitRadius = 8;

/// The least room between two commits along time.
const double _step = 44;

/// The least room between two lanes.
const double _lane = 46;

/// Lays [graph] out with [style].
GitGraphLayout layoutGitGraph(GitGraph graph, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final across = graph.direction == GitGraphDirection.leftRight;
  double width(String? text) =>
      text == null ? 0 : DiagramMetrics.textWidth(text, fontSize);

  // The lanes: the branches with a commit, by their order, then as made.
  final used = {for (final commit in graph.commits) commit.branch};
  final lanes =
      [
        for (var b = 0; b < graph.branches.length; b++)
          if (used.contains(b)) b,
      ]..sort((a, b) {
        final order = graph.branches[a].order.compareTo(
          graph.branches[b].order,
        );
        return order != 0 ? order : a.compareTo(b);
      });
  final laneOf = {for (var k = 0; k < lanes.length; k++) lanes[k]: k};
  int? colour(int branch) =>
      branch < style.palette.series.length ? branch : null;

  // Room along time for the widest id or tag, and across a lane for an id
  // on one side of a dot and a tag on the other.
  final labels = graph.commits.any((c) => c.label != null);
  final tags = graph.commits.any((c) => c.tag != null);
  var widestLabel = 0.0;
  var widestTag = 0.0;
  for (final commit in graph.commits) {
    widestLabel = math.max(widestLabel, width(commit.label));
    widestTag = math.max(widestTag, width(commit.tag) + (tags ? 12 : 0));
  }
  var names = 0.0;
  for (final b in lanes) {
    names = math.max(names, width(graph.branches[b].name));
  }
  final step = across
      ? math.max(_step, math.max(widestLabel, widestTag) + 16)
      : math.max(_step, line + 12);
  // Down the lanes, a tag sits left of its dot and an id right of it: a
  // lane holds both, and its branch's name over it.
  final before = across
      ? (tags ? line + 12 : 0.0)
      : (tags ? widestTag + 6 : 0.0);
  final after = across
      ? (labels ? line + 6 : 0.0)
      : (labels ? widestLabel + 6 : 0.0);
  final lane = math.max(
    across ? _lane : math.max(_lane, names + 12),
    before + 2 * gitCommitRadius + 12 + after + 12,
  );
  // Before the first commit: the branches' names, in a column or a row.
  final head = across ? names + 24 : line + 16;
  final timeLength = head + graph.commits.length * step;
  final laneLength = lanes.length * lane;
  final reversed = graph.direction == GitGraphDirection.bottomUp;

  // A point at [time] along the time axis and [cross] across the lanes.
  Offset at(double time, double cross) {
    final t = reversed ? timeLength - time : time;
    return across
        ? Offset(_margin + t, _margin + cross)
        : Offset(_margin + cross, _margin + t);
  }

  double timeOf(int commit) => head + step * commit + step / 2;
  double crossOf(int branch) =>
      laneOf[branch]! * lane + before + gitCommitRadius + 6;

  final commits = <LaidOutCommit>[];
  for (var i = 0; i < graph.commits.length; i++) {
    final commit = graph.commits[i];
    final centre = at(timeOf(i), crossOf(commit.branch));
    commits.add(
      LaidOutCommit(
        commit: commit,
        centre: centre,
        colour: colour(commit.branch),
        labelBox: _beside(commit.label, centre, width, line, across, false),
        tagBox: _beside(commit.tag, centre, width, line, across, true),
      ),
    );
  }

  final links = <LaidOutLink>[];
  for (var i = 0; i < graph.commits.length; i++) {
    final commit = graph.commits[i];
    for (final (n, parent) in commit.parents.indexed) {
      final other = graph.commits[parent];
      if (other.branch == commit.branch) continue;
      final from = commits[parent].centre;
      final to = commits[i].centre;
      // The curve turns into the child's lane halfway along time.
      final middle = across
          ? Offset((from.dx + to.dx) / 2, 0)
          : Offset(0, (from.dy + to.dy) / 2);
      links.add(
        LaidOutLink(
          from: from,
          control1: across
              ? Offset(middle.dx, from.dy)
              : Offset(from.dx, middle.dy),
          control2: across
              ? Offset(middle.dx, to.dy)
              : Offset(to.dx, middle.dy),
          to: to,
          // A merge's second parent draws in its own branch's colour, the
          // first commit of a branch in the new branch's.
          colour: colour(commit.merge && n == 1 ? other.branch : commit.branch),
        ),
      );
    }
  }

  final laidLanes = <LaidOutLane>[];
  for (final b in lanes) {
    final mine = [
      for (var i = 0; i < graph.commits.length; i++)
        if (graph.commits[i].branch == b) i,
    ];
    // From its first commit: the curve from where it branched joins it.
    final start = mine.first;
    final cross = crossOf(b);
    final name = graph.branches[b].name;
    final label = at(head / 2, cross);
    laidLanes.add(
      LaidOutLane(
        name: name,
        labelBox: Rect.fromCenter(
          center: across ? Offset(_margin + names / 2 + 4, label.dy) : label,
          width: width(name),
          height: line,
        ),
        from: at(timeOf(start), cross),
        to: at(timeOf(mine.last), cross),
        colour: colour(b),
      ),
    );
  }

  final size = across
      ? Size(timeLength + 2 * _margin, laneLength + 2 * _margin)
      : Size(laneLength + 2 * _margin, timeLength + 2 * _margin);
  return GitGraphLayout(
    size: size,
    lanes: List.unmodifiable(laidLanes),
    links: List.unmodifiable(links),
    commits: List.unmodifiable(commits),
  );
}

/// Where [text] goes beside the dot at [centre]: across the lanes, below
/// it for an id and above for a [tag]; down them, right and left.
Rect? _beside(
  String? text,
  Offset centre,
  double Function(String? text) width,
  double line,
  bool across,
  bool tag,
) {
  if (text == null) return null;
  final w = width(text) + (tag ? 12 : 0);
  final h = line + (tag ? 4 : 0);
  const gap = gitCommitRadius + 6;
  if (across) {
    return Rect.fromCenter(
      center: centre + Offset(0, tag ? -(gap + h / 2) : gap + h / 2),
      width: w,
      height: h,
    );
  }
  return Rect.fromCenter(
    center: centre + Offset(tag ? -(gap + w / 2) : gap + w / 2, 0),
    width: w,
    height: h,
  );
}
