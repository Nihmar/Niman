/// Fenwick trees over a list of chunks — their totals and their sizes — so
/// that "which chunk holds value *i*" and "which chunk holds offset *x*" are
/// O(log chunks). The level of `PrefixSums` above its chunks.
library;

/// Two Fenwick trees, 1-indexed, over chunk totals and chunk sizes.
final class ChunkTree {
  /// Trees over chunks of [sizes] values summing to [totals].
  new(List<int> sizes, List<double> totals) {
    rebuild(sizes, totals);
  }

  /// The same trees as [other], apart from it.
  new copy(ChunkTree other)
    : _sums = List<double>.of(other._sums),
      _sizes = List<int>.of(other._sizes),
      _highestPower = other._highestPower;

  List<double> _sums = <double>[0];
  List<int> _sizes = <int>[0];

  /// The largest power of two at or below the chunk count, for the descents.
  int _highestPower = 0;

  /// How many chunks the trees are over.
  int get count => _sums.length - 1;

  /// The sum of every chunk's total.
  double get total => totalBefore(count);

  /// The sum of the totals of the chunks before [chunk].
  double totalBefore(int chunk) {
    var sum = 0.0;
    for (var at = chunk; at > 0; at -= at & -at) {
      sum += _sums[at];
    }
    return sum;
  }

  /// How many values the chunks before [chunk] hold.
  int sizeBefore(int chunk) {
    var size = 0;
    for (var at = chunk; at > 0; at -= at & -at) {
      size += _sizes[at];
    }
    return size;
  }

  /// Which chunk value [index] is in, and where in it.
  (int, int) locate(int index) {
    var chunk = 0;
    var remaining = index;
    for (var power = _highestPower; power > 0; power >>= 1) {
      final next = chunk + power;
      if (next <= count && _sizes[next] <= remaining) {
        remaining -= _sizes[next];
        chunk = next;
      }
    }
    return (chunk, remaining);
  }

  /// The first chunk whose end is past [offset], how many values the chunks
  /// before it hold, and what is left of [offset] inside it — [count] as the
  /// chunk when every chunk ends at or before it.
  (int, int, double) find(double offset) {
    var chunk = 0;
    var before = 0;
    var remaining = offset;
    for (var power = _highestPower; power > 0; power >>= 1) {
      final next = chunk + power;
      if (next <= count && _sums[next] <= remaining) {
        remaining -= _sums[next];
        before += _sizes[next];
        chunk = next;
      }
    }
    return (chunk, before, remaining);
  }

  /// Adds [delta] to chunk [chunk]'s total.
  void add(int chunk, double delta) {
    for (var at = chunk + 1; at <= count; at += at & -at) {
      _sums[at] += delta;
    }
  }

  /// Rebuilds the trees over chunks of [sizes] values summing to [totals],
  /// O(chunks).
  void rebuild(List<int> sizes, List<double> totals) {
    final count = sizes.length;
    final sums = List<double>.filled(count + 1, 0);
    final counts = List<int>.filled(count + 1, 0);
    for (var at = 1; at <= count; at++) {
      sums[at] += totals[at - 1];
      counts[at] += sizes[at - 1];
      final parent = at + (at & -at);
      if (parent <= count) {
        sums[parent] += sums[at];
        counts[parent] += counts[at];
      }
    }
    _sums = sums;
    _sizes = counts;
    var power = 1;
    while (power * 2 <= count) {
      power *= 2;
    }
    _highestPower = count == 0 ? 0 : power;
  }
}
