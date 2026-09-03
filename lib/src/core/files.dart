import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Suffix added to the target name when writing a temporary file.
const _tempMarker = '.copist-tmp';

/// Maximum length of a note or folder name.
///
/// Ext4 caps components at 255 bytes; 200 chars leaves headroom for
/// multibyte encodings.
const _maxNameLength = 200;

/// Characters that cannot appear in a note or folder name on Android or
/// Linux.
final RegExp _invalidChars = RegExp(r'[\/\\:*?"<>|]');

/// Collapses runs of whitespace to single spaces.
final RegExp _whitespaceRuns = RegExp(r'\s+');

/// Two or more trailing dots, which are rejected or mangled by Windows.
final RegExp _trailingDots = RegExp(r'\.{2,}$');

/// The number of uniqueness attempts when resolving name collisions.
const _uniqueAttempts = 100;

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

/// The fallback note name used when [sanitizeName] produces an empty name.
const defaultNoteName = 'Untitled';

/// The fallback folder name used when [sanitizeName] produces an empty name.
const defaultFolderName = 'New folder';

/// Writes [data] to [file] atomically.
///
/// Bytes are first written to a temporary file in the same directory,
/// which is then renamed over [file]. A rename within one filesystem is
/// atomic on Android and Linux, so readers never observe a partial write.
Future<void> writeFileAtomically(File file, List<int> data) async {
  final tmp = File(
    '${file.path}$_tempMarker-${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    await tmp.writeAsBytes(data, flush: true);
    await tmp.rename(file.path);
  } catch (_) {
    if (tmp.existsSync()) {
      await tmp.delete();
    }
    rethrow;
  }
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
    for (var chunk = raf.readSync(_hashChunkSize);
        chunk.isNotEmpty;
        chunk = raf.readSync(_hashChunkSize)) {
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

/// Sanitizes [input] into a valid note or folder name.
///
/// Strips path separators and OS-illegal characters, collapses whitespace,
/// trims trailing dots, and caps the length at [_maxNameLength]. Returns
/// [fallback] when nothing usable remains.
String sanitizeName(String input, {required String fallback}) {
  var name = input.trim();
  name = name.replaceAll(_invalidChars, '');
  name = name.replaceAll(_whitespaceRuns, ' ');
  name = name.trim();
  name = name.replaceAll(_trailingDots, '');
  if (name.length > _maxNameLength) {
    name = name.substring(0, _maxNameLength);
  }
  if (name.isEmpty) {
    return fallback;
  }
  return name;
}

/// Returns a collision-free file name for [base] with extension [ext]
/// inside [dir].
///
/// Tries `<base><ext>` first, then appends numeric suffixes
/// (`<base>_1<ext>`, …) until a name is free on disk. [exclude] (an
/// absolute path) is treated as already free — used to rename an entry onto
/// its own current name.
/// Throws a [StateError] if no free name is found within [_uniqueAttempts]
/// attempts.
Future<String> uniqueFileName(
  Directory dir,
  String base,
  String ext, {
  String? exclude,
}) async {
  for (var i = 0; i < _uniqueAttempts; i++) {
    final candidate = i == 0 ? '$base$ext' : '${base}_$i$ext';
    final abs = p.join(dir.path, candidate);
    if (abs == exclude) return candidate;
    final exists = File(abs).existsSync() || Directory(abs).existsSync();
    if (!exists) {
      return candidate;
    }
  }
  throw StateError('Could not find a free name for "$base" in "${dir.path}"');
}

/// Returns a collision-free folder name for [base] inside [dir].
///
/// Same numeric-suffix strategy as [uniqueFileName] for directories.
Future<String> uniqueFolderName(
  Directory dir,
  String base, {
  String? exclude,
}) async {
  for (var i = 0; i < _uniqueAttempts; i++) {
    final candidate = i == 0 ? base : '${base}_$i';
    final abs = p.join(dir.path, candidate);
    if (abs == exclude) return candidate;
    if (!Directory(abs).existsSync()) {
      return candidate;
    }
  }
  throw StateError('Could not find a free name for "$base" in "${dir.path}"');
}

/// The relative, slash-separated name of [path] inside [root].
///
/// Throws an [ArgumentError] when [path] is not under [root].
String relPath(String path, String root) {
  final rel = p.relative(p.normalize(path), from: p.normalize(root));
  if (rel == '.') return '';
  if (rel.startsWith('..')) {
    throw ArgumentError('$path is not inside $root');
  }
  return p.split(rel).join('/');
}

/// Joins library-relative segments into a slash-separated path.
String joinRel(List<String> segments) {
  return segments.where((s) => s.isNotEmpty).join('/');
}

/// Returns [path] without the first [count] path segments, or `''` when
/// [path] has fewer segments than [count].
String stripSegments(String path, int count) {
  final parts = p.split(path);
  if (parts.length <= count) {
    return '';
  }
  return parts.sublist(count).join('/');
}

/// Whether [path] is strictly inside [parent], at any depth (empty parent
/// = the library root).
bool isUnder(String parent, String path) {
  final prefix = parent.isEmpty ? '' : '$parent/';
  return path.startsWith(prefix) && path.length > prefix.length;
}

/// The longest prefix of [path] that is a library-relative directory path,
/// i.e. its parent path.
String parentOf(String path) {
  final idx = path.lastIndexOf('/');
  return idx < 0 ? '' : path.substring(0, idx);
}

/// Resolves [name] (no separators) against [parentPath] (empty = root).
String resolvePath(String parentPath, String name) {
  return parentPath.isEmpty ? name : '$parentPath/$name';
}

/// Truncates [dt] to whole seconds, the precision at which drift stores
/// `dateTime` columns (unix epoch seconds, mapped back to local time on
/// read).
DateTime toStoredSecond(DateTime dt) {
  final seconds = dt.millisecondsSinceEpoch ~/ 1000;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

/// Returns a deterministic numeric timestamp suffix for collision-safe
/// trash names, e.g. `1714673096`.
int trashTimestampSuffix(DateTime now) {
  return now.millisecondsSinceEpoch ~/ 1000;
}

/// Picks a collision-safe trash file name: [base] with [ext], or
/// `<base>.<unixSeconds><ext>` when [dir] already contains it.
Future<String> trashFileName(Directory dir, String base, String ext) async {
  final plain = '$base$ext';
  if (!File(p.join(dir.path, plain)).existsSync()) {
    return plain;
  }
  return '$base.${trashTimestampSuffix(DateTime.now())}$ext';
}

/// Picks a collision-safe trash folder name: [base], or
/// `<base>.<unixSeconds>` when [dir] already contains it.
Future<String> trashDirName(Directory dir, String base) async {
  final plain = base;
  if (!Directory(p.join(dir.path, plain)).existsSync()) {
    return plain;
  }
  return '$base.${trashTimestampSuffix(DateTime.now())}';
}

/// Splits [fileName] into (base, extension) parts; extension includes the
/// leading dot, empty for extension-less names.
({String base, String ext}) splitFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0) {
    return (base: fileName, ext: '');
  }
  return (
    base: fileName.substring(0, dot),
    ext: fileName.substring(dot),
  );
}
