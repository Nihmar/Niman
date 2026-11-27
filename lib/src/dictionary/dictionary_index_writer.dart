import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/dictionary/byte_sink.dart';
import 'package:niman/src/dictionary/dictionary_index_header.dart';
import 'package:niman/src/dictionary/index_key_table.dart';
import 'package:niman/src/dictionary/index_stamp.dart';

/// Lays a sorted [IndexKeyTable] out as the sidecar index
/// ([DictionaryIndexHeader] has the layout) and publishes the file.
final class DictionaryIndexWriter {
  const new _();

  /// Writes the index of [table], its keys taken in [order], to [path].
  ///
  /// [entries] is the entry table already laid out (offset and size per
  /// `.idx` entry, little-endian) and [stamps] the pack's files as they
  /// were read. The file is written beside [path] and renamed over it, so a
  /// reader never meets half an index. [onProgress] gets 0..1.
  static Future<void> write({
    required String path,
    required IndexKeyTable table,
    required Uint32List order,
    required ByteSink entries,
    required List<IndexStamp> stamps,
    void Function(double fraction)? onProgress,
  }) async {
    const blockKeys = DictionaryIndexHeader.defaultBlockKeys;
    final data = table.bytes;
    final fenceOffsets = ByteSink();
    final fences = ByteSink();
    final blockOffsets = ByteSink();
    final blocks = ByteSink(1 << 20);
    var blockCount = 0;
    var previousStart = 0;
    var previousEnd = 0;
    for (var n = 0; n < order.length; n++) {
      final i = order[n];
      final start = table.keyStart(i);
      final end = table.keyEnd(i);
      var shared = 0;
      if (n % blockKeys == 0) {
        blockOffsets.addUint32(blocks.length);
        fenceOffsets.addUint32(fences.length);
        fences.addRange(data, start, end);
        blockCount++;
      } else {
        final limit = (previousEnd - previousStart) < (end - start)
            ? previousEnd - previousStart
            : end - start;
        while (shared < limit &&
            data[previousStart + shared] == data[start + shared]) {
          shared++;
        }
      }
      blocks
        ..addVarint(shared)
        ..addVarint(end - start - shared)
        ..addRange(data, start + shared, end)
        ..addVarint(table.valueOf(i));
      previousStart = start;
      previousEnd = end;
      if (n & 0xFFFF == 0) onProgress?.call(n / order.length);
    }
    blockOffsets.addUint32(blocks.length);
    fenceOffsets.addUint32(fences.length);
    final header = DictionaryIndexHeader(
      keyCount: order.length,
      entryCount: entries.length ~/ 8,
      blockCount: blockCount,
      fenceBytes: fences.length,
      blocksBytes: blocks.length,
      stamps: stamps,
    );
    final temporary = '$path.tmp';
    final file = await File(temporary).open(mode: FileMode.write);
    try {
      await file.writeFrom(header.encode());
      await file.writeFrom(entries.view);
      await file.writeFrom(fenceOffsets.view);
      await file.writeFrom(fences.view);
      await file.writeFrom(blockOffsets.view);
      await file.writeFrom(blocks.view);
    } finally {
      await file.close();
    }
    if (await File(path).exists()) await File(path).delete();
    await File(temporary).rename(path);
    onProgress?.call(1);
  }
}
