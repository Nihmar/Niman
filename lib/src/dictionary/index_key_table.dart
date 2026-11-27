import 'dart:convert';
import 'dart:typed_data';

import 'package:niman/src/dictionary/byte_sink.dart';
import 'package:niman/src/dictionary/unicode_nfc.dart';

/// The keys an index is built from, held until they are sorted: every
/// `.idx` headword and every `.syn` form, in NFC, with the value each
/// carries.
///
/// The keys are bytes in one buffer, so a million of them are a few tens of
/// megabytes and not a million objects. Sorting them is a sort of integers:
/// each key is reduced to its first bytes and its position, and only the
/// keys that still tie are compared whole.
final class IndexKeyTable {
  /// An empty table.
  new() : _starts = Uint32List(1 << 16), _values = Uint32List(1 << 16);

  final ByteSink _blob = ByteSink(1 << 20);
  Uint32List _starts;
  Uint32List _values;
  int _count = 0;

  /// How many keys were added.
  int get length => _count;

  /// The key bytes, back to back: key `i` is `bytes[keyStart(i), keyEnd(i))`.
  Uint8List get bytes => _blob.view;

  /// Where key [i] starts in [bytes].
  int keyStart(int i) => _starts[i];

  /// Where key [i] ends in [bytes].
  int keyEnd(int i) => i + 1 < _count ? _starts[i + 1] : _blob.length;

  /// The value key [i] was added with.
  int valueOf(int i) => _values[i];

  /// Adds `source[start, end)` as a key carrying [value], composed to NFC.
  /// An empty key is left out: nothing is looked up by it.
  void add(Uint8List source, int start, int end, int value) {
    if (end <= start) return;
    if (_count == _starts.length) {
      _starts = Uint32List(_count * 2)..setRange(0, _count, _starts);
      _values = Uint32List(_count * 2)..setRange(0, _count, _values);
    }
    _starts[_count] = _blob.length;
    _values[_count] = value;
    _count++;
    if (_isPlain(source, start, end)) {
      _blob.addRange(source, start, end);
      return;
    }
    final text = utf8.decode(
      Uint8List.sublistView(source, start, end),
      allowMalformed: true,
    );
    final composed = utf8.encode(UnicodeNfc.compose(text));
    _blob.addRange(Uint8List.fromList(composed), 0, composed.length);
  }

  /// Whether the bytes hold no combining mark: they start at U+0300, whose
  /// UTF-8 begins with 0xCC, so a key under it needs no composing, and
  /// nearly every key is.
  static bool _isPlain(Uint8List source, int start, int end) {
    for (var i = start; i < end; i++) {
      if (source[i] >= 0xCC) return false;
    }
    return true;
  }

  /// The keys' numbers in byte order, equal keys in the order of their
  /// values (the headwords of the `.idx` before the forms of the `.syn`).
  Uint32List sortedOrder() {
    final count = _count;
    final order = Uint32List(count);
    if (count == 0) return order;
    final indexBits = count.bitLength;
    final prefixBytes = (62 - indexBits) ~/ 8;
    final data = bytes;
    final packed = Int64List(count);
    for (var i = 0; i < count; i++) {
      final start = _starts[i];
      final end = keyEnd(i);
      var prefix = 0;
      for (var b = 0; b < prefixBytes; b++) {
        prefix = (prefix << 8) | (start + b < end ? data[start + b] : 0);
      }
      packed[i] = (prefix << indexBits) | i;
    }
    packed.sort();
    final mask = (1 << indexBits) - 1;
    for (var i = 0; i < count; i++) {
      order[i] = packed[i] & mask;
    }
    var runStart = 0;
    for (var i = 1; i <= count; i++) {
      if (i < count &&
          packed[i] >> indexBits == packed[runStart] >> indexBits) {
        continue;
      }
      if (i - runStart > 1) _sortRun(order, runStart, i, data);
      runStart = i;
    }
    return order;
  }

  /// Sorts `order[from, to)`, the keys that share their first bytes.
  void _sortRun(Uint32List order, int from, int to, Uint8List data) {
    final run = order.sublist(from, to).toList()
      ..sort((a, b) {
        final byKey = _compare(data, a, b);
        return byKey != 0 ? byKey : _values[a] - _values[b];
      });
    for (var i = 0; i < run.length; i++) {
      order[from + i] = run[i];
    }
  }

  int _compare(Uint8List data, int a, int b) {
    final aEnd = keyEnd(a);
    final bEnd = keyEnd(b);
    var i = _starts[a];
    var j = _starts[b];
    while (i < aEnd && j < bEnd) {
      final difference = data[i++] - data[j++];
      if (difference != 0) return difference;
    }
    return (aEnd - i) - (bEnd - j);
  }
}
