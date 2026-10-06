// A Mermaid git graph (#530): its commands replayed as git would, laid out
// a lane a branch and a step a commit, and drawn on the canvas and in the
// SVG.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/canvas_target.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/git_graph_layout.dart';
import 'package:niman/src/diagrams/git_graph_model.dart';
import 'package:niman/src/diagrams/git_graph_parser.dart';
import 'package:niman/src/diagrams/git_graph_renderer.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/diagrams/mermaid_parser.dart';
import 'package:niman/src/diagrams/svg_target.dart';

const DiagramStyle _style = DiagramStyle();

const String _flow = '''
gitGraph
  commit id: "Alpha"
  commit tag: "v1.0"
  branch develop
  checkout develop
  commit
  commit type: HIGHLIGHT
  checkout main
  commit type: REVERSE
  merge develop id: "Merged" tag: "v2.0"
  branch feature order: 0.5
  commit
  checkout main
  cherry-pick id: "Alpha"
''';

Matcher _error(int line, String message) => throwsA(
  isA<MermaidParseException>()
      .having((e) => e.line, 'line', line)
      .having((e) => e.message, 'message', contains(message)),
);

void main() {
  test('commands are replayed: branches, parents, merges, picks', () {
    final graph = parseGitGraph(_flow);
    expect(graph.branches.map((b) => b.name), ['main', 'develop', 'feature']);
    final commits = graph.commits;
    expect(commits.map((c) => c.branch), [0, 0, 1, 1, 0, 0, 2, 0]);
    expect(commits.map((c) => c.parents), [
      <int>[],
      [0],
      [1],
      [2],
      [1],
      [4, 3],
      [5],
      [5],
    ]);
    expect(commits[0].label, 'Alpha');
    expect(commits[1].tag, 'v1.0');
    expect(commits[3].type, GitCommitType.highlight);
    expect(commits[4].type, GitCommitType.reverse);
    expect(commits[5].merge && commits[5].tag == 'v2.0', isTrue);
    expect(commits[7].cherryPick, isTrue);
    expect(commits[7].label, 'Alpha');
    expect(graph.branches[2].order, 0.5);
  });

  test('the header names the direction', () {
    expect(
      parseGitGraph('gitGraph TB:\ncommit').direction,
      GitGraphDirection.topDown,
    );
    expect(
      parseGitGraph('gitGraph BT:\ncommit').direction,
      GitGraphDirection.bottomUp,
    );
    expect(
      parseGitGraph('gitGraph\nswitch main\ncommit').direction,
      GitGraphDirection.leftRight,
    );
  });

  test('what git would refuse names its line', () {
    expect(
      () => parseGitGraph('gitGraph\ncommit\ncheckout nowhere'),
      _error(3, 'no branch is called "nowhere"'),
    );
    expect(
      () => parseGitGraph('gitGraph\ncommit\nbranch main'),
      _error(3, 'already exists'),
    );
    expect(
      () => parseGitGraph('gitGraph\ncommit\nmerge main'),
      _error(3, 'cannot merge itself'),
    );
    expect(
      () => parseGitGraph('gitGraph\ncommit\nbranch b\ncheckout main\nmerge b'),
      _error(5, 'nothing new to merge'),
    );
    expect(
      () => parseGitGraph('gitGraph\ncommit\ncherry-pick id: "x"'),
      _error(3, 'no commit has the id "x"'),
    );
    expect(
      () => parseGitGraph('gitGraph\ncommit id: "a"\ncommit id: "a"'),
      _error(3, 'used twice'),
    );
    expect(
      () => parseGitGraph('gitGraph\ncommit type: FANCY'),
      _error(2, 'NORMAL, REVERSE or HIGHLIGHT'),
    );
    expect(() => parseGitGraph('gitGraph\npush'), _error(2, 'found "push"'));
    expect(() => parseGitGraph('gitGraph'), _error(1, 'needs a commit'));
  });

  test('a lane a branch, in their order; a step a commit', () {
    final layout = layoutGitGraph(parseGitGraph(_flow), _style);
    expect(layout.lanes.map((l) => l.name), ['main', 'feature', 'develop']);
    final x = [for (final c in layout.commits) c.centre.dx];
    for (var i = 1; i < x.length; i++) {
      expect(x[i], greaterThan(x[i - 1]));
    }
    double laneY(String name) =>
        layout.lanes.firstWhere((l) => l.name == name).from.dy;
    expect(layout.commits[2].centre.dy, laneY('develop'));
    expect(layout.commits[6].centre.dy, laneY('feature'));
    // Develop's lane starts at its first commit: the curve from main
    // joins it there.
    final develop = layout.lanes.firstWhere((l) => l.name == 'develop');
    expect(develop.from.dx, layout.commits[2].centre.dx);
  });

  test('a curve where a branch is made and where one is merged', () {
    final layout = layoutGitGraph(parseGitGraph(_flow), _style);
    // develop from main's 2nd commit, the merge back, feature off main.
    expect(layout.links, hasLength(3));
    final merge = layout.links[1];
    expect(merge.from, layout.commits[3].centre);
    expect(merge.to, layout.commits[5].centre);
    expect(merge.colour, 1, reason: 'drawn in the merged branch colour');
  });

  test('ids and tags sit beside their commits, not on one another', () {
    final layout = layoutGitGraph(parseGitGraph(_flow), _style);
    final boxes = [
      for (final c in layout.commits) ...[?c.labelBox, ?c.tagBox],
    ];
    for (var i = 0; i < boxes.length; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        expect(boxes[i].overlaps(boxes[j]), isFalse);
      }
    }
    final bounds = Offset.zero & layout.size;
    for (final box in boxes) {
      expect(bounds.contains(box.topLeft), isTrue);
      expect(bounds.contains(box.bottomRight), isTrue);
    }
  });

  test('top to bottom, time runs down the lanes', () {
    final layout = layoutGitGraph(
      parseGitGraph('gitGraph TB:\ncommit\nbranch b\ncommit\ncommit'),
      _style,
    );
    final y = [for (final c in layout.commits) c.centre.dy];
    expect(y[1], greaterThan(y[0]));
    expect(
      layout.commits[1].centre.dx,
      greaterThan(layout.commits[0].centre.dx),
    );
    final up = layoutGitGraph(
      parseGitGraph('gitGraph BT:\ncommit\ncommit'),
      _style,
    );
    expect(up.commits[1].centre.dy, lessThan(up.commits[0].centre.dy));
  });

  test('a git graph dispatches, paints and exports', () {
    expect(parseMermaid(_flow), isA<MermaidGitGraph>());
    final layout = layoutGitGraph(parseGitGraph(_flow), _style);
    final recorder = ui.PictureRecorder();
    GitGraphRenderer(
      layout: layout,
      style: _style,
    ).paint(CanvasDiagramTarget(ui.Canvas(recorder)));
    recorder.endRecording().dispose();
    final svg = SvgDiagramTarget(
      width: layout.size.width,
      height: layout.size.height,
    );
    GitGraphRenderer(layout: layout, style: _style).paint(svg);
    final text = svg.finish();
    expect(text, contains('develop'));
    expect(text, contains('v2.0'));
  });

  test('down the lanes, ids and tags stay apart and in the drawing', () {
    final layout = layoutGitGraph(
      parseGitGraph(
        'gitGraph TB:\ncommit id: "a long id"\nbranch develop\n'
        'commit tag: "v1.0.0"\ncheckout main\nmerge develop tag: "v2.0.0"',
      ),
      _style,
    );
    final boxes = [
      for (final c in layout.commits) ...[?c.labelBox, ?c.tagBox],
    ];
    final bounds = Offset.zero & layout.size;
    for (final box in boxes) {
      expect(bounds.contains(box.topLeft), isTrue, reason: '$box');
      expect(bounds.contains(box.bottomRight), isTrue, reason: '$box');
      for (final other in boxes) {
        if (!identical(other, box)) expect(box.overlaps(other), isFalse);
      }
    }
  });
}
