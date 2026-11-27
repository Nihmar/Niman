import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/dictionary/dictionary_exception.dart';

/// Reads the whole records at the start of `bytes[0, end)` and returns how
/// many bytes they took; what is left is a record cut by the block's end.
typedef RecordParser = int Function(Uint8List bytes, int end);

/// How much of a file is read at a time: a megabyte is a few thousand
/// records and a read the file system does not mind.
const int _block = 1 << 20;

/// Feeds the records of the file at [path] to [parse], a block at a time.
///
/// An English `.idx` is tens of megabytes and its `.syn` more, so neither
/// is held whole: the unfinished record at the end of a block is carried to
/// the next. [onProgress] gets the bytes read so far and the file's length.
Future<void> scanRecords(
  String path,
  RecordParser parse, {
  void Function(int done, int total)? onProgress,
}) async {
  final file = await File(path).open();
  try {
    final total = await file.length();
    var carry = Uint8List(0);
    var done = 0;
    while (done < total) {
      final chunk = await file.read(_block);
      if (chunk.isEmpty) break;
      done += chunk.length;
      final bytes = Uint8List(carry.length + chunk.length)
        ..setRange(0, carry.length, carry)
        ..setRange(carry.length, carry.length + chunk.length, chunk);
      final used = parse(bytes, bytes.length);
      carry = Uint8List.fromList(Uint8List.sublistView(bytes, used));
      onProgress?.call(done, total);
    }
    if (carry.isNotEmpty) {
      throw DictionaryException('$path ends inside a record');
    }
  } finally {
    await file.close();
  }
}
