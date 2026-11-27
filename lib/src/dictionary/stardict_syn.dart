import 'dart:convert';
import 'dart:typed_data';

import 'package:niman/src/dictionary/stardict_scan.dart';

/// One `.syn` record: a key that is not a headword and the `.idx` entry it
/// leads to.
final class SynEntry {
  /// A [word] that leads to the entry number [entryIndex].
  const new(this.word, this.entryIndex);

  /// The key: an inflected form, an alternative spelling.
  final String word;

  /// The position of the lemma's entry in the `.idx`, from 0.
  final int entryIndex;

  @override
  String toString() => 'SynEntry($word, $entryIndex)';
}

/// What a scan hands for each record: the key is `bytes[start, end)`.
typedef SynVisitor = void Function(
  Uint8List bytes,
  int start,
  int end,
  int entryIndex,
);

/// A pack's `.syn`: per record the key, `\0` and the 4-byte big-endian
/// number of the `.idx` entry it points at.
final class StardictSyn {
  const new _();

  /// Walks the records of the file at [path] in file order.
  static Future<void> scan(
    String path, {
    required SynVisitor onEntry,
    void Function(int done, int total)? onProgress,
  }) {
    return scanRecords(path, (bytes, end) {
      final view = ByteData.sublistView(bytes);
      var position = 0;
      while (true) {
        var nul = position;
        while (nul < end && bytes[nul] != 0) {
          nul++;
        }
        if (nul + 5 > end) return position;
        onEntry(bytes, position, nul, view.getUint32(nul + 1));
        position = nul + 5;
      }
    }, onProgress: onProgress);
  }

  /// Every record of the file at [path]: for a small pack and for tests.
  static Future<List<SynEntry>> readAll(String path) async {
    final entries = <SynEntry>[];
    await scan(
      path,
      onEntry: (bytes, start, end, entryIndex) => entries.add(
        SynEntry(
          utf8.decode(
            Uint8List.sublistView(bytes, start, end),
            allowMalformed: true,
          ),
          entryIndex,
        ),
      ),
    );
    return entries;
  }
}
