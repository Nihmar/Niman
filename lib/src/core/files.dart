import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Suffix added to the target name when writing a temporary file.
const _tempMarker = '.niman-tmp';

/// Maximum length of a note or folder name, in UTF-8 bytes.
///
/// A filesystem caps one component at 255 bytes, and the budget stops short
/// of that so the extension a caller appends (`.md`) still fits under the cap.
/// It is a budget of bytes, not of UTF-16 code units: an astral character is
/// four bytes and two units, so a name of 200 units can be 800 bytes and be
/// refused outright (#354).
const _maxNameBytes = 200;

/// Characters that cannot appear in a note or folder name on Android or
/// Linux.
final RegExp _invalidChars = RegExp(r'[\/\\:*?"<>|]');

/// The names Windows reserves for devices.
///
/// A file or folder whose *stem* — the text before the first dot, whatever
/// its case — is one of these is that device rather than a file: `CON`,
/// `con.md` and `NUL.txt` all open the device, or fail to open at all (#354).
final Set<String> _reservedNames = <String>{
  'CON',
  'PRN',
  'AUX',
  'NUL',
  for (var i = 1; i <= 9; i++) 'COM$i',
  for (var i = 1; i <= 9; i++) 'LPT$i',
};

/// Prefixed to a reserved stem, so the name stops naming a device and starts
/// naming a file.
const _reservedPrefix = '_';

/// Trailing spaces and dots, which Windows drops from a component name:
/// `CON ` and `CON.` are the console device as much as `CON` is.
final RegExp _trailingSpaceOrDot = RegExp(r'[ .]+$');

/// Whether this platform's filesystems fold case: Windows and Apple's do,
/// Linux and Android do not.
///
/// A volume that was formatted case-sensitively is the exception, and the one
/// [_excludedEntry] asks the directory itself about.
final bool _caseInsensitivePaths =
    Platform.isWindows || Platform.isMacOS || Platform.isIOS;

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

/// The temp file [writeFileAtomically] writes for [file] at [micros]: a
/// dotfile in the target's own directory (what keeps the rename atomic on
/// the same filesystem). The leading dot puts it under the indexer's
/// hidden-entry rule, so a scan landing mid-write never indexes the temp
/// file.
///
/// The name is cut from the path by hand rather than with `package:path`:
/// this runs inside the write isolates, whose platform style resolves on
/// its first use there, and resolving it asks the process for its working
/// directory — which throws when that directory is gone, as it is when a
/// rebuild replaces the folder the app was launched from. A save must not
/// depend on where the app was started (#319).
File atomicTempPath(File file, int micros) {
  final path = file.path;
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf(r'\');
  final cut = slash > backslash ? slash : backslash;
  final directory = cut < 0 ? '' : path.substring(0, cut + 1);
  return File('$directory.${path.substring(cut + 1)}$_tempMarker-$micros');
}

/// Points the process's working directory at [directory] — one the app
/// owns.
///
/// Not the directory the binary was started from: that one belongs to
/// whoever launched it, and it can be gone while the app is still running
/// (a rebuild replacing the release bundle it was run from). `package:path`
/// resolves the platform's style by asking for the working directory, once
/// per isolate, so a directory that vanished takes the temp name of the
/// next save — and every other relative-path call — down with it: 20 failed
/// writes and five crash reports in one sitting (#319).
///
/// Throws when [directory] cannot be made the working directory; the caller
/// decides whether that is worth reporting.
void pinWorkingDirectory(Directory directory) {
  Directory.current = directory.path;
}

/// Writes [data] to [file] atomically.
///
/// Bytes are first written to a temporary file in the same directory,
/// which is then renamed over [file]. A rename within one filesystem is
/// atomic on Android and Linux, so readers never observe a partial write.
Future<void> writeFileAtomically(File file, List<int> data) async {
  final tmp = atomicTempPath(file, DateTime.now().microsecondsSinceEpoch);
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

/// Sanitizes [input] into a valid note or folder name.
///
/// Strips path separators and OS-illegal characters, collapses whitespace,
/// trims trailing dots, moves a reserved device name out of the way, and caps
/// the length at [_maxNameBytes] UTF-8 bytes. Returns [fallback] when nothing
/// usable remains.
String sanitizeName(String input, {required String fallback}) {
  var name = input.trim();
  name = name.replaceAll(_invalidChars, '');
  name = name.replaceAll(_whitespaceRuns, ' ');
  name = name.trim();
  name = name.replaceAll(_trailingDots, '');
  name = _withoutReservedStem(name);
  name = _truncateToBytes(name, _maxNameBytes);
  if (name.isEmpty) {
    return fallback;
  }
  return name;
}

/// [name] with a prefix in front when its stem names a Windows device.
String _withoutReservedStem(String name) {
  final dot = name.indexOf('.');
  final stem = (dot < 0 ? name : name.substring(0, dot)).replaceAll(
    _trailingSpaceOrDot,
    '',
  );
  if (!_reservedNames.contains(stem.toUpperCase())) {
    return name;
  }
  return '$_reservedPrefix$name';
}

/// [name] cut to at most [maxBytes] UTF-8 bytes, on a rune boundary.
///
/// A code unit is not a byte: counting units against a byte budget both
/// overshoots the filesystem's 255-byte component limit (200 astral
/// characters are 800 bytes) and cuts between the two halves of a surrogate
/// pair, leaving a lone surrogate that encoding turns into U+FFFD (#354).
String _truncateToBytes(String name, int maxBytes) {
  var used = 0;
  var end = 0;
  for (final rune in name.runes) {
    final size = _utf8Length(rune);
    if (used + size > maxBytes) {
      break;
    }
    used += size;
    end += rune > 0xFFFF ? 2 : 1;
  }
  return end == name.length ? name : name.substring(0, end);
}

/// The number of bytes [rune] takes in UTF-8.
int _utf8Length(int rune) {
  if (rune <= 0x7F) {
    return 1;
  }
  if (rune <= 0x7FF) {
    return 2;
  }
  if (rune <= 0xFFFF) {
    return 3;
  }
  return 4;
}

/// Whether [abs] — a candidate name inside [dir] — can only be [exclude], the
/// entry a rename is moving onto its own name.
///
/// `package:path` folds case on Windows, where an entry has one name however
/// it is spelled. Apple's filesystems answer for either spelling too, but
/// nothing in the two strings says so: compared as strings `A.md` and `a.md`
/// are different paths, so the search never recognises the entry it was told
/// to leave alone and returns `A_1.md` for a rename that only changes the
/// case (#354).
///
/// On a case-sensitive volume the two spellings really are two entries, and
/// there the directory's own listing settles it: a candidate found among the
/// entries belongs to somebody else, and the collision stands.
bool _excludedEntry(Directory dir, String abs, String? exclude) {
  if (exclude == null) {
    return false;
  }
  if (p.equals(abs, exclude)) {
    return true;
  }
  if (!_caseInsensitivePaths || abs.toLowerCase() != exclude.toLowerCase()) {
    return false;
  }
  final candidate = p.basename(abs);
  return !dir
      .listSync(followLinks: false)
      .any((entry) => p.basename(entry.path) == candidate);
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
    if (_excludedEntry(dir, abs, exclude)) return candidate;
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
    if (_excludedEntry(dir, abs, exclude)) return candidate;
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

/// Whether [name] (a file name or a library-relative path) is a Markdown
/// note.
///
/// The library holds other files too — attachments, and a `todo.txt` — and
/// they are indexed, listed and linkable. What they are not is notes: they
/// have no frontmatter, so anything that works by writing frontmatter has
/// to ask this first.
bool isMarkdownNote(String name) => name.toLowerCase().endsWith('.md');

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
/// `<base>.<unixSeconds><ext>` when [dir] already contains it — and a
/// `-<n>` counter while even that is taken, so two deletes of one name
/// inside one second cannot land on the same file (a rename replaces its
/// target, which silently destroyed the earlier copy, #335).
Future<String> trashFileName(Directory dir, String base, String ext) async {
  final plain = '$base$ext';
  if (!File(p.join(dir.path, plain)).existsSync()) {
    return plain;
  }
  final stamp = trashTimestampSuffix(DateTime.now());
  var counter = 1;
  var candidate = '$base.$stamp$ext';
  while (File(p.join(dir.path, candidate)).existsSync()) {
    counter += 1;
    candidate = '$base.$stamp-$counter$ext';
  }
  return candidate;
}

/// Picks a collision-safe trash folder name: [base], or
/// `<base>.<unixSeconds>` when [dir] already contains it — and a `-<n>`
/// counter while even that is taken (#335).
Future<String> trashDirName(Directory dir, String base) async {
  final plain = base;
  if (!Directory(p.join(dir.path, plain)).existsSync()) {
    return plain;
  }
  final stamp = trashTimestampSuffix(DateTime.now());
  var counter = 1;
  var candidate = '$base.$stamp';
  while (Directory(p.join(dir.path, candidate)).existsSync()) {
    counter += 1;
    candidate = '$base.$stamp-$counter';
  }
  return candidate;
}

/// Splits [fileName] into (base, extension) parts; extension includes the
/// leading dot, empty for extension-less names.
({String base, String ext}) splitFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot <= 0) {
    return (base: fileName, ext: '');
  }
  return (base: fileName.substring(0, dot), ext: fileName.substring(dot));
}

/// What a file looked like when it was last read or written: its size and
/// its modification time.
///
/// A watcher reports that something happened to a path, not that the note
/// changed: a touch, a rescan, a copy of the same content and an event
/// already acted on all arrive as "changed". Comparing what is on disk now
/// against what was last seen is O(1) — a stat — and it is what tells the two
/// apart without reading the file back and comparing its text, which on a
/// note of hundreds of megabytes is hundreds of milliseconds (see
/// `docs/records/huge-notes.md`).
final class DiskStamp {
  /// Records [size] and [modified].
  const new({required this.size, required this.modified});

  /// The file's size in bytes.
  final int size;

  /// When it was last written, to the millisecond.
  final DateTime modified;

  /// What the file at [path] looks like now, or null when there is nothing
  /// to stamp — the file is gone, or the filesystem will not answer.
  ///
  /// `statSync` answers for a missing file too, with a `notFound` type and a
  /// zero size: stamping that would make a deleted note look unchanged.
  static DiskStamp? of(String path) {
    try {
      final stat = File(path).statSync();
      if (stat.type == FileSystemEntityType.notFound) return null;
      return DiskStamp(size: stat.size, modified: stat.modified);
    } on Object {
      return null;
    }
  }

  /// Whether the file at [path] is still the one this stamped.
  ///
  /// Size and time together: a write that lands in the same second and
  /// changes the size is caught by the size, and one that keeps the size is
  /// caught by the time. A file whose bytes changed with both unchanged is
  /// the one case this cannot see, and no watcher reports it either.
  bool matches(String path) {
    final now = DiskStamp.of(path);
    return now != null &&
        now.size == size &&
        now.modified.millisecondsSinceEpoch == modified.millisecondsSinceEpoch;
  }
}
