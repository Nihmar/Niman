import 'dart:convert';
import 'dart:io';

import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_conflict_merge.dart';
import 'package:niman/src/sync/sync_run_context.dart';
import 'package:niman/src/sync/sync_sides.dart';
import 'package:niman/src/sync/sync_step_failure.dart';
import 'package:niman/src/sync/sync_step_outcome.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:path/path.dart' as p;

/// Carries out one decision of a run's plan at a time: uploads,
/// downloads, deletions, trashing, moves and recorded agreements, each
/// skipped when a side is no longer what the plan saw; conflicts go to
/// the [merger].
final class SyncStepRunner {
  /// A runner for the library at [root]; [hashPasses] is how many
  /// hashing passes the run makes before a path still waiting for a hash
  /// fails.
  new({
    required this.root,
    required this.ops,
    required this.store,
    required this.sides,
    required this.merger,
    required this.hashPasses,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's operations: downloads, trash and moves go through them.
  final NoteOps ops;

  /// The sync state, where the agreed rows go.
  final SyncStore store;

  /// Reads, checks and records both sides of a path.
  final SyncSides sides;

  /// Settles the paths both sides changed.
  final SyncConflictMerger merger;

  /// How many hashing passes a run makes.
  final int hashPasses;

  /// Carries out [d] within the run [c].
  Future<SyncStepOutcome> apply(SyncRunContext c, SyncDecision d) async {
    switch (d.kind) {
      case SyncActionKind.nothing:
        return SyncStepOutcome.done;
      case SyncActionKind.hashLocal:
      case SyncActionKind.hashRemote:
        throw SyncStepFailure(
          'still waiting for a hash after $hashPasses passes',
        );
      case SyncActionKind.upload:
        return await _upload(c, d);
      case SyncActionKind.download:
        return await _download(c, d);
      case SyncActionKind.deleteRemote:
        return await _deleteRemote(c, d);
      case SyncActionKind.trashLocal:
        return await _trashLocal(c, d);
      case SyncActionKind.dropRow:
        await store.removeItems(root, [d.path]);
        return SyncStepOutcome.done;
      case SyncActionKind.record:
        return await _record(c, d);
      case SyncActionKind.conflict:
        return await merger.conflict(c, d);
      case SyncActionKind.moveRemote:
        return await _moveRemote(c, d);
      case SyncActionKind.moveLocal:
        return await _moveLocal(c, d);
    }
  }

  /// The remote still is what the scan saw, checked with a PROPFIND when
  /// the write has no precondition to guard it.
  Future<void> _remoteStillAsPlanned(
    SyncRunContext c,
    SyncDecision d, {
    String? expectedSha,
  }) async {
    if (!d.checkRemoteFirst) return;
    await sides.remoteUnchangedSince(
      c,
      d.fromPath ?? d.path,
      expectedSha: expectedSha,
    );
  }

  /// Whether [file] holds a JSON object — what a [jsonStateFiles] side has to
  /// be before the sync may replace the other with it (#336).
  static Future<bool> _isJsonObject(File file) async {
    try {
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      return jsonDecode(text) is Map;
    } on Object {
      return false;
    }
  }

  Future<SyncStepOutcome> _upload(
    SyncRunContext c,
    SyncDecision d,
  ) => sides.guarded(() async {
    final local = (await sides.localStillAsPlanned(c, d.path))!;
    await _remoteStillAsPlanned(c, d);
    final sha = sides.localShaOf(c, d.path);
    // The #336 rule holds both ways: a JSON state file that does not parse
    // here — a hand edit with a syntax error — is not a newer version of the
    // remote copy either, and `.niman/*` has no history to bring that one
    // back. Both sides stay, and the path is reported for the merge.
    if (jsonStateFiles.contains(d.path) &&
        c.remote[d.path] != null &&
        !await _isJsonObject(File(p.join(root, d.path)))) {
      return sides.reportConflict(
        c,
        d,
        localSha: sha,
        remoteSha: c.rows[d.path]?.localSha256 ?? '',
        why: 'the local copy is not a JSON object',
      );
    }
    await sides.uploadAndRecord(
      c,
      d.path,
      sha: sha,
      local: local,
      notListed: const SyncStepFailure('uploaded but not listed'),
      ifMatch: d.ifMatch,
      ifNoneMatch: d.ifNoneMatch,
      modified: DateTime.fromMillisecondsSinceEpoch(local.mtimeMs),
    );
    return SyncStepOutcome.done;
  });

  Future<SyncStepOutcome> _download(SyncRunContext c, SyncDecision d) =>
      sides.guarded(() async {
        final fetched = await sides.fetch(c, d.path);
        try {
          await sides.localStillAsPlanned(c, d.path);
        } on Object {
          if (fetched.temp.existsSync()) await fetched.temp.delete();
          rethrow;
        }
        // A JSON state file whose remote copy does not parse is not a newer
        // version of this device's: replacing a good local copy with it —
        // there is no history for `.niman/*` — is how a half-written settings
        // file wiped every setting on the run after (#336). Both sides stay,
        // and the path is reported for the merge.
        if (jsonStateFiles.contains(d.path) &&
            // The async stat is on purpose: a blocking one on the UI isolate
            // is the FUSE round trip this engine keeps off its frames.
            // ignore: avoid_slow_async_io
            await File(p.join(root, d.path)).exists() &&
            !await _isJsonObject(fetched.temp)) {
          await fetched.temp.delete();
          return sides.reportConflict(
            c,
            d,
            localSha: c.rows[d.path]?.localSha256 ?? '',
            remoteSha: fetched.download.sha256,
            why: 'the remote copy is not a JSON object',
          );
        }
        await ops.syncReplace(d.path, fetched.temp.path);
        final local = await sides.stat(d.path);
        if (local == null) {
          throw const SyncStepFailure('downloaded but not on disk');
        }
        await store.putItems([
          await sides.row(
            c,
            d.path,
            sha: fetched.download.sha256,
            local: local,
            remote: sides.remoteFrom(c, d.path, fetched.download),
          ),
        ]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _deleteRemote(SyncRunContext c, SyncDecision d) =>
      sides.guarded(() async {
        await sides.localStillAsPlanned(c, d.path);
        await _remoteStillAsPlanned(c, d);
        await c.client.delete(d.path, ifMatch: d.ifMatch);
        await store.removeItems(root, [d.path]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _trashLocal(SyncRunContext c, SyncDecision d) =>
      sides.guarded(() async {
        await sides.localStillAsPlanned(c, d.path);
        await ops.syncTrash(d.path);
        await store.removeItems(root, [d.path]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _record(SyncRunContext c, SyncDecision d) =>
      sides.guarded(() async {
        final local = (await sides.localStillAsPlanned(c, d.path))!;
        final sha = sides.localShaOf(c, d.path);
        final row = c.rows[d.path];
        final remote = c.remote[d.path]!;
        final contentChanged = row == null || row.localSha256 != sha;
        await store.putItems([
          await sides.row(
            c,
            d.path,
            sha: sha,
            local: local,
            remote: remote,
            baseVersion: row?.baseVersion,
            pinBase: contentChanged,
          ),
        ]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _moveRemote(SyncRunContext c, SyncDecision d) =>
      sides.guarded(() async {
        final from = d.fromPath!;
        final local = (await sides.localStillAsPlanned(c, d.path))!;
        await sides.localStillAsPlanned(c, from);
        await _remoteStillAsPlanned(c, d);
        await sides.ensureRemoteParent(c, d.path);
        try {
          await c.client.move(from, d.path);
        } on WebDavUnsupported {
          // The probe said MOVE works; it does not any more. Probe again on
          // the next run, and let it plan DELETE + PUT.
          await store.setCapabilities(
            root,
            WebDavCapabilities.fromJson({
                  ...c.capabilities.toJson(),
                  'move': false,
                }) ??
                c.capabilities,
          );
          rethrow;
        }
        await store.moveItems(root, from, d.path);
        final remote = await c.client.stat(d.path);
        if (remote == null) throw const SyncStepFailure('moved but not listed');
        final row = c.rows[from]!;
        await store.putItems([
          await sides.row(
            c,
            d.path,
            sha: row.localSha256,
            local: local,
            remote: remote,
            baseVersion: row.baseVersion,
            pinBase: false,
          ),
        ]);
        return SyncStepOutcome.done;
      });

  Future<SyncStepOutcome> _moveLocal(SyncRunContext c, SyncDecision d) =>
      sides.guarded(() async {
        final from = d.fromPath!;
        await sides.localStillAsPlanned(c, from);
        await sides.localStillAsPlanned(c, d.path);
        await ops.syncMove(from, d.path);
        await store.moveItems(root, from, d.path);
        final local = await sides.stat(d.path);
        if (local == null) throw const SyncStepFailure('moved but not on disk');
        final row = c.rows[from]!;
        await store.putItems([
          await sides.row(
            c,
            d.path,
            sha: row.localSha256,
            local: local,
            remote: c.remote[d.path]!,
            baseVersion: row.baseVersion,
            pinBase: false,
          ),
        ]);
        return SyncStepOutcome.done;
      });
}
