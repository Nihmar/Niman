import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

// The synchronous file calls of `files.dart`, kept apart: everything here
// blocks the isolate it runs on, so everything here runs on a background
// isolate (every `statSync` or `listSync` is a FUSE round trip on Android,
// #1143). `ui_isolate_io_test.dart` lists this file as one of the places such
// calls may be, and `files.dart` as one they may not.

/// The number of bytes read per chunk when hashing a file.
const _hashChunkSize = 65536;

/// Collects the final [Digest] emitted by a chunked hash conversion.
final class _DigestCollector implements Sink<Digest> {
  /// The last emitted digest, or null before the conversion completes.
  Digest? last;

  @override
  void add(Digest data) {
    last = data;
  }

  @override
  void close() {}
}

/// Computes the hex sha256 digest of [file]'s content.
///
/// Reads in 64 KiB chunks so novel-length files never need a full-file
/// in-memory copy.
Future<String> hashFileSha256(File file) async {
  final raf = file.openSync();
  try {
    final collector = _DigestCollector();
    final sink = sha256.startChunkedConversion(collector);
    for (
      var chunk = raf.readSync(_hashChunkSize);
      chunk.isNotEmpty;
      chunk = raf.readSync(_hashChunkSize)
    ) {
      sink.add(chunk);
    }
    sink.close();
    final digest = collector.last;
    if (digest == null) {
      throw StateError('sha256 digest was not produced');
    }
    return digest.toString();
  } finally {
    raf.closeSync();
  }
}

/// Whether the directory at [dir] holds an entry named [name] exactly as
/// written.
///
/// Top-level and synchronous so `Isolate.run` can take it: its closure
/// carries two strings, and the `listSync` behind it cannot run on the UI
/// isolate. A filesystem that folds case answers for either spelling of a
/// path, so only the folder's own listing says whether the name belongs to
/// somebody else (#354, #492).
bool directoryHoldsName(String dir, String name) =>
    Directory(dir)
        .listSync(followLinks: false)
        .any((entry) => p.basename(entry.path) == name);
