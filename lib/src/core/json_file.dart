import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// A small JSON file of choices that belong to downloaded data on this
/// device (`transcription.json`, `ocr.json`), kept next to that data
/// rather than in `AppDatabase`.
///
/// Both directions run off the UI isolate (every open is a FUSE round
/// trip on Android). A write goes to a temp name and is renamed into
/// place, so a crash mid-write leaves the previous file, never half of
/// one.
final class JsonFile {
  /// The file [fileName] in the directory [directory] resolves to.
  new(this.directory, this.fileName);

  /// Resolves the directory.
  final Future<String> Function() directory;

  /// The file's name.
  final String fileName;

  /// The decoded content; null when the file is missing or unreadable.
  /// Throws [FormatException] when it is not JSON.
  Future<Object?> read() async {
    final path = p.join(await directory(), fileName);
    final text = await Isolate.run(() => _read(path));
    return text == null ? null : jsonDecode(text);
  }

  /// Writes [json], creating the directory.
  Future<void> write(Object? json) async {
    final dir = await directory();
    final text = jsonEncode(json);
    final name = fileName;
    await Isolate.run(() => _write(dir, name, text));
  }
}

Future<String?> _read(String path) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return await file.readAsString();
  } on FileSystemException {
    return null;
  }
}

Future<void> _write(String dir, String name, String text) async {
  await Directory(dir).create(recursive: true);
  final target = p.join(dir, name);
  final temp = '$target.niman-tmp-${DateTime.now().microsecondsSinceEpoch}';
  await File(temp).writeAsString(text, flush: true);
  await File(temp).rename(target);
}
