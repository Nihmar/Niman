import 'dart:typed_data';

/// A growing run of bytes, written without a list or an allocation per
/// item: the index build writes tens of millions of small values, and a
/// `BytesBuilder` would take a chunk for each.
final class ByteSink {
  /// An empty sink, with room for [capacity] bytes before it grows.
  new([int capacity = 1 << 16]) : _bytes = Uint8List(capacity);

  Uint8List _bytes;
  int _length = 0;

  /// How many bytes were written.
  int get length => _length;

  /// The bytes written, without a copy: valid until the sink is written to.
  Uint8List get view => Uint8List.sublistView(_bytes, 0, _length);

  void _reserve(int more) {
    if (_length + more <= _bytes.length) return;
    var capacity = _bytes.length * 2;
    while (capacity < _length + more) {
      capacity *= 2;
    }
    _bytes = Uint8List(capacity)..setRange(0, _length, _bytes);
  }

  /// Writes the byte [value].
  void addByte(int value) {
    _reserve(1);
    _bytes[_length++] = value;
  }

  /// Writes [value] as a little-endian 32-bit number.
  void addUint32(int value) {
    _reserve(4);
    _bytes[_length++] = value & 0xFF;
    _bytes[_length++] = (value >> 8) & 0xFF;
    _bytes[_length++] = (value >> 16) & 0xFF;
    _bytes[_length++] = (value >> 24) & 0xFF;
  }

  /// Writes [value] (not negative) in seven-bit groups, low first, the
  /// high bit of a byte saying another follows.
  void addVarint(int value) {
    var rest = value;
    while (rest >= 0x80) {
      addByte((rest & 0x7F) | 0x80);
      rest >>= 7;
    }
    addByte(rest);
  }

  /// Writes `source[start, end)`.
  void addRange(Uint8List source, int start, int end) {
    _reserve(end - start);
    _bytes.setRange(_length, _length + end - start, source, start);
    _length += end - start;
  }
}
