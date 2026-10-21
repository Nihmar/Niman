/// What each recent change of a library moved in its tree, so a reader
/// holding the rows of an older revision re-reads only the folders that
/// changed since rather than every one it shows (#1132).
///
/// A note's new title, typed into its frontmatter, re-read every folder the
/// tree had open after each save: 21 to 35 ms for two folders on a tablet
/// (device log, 2026-10-20), and one more read for each folder open.
final class TreeMoves {
  /// A log of the last [kept] changes.
  new({this.kept = 64});

  /// How many changes are remembered: a reader further behind re-reads
  /// everything.
  final int kept;

  final List<({int revision, int? treeRevision, Set<int>? folders})> _log = [];

  /// The newest library revision, and the newest tree revision, among the
  /// changes the log has forgotten (0 = none yet).
  ///
  /// "Nothing moved since" is a claim the log has to be able to prove, not
  /// the absence of what it still holds: once the changes that moved the tree
  /// are pushed out by contents-only ones, the log holds no tree change at
  /// all, which read as "nothing moved" and left a reader on stale rows.
  int _forgottenRevision = 0;
  int _forgottenTreeRevision = 0;

  /// Records the change that made the library's revision [revision] — and
  /// its tree revision [treeRevision], when that moved too — which moved
  /// rows in [folders] alone (row ids, 0 = the root), or anywhere when null.
  void record({required int revision, int? treeRevision, Set<int>? folders}) {
    _log.add((
      revision: revision,
      treeRevision: treeRevision,
      folders: folders,
    ));
    if (_log.length > kept) {
      final forgotten = _log.removeAt(0);
      if (forgotten.revision > _forgottenRevision) {
        _forgottenRevision = forgotten.revision;
      }
      final tree = forgotten.treeRevision;
      if (tree != null && tree > _forgottenTreeRevision) {
        _forgottenTreeRevision = tree;
      }
    }
  }

  /// The folders whose rows moved after [since] — a tree revision when
  /// [tree], the library's revision otherwise — or null when any may have:
  /// a change that did not say which, or one older than the log.
  ///
  /// An empty set says that nothing moved: no change after [since] was
  /// forgotten, and none that is held moved the tree.
  Set<int>? since(int since, {required bool tree}) {
    final forgotten = tree ? _forgottenTreeRevision : _forgottenRevision;
    if (forgotten > since) return null;
    final moved = <int>{};
    for (final entry in _log.reversed) {
      final at = tree ? entry.treeRevision : entry.revision;
      if (at == null) continue; // moved the library, not the tree
      if (at <= since) break;
      final folders = entry.folders;
      if (folders == null) return null;
      moved.addAll(folders);
    }
    return moved;
  }
}
