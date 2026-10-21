/// Pinning a note's versions (docs/records/sync.md, "Rotation and the pinned
/// base"): a pin keeps its version through rotation; the sync's base is
/// one. Each runs holding the note's lock (`history_lock.dart`).
library;

import 'dart:io';

import 'package:niman/src/history/history_access.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:path/path.dart' as p;

/// Pins version [number] of [rel] under [pin] (null unpins), then rotates
/// the version the pin released when it no longer fits [limit].
///
/// Returns the version numbers rotated out.
List<int> pinHistoryVersion(
  String root,
  String rel,
  String pin,
  int? number, {
  required int limit,
}) => withHistoryLock(root, [rel], () {
  final log = loadHistoryLog(root, rel);
  final manifest = presentVersions(root, log);
  if (number != null && manifest.version(number) == null) {
    throw StateError('"$rel" has no v$number to pin');
  }
  var next = manifest.pinning(pin, number);
  final rotated = [for (final v in next.overflow(limit)) v.number];
  next = next.removing(rotated.toSet());
  recordHistory(root, rel, log, next, [
    pinLine(pin, number),
    if (rotated.isNotEmpty) dropLine(rotated),
  ]);
  return rotated;
});

/// Pins, as the sync base of [rel], the version whose content hashes to
/// [sha] — the content both sides agreed on at a successful sync
/// (docs/records/sync.md, "Rotation and the pinned base").
///
/// The newest version with that content is pinned. When there is none and
/// the note on disk still holds that content, it is kept as a new version
/// (reason `sync`) first. When neither holds it — the note was edited
/// again before the pin — nothing is pinned and the old pin is released.
/// Rotation then runs against [limit]; the pin never rotates out.
///
/// Returns the pinned version number (null when none), whether a version
/// was written, and the numbers rotated out.
({int? pinned, bool wrote, List<int> rotated}) pinSyncBaseVersion(
  String root,
  String rel,
  String sha, {
  required int limit,
  required DateTime now,
}) => withHistoryLock(root, [rel], () {
  final log = loadHistoryLog(root, rel);
  var manifest = presentVersions(root, log);
  final lines = <String>[];
  int? number;
  for (final version in manifest.versions.reversed) {
    if (version.sha256 != sha) continue;
    // An object that no longer rebuilds its content is never pinned as the
    // base (#378): the same content may still be read through another
    // version, so the search goes on.
    if (readObject(root, version.sha256) == null) continue;
    number = version.number;
    break;
  }
  var wrote = false;
  if (number == null) {
    final note = File(p.join(root, rel));
    final bytes = note.existsSync() ? note.readAsBytesSync() : null;
    if (bytes != null && shaOf(bytes) == sha) {
      final version = HistoryVersion(
        number: nextVersionNumber(log, manifest),
        savedAt: now,
        reason: HistoryReason.sync,
        size: bytes.length,
        sha256: sha,
      );
      writeObject(root, sha, bytes);
      manifest = manifest.adding(version);
      lines.add(keptLine(version));
      number = version.number;
      wrote = true;
    }
  }
  if (number == null && manifest.pins[syncBasePin] == null) {
    return (pinned: null, wrote: false, rotated: const <int>[]);
  }
  var next = manifest.pinning(syncBasePin, number);
  final rotated = [for (final v in next.overflow(limit)) v.number];
  next = next.removing(rotated.toSet());
  recordHistory(root, rel, log, next, [
    ...lines,
    pinLine(syncBasePin, number),
    if (rotated.isNotEmpty) dropLine(rotated),
  ]);
  return (pinned: number, wrote: wrote, rotated: rotated);
});
