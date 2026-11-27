import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/dictionary_exception.dart';

/// A `.dict.dz`: gzip whose header's `RA` field lists the compressed size
/// of each fixed-length chunk of the data.
///
/// The chunks are raw deflate after `Z_FULL_FLUSH`, so each inflates alone:
/// a look-up reads the one or two chunks an entry spans and never the
/// file. Opening reads only the header, a few kilobytes even for an English
/// pack.
final class DictzipFile implements DictSource {
  new _(this._file, this._chunkLength, this._starts);

  /// Opens the file at [path], or throws [DictionaryException] when it is
  /// not a dictzip file.
  static Future<DictzipFile> open(String path) async {
    final file = await File(path).open();
    try {
      return await _readHeader(file);
    } on Object {
      await file.close();
      rethrow;
    }
  }

  static Future<DictzipFile> _readHeader(RandomAccessFile file) async {
    final head = await file.read(12);
    if (head.length < 12 ||
        head[0] != 0x1f ||
        head[1] != 0x8b ||
        head[2] != 8) {
      throw const DictionaryException('not a gzip file');
    }
    final flags = head[3];
    if (flags & _extra == 0) {
      throw const DictionaryException('a gzip file without a dictzip header');
    }
    final extra = await file.read(head[10] | (head[11] << 8));
    final (chunkLength, sizes) = _chunkTable(extra);
    var dataStart = 12 + extra.length;
    if (flags & _name != 0) dataStart = await _afterString(file, dataStart);
    if (flags & _comment != 0) dataStart = await _afterString(file, dataStart);
    if (flags & _headerCrc != 0) dataStart += 2;
    final starts = Int64List(sizes.length + 1);
    starts[0] = dataStart;
    for (var i = 0; i < sizes.length; i++) {
      starts[i + 1] = starts[i] + sizes[i];
    }
    return DictzipFile._(file, chunkLength, starts);
  }

  static const int _extra = 4;
  static const int _name = 8;
  static const int _comment = 16;
  static const int _headerCrc = 2;

  /// The chunk length and the compressed size of each chunk, from the `RA`
  /// subfield of the gzip header's extra field.
  static (int, List<int>) _chunkTable(Uint8List extra) {
    final view = ByteData.sublistView(extra);
    var position = 0;
    while (position + 4 <= extra.length) {
      final length = view.getUint16(position + 2, Endian.little);
      final body = position + 4;
      if (extra[position] == 0x52 && extra[position + 1] == 0x41) {
        if (body + 6 > extra.length ||
            view.getUint16(body, Endian.little) != 1) {
          throw const DictionaryException(
            'a dictzip header of another version',
          );
        }
        final chunkLength = view.getUint16(body + 2, Endian.little);
        final count = view.getUint16(body + 4, Endian.little);
        if (chunkLength == 0 || body + 6 + 2 * count > extra.length) {
          throw const DictionaryException('a damaged dictzip chunk table');
        }
        return (
          chunkLength,
          [
            for (var i = 0; i < count; i++)
              view.getUint16(body + 6 + 2 * i, Endian.little),
          ],
        );
      }
      position = body + length;
    }
    throw const DictionaryException('a gzip file without the RA field');
  }

  /// The position after the zero-terminated string that starts at [from].
  static Future<int> _afterString(RandomAccessFile file, int from) async {
    await file.setPosition(from);
    var position = from;
    while (true) {
      final bytes = await file.read(256);
      if (bytes.isEmpty) {
        throw const DictionaryException('a gzip header that does not end');
      }
      final nul = bytes.indexOf(0);
      if (nul >= 0) return position + nul + 1;
      position += bytes.length;
    }
  }

  /// How many chunks stay inflated: neighbouring entries of a look-up, and
  /// the one that follows it, are most often in the same one.
  static const int _cached = 4;

  final RandomAccessFile _file;
  final int _chunkLength;

  /// Where each chunk starts in the file, and where the last one ends.
  final Int64List _starts;
  final LinkedHashMap<int, Uint8List> _chunks = LinkedHashMap();

  /// The chunks the file holds.
  int get chunkCount => _starts.length - 1;

  /// How many bytes of data each chunk inflates to, but the last.
  int get chunkLength => _chunkLength;

  @override
  Future<Uint8List> read(int offset, int size) async {
    if (size == 0) return Uint8List(0);
    final first = offset ~/ _chunkLength;
    final last = (offset + size - 1) ~/ _chunkLength;
    if (last >= chunkCount) {
      throw const DictionaryException('the .dict.dz ends before its entry');
    }
    final out = BytesBuilder(copy: false);
    for (var index = first; index <= last; index++) {
      out.add(await _chunk(index));
    }
    final skip = offset - first * _chunkLength;
    final bytes = out.takeBytes();
    if (skip + size > bytes.length) {
      throw const DictionaryException('the .dict.dz ends before its entry');
    }
    return Uint8List.sublistView(bytes, skip, skip + size);
  }

  Future<Uint8List> _chunk(int index) async {
    final cached = _chunks.remove(index);
    if (cached != null) return _chunks[index] = cached;
    await _file.setPosition(_starts[index]);
    final packed = await _file.read(_starts[index + 1] - _starts[index]);
    final Uint8List inflated;
    try {
      inflated = Uint8List.fromList(ZLibDecoder(raw: true).convert(packed));
    } on FormatException catch (error) {
      throw DictionaryException('a damaged chunk $index: ${error.message}');
    }
    if (_chunks.length >= _cached) _chunks.remove(_chunks.keys.first);
    return _chunks[index] = inflated;
  }

  @override
  Future<void> close() => _file.close();
}
