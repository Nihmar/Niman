import 'dart:typed_data';

import 'package:niman/src/dictionary/index_stamp.dart';

/// The fixed start of a sidecar index (`<id>.niman-index`), and with it the
/// whole layout, little-endian throughout:
///
/// | Section | Holds |
/// |---|---|
/// | header, [size] bytes | magic, version, counts, the pack's stamps |
/// | entry table | per `.idx` entry, its place in the `.dict`: 2 x u32 |
/// | fence offsets | per block and one more, u32 into the fence keys |
/// | fence keys | the first key of each block, whole |
/// | block offsets | per block and one more, u32 into the blocks |
/// | blocks | up to [blockKeys] keys each, front-coded, then the value |
///
/// The keys are the pack's `.idx` headwords and `.syn` forms, NFC, in byte
/// order. A key is stored as the length it shares with the one before, the
/// length of its tail, the tail, and a varint value: the entry number
/// shifted left once, the low bit saying the key came from the `.syn`. A
/// look-up is a binary search over the fences, which stay in memory, and one
/// read of one block.
final class DictionaryIndexHeader {
  /// A header for an index of [keyCount] keys in [blockCount] blocks over
  /// [entryCount] entries, built from the pack files [stamps] describe.
  const new({
    required this.keyCount,
    required this.entryCount,
    required this.blockCount,
    required this.fenceBytes,
    required this.blocksBytes,
    required this.stamps,
    this.blockKeys = defaultBlockKeys,
  });

  /// Reads a header from [bytes], or null when they are not one this app
  /// wrote: a rebuild is always the answer to that.
  static DictionaryIndexHeader? parse(Uint8List bytes) {
    if (bytes.length < size) return null;
    final view = ByteData.sublistView(bytes);
    if (view.getUint32(0, Endian.little) != _magic ||
        view.getUint32(4, Endian.little) != version) {
      return null;
    }
    int u32(int at) => view.getUint32(at, Endian.little);
    return DictionaryIndexHeader(
      blockKeys: u32(8),
      keyCount: u32(12),
      entryCount: u32(16),
      blockCount: u32(20),
      fenceBytes: u32(24),
      blocksBytes: u32(28),
      stamps: [
        for (var i = 0; i < stampCount; i++)
          IndexStamp(
            view.getUint64(32 + 16 * i, Endian.little),
            view.getUint64(40 + 16 * i, Endian.little),
          ),
      ],
    );
  }

  /// `NMIX`, read little-endian.
  static const int _magic = 0x58494D4E;

  /// The layout this app writes; any other number is rebuilt.
  static const int version = 1;

  /// Bytes the header takes.
  static const int size = 32 + 16 * stampCount;

  /// How many files are stamped: `.ifo`, `.idx`, `.syn` and the data file.
  static const int stampCount = 4;

  /// Keys per block: one read is about a kilobyte, and the fences kept in
  /// memory are a sixty-fourth of the keys.
  static const int defaultBlockKeys = 64;

  /// Keys per block.
  final int blockKeys;

  /// Keys in the index: every headword and every form.
  final int keyCount;

  /// Entries of the pack's `.idx`.
  final int entryCount;

  /// Blocks of keys.
  final int blockCount;

  /// Bytes of the fence keys.
  final int fenceBytes;

  /// Bytes of the blocks.
  final int blocksBytes;

  /// The `.ifo`, `.idx`, `.syn` and data file, as they were when the index
  /// was built.
  final List<IndexStamp> stamps;

  /// Where the entry table starts.
  int get entryTableStart => size;

  /// Where the fence offsets start.
  int get fencesStart => entryTableStart + entryCount * 8;

  /// Where the fence keys start.
  int get fenceKeysStart => fencesStart + (blockCount + 1) * 4;

  /// Where the block offsets start.
  int get blockOffsetsStart => fenceKeysStart + fenceBytes;

  /// Where the blocks start.
  int get blocksStart => blockOffsetsStart + (blockCount + 1) * 4;

  /// The file's whole length.
  int get fileSize => blocksStart + blocksBytes;

  /// The header's bytes.
  Uint8List encode() {
    final bytes = Uint8List(size);
    final view = ByteData.sublistView(bytes)
      ..setUint32(0, _magic, Endian.little)
      ..setUint32(4, version, Endian.little)
      ..setUint32(8, blockKeys, Endian.little)
      ..setUint32(12, keyCount, Endian.little)
      ..setUint32(16, entryCount, Endian.little)
      ..setUint32(20, blockCount, Endian.little)
      ..setUint32(24, fenceBytes, Endian.little)
      ..setUint32(28, blocksBytes, Endian.little);
    for (final (i, stamp) in stamps.indexed) {
      view
        ..setUint64(32 + 16 * i, stamp.size, Endian.little)
        ..setUint64(40 + 16 * i, stamp.modifiedMs, Endian.little);
    }
    return bytes;
  }
}
