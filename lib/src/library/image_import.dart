import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Copies a picked image into the library and returns its library-relative
/// path (T-M2-09): the content-addressed name is the file's sha256 (so the
/// same image never duplicates) and the file lands in `<library>/assets/`
/// (created on demand) — the design's "copy file into the library, insert
/// a link, no base64". The copy runs off the UI isolate (reads/writes are
/// FUSE round trips on Android).
///
/// Returns something like `assets/ab12…cd.png` — exactly what the preview
/// resolves against the library root (its `imageDirectory`) and what the
/// editor highlights as an image link.
Future<String> importImageToLibrary({
  required String libraryRoot,
  required String sourcePath,
}) {
  return Isolate.run(() => _copyIntoLibrary(libraryRoot, sourcePath));
}

String _copyIntoLibrary(String libraryRoot, String sourcePath) {
  final source = File(sourcePath);
  final bytes = source.readAsBytesSync();
  final digest = sha256.convert(bytes).toString();
  final extension = p.extension(sourcePath); // '' or '.png'
  final assets = Directory(p.join(libraryRoot, 'assets'))
    ..createSync(recursive: true);
  final target = p.join(assets.path, '$digest$extension');
  if (!File(target).existsSync()) {
    File(target).writeAsBytesSync(bytes);
  }
  return 'assets/$digest$extension';
}
