import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/dictionary/dictzip_file.dart';
import 'package:niman/src/dictionary/plain_dict_file.dart';
import 'package:path/path.dart' as p;

/// A pack's `.dict`: the entries' bytes, read at an offset of the
/// uncompressed data, whether the file is compressed or not.
abstract interface class DictSource {
  /// Opens the pack [id]'s data in [directory]: `<id>.dict.dz` when it is
  /// there, else a plain `<id>.dict` (what a fixture, or a build without the
  /// `dictzip` tool, writes). Null when neither exists.
  static Future<DictSource?> open(String directory, String id) async {
    final compressed = p.join(directory, '$id.dict.dz');
    if (await File(compressed).exists()) {
      return await DictzipFile.open(compressed);
    }
    final plain = p.join(directory, '$id.dict');
    if (await File(plain).exists()) return await PlainDictFile.open(plain);
    return null;
  }

  /// The path of the data file of pack [id] in [directory], or null.
  ///
  /// The sidecar index records its size and time to know it went stale.
  static Future<String?> pathOf(String directory, String id) async {
    for (final name in ['$id.dict.dz', '$id.dict']) {
      final path = p.join(directory, name);
      if (await File(path).exists()) return path;
    }
    return null;
  }

  /// [size] bytes from [offset] of the uncompressed data.
  ///
  /// One read at a time: the file has a single position.
  Future<Uint8List> read(int offset, int size);

  /// Releases the file.
  Future<void> close();
}
