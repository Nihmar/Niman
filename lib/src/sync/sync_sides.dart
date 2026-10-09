import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_conflict.dart';
import 'package:niman/src/sync/sync_run_context.dart';
import 'package:niman/src/sync/sync_step_failure.dart';
import 'package:niman/src/sync/sync_step_outcome.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:path/path.dart' as p;

/// Reads, checks and records the two sides of one path, for the steps of
/// a sync run, its conflict merges and the conflict resolutions: the
/// local file's state and hash, the guards that a side is still what the
/// plan saw, the transfers, and the row both sides agree on afterwards.
final class SyncSides {
  /// The sides of the library at [root]; [_now] is the device clock the
  /// rows are stamped with.
  new({
    required this.root,
    required this.ops,
    required this.store,
    required this._now,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's operations: history pins go through them.
  final NoteOps ops;

  /// The sync state, where the agreed rows go.
  final SyncStore store;

  final DateTime Function() _now;

  static const _log = AppLogger(name: 'sync');

  /// The local file at [path], or null when there is no file there.
  Future<LocalFileState?> stat(String path) async {
    final stat = await FileStat.stat(p.join(root, path));
    if (stat.type != FileSystemEntityType.file) return null;
    return LocalFileState(
      size: stat.size,
      mtimeMs: stat.modified.millisecondsSinceEpoch,
    );
  }

  /// The sha256 of each of the local [paths], off the UI isolate; a file
  /// that vanished is left out.
  Future<Map<String, String>> hashLocal(List<String> paths) =>
      _hashLocal(root, paths);

  static Future<Map<String, String>> _hashLocal(
    String root,
    List<String> paths,
  ) => Isolate.run(() => hashLocalFiles(root, paths));

  /// The sha256 of the server's copy of [path], downloaded and dropped.
  Future<String> remoteSha(WebDavClient client, String path) async =>
      (await client.download(path, _DiscardSink())).sha256;

  /// The file at [path] still is what the scan saw (both absent counts).
  Future<LocalFileState?> localStillAsPlanned(
    SyncRunContext c,
    String path,
  ) async {
    final now = await stat(path);
    final planned = c.local[path];
    final same = now == null
        ? planned == null
        : planned != null &&
              planned.size == now.size &&
              planned.mtimeMs == now.mtimeMs;
    if (!same) throw const _ChangedDuringSync();
    return now;
  }

  /// The remote at [path] still holds what the plan saw it hold.
  ///
  /// A listing is only as good as its evidence: without file ETags a
  /// same-second rewrite of the same size leaves ETag (null), size and the
  /// one-second mtime all equal, so the listing alone reads as unchanged
  /// and the write would destroy the rewrite. When the listing cannot rule
  /// that out — the test [SyncItem.remoteUnverified] records, applied to
  /// the mtime the server shows now — the content decides: the remote is
  /// hashed and compared with [expectedSha] — the content the write is
  /// based on, the agreed one for an upload or a delete, the fetched copy
  /// for a merge — and a mismatch skips the path (#350).
  ///
  /// Not the row's own flag: the row describes the remote as last agreed,
  /// which for a merge is the version being replaced, not the one the
  /// merge was built from — a row recorded minutes ago reads as verified
  /// while the listing is in the server's current second.
  Future<void> remoteUnchangedSince(
    SyncRunContext c,
    String path, {
    String? expectedSha,
  }) async {
    final now = await c.client.stat(path);
    final planned = c.remote[path];
    final same = now == null
        ? planned == null
        : planned != null &&
              now.etag == planned.etag &&
              now.size == planned.size &&
              now.modified == planned.modified;
    if (!same) throw const _ChangedDuringSync();
    if (now == null) return;
    if (!unverified(c, now.modified)) return;
    final expected = expectedSha ?? c.rows[path]?.localSha256;
    if (expected == null) return;
    if (await remoteSha(c.client, path) != expected) {
      throw const _ChangedDuringSync();
    }
  }

  /// Guards a merge upload that carries no If-Match (#350): the merge was
  /// built from the remote [expectedSha] holds, and the remote must still
  /// hold it when the merged text is written over it. On a server that
  /// honors ETags the upload carries If-Match instead, and this does
  /// nothing — unless the ETag is weak, which the upload cannot carry.
  Future<void> guardMergeUpload(
    SyncRunContext c,
    SyncDecision d,
    WebDavResource remote, {
    required String expectedSha,
  }) async {
    if (c.capabilities.ifMatch && remote.guardEtag != null) return;
    await remoteUnchangedSince(c, d.path, expectedSha: expectedSha);
  }

  /// The local content hash of [path] the run knows: the scan's, the
  /// run's, or the agreed one; a [SyncStepFailure] when none.
  String localShaOf(SyncRunContext c, String path) {
    final sha =
        c.local[path]?.sha256 ?? c.localSha[path] ?? c.rows[path]?.localSha256;
    if (sha == null) throw SyncStepFailure('no hash for $path');
    return sha;
  }

  /// Records [d]'s path as a conflict and touches neither side: the merge
  /// screen is where it is resolved.
  SyncStepOutcome reportConflict(
    SyncRunContext c,
    SyncDecision d, {
    required String localSha,
    required String remoteSha,
    required String why,
  }) {
    c.report.conflicts.add(
      SyncConflict(
        path: d.path,
        localSha256: localSha,
        remoteSha256: remoteSha,
        baseVersion: d.baseVersion,
      ),
    );
    _log.warning('conflict ${d.path}: $why; left for the merge');
    return SyncStepOutcome.conflict;
  }

  /// Whether a listing of [modified] cannot rule out a second write within
  /// the same second: no file ETags, and the mtime is the server's current
  /// second (or the server sends no clock at all).
  bool unverified(SyncRunContext c, DateTime? modified) {
    if (c.capabilities.fileEtags) return false;
    final serverNow = c.client.serverDate;
    if (modified == null || serverNow == null) return true;
    return serverNow.difference(modified).inMilliseconds < 2000;
  }

  /// The row both sides agree on for [path] — content [sha], the local
  /// state [local] and the listing [remote] — pinning [sha] as the merge
  /// base unless [pinBase] is false, which keeps [baseVersion].
  Future<SyncItem> row(
    SyncRunContext c,
    String path, {
    required String sha,
    required LocalFileState local,
    required WebDavResource remote,
    int? baseVersion,
    bool pinBase = true,
  }) async {
    var base = baseVersion;
    if (pinBase) {
      try {
        base = await ops.pinSyncBase(path, sha);
      } on Object catch (e) {
        _log.warning('sync base "$path" not pinned: $e');
      }
    }
    return SyncItem(
      baseText: await _agreedStateText(path, sha),
      libraryPath: root,
      path: path,
      localSha256: sha,
      localSize: local.size,
      localMtimeMs: local.mtimeMs,
      remoteEtag: remote.etag,
      remoteSize: remote.size ?? local.size,
      remoteMtimeMs: remote.modified?.millisecondsSinceEpoch ?? 0,
      remoteUnverified: unverified(c, remote.modified),
      remoteFileId: remote.fileId,
      baseVersion: base,
      syncedAtMs: _now().millisecondsSinceEpoch,
    );
  }

  /// For a library state file, its text on disk when it still is the
  /// agreed content [sha] — the base of the next key-by-key merge; null
  /// for every other file, or when the file moved on already.
  Future<String?> _agreedStateText(String path, String sha) async {
    if (!libraryStateFiles.contains(path)) return null;
    try {
      final bytes = await File(p.join(root, path)).readAsBytes();
      if (sha256.convert(bytes).toString() != sha) return null;
      return utf8.decode(bytes, allowMalformed: true);
    } on FileSystemException {
      return null;
    }
  }

  /// Runs [action], a skipped outcome when a side turned out to have
  /// changed since the plan.
  Future<SyncStepOutcome> guarded(
    Future<SyncStepOutcome> Function() action,
  ) async {
    try {
      return await action();
    } on _ChangedDuringSync {
      return SyncStepOutcome.skipped;
    }
  }

  /// Uploads the local file at [path] — content [sha], state [local] —
  /// and records the row both sides now agree on, from the listing the
  /// server gives after the upload; throws [notListed] when the file is
  /// not listed then. [ifMatch], [ifNoneMatch] and [modified] go with the
  /// upload as they are.
  Future<void> uploadAndRecord(
    SyncRunContext c,
    String path, {
    required String sha,
    required LocalFileState local,
    required Exception notListed,
    String? ifMatch,
    bool ifNoneMatch = false,
    DateTime? modified,
  }) async {
    await ensureRemoteParent(c, path);
    await c.client.uploadFile(
      path,
      File(p.join(root, path)),
      ifMatch: ifMatch,
      ifNoneMatch: ifNoneMatch,
      modified: modified,
    );
    final listed = await c.client.stat(path);
    if (listed == null) throw notListed;
    await store.putItems([
      await row(c, path, sha: sha, local: local, remote: listed),
    ]);
  }

  /// Creates the remote folder [path] goes in, unless the run knows it
  /// exists.
  Future<void> ensureRemoteParent(SyncRunContext c, String path) async {
    final slash = path.lastIndexOf('/');
    if (slash < 0) return;
    final parent = path.substring(0, slash);
    if (c.folders.contains(parent)) return;
    await c.client.createFolders(parent);
    var folder = parent;
    while (folder.isNotEmpty) {
      c.folders.add(folder);
      final up = folder.lastIndexOf('/');
      folder = up < 0 ? '' : folder.substring(0, up);
    }
  }

  /// GETs [path] into a temp file next to its target; returns it with the
  /// response's metadata. The temp file is removed on failure.
  Future<({File temp, WebDavDownload download})> fetch(
    SyncRunContext c,
    String path,
  ) async {
    final target = p.join(root, path);
    await Directory(p.dirname(target)).create(recursive: true);
    final temp = File(
      p.join(
        p.dirname(target),
        '.${p.basename(target)}.niman-tmp-sync-'
        '${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      // The sink is ours, not the client's (issue #103). Handing
      // `temp.openWrite()` straight in left its closing to whatever the
      // consumer did with it, and the file the download had just written
      // then went into a rename that never returned on Windows — where,
      // unlike POSIX, a file with a handle still on it cannot be
      // renamed. A note never hit it because its temp is written by
      // `writeAsBytes`, which closes on its own.
      final sink = temp.openWrite();
      final WebDavDownload download;
      try {
        download = await c.client.download(path, sink);
      } finally {
        // The consumer closes the sink; closing a closed sink is a no-op
        // that hands back the same `done`. Awaiting it is what says the
        // bytes are on disk and the handle is gone before anyone renames.
        // A sink the transfer still holds throws straight out of
        // `close()`, though, and that StateError must not replace the
        // transfer's own failure (#495).
        try {
          await sink.close();
          await sink.done;
        } on Object {
          // The transfer's own failure is the one to report.
        }
      }
      // The client already checked Content-Length. A chunked answer has none,
      // so compare with the listing too — unless the ETag says the file was
      // rewritten since, which makes a different size legitimate.
      final listed = c.remote[path];
      final expected = listed?.size;
      final rewritten = download.etag != null && download.etag != listed?.etag;
      if (expected != null && download.bytes != expected && !rewritten) {
        throw WebDavProtocolFailure(
          'GET $path: ${download.bytes} bytes, the listing said $expected',
        );
      }
      return (temp: temp, download: download);
    } on Object {
      if (temp.existsSync()) await temp.delete();
      rethrow;
    }
  }

  /// The server's copy of [path] as a [download] of it describes it,
  /// with what the listing knew where the response says nothing.
  WebDavResource remoteFrom(
    SyncRunContext c,
    String path,
    WebDavDownload download,
  ) {
    final listed = c.remote[path];
    return WebDavResource(
      path: path,
      isCollection: false,
      etag: download.etag ?? listed?.etag,
      size: download.bytes,
      modified: download.modified ?? listed?.modified,
      fileId: listed?.fileId,
    );
  }
}

/// Thrown inside an action when a side no longer looks like the plan: the
/// path is skipped and the next run decides again.
final class _ChangedDuringSync implements Exception {
  const new();
}

final class _DiscardSink implements StreamConsumer<List<int>> {
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<void> close() async {}
}

/// The sha256 of each of [paths] under [root], streamed; a file that
/// vanished is left out.
///
/// Top-level so `Isolate.run` can take it.
Future<Map<String, String>> hashLocalFiles(
  String root,
  List<String> paths,
) async {
  final hashes = <String, String>{};
  for (final path in paths) {
    final file = File(p.join(root, path));
    if (!file.existsSync()) continue;
    hashes[path] = (await sha256.bind(file.openRead()).first).toString();
  }
  return hashes;
}
