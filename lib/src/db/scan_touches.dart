/// The paths a write outside a full scan touched while the scan ran
/// (#697).
///
/// The scan holds the indexer's lock a directory at a time, so a note made,
/// renamed or deleted meanwhile is written at once instead of waiting for
/// the whole walk. Its listing may have been taken before that write: what
/// the write touched is the write's, and the scan neither writes a row for
/// it from the older listing nor prunes it — nor a folder above it, whose
/// subtree the prune would take along.
library;

/// The touched paths of the scan running, if any.
final class ScanTouches {
  final Set<String> _paths = {};
  bool _open = false;

  /// A scan starts: touches count from now.
  void begin() {
    _paths.clear();
    _open = true;
  }

  /// The scan ended: nothing counts any more.
  void end() {
    _paths.clear();
    _open = false;
  }

  /// Library-relative [rels] were written by something other than the
  /// scan; nothing while no scan runs.
  void add(Iterable<String> rels) {
    if (_open) _paths.addAll(rels);
  }

  /// Whether a listing's entry [rel] is a touched path or inside one: the
  /// write that touched it already put the disk's word in the index.
  bool owns(String rel) => _paths.any((t) => rel == t || _inside(rel, t));

  /// Whether the scan must leave the row [rel] in place although its
  /// listing did not show it: [rel] was touched, lies inside a touched
  /// folder, or holds a touched path.
  bool shields(String rel) =>
      _paths.any((t) => rel == t || _inside(rel, t) || _inside(t, rel));

  static bool _inside(String rel, String folder) =>
      folder.isEmpty || rel.startsWith('$folder/');
}
