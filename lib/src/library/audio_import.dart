import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/logging.dart';
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
///
/// The copy streams: the file is hashed chunk by chunk and copied with
/// asynchronous `dart:io`, never read whole into the Dart heap. The
/// earlier read-all + `writeAsBytesSync` onto Android's FUSE storage took
/// 2.3 s, and the UI drew no frame for that whole time (device log,
/// 2026-09-15) although the copy ran in another isolate — most likely a
/// garbage collection of the shared isolate-group heap waiting on the
/// synchronous call that held the buffer. Asynchronous file work runs on
/// the I/O threads instead.
Future<String> importAudioToLibrary({
  required String libraryRoot,
  required String sourcePath,
  String attachmentsFolder = defaultAttachmentsFolder,
}) async {
  final clock = Stopwatch()..start();
  final result = await Isolate.run(
    () => _copyIntoLibrary(libraryRoot, sourcePath, attachmentsFolder),
  );
  _log.info(
    'import ${result.relative}: ${result.bytes} b, hash ${result.hashMs} ms, '
    '${result.reused ? 'already in the library' : 'copy ${result.copyMs} ms'}, '
    'total ${clock.elapsedMilliseconds} ms',
  );
  return result.relative;
}

const _log = AppLogger(name: 'audio');

/// What [_copyIntoLibrary] did, for the main isolate to log.
typedef _Imported = ({
  String relative,
  int bytes,
  int hashMs,
  int copyMs,
  bool reused,
});

Future<_Imported> _copyIntoLibrary(
  String libraryRoot,
  String sourcePath,
  String attachmentsFolder,
) async {
  final source = File(sourcePath);
  final hashClock = Stopwatch()..start();
  final digest = (await sha256.bind(source.openRead()).first).toString();
  final hashMs = hashClock.elapsedMilliseconds;
  final extension = p.extension(sourcePath).toLowerCase();
  final assets = Directory(p.join(libraryRoot, attachmentsFolder));
  await assets.create(recursive: true);
  final target = File(p.join(assets.path, '$digest$extension'));
  final relative = '$attachmentsFolder/$digest$extension';
  final bytes = await source.length();
  // A stat moves no buffer through the heap, unlike the read/write above.
  if (target.existsSync()) {
    return (
      relative: relative,
      bytes: bytes,
      hashMs: hashMs,
      copyMs: 0,
      reused: true,
    );
  }
  final copyClock = Stopwatch()..start();
  // Into a hidden temp name first, so the index and a sync never see a
  // half-copied clip under its final name.
  final temp = p.join(
    assets.path,
    '.$digest$extension.niman-tmp-${DateTime.now().microsecondsSinceEpoch}',
  );
  await source.copy(temp);
  await File(temp).rename(target.path);
  return (
    relative: relative,
    bytes: bytes,
    hashMs: hashMs,
    copyMs: copyClock.elapsedMilliseconds,
    reused: false,
  );
}

/// Renames an audio file inside the library, off the UI isolate (reads
/// are FUSE round trips on Android).
///
/// [oldRelative] and [newFileName] resolve under [libraryRoot]; the
/// extension of the current file is kept when [newFileName] carries none,
/// and a `-1`, `-2` suffix disambiguates a collision. Returns the new
/// library-relative path for the note's embed.
Future<String> renameAudioInLibrary({
  required String libraryRoot,
  required String oldRelative,
  required String newFileName,
}) {
  return Isolate.run(
    () => _renameInLibrary(libraryRoot, oldRelative, newFileName),
  );
}

String _renameInLibrary(
  String libraryRoot,
  String oldRelative,
  String newFileName,
) {
  final oldFile = File(p.join(libraryRoot, oldRelative));
  if (!oldFile.existsSync()) {
    throw StateError('Recording not found: $oldRelative');
  }
  var name = newFileName.trim();
  if (name.isEmpty) {
    throw ArgumentError('The new name must not be empty');
  }
  // A bare name keeps the recording's extension.
  if (!name.contains('.')) {
    name = '$name${p.extension(oldFile.path)}';
  }
  final dir = p.dirname(oldFile.path);
  var candidate = p.join(dir, name);
  var counter = 1;
  while (File(candidate).existsSync() &&
      p.normalize(candidate) != p.normalize(oldFile.path)) {
    counter++;
    final stem = p.basenameWithoutExtension(name);
    candidate = p.join(dir, '$stem-$counter${p.extension(name)}');
  }
  if (p.normalize(candidate) != p.normalize(oldFile.path)) {
    oldFile.renameSync(candidate);
  }
  return p.relative(candidate, from: libraryRoot);
}
