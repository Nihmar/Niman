/// A binary heap of integer keys with an integer attached (#530).
library;

/// Holds `(key, value)` pairs and gives the smallest key first, the
/// smaller value first among equal keys, so which one comes out never
/// depends on the order they went in.
final class LayeredMinHeap {
  final List<int> _keys = [];
  final List<int> _values = [];

  /// Whether nothing is in it.
  bool get isEmpty => _keys.isEmpty;

  /// The smallest key. The heap must not be empty.
  int get topKey => _keys[0];

  /// The value kept with the smallest key. The heap must not be empty.
  int get topValue => _values[0];

  /// Adds [value] under [key].
  void push(int key, int value) {
    var at = _keys.length;
    _keys.add(key);
    _values.add(value);
    while (at > 0) {
      final up = (at - 1) >> 1;
      if (!_before(key, value, _keys[up], _values[up])) break;
      _keys[at] = _keys[up];
      _values[at] = _values[up];
      at = up;
    }
    _keys[at] = key;
    _values[at] = value;
  }

  /// Takes the smallest pair out. The heap must not be empty.
  void pop() {
    final key = _keys.removeLast();
    final value = _values.removeLast();
    if (_keys.isEmpty) return;
    var at = 0;
    final last = _keys.length;
    while (true) {
      var child = 2 * at + 1;
      if (child >= last) break;
      if (child + 1 < last &&
          _before(
            _keys[child + 1],
            _values[child + 1],
            _keys[child],
            _values[child],
          )) {
        child++;
      }
      if (!_before(_keys[child], _values[child], key, value)) break;
      _keys[at] = _keys[child];
      _values[at] = _values[child];
      at = child;
    }
    _keys[at] = key;
    _values[at] = value;
  }

  static bool _before(int keyA, int valueA, int keyB, int valueB) =>
      keyA < keyB || (keyA == keyB && valueA < valueB);
}
