/// A note's history log (#1148): `.history/<path>.log`, one JSON object a
/// line, appended to and never rewritten on a save's path.
///
/// ```text
/// {"v":14,"t":1729500000000,"r":"session","n":5120,"h":"<sha256>"}  kept
/// {"pin":"syncBase","v":12}                                         pinned
/// {"pin":"syncBase","v":null}                                       unpinned
/// {"drop":[3,4]}                                                    rotated
/// ```
///
/// Read by folding the lines in order into a [HistoryManifest]. A line that
/// does not decode — the tail of an append a crash cut short — is skipped,
/// and each append starts on a line of its own, so a torn line never takes
/// the next one with it. The log is rewritten whole only to compact it, or
/// when a move merges two histories, and then atomically and flushed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:path/path.dart' as p;

/// The log of the note at library-relative [rel].
String historyLogPath(String root, String rel) =>
    p.join(root, historyFolderName, '$rel.log');

/// A log line keeping [version].
String keptLine(HistoryVersion version) => jsonEncode({
  'v': version.number,
  't': version.savedAt.millisecondsSinceEpoch,
  'r': version.reason.name,
  'n': version.size,
  'h': version.sha256,
});

/// A log line moving [pin] to [number] (null releases it).
String pinLine(String pin, int? number) =>
    jsonEncode({'pin': pin, 'v': number});

/// A log line rotating the versions numbered [numbers] out.
String dropLine(Iterable<int> numbers) =>
    jsonEncode({'drop': numbers.toList()});

/// What a log holds: the history it folds to, and how many lines it took.
typedef FoldedLog = ({HistoryManifest manifest, int lines});

/// Folds the log [text] into the history it describes.
FoldedLog foldLog(String text) {
  final versions = <int, HistoryVersion>{};
  final pins = <String, int>{};
  var lines = 0;
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty) continue;
    lines++;
    final Object? json;
    try {
      json = jsonDecode(line);
    } on FormatException {
      continue;
    }
    if (json is! Map) continue;
    final pin = json['pin'];
    final drop = json['drop'];
    if (pin is String) {
      final number = json['v'];
      if (number is int && number > 0) {
        pins[pin] = number;
      } else if (number == null) {
        pins.remove(pin);
      }
    } else if (drop is List) {
      for (final number in drop.whereType<int>()) {
        versions.remove(number);
        pins.removeWhere((_, pinned) => pinned == number);
      }
    } else {
      final version = _version(json);
      if (version != null) versions[version.number] = version;
    }
  }
  return (
    manifest: HistoryManifest(
      versions: versions.values,
      pins: {
        for (final e in pins.entries)
          if (versions.containsKey(e.value)) e.key: e.value,
      },
    ),
    lines: lines,
  );
}

HistoryVersion? _version(Map<Object?, Object?> json) {
  final number = json['v'];
  final savedAt = json['t'];
  final size = json['n'];
  final sha = json['h'];
  if (number is! int || number < 1 || savedAt is! int || size is! int) {
    return null;
  }
  if (sha is! String || sha.length != 64) return null;
  return HistoryVersion(
    number: number,
    savedAt: DateTime.fromMillisecondsSinceEpoch(savedAt),
    reason: HistoryReason.parse(json['r']),
    size: size,
    sha256: sha,
  );
}

/// The log of [rel] as it stands, or null when it has none.
FoldedLog? readLog(String root, String rel) {
  final file = File(historyLogPath(root, rel));
  final String text;
  try {
    text = file.readAsStringSync();
  } on PathNotFoundException {
    return null;
  } on FormatException {
    // Bytes that are not UTF-8 at all: the lines that are survive.
    return foldLog(utf8.decode(file.readAsBytesSync(), allowMalformed: true));
  }
  return foldLog(text);
}

/// Appends [lines] to the log of [rel], creating it. Not flushed: a line a
/// crash cuts short is skipped when read, and starts no other line.
void appendLog(String root, String rel, List<String> lines) {
  if (lines.isEmpty) return;
  final file = File(historyLogPath(root, rel));
  file.parent.createSync(recursive: true);
  final handle = file.openSync(mode: FileMode.append);
  try {
    handle.writeStringSync('\n${lines.join('\n')}\n');
  } finally {
    handle.closeSync();
  }
}

/// Replaces the log of [rel] with the lines that rebuild [manifest]: kept
/// versions oldest first, then the pins. Atomic and flushed, since it is
/// the only copy of the list; removes the log when [manifest] is empty.
void writeLog(String root, String rel, HistoryManifest manifest) {
  final file = File(historyLogPath(root, rel));
  if (manifest.versions.isEmpty) {
    if (file.existsSync()) file.deleteSync();
    return;
  }
  file.parent.createSync(recursive: true);
  final text = [
    for (final v in manifest.versions) keptLine(v),
    for (final e in manifest.pins.entries) pinLine(e.key, e.value),
  ].join('\n');
  final temp = File(
    p.join(
      file.parent.path,
      '.${p.basename(file.path)}.niman-tmp-'
      '${DateTime.now().microsecondsSinceEpoch}',
    ),
  );
  try {
    final handle = temp.openSync(mode: FileMode.writeOnly);
    try {
      handle
        ..writeStringSync('$text\n')
        ..flushSync();
    } finally {
      handle.closeSync();
    }
    temp.renameSync(file.path);
  } on Object {
    if (temp.existsSync()) temp.deleteSync();
    rethrow;
  }
}

/// Whether [log] has grown enough past the history it holds to be
/// rewritten: rotation appends a line a version,
/// and a history of ten versions would otherwise read thousands.
bool logWantsCompacting(FoldedLog log) =>
    log.lines >
    2 * (log.manifest.versions.length + log.manifest.pins.length) + 16;
