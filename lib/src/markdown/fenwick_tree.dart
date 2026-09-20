/// A Fenwick tree over non-negative spans: offset ↔ index in O(log n).
///
/// Two callers depend on the same two questions, which is why this is a type of
/// its own rather than a private detail of either. The source buffer asks
/// "which
/// line is this offset in, and where does line *i* start"; the height map
/// (`docs/dev/unified-surface.md` §8.4.1) asks "which block is this pixel in,
/// and where does block *i* start". Both are the same arithmetic over
/// variable-length spans.
///
/// A content edit resizes one span, which is `setSpan` and O(log n). An edit
/// that changes *how many* spans there are — a newline, a paste, a line joined
/// — moves every index after it, which no array-shaped structure can avoid;
/// that is `reset`, O(n) in a flat loop with a small constant, and it is the
/// rare case (Enter, paste) rather than the common one (typing in a line).
library;

/// A Fenwick (binary indexed) tree over a list of non-negative spans.
final class FenwickTree {
  /// Creates a tree over [length] zero spans.
  new(int length)
    : _length = length,
      _tree = List<int>.filled(length + 1, 0, growable: true) {
    _highestPower = _powerAtMost(length);
  }

  /// Creates a tree over [spans], in O(spans.length).
  factory fromSpans(List<int> spans) => FenwickTree(spans.length)..reset(spans);

  /// The tree, 1-indexed; node `i` sums the range ending at `i`.
  final List<int> _tree;

  /// How many spans the tree covers.
  int _length;

  /// The largest power of two at or below [_length], for [indexOf]'s walk.
  late int _highestPower;

  /// How many spans the tree covers.
  int get length => _length;

  /// The sum of every span.
  int get total => _prefix(_length);

  /// The sum of spans `[0, end)`. O(log n).
  int _prefix(int end) {
    var sum = 0;
    for (var i = end; i > 0; i -= i & -i) {
      sum += _tree[i];
    }
    return sum;
  }

  /// The offset at which span [index] starts: the sum of the spans before it.
  ///
  /// O(log n). [index] may be [length], which answers [total].
  int offsetOf(int index) {
    assert(index >= 0 && index <= _length, 'index $index out of 0..$_length');
    return _prefix(index);
  }

  /// The size of span [index], as the difference of two prefix sums rather than
  /// a second array. O(log n).
  int spanAt(int index) {
    assert(index >= 0 && index < _length, 'index $index out of range');
    return _prefix(index + 1) - _prefix(index);
  }

  /// The index of the span containing [offset].
  ///
  /// The inverse of [offsetOf] in the only sense that is well defined when
  /// spans may be zero-length: the largest `i` with `offsetOf(i) <= offset`.
  /// Offsets at or before the start answer 0 — the start belongs to the first
  /// span by definition, even if that span is empty — and offsets at or past
  /// [total] answer `length - 1`, so the result is always a valid index, which
  /// the callers can rely on because a buffer always has at least one line and
  /// a height map at least one block.
  ///
  /// O(log n), by binary lifting rather than by a binary search over
  /// [offsetOf], because each [offsetOf] is itself O(log n).
  int indexOf(int offset) {
    if (_length == 0) return 0;
    if (offset <= 0) return 0;
    if (offset >= total) return _length - 1;
    var index = 0;
    var remaining = offset;
    for (var power = _highestPower; power > 0; power >>= 1) {
      final next = index + power;
      if (next <= _length && _tree[next] <= remaining) {
        remaining -= _tree[next];
        index = next;
      }
    }
    return index < _length ? index : _length - 1;
  }

  /// Resizes span [index] to [span]. O(log n).
  void setSpan(int index, int span) {
    assert(index >= 0 && index < _length, 'index $index out of range');
    final delta = span - spanAt(index);
    if (delta == 0) return;
    assert(span >= 0, 'span $index would go negative');
    for (var i = index + 1; i <= _length; i += i & -i) {
      _tree[i] += delta;
    }
  }

  /// Rebuilds the tree over the first `spans.length` spans. O(n).
  ///
  /// The spans must be non-negative: [indexOf]'s walk assumes it, since a
  /// negative span could make `offsetOf` decrease and the search
  /// non-monotonic.
  void reset(List<int> spans) {
    final length = spans.length;
    if (length != _length) {
      _length = length;
      _highestPower = _powerAtMost(length);
    }
    if (_tree.length < length + 1) {
      _tree.addAll(List<int>.filled(length + 1 - _tree.length, 0));
    }
    _tree.fillRange(0, _length + 1, 0);
    for (var i = 1; i <= _length; i++) {
      final span = spans[i - 1];
      assert(span >= 0, 'span ${i - 1} is negative: $span');
      _tree[i] += span;
      final parent = i + (i & -i);
      if (parent <= _length) _tree[parent] += _tree[i];
    }
  }
}

/// The largest power of two at or below [value], or 0 for a non-positive one.
int _powerAtMost(int value) {
  var power = 0;
  while ((1 << (power + 1)) <= value) {
    power++;
  }
  return power == 0 ? 0 : 1 << power;
}
