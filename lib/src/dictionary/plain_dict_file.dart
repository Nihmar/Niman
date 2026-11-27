import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/dictionary/dict_source.dart';
import 'package:niman/src/dictionary/dictionary_exception.dart';

/// An uncompressed `.dict`, read in place.
final class PlainDictFile implements DictSource {
  const new _(this._file);

  /// Opens the file at [path].
  static Future<PlainDictFile> open(String path) async =>
      PlainDictFile._(await File(path).open());

  final RandomAccessFile _file;

  @override
  Future<Uint8List> read(int offset, int size) async {
    await _file.setPosition(offset);
    final bytes = await _file.read(size);
    if (bytes.length != size) {
      throw const DictionaryException('the .dict ends before its entry does');
    }
    return bytes;
  }

  @override
  Future<void> close() => _file.close();
}
