import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show defaultAttachmentsFolder;
import 'package:path/path.dart' as p;

/// Copies a recorded or picked audio file into the library's attachments
/// folder and returns its library-relative path (issue #56): the
/// content-addressed name is the file's sha256 (so the same clip never
/// duplicates) and the file lands in `<library>/<attachmentsFolder>/`
/// (created on demand) — the same layout images use ("copy file into the
/// library, insert a link, no base64"). The copy runs off the UI isolate
/// (reads/writes are FUSE round trips on Android).
///
/// Returns something like `assets/ab12…cd.wav` — exactly what the audio
/// view resolves against the library root.
Future<String> importAudioToLibrary({
  required String libraryRoot,
  required String sourcePath,
  String attachmentsFolder = defaultAttachmentsFolder,
}) {
  return Isolate.run(
    () => _copyIntoLibrary(libraryRoot, sourcePath, attachmentsFolder),
  );
}

String _copyIntoLibrary(
  String libraryRoot,
  String sourcePath,
  String attachmentsFolder,
) {
  final source = File(sourcePath);
  final bytes = source.readAsBytesSync();
  final digest = sha256.convert(bytes).toString();
  final extension = p.extension(sourcePath).toLowerCase();
  final assets = Directory(p.join(libraryRoot, attachmentsFolder))
    ..createSync(recursive: true);
  final target = p.join(assets.path, '$digest$extension');
  if (!File(target).existsSync()) {
    File(target).writeAsBytesSync(bytes);
  }
  return '$attachmentsFolder/$digest$extension';
}
