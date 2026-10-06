/// The git-graph model (#530): its branches, and its commits in the order
/// they were made, each on its branch with its parents.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// How a commit is drawn, as `type:` writes it.
enum GitCommitType {
  /// A plain commit: a filled dot.
  normal,

  /// `REVERSE`: a dot struck through.
  reverse,

  /// `HIGHLIGHT`: a filled square.
  highlight,
}

/// The way a git graph's lanes run.
enum GitGraphDirection {
  /// `LR`: branches are rows, time runs left to right.
  leftRight,

  /// `TB`: branches are columns, time runs down.
  topDown,

  /// `BT`: branches are columns, time runs up.
  bottomUp,
}

/// One branch.
final class GitBranch {
  /// Creates a branch.
  const new({required this.name, required this.order});

  /// Its name.
  final String name;

  /// Where its lane sits among the others, smallest first.
  final double order;
}

/// One commit.
final class GitCommit {
  /// Creates a commit.
  const new({
    required this.branch,
    required this.parents,
    this.label,
    this.tag,
    this.type = GitCommitType.normal,
    this.merge = false,
    this.cherryPick = false,
  });

  /// The branch it was made on, by its place in [GitGraph.branches].
  final int branch;

  /// Its parents, by their place in [GitGraph.commits]: none for the
  /// first, two for a merge.
  final List<int> parents;

  /// The id it was written with, drawn beside it, or null.
  final String? label;

  /// Its tag, or null.
  final String? tag;

  /// How it is drawn.
  final GitCommitType type;

  /// Whether it is a merge.
  final bool merge;

  /// Whether it is a cherry-pick of another.
  final bool cherryPick;
}

/// A parsed git graph.
final class GitGraph {
  /// Creates a git graph.
  const new({
    required this.branches,
    required this.commits,
    this.direction = GitGraphDirection.leftRight,
  });

  /// The branches, in the order they were made.
  final List<GitBranch> branches;

  /// The commits, in the order they were made.
  final List<GitCommit> commits;

  /// The way the lanes run.
  final GitGraphDirection direction;
}
