/// The library's attachments folder, where a file's content names it: its
/// SHA-256, so the same picture is never there twice. A picked picture is
/// copied in ([importImageToLibrary]), a downloaded one written in
/// ([storeAttachmentBytes]) — under a hidden temporary name first, so the
/// index and a sync never see half a file under its final one.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show defaultAttachmentsFolder;
import 'package:niman/src/library/note_writer.dart' show swapFileIn;
import 'package:path/path.dart' as p;

/// Copies a picked image into the library's attachments folder and returns
/// its library-relative path (T-M2-09): the content-addressed name is the
/// file's sha256 (so the same image never duplicates) and the file lands
/// in `<library>/<attachmentsFolder>/` (created on demand) — the design's
/// "copy file into the library, insert a link, no base64". The copy runs
/// off the UI isolate (reads/writes are FUSE round trips on Android).
///
/// Returns something like `assets/ab12…cd.png` — exactly what the preview
/// resolves against the library root (its `imageDirectory`) and what the
/// editor highlights as an image link.
///
/// The copy streams: the file is hashed chunk by chunk and copied with
/// asynchronous `dart:io`, never read whole into the Dart heap. The voice
/// note's import did read-all + `writeAsBytesSync` the same way and froze
/// the UI for its whole 2.3 s copy onto Android's FUSE storage, although
/// it ran in another isolate (device log, 2026-09-15) — most likely a
/// garbage collection of the shared isolate-group heap waiting on the
/// synchronous write. A camera photo is larger than that clip.
Future<String> importImageToLibrary({
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

const _log = AppLogger(name: 'image');

/// Writes [bytes] into `<libraryRoot>/<attachmentsFolder>/`, named by their
/// SHA-256 and [extension] (`.png`, or ''), and returns the library-relative
/// path; a file already there with that content is kept as it is. The
/// writing is asynchronous: call it off the UI isolate, as the capture does
/// for a page's pictures (#531).
Future<String> storeAttachmentBytes({
  required String libraryRoot,
  required List<int> bytes,
  required String extension,
  String attachmentsFolder = defaultAttachmentsFolder,
}) async {
  final digest = sha256.convert(bytes).toString();
  final assets = Directory(p.join(libraryRoot, attachmentsFolder));
  await assets.create(recursive: true);
  final target = File(p.join(assets.path, '$digest$extension'));
  final relative = '$attachmentsFolder/$digest$extension';
  if (target.existsSync()) return relative;
  final temp = File(_tempName(assets.path, digest, extension));
  await temp.writeAsBytes(bytes, flush: true);
  // Not a bare rename: on Windows one can go in and never come out
  // (#103), and a capture's four downloads all stopped on theirs, the
  // pictures whole under their temp names and the app hung behind them.
  await swapFileIn(target.path, temp.path);
  return relative;
}

/// A hidden name in [folder] for a file on its way to `<digest><extension>`.
String _tempName(String folder, String digest, String extension) => p.join(
  folder,
  '.$digest$extension.niman-tmp-${DateTime.now().microsecondsSinceEpoch}',
);

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
  final extension = p.extension(sourcePath); // '' or '.png'
  final assets = Directory(p.join(libraryRoot, attachmentsFolder));
  await assets.create(recursive: true);
  final target = File(p.join(assets.path, '$digest$extension'));
  final relative = '$attachmentsFolder/$digest$extension';
  final bytes = await source.length();
  // A stat moves no buffer through the heap, unlike a read or a write.
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
  // half-copied image under its final name.
  final temp = _tempName(assets.path, digest, extension);
  await source.copy(temp);
  // Through the rename that gives up on a hung one (#103).
  await swapFileIn(target.path, temp);
  return (
    relative: relative,
    bytes: bytes,
    hashMs: hashMs,
    copyMs: copyClock.elapsedMilliseconds,
    reused: false,
  );
}
