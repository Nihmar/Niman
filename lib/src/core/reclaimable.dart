/// What the app can ask a cache to give back.
library;

/// Something that keeps memory it can rebuild, and can let go of it on
/// demand.
///
/// An owner implements this when everything it holds is a copy of something
/// else — the note on disk, a row of the index, a pure function of its
/// input — so that emptying it costs a re-read on the next ask and loses
/// nothing. It then hands itself to `MemoryReclaim.track`; the system's
/// call for memory and the app going to the background empty it.
///
/// What is not rebuilt without a cost the user sees (the tree's rows on
/// screen, an open note's buffer) or at all (an unsaved edit) does not
/// implement it.
abstract interface class Reclaimable {
  /// Lets go of everything that is kept only to save a rebuild.
  ///
  /// Called on the UI isolate, between frames, possibly while a reader of
  /// the cache is awaiting a result it already asked for: what is under way
  /// must still complete, and the next ask must rebuild what was let go.
  void reclaim();
}
