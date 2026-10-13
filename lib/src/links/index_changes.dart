/// The library's announcement that its index moved.
library;

/// Something that can say the library's index changed.
abstract interface class IndexChanges {
  /// Fires after the index changed — a note made, renamed, deleted or saved
  /// anywhere in the library — which can make a dead link live and a live
  /// one dead, and add or remove a note that links to another. A source with
  /// no index to watch never fires.
  Stream<void> get changes;
}
