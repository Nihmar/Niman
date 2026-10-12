/// What an index change did to the tree's rows (#751).
///
/// The tree is drawn from the shape of the index rows — their paths, names,
/// folders, whether they are folders — and from three frontmatter fields on
/// them: the title a row shows for its name, the date at its right, the pin
/// that puts it in the pinned block; the field orders read a note's size
/// and times too. A save that writes only size and time draws nothing new
/// in a name-ordered tree: that change is `contents`, and the tree that
/// orders by name has nothing to read again. A save that changes the
/// title, the date or the pin is `tree` (#760).
library;

/// The kind of change an index write made.
enum IndexChange {
  /// A row was added, removed or reshaped — its path, its name, its folder,
  /// whether it is a folder — or its title, date or pin changed: what the
  /// tree draws has changed.
  tree,

  /// A row was written without its shape changing: a save's new size and
  /// time, a reindex of the same path, the title, date and pin as they
  /// were. The name orders draw the same tree;
  /// the field orders can move the row.
  contents,
}
