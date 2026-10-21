import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/todo/todo_file_names.dart';
import 'package:path/path.dart' as p;

// The todo files' synchronous reads: each runs on a background isolate (an
// `existsSync` or `statSync` is a FUSE round trip on Android, #1143), which
// `ui_isolate_io_test.dart` holds this file to.

/// Reads both files' raw bytes off the caller's isolate (the Android
/// FUSE rule: no disk reads on the UI isolate).
///
/// Top-level and fully synchronous so it can be handed to `Isolate.run`;
/// captures only the sendable `root`. Returns `[todoBytes, doneBytes]`
/// (null per missing file). Byte buffers (not strings) cross the isolate
/// boundary; decoding and line splitting stay on the caller.
List<Uint8List?> readTodoFiles(String root) {
  Uint8List? read(String name) {
    final file = File(p.join(root, name));
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsBytesSync();
  }

  return <Uint8List?>[read(todoFileName), read(doneFileName)];
}

/// Stats both files off the caller's isolate.
///
/// Top-level and fully synchronous so it can be handed to `Isolate.run`;
/// captures only the sendable `root`. Returns
/// `[todoSize, todoMtimeUs, doneSize, doneMtimeUs]` (-1 per missing
/// file); only plain ints cross the isolate boundary.
List<int> probeTodoFiles(String root) {
  List<int> probe(String name) {
    final file = File(p.join(root, name));
    if (!file.existsSync()) {
      return <int>[-1, -1];
    }
    final stat = file.statSync();
    return <int>[stat.size, stat.modified.microsecondsSinceEpoch];
  }

  return <int>[...probe(todoFileName), ...probe(doneFileName)];
}
