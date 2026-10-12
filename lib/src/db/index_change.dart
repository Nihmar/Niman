/// What an index change did to the tree's rows (#751).
///
/// The tree is drawn from the shape of the index rows — their paths, names,
/// folders, whether they are folders, whether they are pinned — and the
/// field orders from a note's size and times. A save writes size and time,
/// and nothing a name-ordered tree draws: that change is `contents`, and
/// the tree that orders by name has nothing to read again.
library;

/// The kind of change an index write made.
enum IndexChange {
  /// A row was added, removed or reshaped — its path, its name, its folder,
  /// whether it is a folder — or a pin moved: what the tree draws has
  /// changed.
  tree,

  /// A row was written without its shape changing: a save's new size and
  /// time, a reindex of the same path. The name orders draw the same tree;
  /// the field orders can move the row.
  contents,
}
