import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/dictionary_index_header.dart';
import 'package:niman/src/dictionary/index_stamp.dart';
import 'package:niman/src/dictionary/unicode_nfc.dart';
import 'package:path/path.dart' as p;

/// What a key leads to: the `.idx` entry number, and whether the key is a
/// `.syn` form (the headword itself when not).
typedef IndexHit = ({int entry, bool isSyn});

/// Where an entry sits in the uncompressed `.dict`.
typedef EntryPlace = ({int offset, int size});

/// The sidecar index of a pack, open for look-ups
/// ([DictionaryIndexHeader] has its layout).
///
/// What stays in memory is the first key of each block, a sixty-fourth of
/// the keys; a look-up searches them and reads the one block that can hold
/// its key, then the entry's place: no scan, whatever the pack's size. One
/// look-up at a time, the file having a single position.
final class DictionaryIndex {
  new _(
    this._file,
    this._header,
    this._fenceOffsets,
    this._fenceKeys,
    this._blockOffsets,
  );

  /// The sidecar of the pack [id] in [directory].
  static String pathOf(String directory, String id) =>
      p.join(directory, '$id.niman-index');

  /// The stamps of the pack's `.ifo`, `.idx`, `.syn` and data file, in that
  /// order: what the sidecar records and is checked against.
  static Future<List<IndexStamp>> stampsOf(String directory, String id) async {
    final data = await DictSource.pathOf(directory, id);
    return [
      await IndexStamp.of(p.join(directory, '$id.ifo')),
      await IndexStamp.of(p.join(directory, '$id.idx')),
      await IndexStamp.of(p.join(directory, '$id.syn')),
      if (data != null) await IndexStamp.of(data) else IndexStamp.absent,
    ];
  }

  /// Opens the sidecar of pack [id] in [directory]; null when it is absent,
  /// built from other files than the pack's now are, or unreadable: the
  /// answer to each is to build it again.
  static Future<DictionaryIndex?> open(String directory, String id) async {
    final path = pathOf(directory, id);
    if (!await File(path).exists()) return null;
    final file = await File(path).open();
    try {
      final header = DictionaryIndexHeader.parse(
        await file.read(DictionaryIndexHeader.size),
      );
      if (header == null || await file.length() != header.fileSize) {
        await file.close();
        return null;
      }
      final stamps = await stampsOf(directory, id);
      for (var i = 0; i < stamps.length; i++) {
        if (stamps[i] != header.stamps[i]) {
          await file.close();
          return null;
        }
      }
      await file.setPosition(header.fencesStart);
      final memory = await file.read(header.blocksStart - header.fencesStart);
      final view = ByteData.sublistView(memory);
      final offsets = header.blockCount + 1;
      return DictionaryIndex._(
        file,
        header,
        [
          for (var i = 0; i < offsets; i++)
            view.getUint32(4 * i, Endian.little),
        ],
        Uint8List.sublistView(
          memory,
          offsets * 4,
          offsets * 4 + header.fenceBytes,
        ),
        [
          for (var i = 0; i < offsets; i++)
            view.getUint32(
              offsets * 4 + header.fenceBytes + 4 * i,
              Endian.little,
            ),
        ],
      );
    } on Object {
      await file.close();
      return null;
    }
  }

  final RandomAccessFile _file;
  final DictionaryIndexHeader _header;
  final List<int> _fenceOffsets;
  final Uint8List _fenceKeys;
  final List<int> _blockOffsets;

  /// How many keys the index holds.
  int get keyCount => _header.keyCount;

  /// How many entries the pack has.
  int get entryCount => _header.entryCount;

  /// Every entry [key] is the headword of, or a form of: the same key can
  /// be both (*Polish* and *polish* are two entries, and *ancora* may be a
  /// headword and a form), and a form can have several lemmas.
  Future<List<IndexHit>> find(String key) async {
    final target = Uint8List.fromList(utf8.encode(UnicodeNfc.compose(key)));
    final hits = <IndexHit>[];
    await _walk(target, (bytes, length, value) {
      final order = _compare(bytes, 0, length, target);
      if (order == 0) hits.add((entry: value >> 1, isSyn: value & 1 == 1));
      return order <= 0;
    });
    return hits;
  }

  /// Up to [limit] distinct keys that start with [prefix], in byte order:
  /// the nearest keys to one that was not found.
  Future<List<String>> keysWithPrefix(String prefix, int limit) async {
    final target = Uint8List.fromList(utf8.encode(UnicodeNfc.compose(prefix)));
    final found = <String>[];
    await _walk(target, (bytes, length, value) {
      if (length >= target.length &&
          _compare(bytes, 0, target.length, target) == 0) {
        final key = utf8.decode(
          Uint8List.sublistView(bytes, 0, length),
          allowMalformed: true,
        );
        if (found.isEmpty || found.last != key) found.add(key);
        return found.length < limit;
      }
      return _compare(bytes, 0, length, target) < 0;
    });
    return found;
  }

  /// The place of the entry number [entry] in the `.dict`.
  Future<EntryPlace> entry(int entry) async {
    await _file.setPosition(_header.entryTableStart + entry * 8);
    final bytes = await _file.read(8);
    final view = ByteData.sublistView(bytes);
    return (
      offset: view.getUint32(0, Endian.little),
      size: view.getUint32(4, Endian.little),
    );
  }

  /// Releases the file.
  Future<void> close() => _file.close();

  /// Visits the keys in order from the first block that can hold [from],
  /// each as the bytes `key[0, length)` of a buffer reused between calls,
  /// until [visit] says to stop.
  Future<void> _walk(
    Uint8List from,
    bool Function(Uint8List key, int length, int value) visit,
  ) async {
    var key = Uint8List(64);
    // The first block whose first key is not below [from], less one: the
    // keys equal to it may begin at the end of the block before.
    var low = 0;
    var high = _header.blockCount;
    while (low < high) {
      final middle = (low + high) >> 1;
      final start = _fenceOffsets[middle];
      final length = _fenceOffsets[middle + 1] - start;
      if (_compare(_fenceKeys, start, length, from) < 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    for (
      var block = low > 0 ? low - 1 : 0;
      block < _header.blockCount;
      block++
    ) {
      final first = _blockOffsets[block];
      await _file.setPosition(_header.blocksStart + first);
      final bytes = await _file.read(_blockOffsets[block + 1] - first);
      var at = 0;
      var length = 0;
      while (at < bytes.length) {
        final (shared, afterShared) = _varint(bytes, at);
        final (tail, afterTail) = _varint(bytes, afterShared);
        length = shared + tail;
        if (length > key.length) {
          key = Uint8List(length * 2)..setRange(0, shared, key);
        }
        key.setRange(shared, length, bytes, afterTail);
        final (value, afterValue) = _varint(bytes, afterTail + tail);
        at = afterValue;
        if (!visit(key, length, value)) return;
      }
    }
  }

  /// The number at [at] in [bytes] and the position after it.
  static (int, int) _varint(Uint8List bytes, int at) {
    var value = 0;
    var shift = 0;
    var position = at;
    while (true) {
      final byte = bytes[position++];
      value |= (byte & 0x7F) << shift;
      if (byte < 0x80) return (value, position);
      shift += 7;
    }
  }

  /// Compares `a[start, start + length)` with all of [b], bytewise.
  static int _compare(Uint8List a, int start, int length, Uint8List b) {
    final common = length < b.length ? length : b.length;
    for (var i = 0; i < common; i++) {
      final difference = a[start + i] - b[i];
      if (difference != 0) return difference;
    }
    return length - b.length;
  }
}
