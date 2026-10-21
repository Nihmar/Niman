/// The delta between two versions of a note, as the history stores an older
/// version against the one after it (#1148).
///
/// A delta is a list of instructions that rebuilds the target from the
/// base: copy a run of the base's bytes, or insert bytes of the target's
/// own. It is found a line at a time, the way a note changes — an edit
/// session leaves most lines where they were — and each match is then
/// extended a byte at a time, across lines, as far as the two agree. Linear
/// in the two lengths; the format is the store's own and is read only by
/// [applyDelta].
library;

import 'dart:typed_data';

/// The shortest copy worth an instruction: below it, the copy's offset and
/// length cost about what the bytes do.
const int _minCopy = 16;

const int _copy = 1;
const int _insert = 2;

/// The instructions that rebuild [target] from [base].
Uint8List computeDelta(Uint8List base, Uint8List target) {
  final index = _lineIndex(base);
  final out = _Writer()
    ..varint(base.length)
    ..varint(target.length);
  var pendingFrom = 0;
  var at = 0;
  // Where the last copy ended in the base: the next line is most likely the
  // base's next one too, and that is tried before the index.
  var follow = -1;

  void flushInsert(int until) {
    if (until <= pendingFrom) return;
    out
      ..byte(_insert)
      ..varint(until - pendingFrom)
      ..bytes(target, pendingFrom, until);
  }

  while (at < target.length) {
    final end = _lineEnd(target, at);
    var from = -1;
    if (follow >= 0 && _same(base, follow, target, at, end - at)) {
      from = follow;
    } else {
      final candidate = index[_hash(target, at, end)];
      if (candidate != null && _same(base, candidate, target, at, end - at)) {
        from = candidate;
      }
    }
    if (from < 0) {
      follow = -1;
      at = end;
      continue;
    }
    var length = end - at;
    while (at + length < target.length &&
        from + length < base.length &&
        target[at + length] == base[from + length]) {
      length++;
    }
    if (length < _minCopy) {
      follow = -1;
      at = end;
      continue;
    }
    flushInsert(at);
    out
      ..byte(_copy)
      ..varint(from)
      ..varint(length);
    at += length;
    pendingFrom = at;
    follow = from + length;
  }
  flushInsert(target.length);
  return out.take();
}

/// Rebuilds the target [computeDelta] described from [base].
///
/// Throws a [FormatException] when [delta] is not one, or was made against
/// another base: a damaged object never reads as content.
Uint8List applyDelta(Uint8List base, Uint8List delta) {
  final read = _Reader(delta);
  final baseLength = read.varint();
  if (baseLength != base.length) {
    throw const FormatException('delta made against another base');
  }
  final out = Uint8List(read.varint());
  var at = 0;
  while (!read.done) {
    final op = read.byte();
    final int length;
    if (op == _copy) {
      final from = read.varint();
      length = read.varint();
      if (from + length > base.length || at + length > out.length) {
        throw const FormatException('copy out of range');
      }
      out.setRange(at, at + length, base, from);
    } else if (op == _insert) {
      length = read.varint();
      if (at + length > out.length) {
        throw const FormatException('insert out of range');
      }
      read.into(out, at, length);
    } else {
      throw FormatException('unknown delta instruction $op');
    }
    at += length;
  }
  if (at != out.length) throw const FormatException('delta ends short');
  return out;
}

/// Each line of [bytes] by its hash, at its first offset.
Map<int, int> _lineIndex(Uint8List bytes) {
  final index = <int, int>{};
  var at = 0;
  while (at < bytes.length) {
    final end = _lineEnd(bytes, at);
    index.putIfAbsent(_hash(bytes, at, end), () => at);
    at = end;
  }
  return index;
}

/// The end of the line starting at [at]: past its `\n`, or the end.
int _lineEnd(Uint8List bytes, int at) {
  var i = at;
  while (i < bytes.length && bytes[i] != 0x0A) {
    i++;
  }
  return i < bytes.length ? i + 1 : i;
}

/// FNV-1a over `bytes[from, to)`, kept to 32 bits.
int _hash(Uint8List bytes, int from, int to) {
  var hash = 0x811C9DC5;
  for (var i = from; i < to; i++) {
    hash = ((hash ^ bytes[i]) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

bool _same(Uint8List base, int from, Uint8List target, int at, int length) {
  if (from + length > base.length) return false;
  for (var i = 0; i < length; i++) {
    if (base[from + i] != target[at + i]) return false;
  }
  return true;
}

final class _Writer {
  final BytesBuilder _out = BytesBuilder(copy: false);
  final Uint8List _scratch = Uint8List(10);

  void byte(int value) => _out.addByte(value);

  void varint(int value) {
    var v = value;
    var n = 0;
    while (v >= 0x80) {
      _scratch[n++] = (v & 0x7F) | 0x80;
      v >>= 7;
    }
    _scratch[n++] = v;
    _out.add(Uint8List.fromList(_scratch.sublist(0, n)));
  }

  void bytes(Uint8List source, int from, int to) =>
      _out.add(Uint8List.sublistView(source, from, to));

  Uint8List take() => _out.takeBytes();
}

final class _Reader {
  new(this._bytes);

  final Uint8List _bytes;
  int _at = 0;

  bool get done => _at >= _bytes.length;

  int byte() {
    if (_at >= _bytes.length) throw const FormatException('delta truncated');
    return _bytes[_at++];
  }

  int varint() {
    var value = 0;
    var shift = 0;
    while (true) {
      final b = byte();
      value |= (b & 0x7F) << shift;
      if (b < 0x80) return value;
      shift += 7;
      if (shift > 56) throw const FormatException('varint too long');
    }
  }

  void into(Uint8List out, int at, int length) {
    if (_at + length > _bytes.length) {
      throw const FormatException('delta truncated');
    }
    out.setRange(at, at + length, _bytes, _at);
    _at += length;
  }
}
