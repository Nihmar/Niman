/// A note's blocks, kept in chunks that a copy shares, each chunk with the
/// lines it has moved by.
///
/// The block scanner's list, and the one it hands out: two costs of a flat
/// list were a note's length where they should have been an edit's
/// (`docs/records/huge-notes.md`), on the 246 MB note of 2 M blocks:
///
/// * **A copy.** The read pane takes the editor's blocks when it opens, and
///   the list was copied whole: 13–50 ms.
/// * **A move.** An Enter moves every block after it down a line. The
///   scanner owed that move rather than making it, but a reader that wanted
///   the whole list paid it: 50–110 ms on the frame that opened the pane
///   after an Enter in the middle of the note.
///
/// So the blocks live in chunks of about [BlockList.chunkSize], and each
/// chunk carries a shift: the lines every block in it has moved since it was
/// stored. Moving everything past an index adds to the shifts of the chunks
/// after it and moves the blocks of one chunk — O(chunks + chunk), about
/// 3 000 steps for 2 M blocks. A copy takes the chunks and their shifts, and
/// the two share every chunk until one writes to it, which copies that one
/// first (the scheme `LineStore` uses for a note's lines).
///
/// To everyone else it is a `List<Block>` that cannot be changed: a block
/// read is its stored one moved by its chunk's shift.
library;

import 'dart:collection';

import 'package:niman/src/markdown/block.dart';

/// Chunked blocks with per-chunk shifts, shared by copies until written.
final class BlockList with ListMixin<Block> implements List<Block> {
  /// Holds [blocks].
  new([List<Block> blocks = const <Block>[]]) {
    for (var at = 0; at < blocks.length; at += chunkSize) {
      final end = at + chunkSize < blocks.length
          ? at + chunkSize
          : blocks.length;
      _chunks.add(List<Block>.of(blocks.getRange(at, end)));
      _shifts.add(0);
      _owned.add(true);
    }
    _restart();
  }

  /// A list holding what [other] holds now, apart from it: a write to either
  /// is not seen by the other. O(chunks).
  new sharing(BlockList other) : _length = other._length {
    _chunks.addAll(other._chunks);
    _shifts.addAll(other._shifts);
    _starts = List<int>.of(other._starts);
    _owned.addAll(List<bool>.filled(other._owned.length, false));
    other._owned.fillRange(0, other._owned.length, false);
  }

  /// How many blocks a chunk is cut to, and half of what it may grow to
  /// before it is cut again.
  static const int chunkSize = 1024;

  final List<List<Block>> _chunks = <List<Block>>[];

  /// The lines each chunk's blocks have moved since they were stored.
  final List<int> _shifts = <int>[];

  /// Whether this list may write to chunk *c* in place: false for a chunk it
  /// shares with a copy.
  final List<bool> _owned = <bool>[];

  /// Where each chunk starts, and the length after the last.
  List<int> _starts = <int>[0];

  /// The chunk the last read landed in.
  int _cursor = 0;

  int _length = 0;

  @override
  int get length => _length;

  @override
  Block operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    final chunk = _chunkOf(index);
    return _chunks[chunk][index - _starts[chunk]].shifted(_shifts[chunk]);
  }

  /// The blocks [test] accepts, where they are, in order.
  ///
  /// [test] is asked of each block as it is stored, so it may read only
  /// what a move does not change — its kind, its depths, its line count —
  /// and only the blocks it accepts are moved: a reader after the headings
  /// of 2 M blocks makes a block per heading, not one per block.
  Iterable<Block> matching(bool Function(Block block) test) sync* {
    for (var chunk = 0; chunk < _chunks.length; chunk++) {
      final shift = _shifts[chunk];
      for (final block in _chunks[chunk]) {
        if (test(block)) yield block.shifted(shift);
      }
    }
  }

  // Changed only through [shiftFrom] and [splice]: a reader holds a copy, and
  // a copy that could be written as a list would be a second way in.
  @override
  void operator []=(int index, Block value) =>
      throw UnsupportedError('A block list is changed by splice');

  @override
  set length(int newLength) =>
      throw UnsupportedError('A block list is changed by splice');

  /// Moves every block from [index] on [delta] lines down (up, when
  /// negative). O(chunks + chunk).
  void shiftFrom(int index, int delta) {
    if (delta == 0 || index >= _length) return;
    var chunk = _chunkOf(index);
    final local = index - _starts[chunk];
    if (local > 0) {
      // The chunk the index falls inside: its blocks from there on move, the
      // ones before stay where its shift already puts them.
      _own(chunk);
      final blocks = _chunks[chunk];
      for (var at = local; at < blocks.length; at++) {
        blocks[at] = blocks[at].shifted(delta);
      }
      chunk++;
    }
    for (; chunk < _chunks.length; chunk++) {
      _shifts[chunk] += delta;
    }
  }

  /// Replaces the blocks `[start, end)` with [blocks], which are where they
  /// are now. O(the blocks written + the chunks).
  void splice(int start, int end, List<Block> blocks) {
    RangeError.checkValidRange(start, end, _length);
    if (start == end && blocks.isEmpty) return;
    final first = start == _length ? _chunks.length - 1 : _chunkOf(start);
    final last = end == start
        ? first
        : end == _length
        ? _chunks.length - 1
        : _chunkOf(end - 1);
    final from = start - _starts[first];
    final to = end - _starts[last];
    final firstShift = _shifts[first];
    final lastShift = _shifts[last];
    // The chunks the splice runs through are written anew, with no shift of
    // their own: the blocks kept from them are moved to where they are.
    final touched = <Block>[
      for (final block in _chunks[first].take(from)) block.shifted(firstShift),
      ...blocks,
      for (final block in _chunks[last].skip(to)) block.shifted(lastShift),
    ];
    final cut = <List<Block>>[];
    if (touched.length <= 2 * chunkSize) {
      if (touched.isNotEmpty) cut.add(touched);
    } else {
      for (var at = 0; at < touched.length; at += chunkSize) {
        final stop = at + chunkSize < touched.length
            ? at + chunkSize
            : touched.length;
        cut.add(touched.sublist(at, stop));
      }
    }
    _chunks.replaceRange(first, last + 1, cut);
    _shifts.replaceRange(first, last + 1, List<int>.filled(cut.length, 0));
    _owned.replaceRange(first, last + 1, List<bool>.filled(cut.length, true));
    _restart();
  }

  /// Makes chunk [chunk] this list's own, copying it if a copy shares it.
  void _own(int chunk) {
    if (_owned[chunk]) return;
    _chunks[chunk] = List<Block>.of(_chunks[chunk]);
    _owned[chunk] = true;
  }

  /// The chunk block [index] is in: the last read's, or its neighbour's —
  /// a walk down the list — or found by the chunk starts.
  int _chunkOf(int index) {
    final chunk = _cursor;
    if (index >= _starts[chunk]) {
      if (index < _starts[chunk + 1]) return chunk;
      if (chunk + 2 < _starts.length && index < _starts[chunk + 2]) {
        return _cursor = chunk + 1;
      }
    }
    var low = 0;
    var high = _chunks.length - 1;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_starts[middle] <= index) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return _cursor = low;
  }

  /// Recomputes the chunk starts after the chunks changed, O(chunks).
  void _restart() {
    if (_chunks.isEmpty) {
      _chunks.add(<Block>[]);
      _shifts.add(0);
      _owned.add(true);
    }
    final starts = List<int>.filled(_chunks.length + 1, 0);
    for (var at = 0; at < _chunks.length; at++) {
      starts[at + 1] = starts[at] + _chunks[at].length;
    }
    _starts = starts;
    _length = starts.last;
    _cursor = 0;
  }
}
