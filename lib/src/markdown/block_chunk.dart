/// A run of a note's blocks, packed into typed arrays (#1196).
///
/// A [Block] has fifteen fields and almost every block of a note leaves most
/// of them at zero or null: stored as objects, a block held 98 B, 93 MB for a
/// million-line note and ~270 MB for the 2.76 M-line stress note
/// (`docs/records/memory-usage.md`). A chunk stores what every block has
/// in columns and what a few blocks have on the side, and makes a [Block]
/// only when one is read — the way the height map stores its heights.
///
/// Per block, in the columns: four 32-bit ints (first line, one past the last,
/// list ordinal, reach), one 32-bit word of small fields, and a pointer to
/// the state entering its first line — a state the scanner shares among all
/// the lines that have the same one. A block with a fence info string, or
/// with a field too large for its bits, has an *extra* beside the columns,
/// found by binary search on its index.
///
/// A chunk is immutable but for the lines its blocks cover, which
/// `shiftFrom` moves. A `BlockList` shares chunks among its copies and
/// makes one its own (`toOwn`) before it moves lines in it.
library;

import 'dart:typed_data';

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/line_state.dart';

/// The fields a block has too large for their bits in the word, for the
/// few blocks that have any: all of them, whole, in place of the word's.
typedef _Wide = ({
  int quoteDepth,
  int listDepth,
  int listOrdinal,
  int headingLevel,
  int footnote,
  int definition,
  int reach,
  int divDepth,
});

/// What a block has beside the columns: a fence info string, or a [_Wide] in
/// place of the word's fields.
///
/// Equal extras are one object within a chunk: the fences of a note that
/// quotes a language carry the same few strings.
typedef _Extra = ({String? fenceInfo, _Wide? wide});

/// Blocks packed into typed arrays, read back as [Block]s.
final class BlockChunk {
  /// Packs `blocks[start, end)` — all of [blocks] by default — with the
  /// lines they have now.
  ///
  /// A line number must fit 32 bits: no note has two billion lines.
  new of(List<Block> blocks, [int start = 0, int? end])
    : this._pack(blocks, start, end ?? blocks.length);

  new _pack(List<Block> blocks, int start, int end)
    : assert(
        // A kind or a role past the bits they have would be read back as
        // another: adding one is a change to the layout, not to an enum.
        BlockKind.values.length <= 16 && DivRole.values.length <= 7,
        'BlockChunk: the kind or the div role does not fit its bits',
      ),
      length = end - start,
      _lines = Int32List((end - start) * _stride),
      _bits = Uint32List(end - start),
      _entering = List<LineState?>.filled(end - start, null) {
    final extraAt = <int>[];
    final extras = <_Extra>[];
    final shared = <_Extra, _Extra>{};
    _Extra? last;
    var divs = 0;
    var quotes = 0;
    for (var local = 0; local < length; local++) {
      final block = blocks[start + local];
      final fits = _fits(block);
      _Extra? extra;
      if (!fits || block.fenceInfo != null) {
        // The same string and nothing wide as the extra just made (a wide one
        // belongs to its own block only): the run of fences of one language,
        // which is most of them, is not hashed.
        if (fits &&
            last != null &&
            last.wide == null &&
            last.fenceInfo == block.fenceInfo) {
          extra = last;
        } else {
          final made = (
            fenceInfo: block.fenceInfo,
            wide: fits
                ? null
                : (
                    quoteDepth: block.quoteDepth,
                    listDepth: block.listDepth,
                    listOrdinal: block.listOrdinal,
                    headingLevel: block.headingLevel,
                    footnote: block.footnote,
                    definition: block.definition,
                    reach: block.reach,
                    divDepth: block.divDepth,
                  ),
          );
          extra = last = shared.putIfAbsent(made, () => made);
        }
        extraAt.add(local);
        extras.add(extra);
      }
      final at = local * _stride;
      _lines[at] = block.startLine;
      _lines[at + 1] = block.endLine;
      var word =
          block.kind.index |
          (block.holdsFence ? _fenceBit : 0) |
          ((block.divRole?.index ?? -1) + 1) << _roleShift |
          (extra == null ? 0 : _extraBit);
      if (fits) {
        _lines[at + 2] = block.listOrdinal;
        _lines[at + 3] = block.reach;
        word |=
            block.headingLevel << _headingShift |
            block.footnote << _footnoteShift |
            block.definition << _definitionShift |
            block.quoteDepth << _quoteShift |
            (block.listDepth + 1) << _listShift |
            block.divDepth << _divShift;
      }
      _bits[local] = word;
      _entering[local] = block.entering;
      if (block.kind == BlockKind.div) divs++;
      if (block.kind == BlockKind.quote && block.holdsFence) quotes++;
    }
    _extraAt = extras.isEmpty ? _none : Int32List.fromList(extraAt);
    _extras = extras.isEmpty
        ? const <_Extra>[]
        : extras.toList(growable: false);
    divCount = divs;
    fenceQuoteCount = quotes;
  }

  new _copyOf(BlockChunk other)
    : length = other.length,
      _lines = Int32List.fromList(other._lines),
      _bits = other._bits,
      _entering = other._entering,
      _extraAt = other._extraAt,
      _extras = other._extras,
      divCount = other.divCount,
      fenceQuoteCount = other.fenceQuoteCount;

  /// Ints per block in [_lines]: first line, end line, list ordinal, reach.
  static const int _stride = 4;

  // The word of small fields, from the lowest bit: kind (4), heading level
  // (3), footnote (2), definition (2), holds a fence (1), div role (3: none,
  // or the role's index + 1), has an extra (1), quote depth (6), list depth
  // + 1 (7, so that -1 is 0), div depth (3). A note's depths are far below
  // what they hold, and the div depth is what every block of a column has:
  // in an extra it made the blocks of a note's columns a fifth larger and
  // their scan a third slower (#1196).
  static const int _headingShift = 4;
  static const int _footnoteShift = 7;
  static const int _definitionShift = 9;
  static const int _fenceBit = 1 << 11;
  static const int _roleShift = 12;
  static const int _extraBit = 1 << 15;
  static const int _quoteShift = 16;
  static const int _quoteMask = 63;
  static const int _listShift = 22;
  static const int _listMask = 127;
  static const int _divShift = 29;

  static final Int32List _none = Int32List(0);
  static const List<BlockKind> _kinds = BlockKind.values;
  static const List<DivRole> _roles = DivRole.values;

  static bool _fits32(int value) => value >= -0x80000000 && value <= 0x7fffffff;

  /// Whether every field of [block] that has a width fits it.
  static bool _fits(Block block) =>
      block.quoteDepth >= 0 &&
      block.quoteDepth <= _quoteMask &&
      block.listDepth >= -1 &&
      block.listDepth <= _listMask - 1 &&
      block.headingLevel >= 0 &&
      block.headingLevel <= 7 &&
      block.footnote >= 0 &&
      block.footnote <= 3 &&
      block.definition >= 0 &&
      block.definition <= 3 &&
      block.divDepth >= 0 &&
      block.divDepth <= 7 &&
      _fits32(block.listOrdinal) &&
      _fits32(block.reach);

  /// How many blocks it holds.
  final int length;

  /// Per block, [_stride] ints: first line, end line, list ordinal, reach.
  final Int32List _lines;

  /// Per block, its small fields in one word.
  final Uint32List _bits;

  /// Per block, the state entering its first line, or null.
  final List<LineState?> _entering;

  /// The indices of the blocks that have an extra, ascending.
  late final Int32List _extraAt;

  /// The extra of each block in [_extraAt].
  late final List<_Extra> _extras;

  /// How many of its blocks are the fence lines of fenced divs (#729): a
  /// reader after a note's columns walks the chunks that have any.
  late final int divCount;

  /// How many of its blocks are quotes that hold a `:::` line (#1048).
  late final int fenceQuoteCount;

  /// How many of its blocks have an extra beside the columns.
  int get extraCount => _extras.length;

  /// What block [local] is, without making it.
  BlockKind kindAt(int local) => _kinds[_bits[local] & 15];

  /// Whether block [local] is marked as holding a `:::` line
  /// ([Block.holdsFence]).
  bool holdsFenceAt(int local) => _bits[local] & _fenceBit != 0;

  /// Block [local], [shift] lines further down than it is stored.
  Block blockAt(int local, int shift) {
    final word = _bits[local];
    final at = local * _stride;
    final extra = word & _extraBit == 0 ? null : _extras[_extraIndex(local)];
    final wide = extra?.wide;
    final role = (word >> _roleShift) & 7;
    return Block(
      kind: _kinds[word & 15],
      startLine: _lines[at] + shift,
      endLine: _lines[at + 1] + shift,
      quoteDepth: wide?.quoteDepth ?? (word >> _quoteShift) & _quoteMask,
      listDepth: wide?.listDepth ?? ((word >> _listShift) & _listMask) - 1,
      listOrdinal: wide?.listOrdinal ?? _lines[at + 2],
      headingLevel: wide?.headingLevel ?? (word >> _headingShift) & 7,
      fenceInfo: extra?.fenceInfo,
      entering: _entering[local],
      footnote: wide?.footnote ?? (word >> _footnoteShift) & 3,
      definition: wide?.definition ?? (word >> _definitionShift) & 3,
      reach: wide?.reach ?? _lines[at + 3],
      divRole: role == 0 ? null : _roles[role - 1],
      divDepth: wide?.divDepth ?? (word >> _divShift) & 7,
      holdsFence: word & _fenceBit != 0,
    );
  }

  /// Moves the blocks from [local] on [delta] lines down (up, when
  /// negative). Only on a chunk nobody else holds: see [toOwn].
  void shiftFrom(int local, int delta) {
    for (var at = local * _stride; at < length * _stride; at += _stride) {
      _lines[at] += delta;
      _lines[at + 1] += delta;
    }
  }

  /// A chunk that holds the same blocks and can be moved apart from this
  /// one. Only the lines are copied: nothing else of a chunk is ever
  /// written.
  BlockChunk toOwn() => BlockChunk._copyOf(this);

  /// Where block [local]'s extra is in [_extras]: [local] has one.
  int _extraIndex(int local) {
    var low = 0;
    var high = _extraAt.length - 1;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_extraAt[middle] < local) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}
