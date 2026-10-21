/// The history's objects (#1148): every version a note's history keeps,
/// named by the sha256 of its content and kept once, whichever note or
/// version names it — the way git keeps blobs.
///
/// `.history/.objects/<first two hex>/<the other 62>`. An object is whole
/// or a delta against another object (a reverse delta: an older version
/// against the one after it), compressed either way:
///
/// ```text
/// "NHO1" | kind | [base sha256, 32 bytes, a delta's] | zlib(payload)
/// ```
///
/// The kind is 0 for a whole object compressed hard, 2 for a whole one
/// compressed fast — what a snapshot writes, since a save waits for it: 7 ms
/// for 1.5 MB of prose where the hard level takes 62 — and 1 for a delta.
/// The upkeep turns a fast one into a delta or a hard one.
///
/// A new object is not flushed: an object is trusted only when what it
/// rebuilds hashes to its name, so one a crash cut short reads as a missing
/// version — what a drifted version always read as (#378) — never as
/// content, and the note it was kept from still holds that content. An
/// object the upkeep REPLACES — a whole one turned into a delta, or
/// compressed hard — is flushed before it is renamed over the good copy,
/// as is every object the old history's move writes before it deletes the
/// old files: for those the copy that goes is the only other one.
///
/// Synchronous and top-level, like the rest of the store: it runs on a
/// background isolate.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:niman/src/history/text_delta.dart';
import 'package:path/path.dart' as p;

/// The history folder's name inside the library root.
const String historyFolderName = '.history';

/// The objects folder's name inside `.history/`: a dot name, so no note's
/// folder can take it.
const String historyObjectsFolderName = '.objects';

/// The longest chain of deltas a read follows before it gives up: the packer
/// keeps them to [maxDeltaChain], so a longer one is damage, or a loop.
const int _readableChain = 64;

/// The most deltas the packer stacks before a whole object (#1148): a read of
/// the oldest version applies at most this many.
const int maxDeltaChain = 15;

const List<int> _magic = [0x4E, 0x48, 0x4F, 0x31];
const int _whole = 0;
const int _delta = 1;
const int _fastWhole = 2;
const int _wholeHeader = 5;
const int _deltaHeader = 37;

/// The folder holding the objects of the library at [root].
String historyObjectsPath(String root) =>
    p.join(root, historyFolderName, historyObjectsFolderName);

/// The file of object [sha].
String historyObjectPath(String root, String sha) =>
    p.join(historyObjectsPath(root), sha.substring(0, 2), sha.substring(2));

/// The hex sha256 of [bytes].
String shaOf(List<int> bytes) => sha256.convert(bytes).toString();

/// Whether object [sha] is on disk (not whether it reads).
bool hasObject(String root, String sha) =>
    sha.length == 64 && File(historyObjectPath(root, sha)).existsSync();

/// Keeps [bytes], whose sha256 is [sha], as an object, compressed fast;
/// answers whether it wrote one.
///
/// An object already there that reads back as [sha] is the same content and
/// is kept as it is. One that does not — a write a crash cut short — is
/// replaced, whole.
bool writeObject(String root, String sha, List<int> bytes) {
  final file = File(historyObjectPath(root, sha));
  if (file.existsSync() && readObject(root, sha) != null) {
    _touch(file);
    return false;
  }
  _write(file, [
    ..._magic,
    _fastWhole,
    ...ZLibEncoder(level: 1).convert(bytes),
  ]);
  return true;
}

/// Whether object [sha] is whole and compressed fast: what the upkeep
/// compresses again, or stores as a delta.
bool isFastWhole(String root, String sha) =>
    _header(File(historyObjectPath(root, sha)))?.fast ?? false;

/// Flushes the object [sha] already on disk: written once without, and
/// about to be the only copy of a version.
void flushObject(String root, String sha) {
  File(historyObjectPath(root, sha))
      .writeAsBytesSync(const <int>[], mode: FileMode.append, flush: true);
}

/// Stores the fast-compressed object [sha], whose content is [content],
/// compressed hard: no longer one the upkeep compresses again, and kept as
/// it was when the hard level saves nothing. Flushed before it replaces
/// the copy it came from.
void storeHard(String root, String sha, Uint8List content) {
  final file = File(historyObjectPath(root, sha));
  final bytes = file.readAsBytesSync();
  final header = _parseHeader(bytes);
  if (header == null || !header.fast) return;
  final payload = ZLibEncoder(level: 9).convert(content);
  _write(file, flush: true, [
    ..._magic,
    _whole,
    if (_wholeHeader + payload.length < bytes.length)
      ...payload
    else
      ...Uint8List.sublistView(bytes, _wholeHeader),
  ]);
}

/// The content of object [sha], rebuilt through its deltas; null when it is
/// gone, damaged, or rebuilds to anything that does not hash to [sha].
Uint8List? readObject(String root, String sha) {
  final chain = <_Stored>[];
  final seen = <String>{};
  var current = sha;
  while (true) {
    if (!seen.add(current) || seen.length > _readableChain) return null;
    final stored = _load(root, current);
    if (stored == null) return null;
    chain.add(stored);
    final base = stored.base;
    if (base == null) break;
    current = base;
  }
  var content = chain.last.payload;
  try {
    for (var i = chain.length - 2; i >= 0; i--) {
      content = applyDelta(content, chain[i].payload);
    }
  } on FormatException {
    return null;
  }
  return shaOf(content) == sha ? content : null;
}

/// The object [sha] is a delta against, or null when it is whole, gone or
/// unreadable. Reads the header alone.
String? deltaBaseOf(String root, String sha) {
  final header = _header(File(historyObjectPath(root, sha)));
  return header?.base;
}

/// How many deltas a read of [sha] applies: 0 for a whole object, null when
/// its chain is broken or loops.
int? chainDepth(String root, String sha) {
  final seen = <String>{};
  var current = sha;
  var depth = 0;
  while (true) {
    if (!seen.add(current) || seen.length > _readableChain) return null;
    final header = _header(File(historyObjectPath(root, current)));
    if (header == null) return null;
    final base = header.base;
    if (base == null) return depth;
    depth++;
    current = base;
  }
}

/// Stores object [sha] as a delta against [baseSha] when that is smaller
/// than half of what it takes now; answers whether it did.
///
/// [content] and [baseContent], when the caller has them, spare reading
/// them again. Never makes a loop: a base whose own chain reaches [sha] is
/// refused.
bool storeAsDelta(
  String root,
  String sha,
  String baseSha, {
  Uint8List? content,
  Uint8List? baseContent,
}) {
  if (sha == baseSha) return false;
  final file = File(historyObjectPath(root, sha));
  final header = _header(file);
  if (header == null || header.base != null) return false;
  // The base must not lead back here: a loop reads as nothing.
  final seen = <String>{};
  for (String? at = baseSha; at != null; at = deltaBaseOf(root, at)) {
    if (at == sha || !seen.add(at) || seen.length > _readableChain) {
      return false;
    }
  }
  final target = content ?? readObject(root, sha);
  final base = baseContent ?? readObject(root, baseSha);
  if (target == null || base == null) return false;
  final payload = ZLibEncoder(level: 9).convert(computeDelta(base, target));
  final now = file.lengthSync();
  if (_deltaHeader + payload.length > now ~/ 2) return false;
  final prefix = [..._magic, _delta, ..._hexBytes(baseSha)];
  _write(file, flush: true, [...prefix, ...payload]);
  _touch(File(historyObjectPath(root, baseSha)));
  return true;
}

/// Marks [file] as just used: the collection keeps an object younger than
/// its grace, so one a log is about to name — a snapshot of content kept
/// before, or a delta's new base — is not taken in between.
void _touch(File file) {
  try {
    file.setLastModifiedSync(DateTime.now());
  } on FileSystemException {
    // Best effort: the grace is a guard, not the store's correctness.
  }
}

/// Every object on disk, by sha.
Map<String, File> listObjects(String root) {
  final dir = Directory(historyObjectsPath(root));
  if (!dir.existsSync()) return const {};
  final out = <String, File>{};
  for (final fan in dir.listSync(followLinks: false)) {
    if (fan is! Directory) continue;
    final head = p.basename(fan.path);
    if (head.length != 2) continue;
    for (final entry in fan.listSync(followLinks: false)) {
      if (entry is! File) continue;
      final sha = '$head${p.basename(entry.path)}';
      if (_isSha(sha)) out[sha] = entry;
    }
  }
  return out;
}

/// What one object holds: its base when a delta, and its payload.
typedef _Stored = ({String? base, Uint8List payload});

_Stored? _load(String root, String sha) {
  final Uint8List bytes;
  try {
    bytes = File(historyObjectPath(root, sha)).readAsBytesSync();
  } on FileSystemException {
    return null;
  }
  final header = _parseHeader(bytes);
  if (header == null) return null;
  try {
    final payload = ZLibDecoder().convert(
      Uint8List.sublistView(bytes, header.length),
    );
    return (base: header.base, payload: Uint8List.fromList(payload));
  } on FormatException {
    return null;
  }
}

typedef _Header = ({String? base, int length, bool fast});

_Header? _header(File file) {
  RandomAccessFile? handle;
  try {
    handle = file.openSync();
    return _parseHeader(handle.readSync(_deltaHeader));
  } on FileSystemException {
    return null;
  } finally {
    handle?.closeSync();
  }
}

_Header? _parseHeader(Uint8List bytes) {
  if (bytes.length < _wholeHeader) return null;
  for (var i = 0; i < _magic.length; i++) {
    if (bytes[i] != _magic[i]) return null;
  }
  return switch (bytes[4]) {
    _whole => (base: null, length: _wholeHeader, fast: false),
    _fastWhole => (base: null, length: _wholeHeader, fast: true),
    _delta when bytes.length >= _deltaHeader => (
      base: _hex(Uint8List.sublistView(bytes, 5, _deltaHeader)),
      length: _deltaHeader,
      fast: false,
    ),
    _ => null,
  };
}

/// Writes [bytes] to a temp file beside [file] and renames it over: a
/// reader sees the old object or the new one, never half of either. Flushed
/// before the rename when [flush] (see the library's doc).
void _write(File file, List<int> bytes, {bool flush = false}) {
  file.parent.createSync(recursive: true);
  final temp = File(
    p.join(
      file.parent.path,
      '.${p.basename(file.path)}.niman-tmp-'
      '${DateTime.now().microsecondsSinceEpoch}',
    ),
  );
  try {
    temp
      ..writeAsBytesSync(bytes, flush: flush)
      ..renameSync(file.path);
  } on Object {
    if (temp.existsSync()) temp.deleteSync();
    rethrow;
  }
}

final RegExp _sha = RegExp(r'^[0-9a-f]{64}$');

bool _isSha(String text) => _sha.hasMatch(text);

String _hex(Uint8List bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();

List<int> _hexBytes(String hex) => [
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
];
