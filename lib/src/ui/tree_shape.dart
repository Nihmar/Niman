/// Where the tree's island stands on the wide shell (#1266): beside the
/// panes, as on a desktop, or over them where a tablet has no room for it
/// beside the note.
library;

/// The tree's place.
enum TreeShape {
  /// Docked beside the panes, the panes narrower by its width.
  beside,

  /// Laid over the panes from the rail's edge when asked for, a scrim over
  /// the rest; closed until then.
  over,
}

/// The least width the panes keep beside a docked tree on a touch device
/// held in landscape: under it the tree lies over them instead.
const double minPanesBesideTree = 360;

/// The tree's place on a surface that is [touch] or not, in a window held
/// in [portrait] or not, whose panes would be [panesBeside] wide beside a
/// docked tree, while a [page] — Home, Todo — shows or not, and while a
/// note is being [writing] in or not.
///
/// A tablet held upright gives the note its width, and lays the tree over
/// it (an 11″ one has 440 dp left beside it); held in landscape it keeps
/// the tree beside unless that leaves the note too little. Home and Todo
/// are pages that want the width, not notes beside the tree; a note
/// being written in is the note and the keyboard. A mouse's
/// tree is always beside: the desktop's shell does not change.
TreeShape treeShapeFor({
  required bool touch,
  required bool portrait,
  required double panesBeside,
  bool page = false,
  bool writing = false,
}) {
  if (!touch) return TreeShape.beside;
  if (portrait || page || writing || panesBeside < minPanesBesideTree) {
    return TreeShape.over;
  }
  return TreeShape.beside;
}
