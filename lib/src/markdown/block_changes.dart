/// What edits did to a note's block list, folded into the few stretches they
/// changed.
///
/// The read pane keeps a height for every block, measured where a frame drew
/// it and estimated elsewhere. When it takes the editor's blocks after some
/// edits, estimating the whole list again cost 100–200 ms on a note of 2 M
/// blocks, and forgot every height a frame had measured. What it needs to
/// know instead is which blocks are new: everywhere else the list holds the
/// blocks it held, moved along.
///
/// The block scanner reports each splice it makes to its list. Replayed one by
/// one they would move the pane's list once per keystroke, so they are folded
/// as they come: splices that overlap or touch become one stretch, and the
/// stretches are kept apart and in order. What comes out is a handful of
/// stretches for a writer who edits in a few places, each saying where it
/// starts in the list *as it is now*, how many blocks it took out of the list
/// as it was, and how many are there now. Replayed in order — each start is
/// right once the stretches before it are in — they turn the old list into
/// the new one.
library;

/// One changed stretch: where it starts in the new list, how many blocks it
/// replaced, and how many it holds.
typedef BlockChange = ({int start, int removed, int inserted});

/// The splices made to a block list, folded.
final class BlockChanges {
  /// No changes yet.
  new();

  /// Past this many separate stretches the changes are not worth replaying:
  /// the note was edited all over, and reading it whole is as cheap.
  static const int limit = 64;

  final List<BlockChange> _stretches = <BlockChange>[];
  bool _overflowed = false;

  /// The changed stretches in list order, or null when they stopped being
  /// worth keeping ([limit]).
  List<BlockChange>? get stretches =>
      _overflowed ? null : List<BlockChange>.unmodifiable(_stretches);

  /// Records that [removed] blocks from [index] on were replaced by
  /// [inserted] ones, [index] in the list as it was just before.
  void record(int index, int removed, int inserted) {
    if (_overflowed || (removed == 0 && inserted == 0)) return;
    final end = index + removed;
    final delta = inserted - removed;
    // The stretches before the splice, the ones it overlaps or touches,
    // and the ones after it, which only move.
    var first = 0;
    while (first < _stretches.length &&
        _stretches[first].start + _stretches[first].inserted < index) {
      first++;
    }
    var last = first;
    while (last < _stretches.length && _stretches[last].start <= end) {
      last++;
    }
    var start = index;
    var stop = end;
    var grown = 0;
    for (var at = first; at < last; at++) {
      final stretch = _stretches[at];
      if (stretch.start < start) start = stretch.start;
      final stretchEnd = stretch.start + stretch.inserted;
      if (stretchEnd > stop) stop = stretchEnd;
      grown += stretch.inserted - stretch.removed;
    }
    // The merged stretch, over [start, stop) of the list before this splice:
    // what it covered then less what the stretches in it had already grown
    // by is what it covered in the list they were recorded against.
    final merged = (
      start: start,
      removed: stop - start - grown,
      inserted: stop - start + delta,
    );
    for (var at = last; at < _stretches.length; at++) {
      final stretch = _stretches[at];
      _stretches[at] = (
        start: stretch.start + delta,
        removed: stretch.removed,
        inserted: stretch.inserted,
      );
    }
    _stretches.replaceRange(first, last, <BlockChange>[merged]);
    if (_stretches.length > limit) {
      _overflowed = true;
      _stretches.clear();
    }
  }
}
