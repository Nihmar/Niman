import 'dart:convert';
import 'dart:typed_data';

import 'package:niman/src/dictionary/stardict_scan.dart';

/// One `.idx` entry: a headword and where its entry sits in the `.dict`.
final class IdxEntry {
  /// An entry for [headword], [size] bytes at [offset] of the uncompressed
  /// `.dict`.
  const new(this.headword, this.offset, this.size);

  /// The headword, keeping its case.
  final String headword;

  /// Where the entry starts in the uncompressed `.dict`.
  final int offset;

  /// How many bytes it takes.
  final int size;

  @override
  String toString() => 'IdxEntry($headword, $offset, $size)';
}

/// What a scan hands for each entry: the headword is
/// `bytes[start, end)`, so a caller that only needs the bytes (the index
/// build) does not make a string of each of a million entries.
typedef IdxVisitor = void Function(
  Uint8List bytes,
  int start,
  int end,
  int offset,
  int size,
);

/// A pack's `.idx`: per entry the headword, `\0`, the offset (4 or 8
/// bytes) and the size (4 bytes), all big-endian (StarDict 3.0.0).
final class StardictIdx {
  const new _();

  /// Walks the entries of the file at [path] in file order, calling
  /// [onEntry] for each. [offsetBits] is the `.ifo`'s `idxoffsetbits`.
  static Future<void> scan(
    String path, {
    required IdxVisitor onEntry,
    int offsetBits = 32,
    void Function(int done, int total)? onProgress,
  }) {
    final offsetBytes = offsetBits ~/ 8;
    return scanRecords(path, (bytes, end) {
      final view = ByteData.sublistView(bytes);
      var position = 0;
      while (true) {
        var nul = position;
        while (nul < end && bytes[nul] != 0) {
          nul++;
        }
        if (nul + 1 + offsetBytes + 4 > end) return position;
        final offset = offsetBytes == 8
            ? view.getUint64(nul + 1)
            : view.getUint32(nul + 1);
        final size = view.getUint32(nul + 1 + offsetBytes);
        onEntry(bytes, position, nul, offset, size);
        position = nul + 1 + offsetBytes + 4;
      }
    }, onProgress: onProgress);
  }

  /// Every entry of the file at [path], in file order: for a small pack and
  /// for tests, not for an English one.
  static Future<List<IdxEntry>> readAll(
    String path, {
    int offsetBits = 32,
  }) async {
    final entries = <IdxEntry>[];
    await scan(
      path,
      offsetBits: offsetBits,
      onEntry: (bytes, start, end, offset, size) => entries.add(
        IdxEntry(
          utf8.decode(
            Uint8List.sublistView(bytes, start, end),
            allowMalformed: true,
          ),
          offset,
          size,
        ),
      ),
    );
    return entries;
  }
}
