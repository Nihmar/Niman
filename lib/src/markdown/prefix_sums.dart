/// Prefix sums over a list of non-negative values, with insertion: offset ↔
/// index in O(log n), and an edit that adds or removes values in O(chunk).
///
/// Two callers ask the same two questions. The source buffer asks "which line
/// is this offset in, and where does line *i* start"; the height map
/// (`docs/dev/unified-surface.md` §8.4.1) asks "which block is this pixel in,
/// and where does block *i* start". Both are the same arithmetic over
/// variable-length spans.
///
/// A Fenwick tree answered them, and could not take an insertion: an edit that
/// changed *how many* spans there are — every Enter, paste, joined line and
/// undo — rebuilt it, O(n). On a note of a million lines that was 41 ms in the
/// buffer and 59 ms in the height map per Enter, which a writer feels. So the
/// values are kept in chunks of about a thousand, each with its own prefix
/// sums, and a Fenwick tree runs over the *chunks* — their totals and their
/// sizes. A lookup descends the chunk tree and reads a chunk's prefix; an
/// insertion rewrites one chunk and rebuilds the chunk trees, which are a
/// thousandth of the note.
///
/// The values are doubles: the height map's are, and the buffer's spans are
/// integers well inside what a double holds exactly.
library;

/// Chunked prefix sums over a list of non-negative values.
final class PrefixSums {
  /// Sums over [values], in O(values.length).
  new(List<double> values) {
    for (var at = 0; at < values.length; at += _chunkSize) {
      final end = at + _chunkSize < values.length
          ? at + _chunkSize
          : values.length;
      _chunks.add(values.sublist(at, end));
    }
    if (_chunks.isEmpty) _chunks.add(<double>[]);
    _prefixes.addAll(_chunks.map(_prefixOf));
    _length = values.length;
    _rebuildTrees();
  }

  /// How many values a chunk is cut to, and half of when it may grow before it
  /// is split again.
  static const int _chunkSize = 1024;

  /// The values, chunk by chunk. Never empty: an empty list is one empty chunk.
  final List<List<double>> _chunks = <List<double>>[];

  /// Each chunk's own prefix sums: `_prefixes[c][i]` is the sum of the first
  /// `i` values of chunk `c`, so it has one entry more than the chunk.
  final List<List<double>> _prefixes = <List<double>>[];

  /// Fenwick trees over the chunks, 1-indexed: their totals and their sizes.
  List<double> _sumTree = <double>[0];
  List<int> _sizeTree = <int>[0];

  /// The largest power of two at or below the chunk count, for the descents.
  int _highestPower = 0;

  int _length = 0;

  /// How many values there are.
  int get length => _length;

  /// The sum of every value.
  double get total => _chunkPrefix(_chunks.length);

  /// The sum of the values before [index]. [index] may be [length], which
  /// answers [total]. O(log chunks).
  double offsetOf(int index) {
    assert(index >= 0 && index <= _length, 'index $index out of 0..$_length');
    if (index >= _length) return total;
    final (chunk, local) = _locate(index);
    return _chunkPrefix(chunk) + _prefixes[chunk][local];
  }

  /// Value [index].
  double valueAt(int index) {
    assert(index >= 0 && index < _length, 'index $index out of range');
    final (chunk, local) = _locate(index);
    return _chunks[chunk][local];
  }

  /// The largest index whose offset is at or before [offset]: the value that
  /// contains it, the one that starts there on a boundary.
  ///
  /// Offsets at or before the start answer 0, and offsets at or past [total]
  /// answer `length - 1`, so the result is always a valid index — the callers
  /// rely on it, since a buffer always has a line and a height map a block.
  int indexOf(double offset) {
    if (_length == 0 || offset <= 0) return 0;
    if (offset >= total) return _length - 1;
    // The chunks that end at or before [offset], by binary lifting.
    var chunk = 0;
    var before = 0;
    var remaining = offset;
    final count = _chunks.length;
    for (var power = _highestPower; power > 0; power >>= 1) {
      final next = chunk + power;
      if (next <= count && _sumTree[next] <= remaining) {
        remaining -= _sumTree[next];
        before += _sizeTree[next];
        chunk = next;
      }
    }
    if (chunk >= count) return _length - 1;
    // Inside that chunk: the last local start at or before what is left.
    final prefix = _prefixes[chunk];
    var low = 0;
    var high = _chunks[chunk].length - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (prefix[mid] <= remaining) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    final index = before + low;
    return index < _length ? index : _length - 1;
  }

  /// Sets value [index] to [value]. O(chunk + log chunks).
  void setValue(int index, double value) {
    assert(index >= 0 && index < _length, 'index $index out of range');
    assert(value >= 0, 'value $index would be negative: $value');
    final (chunk, local) = _locate(index);
    final values = _chunks[chunk];
    final delta = value - values[local];
    if (delta == 0) return;
    values[local] = value;
    final prefix = _prefixes[chunk];
    for (var at = local + 1; at < prefix.length; at++) {
      prefix[at] += delta;
    }
    for (var at = chunk + 1; at <= _chunks.length; at += at & -at) {
      _sumTree[at] += delta;
    }
  }

  /// Replaces the [removed] values from [first] on with [inserted].
  ///
  /// O(the values touched + the chunks): the chunks the edit falls in are
  /// rewritten, and the trees over the chunks rebuilt.
  void splice(int first, int removed, List<double> inserted) {
    assert(first >= 0 && first <= _length, 'first $first out of 0..$_length');
    assert(first + removed <= _length, 'removing past the end');
    if (removed == 0 && inserted.isEmpty) return;
    final (chunk, local) = first == _length
        ? (_chunks.length - 1, _chunks.last.length)
        : _locate(first);
    final firstChunk = chunk;
    var left = removed;
    var at = local;
    var lastChunk = chunk;
    while (left > 0) {
      final values = _chunks[lastChunk];
      final take = values.length - at < left ? values.length - at : left;
      values.removeRange(at, at + take);
      left -= take;
      if (left > 0) {
        lastChunk++;
        at = 0;
      }
    }
    _chunks[firstChunk].insertAll(local, inserted);
    // Every chunk the edit went through is recut, and the empty ones go.
    final touched = <double>[
      for (var c = firstChunk; c <= lastChunk; c++) ..._chunks[c],
    ];
    final recut = <List<double>>[];
    if (touched.length <= 2 * _chunkSize) {
      if (touched.isNotEmpty) recut.add(touched);
    } else {
      for (var from = 0; from < touched.length; from += _chunkSize) {
        final to = from + _chunkSize < touched.length
            ? from + _chunkSize
            : touched.length;
        recut.add(touched.sublist(from, to));
      }
    }
    _chunks.replaceRange(firstChunk, lastChunk + 1, recut);
    _prefixes.replaceRange(firstChunk, lastChunk + 1, recut.map(_prefixOf));
    if (_chunks.isEmpty) {
      _chunks.add(<double>[]);
      _prefixes.add(<double>[0]);
    }
    _length += inserted.length - removed;
    _rebuildTrees();
  }

  /// Which chunk value [index] is in, and where in it. O(log chunks).
  (int, int) _locate(int index) {
    var chunk = 0;
    var remaining = index;
    final count = _chunks.length;
    for (var power = _highestPower; power > 0; power >>= 1) {
      final next = chunk + power;
      if (next <= count && _sizeTree[next] <= remaining) {
        remaining -= _sizeTree[next];
        chunk = next;
      }
    }
    return (chunk, remaining);
  }

  /// The sum of the first [count] chunks.
  double _chunkPrefix(int count) {
    var sum = 0.0;
    for (var at = count; at > 0; at -= at & -at) {
      sum += _sumTree[at];
    }
    return sum;
  }

  static List<double> _prefixOf(List<double> values) {
    final prefix = List<double>.filled(values.length + 1, 0);
    var sum = 0.0;
    for (var at = 0; at < values.length; at++) {
      prefix[at] = sum;
      sum += values[at];
    }
    prefix[values.length] = sum;
    return prefix;
  }

  /// Rebuilds the trees over the chunks, O(chunks).
  void _rebuildTrees() {
    final count = _chunks.length;
    final sums = List<double>.filled(count + 1, 0);
    final sizes = List<int>.filled(count + 1, 0);
    for (var at = 1; at <= count; at++) {
      sums[at] += _prefixes[at - 1].last;
      sizes[at] += _chunks[at - 1].length;
      final parent = at + (at & -at);
      if (parent <= count) {
        sums[parent] += sums[at];
        sizes[parent] += sizes[at];
      }
    }
    _sumTree = sums;
    _sizeTree = sizes;
    var power = 1;
    while (power * 2 <= count) {
      power *= 2;
    }
    _highestPower = count == 0 ? 0 : power;
  }
}
