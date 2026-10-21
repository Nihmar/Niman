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

  /// Records the change that made the library's revision [revision] — and
  /// its tree revision [treeRevision], when that moved too — which moved
  /// rows in [folders] alone (row ids, 0 = the root), or anywhere when null.
  void record({required int revision, int? treeRevision, Set<int>? folders}) {
    _log.add((
      revision: revision,
      treeRevision: treeRevision,
      folders: folders,
    ));
    if (_log.length > kept) _log.removeAt(0);
  }

  /// The folders whose rows moved after [since] — a tree revision when
  /// [tree], the library's revision otherwise — or null when any may have:
  /// a change that did not say which, or one older than the log.
  Set<int>? since(int since, {required bool tree}) {
    final moved = <int>{};
    int? oldest;
    for (final entry in _log.reversed) {
      final at = tree ? entry.treeRevision : entry.revision;
      if (at == null) continue; // moved the library, not the tree
      if (at <= since) break;
      final folders = entry.folders;
      if (folders == null) return null;
      moved.addAll(folders);
      oldest = at;
    }
    // Nothing after it, or every change after it is in the log.
    return oldest == null || oldest == since + 1 ? moved : null;
  }
}
