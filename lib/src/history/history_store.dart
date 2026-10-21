/// The `.history/` folder on disk (docs/records/history-store.md).
///
/// A note's versions are objects named by their content, kept once
/// (`history_objects.dart`), and listed by the note's append-only log
/// (`history_log.dart`); a history kept the old way is moved in the first
/// time it is touched (`history_legacy.dart`). This file keeps a version
/// before a save and reads them back; pins are `history_pins.dart`'s, moves
/// and deletes `history_moves.dart`'s. Every write runs holding the note's
/// lock (`history_lock.dart`).
///
/// Everything here is synchronous and top-level: it runs inside
/// `Isolate.run`, where the app's log buffer is not the main one, so the
/// functions return what happened (with log-ready notes) instead of
/// logging it.
library;

import 'dart:io';

import 'package:niman/src/history/external_write_check.dart';
import 'package:niman/src/history/history_access.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_log.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_objects.dart';
import 'package:niman/src/history/snapshot_outcome.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/history/history_moves.dart';
export 'package:niman/src/history/history_objects.dart' show historyFolderName;
export 'package:niman/src/history/history_pins.dart';
export 'package:niman/src/history/snapshot_outcome.dart';

/// The versions kept for [rel] (oldest first) and its pins. A version whose
/// object is gone is not listed.
HistoryManifest readHistoryManifest(String root, String rel) =>
    presentVersions(root, loadHistoryLog(root, rel));

/// Keeps the current content of the note at [rel] as a version when
/// the request says so, then rotates. Call it right before overwriting the
/// note.
SnapshotOutcome snapshotBeforeWrite(
  String root,
  String rel,
  SnapshotRequest asked,
) {
  final clock = Stopwatch()..start();
  final note = File(p.join(root, rel));
  final exists = note.existsSync();
  // A file that is not the one the editor last saw, nor the one the app last
  // wrote, was written by somebody else, and the save about to replace it is
  // the last chance to keep what they wrote (#1055). A reason already forced
  // (a restore, a sync) stands.
  final check = exists ? ExternalWriteCheck.of(note, asked) : null;
  final foreign = check?.foreign ?? false;
  final request = foreign
      ? SnapshotRequest(
          limit: asked.limit,
          interval: asked.interval,
          now: asked.now,
          sessionStart: asked.sessionStart,
          forced: asked.forced ?? HistoryReason.external,
        )
      : asked;
  if (!exists) {
    return SnapshotOutcome(
      decision: decideSnapshot(
        manifest: HistoryManifest(),
        oldSha: null,
        request: request,
      ),
      external: check?.note,
      elapsedMs: clock.elapsedMilliseconds,
    );
  }
  return withHistoryLock(root, [rel], () {
    final log = loadHistoryLog(root, rel);
    final manifest = withoutMissingNewest(root, log);
    // The manifest alone often decides: the note is read only when it can.
    final early = skipWithoutReading(manifest: manifest, request: request);
    if (early != null) {
      return SnapshotOutcome(
        decision: early,
        external: check?.note,
        elapsedMs: clock.elapsedMilliseconds,
      );
    }
    final bytes = check?.bytes ?? note.readAsBytesSync();
    final oldSha = shaOf(bytes);
    final decision = decideSnapshot(
      manifest: manifest,
      oldSha: oldSha,
      request: request,
    );
    if (!decision.take) {
      // Unchanged since the newest version, whose object is there: whether
      // it still reads is the upkeep's to check (`history_upkeep.dart`),
      // not a save's to wait on.
      return SnapshotOutcome(
        decision: decision,
        external: check?.note,
        elapsedMs: clock.elapsedMilliseconds,
      );
    }
    final version = HistoryVersion(
      number: nextVersionNumber(log, manifest),
      savedAt: request.now,
      reason: decision.reason!,
      size: bytes.length,
      sha256: oldSha,
    );
    final keepAt = clock.elapsedMilliseconds;
    writeObject(root, version.sha256, bytes);
    final logAt = clock.elapsedMilliseconds;
    var next = manifest.adding(version);
    final rotated = [
      for (final old in next.overflow(request.limit)) old.number,
    ];
    next = next.removing(rotated.toSet());
    recordHistory(root, rel, log, next, [
      keptLine(version),
      if (rotated.isNotEmpty) dropLine(rotated),
    ]);
    return SnapshotOutcome(
      decision: decision,
      version: version,
      rotated: rotated,
      external: check?.note,
      elapsedMs: clock.elapsedMilliseconds,
      keepMs: logAt - keepAt,
      manifestMs: clock.elapsedMilliseconds - logAt,
    );
  });
}

/// The bytes of version [number] of [rel], or null when it is gone — or
/// when what its object rebuilds no longer hashes to the sha256 the log
/// records (a write a crash cut short, an edit by hand).
///
/// A drifted version is never handed back as the content its hash claims:
/// it is treated the way a missing one is, so a caller that would use it as
/// a merge base gets no base and the path becomes a conflict instead (see
/// #378).
List<int>? readHistoryVersion(String root, String rel, int number) {
  final version = loadHistoryLog(root, rel).manifest.version(number);
  if (version == null) return null;
  return readObject(root, version.sha256);
}
