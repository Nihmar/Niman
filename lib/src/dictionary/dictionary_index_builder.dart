import 'dart:io';
import 'dart:math';

import 'package:niman/src/dictionary/byte_sink.dart';
import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/dictionary_exception.dart';
import 'package:niman/src/dictionary/dictionary_index.dart';
import 'package:niman/src/dictionary/dictionary_index_writer.dart';
import 'package:niman/src/dictionary/index_key_table.dart';
import 'package:niman/src/dictionary/stardict_idx.dart';
import 'package:niman/src/dictionary/stardict_ifo.dart';
import 'package:niman/src/dictionary/stardict_syn.dart';
import 'package:path/path.dart' as p;

/// Builds the sidecar index of a pack from the pack's own files, and
/// nothing else: deleting the sidecar and building it again gives the same
/// bytes.
///
/// It blocks for as long as the sort takes, so it runs on an isolate of its
/// own (`buildDictionaryIndexOnIsolate`), never on the UI's.
final class DictionaryIndexBuilder {
  const new _();

  /// Builds `<id>.niman-index` in [directory]. [onProgress] gets 0..1: the
  /// reads take the first four tenths, the sort the next four, the writing
  /// the rest.
  ///
  /// Throws [DictionaryException] for a pack the engine cannot read.
  static Future<void> build({
    required String directory,
    required String id,
    void Function(double fraction)? onProgress,
  }) async {
    final ifoFile = File(p.join(directory, '$id.ifo'));
    final ifo = await ifoFile.exists()
        ? StardictIfo.parse(await ifoFile.readAsString())
        : null;
    if (ifo == null) throw DictionaryException('$id has no readable .ifo');
    final unsupported = ifo.unsupportedReason;
    if (unsupported != null) throw DictionaryException('$id: $unsupported');
    final idxPath = p.join(directory, '$id.idx');
    if (!await File(idxPath).exists()) {
      throw DictionaryException('$id has no .idx');
    }
    if (await DictSource.pathOf(directory, id) == null) {
      throw DictionaryException('$id has no .dict');
    }
    // Stamped before the reads: a file replaced meanwhile then reads stale
    // at the next open, and the index is built again.
    final stamps = await DictionaryIndex.stampsOf(directory, id);
    final synPath = p.join(directory, '$id.syn');
    final idxBytes = stamps[1].size;
    final synBytes = stamps[2].size;
    final readBytes = idxBytes + synBytes == 0 ? 1 : idxBytes + synBytes;

    // What the `.ifo` counts is a hint, never trusted: a table that is too
    // small only grows, and one too big is held to what the files could
    // hold. A key is its record less the bytes of its number.
    final hinted = (ifo.wordCount ?? 0) + (ifo.synWordCount ?? 0);
    final fileBytes = idxBytes + synBytes;
    final keyBytes =
        fileBytes - 8 * (ifo.wordCount ?? 0) - 5 * (ifo.synWordCount ?? 0);
    final table = IndexKeyTable(
      keys: hinted.clamp(0, fileBytes ~/ 5),
      bytes: keyBytes.clamp(0, fileBytes),
    );
    final entries = ByteSink(
      min(max(8 * (ifo.wordCount ?? 0), 64), 8 * (idxBytes ~/ 9 + 1)),
    );
    await StardictIdx.scan(
      idxPath,
      offsetBits: ifo.idxOffsetBits,
      onEntry: (bytes, start, end, offset, size) {
        if (offset > 0xFFFFFFFF) {
          throw DictionaryException('$id: a .dict past 4 GB');
        }
        final number = entries.length ~/ 8;
        entries
          ..addUint32(offset)
          ..addUint32(size);
        table.add(bytes, start, end, number << 1);
      },
      onProgress: (done, total) => onProgress?.call(0.4 * done / readBytes),
    );
    final entryCount = entries.length ~/ 8;
    if (synBytes > 0) {
      await StardictSyn.scan(
        synPath,
        onEntry: (bytes, start, end, entryIndex) {
          // A record that points past the `.idx` is a damaged one.
          if (entryIndex < entryCount) {
            table.add(bytes, start, end, (entryIndex << 1) | 1);
          }
        },
        onProgress: (done, total) =>
            onProgress?.call(0.4 * (idxBytes + done) / readBytes),
      );
    }
    onProgress?.call(0.4);
    final order = table.sortedOrder();
    onProgress?.call(0.8);
    await DictionaryIndexWriter.write(
      path: DictionaryIndex.pathOf(directory, id),
      table: table,
      order: order,
      entries: entries,
      stamps: stamps,
      onProgress: (fraction) => onProgress?.call(0.8 + 0.2 * fraction),
    );
  }
}
