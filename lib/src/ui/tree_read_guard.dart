/// When a read began: the guard's epoch and its forget sequence then.
typedef ReadStamp = ({int epoch, int sequence});

/// Tells a read that lands late whether what it carries still holds (#1200).
///
/// The tree reads from the index while the index keeps changing, so a read
/// can land after the revision that made it stale. The scheme is
/// `TreeChildCache`'s (#1064, #1132): [clear] starts a new epoch, so every
/// read begun before it is void, and [forget] voids the reads begun before it
/// of the folders it names alone. A [stamp] is taken before a read starts and
/// asked about with [holds] once it ends.
///
/// The forgets are numbered in one sequence rather than counted per folder,
/// so a read whose folder is not known until it ends (a folder looked up by
/// its path) is checked all the same: it holds unless its folder was forgotten
/// after the stamp.
final class TreeReadGuard {
  /// Counts the times everything was dropped.
  int get epoch => _epoch;
  int _epoch = 0;

  int _sequence = 0;

  /// For each folder forgotten in this epoch, the sequence of its last forget.
  final Map<int, int> _forgottenAt = <int, int>{};

  /// The stamp of a read that begins now.
  ReadStamp stamp() => (epoch: _epoch, sequence: _sequence);

  /// Whether a read of folder [parentId] begun at [stamp] still holds.
  bool holds(ReadStamp stamp, int parentId) =>
      stamp.epoch == _epoch && (_forgottenAt[parentId] ?? 0) <= stamp.sequence;

  /// Whether nothing at all was cleared or forgotten since [stamp]: for a
  /// read that depends on no one folder, which any revision outdates.
  bool untouched(ReadStamp stamp) =>
      stamp.epoch == _epoch && stamp.sequence == _sequence;

  /// Voids every read begun so far: the index moved, or the order changed.
  void clear() {
    _epoch++;
    // Nothing begun before this epoch holds, whichever folder it names.
    _forgottenAt.clear();
  }

  /// Voids the reads begun so far of the folders with ids [parents].
  void forget(Iterable<int> parents) {
    final at = ++_sequence;
    for (final id in parents) {
      _forgottenAt[id] = at;
    }
  }
}
