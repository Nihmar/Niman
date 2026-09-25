/// Prefix sums over a list of non-negative values, with insertion: offset ↔
/// index in O(log n), and an edit that adds or removes values in O(chunk).
///
/// Two callers ask the same two questions. The source buffer asks "which line
/// is this offset in, and where does line *i* start"; the height map
/// (`docs/records/unified-surface.md` §8.4.1) asks "which block is this pixel in,
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
/// integers well inside what a double holds exactly. They are kept in typed
/// lists, unboxed: a list of `double` holds each value as an object, and
/// building one over 2.76 M lines — the 246 MB note's height map and its
/// buffer's index, both on opening it — cost ~200 ms apiece in allocations.
///
/// Sums made [PrefixSums.lazy] do not know their values until they are asked
/// for them: a chunk stands at an estimate of its total until a question
/// reaches inside it. That is what a height map is on a note it has not drawn
/// yet — the sliver asks about the chunks around the viewport, and nothing
/// asks about the rest.
library;

import 'dart:typed_data';

import 'package:niman/src/markdown/chunk_tree.dart';

/// Chunked prefix sums over a list of non-negative values.
final class PrefixSums {
  /// Sums over [values], in O(values.length).
  new(List<double> values) : this.generate(values.length, (at) => values[at]);

  /// Sums over [count] values, value `at` being `valueOf(at)`, asked once
  /// each and in order: no list of them is built on the way.
  new generate(int count, double Function(int at) valueOf)
    : _valueOf = null,
      _tree = ChunkTree(const <int>[], const <double>[]) {
    for (var at = 0; at < count; at += _chunkSize) {
      final end = at + _chunkSize < count ? at + _chunkSize : count;
      final chunk = Float64List(end - at);
      for (var local = 0; local < chunk.length; local++) {
        chunk[local] = valueOf(at + local);
      }
      final prefix = _prefixOf(chunk);
      _chunks.add(chunk);
      _prefixes.add(prefix);
      _sizes.add(chunk.length);
      _totals.add(prefix.last);
    }
    _start(count);
  }

  /// Sums over [count] values that are worked out a chunk at a time, when a
  /// question first reaches inside the chunk: value `at` is `valueOf(at)`,
  /// asked once, with the index it has *then* — after whatever splices came
  /// before. Until a chunk is worked out it counts for `estimate(first,
  /// end)`, the sum of values `[first, end)` as best known without them.
  ///
  /// O(count / chunk size) to make, where [PrefixSums.generate] is
  /// O(count): what a height map over a note of millions of lines costs on
  /// the frame that opens it. An estimate that is off moves the offsets
  /// after the chunk when the chunk is worked out, as a measured height does.
  new lazy(
    int count,
    double Function(int at) valueOf, {
    required double Function(int first, int end) estimate,
  }) : _valueOf = valueOf,
       _tree = ChunkTree(const <int>[], const <double>[]) {
    for (var at = 0; at < count; at += _chunkSize) {
      final end = at + _chunkSize < count ? at + _chunkSize : count;
      _chunks.add(null);
      _prefixes.add(null);
      _sizes.add(end - at);
      _totals.add(estimate(at, end));
    }
    _start(count);
  }

  /// Sums holding what [other] holds now, apart from it: a write to either
  /// is not seen by the other. O(chunks): the chunks are shared until one
  /// side writes to one, and that side copies it first.
  ///
  /// What a snapshot of the source buffer takes instead of summing every
  /// line again (~200 ms of reading 2.76 M lines' lengths on a 246 MB note).
  new sharing(PrefixSums other)
    : _valueOf = other._valueOf,
      _tree = ChunkTree.copy(other._tree),
      _length = other._length {
    _chunks.addAll(other._chunks);
    _prefixes.addAll(other._prefixes);
    _sizes.addAll(other._sizes);
    _totals.addAll(other._totals);
    _owned.addAll(List<bool>.filled(other._owned.length, false));
    other._owned.fillRange(0, other._owned.length, false);
  }

  /// Every chunk this side's own, with no chunk left empty, and the trees.
  void _start(int count) {
    if (_chunks.isEmpty) {
      _chunks.add(Float64List(0));
      _prefixes.add(Float64List(1));
      _sizes.add(0);
      _totals.add(0);
    }
    _owned.addAll(List<bool>.filled(_chunks.length, true));
    _length = count;
    _tree.rebuild(_sizes, _totals);
  }

  /// Works a lazy chunk's values out; null for sums that know them all.
  final double Function(int at)? _valueOf;

  /// Whether chunk *c* may be written in place: false for one shared with a
  /// copy.
  final List<bool> _owned = <bool>[];

  /// How many values a chunk is cut to, and half of when it may grow before it
  /// is split again.
  static const int _chunkSize = 1024;

  /// The values, chunk by chunk; null for a lazy chunk not worked out yet.
  /// Never empty: an empty list is one empty chunk.
  final List<Float64List?> _chunks = <Float64List?>[];

  /// Each chunk's own prefix sums: `_prefixes[c][i]` is the sum of the first
  /// `i` values of chunk `c`, so it has one entry more than the chunk. Null
  /// where the chunk is.
  final List<Float64List?> _prefixes = <Float64List?>[];

  /// How many values each chunk holds, worked out or not.
  final List<int> _sizes = <int>[];

  /// Each chunk's total: its values', or its estimate while it has none.
  final List<double> _totals = <double>[];

  /// The trees over the chunks' totals and sizes.
  final ChunkTree _tree;

  int _length = 0;

  /// How many values there are.
  int get length => _length;

  /// The sum of every value.
  double get total => _tree.total;

  /// The sum of the values before [index]. [index] may be [length], which
  /// answers [total]. O(log chunks).
  double offsetOf(int index) {
    assert(index >= 0 && index <= _length, 'index $index out of 0..$_length');
    if (index >= _length) return total;
    final (chunk, local) = _tree.locate(index);
    final within = _prefixAt(chunk)[local];
    return _tree.totalBefore(chunk) + within;
  }

  /// Value [index].
  double valueAt(int index) {
    assert(index >= 0 && index < _length, 'index $index out of range');
    final (chunk, local) = _tree.locate(index);
    return _valuesAt(chunk)[local];
  }

  /// The largest index whose offset is at or before [offset]: the value that
  /// contains it, the one that starts there on a boundary.
  ///
  /// Offsets at or before the start answer 0, and offsets at or past [total]
  /// answer `length - 1`, so the result is always a valid index — the callers
  /// rely on it, since a buffer always has a line and a height map a block.
  int indexOf(double offset) {
    while (true) {
      if (_length == 0 || offset <= 0) return 0;
      if (offset >= total) return _length - 1;
      // The chunks that end at or before [offset], by binary lifting.
      final (chunk, before, remaining) = _tree.find(offset);
      if (chunk >= _chunks.length) return _length - 1;
      // A chunk that stood at an estimate is worked out, which moves every
      // offset after it: the descent is asked again of the sums as they are.
      if (_prefixes[chunk] == null) {
        _workOut(chunk);
        continue;
      }
      // Inside that chunk: the last local start at or before what is left.
      final prefix = _prefixes[chunk]!;
      var low = 0;
      var high = _sizes[chunk] - 1;
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
  }

  /// Sets value [index] to [value]. O(chunk + log chunks).
  void setValue(int index, double value) {
    assert(index >= 0 && index < _length, 'index $index out of range');
    assert(value >= 0, 'value $index would be negative: $value');
    final (chunk, local) = _tree.locate(index);
    if (_valuesAt(chunk)[local] == value) return;
    if (!_owned[chunk]) {
      _chunks[chunk] = Float64List.fromList(_chunks[chunk]!);
      _prefixes[chunk] = Float64List.fromList(_prefixes[chunk]!);
      _owned[chunk] = true;
    }
    final values = _chunks[chunk]!;
    final delta = value - values[local];
    values[local] = value;
    final prefix = _prefixes[chunk]!;
    for (var at = local + 1; at < prefix.length; at++) {
      prefix[at] += delta;
    }
    _totals[chunk] += delta;
    _tree.add(chunk, delta);
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
        ? (_chunks.length - 1, _sizes.last)
        : _tree.locate(first);
    final firstChunk = chunk;
    // Where the removal ends: the chunk, and the place in it. Nothing is
    // written in place, because a copy may share these chunks.
    var left = removed;
    var lastChunk = chunk;
    var end = local;
    while (left > _sizes[lastChunk] - end) {
      left -= _sizes[lastChunk] - end;
      lastChunk++;
      end = 0;
    }
    end += left;
    // Every chunk the edit went through is recut, and the empty ones go.
    // Only the two it starts and ends in keep values, so only those two are
    // worked out — asked with the indices they have *after* the edit, which
    // the note they are read from already holds: the values past it moved
    // by what it inserted less what it removed.
    final touched = <double>[
      ..._kept(firstChunk, 0, local, 0),
      ...inserted,
      ..._kept(lastChunk, end, _sizes[lastChunk], inserted.length - removed),
    ];
    final recut = <Float64List>[];
    if (touched.length <= 2 * _chunkSize) {
      if (touched.isNotEmpty) recut.add(Float64List.fromList(touched));
    } else {
      for (var from = 0; from < touched.length; from += _chunkSize) {
        final to = from + _chunkSize < touched.length
            ? from + _chunkSize
            : touched.length;
        recut.add(Float64List.fromList(touched.sublist(from, to)));
      }
    }
    final prefixes = <Float64List>[
      for (final values in recut) _prefixOf(values),
    ];
    _chunks.replaceRange(firstChunk, lastChunk + 1, recut);
    _prefixes.replaceRange(firstChunk, lastChunk + 1, prefixes);
    _sizes.replaceRange(firstChunk, lastChunk + 1, [
      for (final values in recut) values.length,
    ]);
    _totals.replaceRange(firstChunk, lastChunk + 1, [
      for (final prefix in prefixes) prefix.last,
    ]);
    _owned.replaceRange(
      firstChunk,
      lastChunk + 1,
      List<bool>.filled(recut.length, true),
    );
    if (_chunks.isEmpty) {
      _chunks.add(Float64List(0));
      _prefixes.add(Float64List(1));
      _sizes.add(0);
      _totals.add(0);
      _owned.add(true);
    }
    _length += inserted.length - removed;
    _tree.rebuild(_sizes, _totals);
  }

  /// Values `[from, to)` of chunk [chunk], a splice keeps: the chunk's own
  /// when it has them, and otherwise asked for at their index [shift] on,
  /// where the splice moves them.
  List<double> _kept(int chunk, int from, int to, int shift) {
    final values = _chunks[chunk];
    if (values != null) return values.sublist(from, to);
    final valueOf = _valueOf!;
    final start = _tree.sizeBefore(chunk) + shift;
    return <double>[for (var at = from; at < to; at++) valueOf(start + at)];
  }

  /// Chunk [chunk]'s values, worked out first when it has none yet.
  Float64List _valuesAt(int chunk) {
    if (_chunks[chunk] == null) _workOut(chunk);
    return _chunks[chunk]!;
  }

  /// Chunk [chunk]'s prefix sums, worked out first when it has none yet.
  Float64List _prefixAt(int chunk) {
    if (_prefixes[chunk] == null) _workOut(chunk);
    return _prefixes[chunk]!;
  }

  /// Asks for lazy chunk [chunk]'s values, and puts its total where its
  /// estimate was.
  void _workOut(int chunk) {
    final valueOf = _valueOf!;
    final first = _tree.sizeBefore(chunk);
    final values = Float64List(_sizes[chunk]);
    for (var local = 0; local < values.length; local++) {
      values[local] = valueOf(first + local);
    }
    final prefix = _prefixOf(values);
    _chunks[chunk] = values;
    _prefixes[chunk] = prefix;
    _owned[chunk] = true;
    final delta = prefix.last - _totals[chunk];
    _totals[chunk] = prefix.last;
    _tree.add(chunk, delta);
  }

  static Float64List _prefixOf(Float64List values) {
    final prefix = Float64List(values.length + 1);
    var sum = 0.0;
    for (var at = 0; at < values.length; at++) {
      prefix[at] = sum;
      sum += values[at];
    }
    prefix[values.length] = sum;
    return prefix;
  }
}
