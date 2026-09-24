/// Reconcile: what to do with each path, decided from disk now, the
/// remote now and the row both sides agreed on (docs/dev/sync.md,
/// "State: `sync_items`").
///
/// Pure functions over plain values — no I/O, no clock — so every branch
/// of the decision table is a unit test. The engine gathers the inputs,
/// supplies hashes when a decision asks for them, and carries the
/// actions out.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';

/// The library's own files inside `.niman/` that belong on every device.
///
/// They are the library's state rather than its content, and the sync
/// never removes one: a copy missing on one side is restored from the
/// other ([reconcilePath]), because the file gone is never what the user
/// meant. Without that, one device that lost its `settings.json` deleted
/// it on the server, and every other device then moved its own copy into
/// the trash and fell back to the defaults (the log of 2026-09-21).
const Set<String> libraryStateFiles = {
  '.niman/settings.json',
  '.niman/counters.json',
  '.niman/dictionary.txt',
};

/// The paths the sync never touches.
///
/// Dot folders and dot files are left out — `.trash/`, `.history/`, the
/// atomic-write temp files, a `.git/` the user keeps — except the
/// [libraryStateFiles]. So are the files operating systems drop into
/// folders on their own.
bool isSyncablePath(String path) {
  if (path.isEmpty) return false;
  final segments = path.split('/');
  if (segments.any((s) => s.isEmpty)) return false;
  if (libraryStateFiles.contains(path)) return true;
  if (segments.any((s) => s.startsWith('.'))) return false;
  final name = segments.last.toLowerCase();
  return !_systemJunk.contains(name);
}

const _systemJunk = {'thumbs.db', 'desktop.ini'};

/// A file on disk, as the engine stat-ed it.
@immutable
final class LocalFileState {
  /// A file of [size] bytes modified at [mtimeMs], with its [sha256] when
  /// it has been hashed.
  const new({required this.size, required this.mtimeMs, this.sha256});

  /// Size in bytes.
  final int size;

  /// Modification time, ms since epoch.
  final int mtimeMs;

  /// Hex sha256, or null when not hashed (yet).
  final String? sha256;

  @override
  String toString() =>
      'local($size b, $mtimeMs${sha256 == null ? '' : ', ${_short(sha256)}'})';
}

/// How one side compares with the agreed row.
enum SideChange {
  /// No row and no file: nothing on this side.
  absent,

  /// No row, a file: new on this side.
  created,

  /// The file matches the row.
  unchanged,

  /// The file differs from the row.
  changed,

  /// A row, no file: deleted on this side.
  deleted,

  /// Cannot tell without hashing the content.
  needsHash,
}

/// A side's comparison and the evidence, for the log.
typedef SideVerdict = ({SideChange change, String why});

/// How the local file compares with [row].
///
/// Size and mtime equal to the row mean unchanged without reading the
/// file. Otherwise the sha256 decides, and without one the verdict is
/// [SideChange.needsHash]. A new file needs its hash too: the upload
/// records it, and move detection pairs by it.
SideVerdict classifyLocal(LocalFileState? local, SyncItem? row) {
  if (row == null) {
    if (local == null) return (change: SideChange.absent, why: 'no file');
    if (local.sha256 == null) {
      return (change: SideChange.needsHash, why: 'new, not hashed');
    }
    return (change: SideChange.created, why: 'new, ${local.size} b');
  }
  if (local == null) return (change: SideChange.deleted, why: 'deleted');
  if (local.size == row.localSize && local.mtimeMs == row.localMtimeMs) {
    return (change: SideChange.unchanged, why: 'same size and mtime');
  }
  final sha = local.sha256;
  if (sha == null) {
    return (
      change: SideChange.needsHash,
      why:
          'size ${row.localSize}→${local.size}, '
          'mtime ${row.localMtimeMs}→${local.mtimeMs}, not hashed',
    );
  }
  if (sha == row.localSha256) {
    return (change: SideChange.unchanged, why: 'touched, same sha');
  }
  return (
    change: SideChange.changed,
    why: 'sha ${_short(row.localSha256)}→${_short(sha)}',
  );
}

/// How the remote file compares with [row], given what the server can
/// do ([capabilities]; null = compatible mode).
///
/// With file ETags on both the row and the listing, the ETag decides.
/// Without, size and `getlastmodified` do, except when they cannot rule
/// out a same-second rewrite: the row is marked `remoteUnverified`, or
/// the server sends no mtime at all. Then the content hash decides —
/// [remoteSha256], computed by downloading — and without it the verdict
/// is [SideChange.needsHash].
SideVerdict classifyRemote(
  WebDavResource? remote,
  SyncItem? row,
  WebDavCapabilities? capabilities, {
  String? remoteSha256,
}) {
  if (row == null) {
    return remote == null
        ? (change: SideChange.absent, why: 'no file')
        : (change: SideChange.created, why: 'new, ${remote.size ?? '?'} b');
  }
  if (remote == null) return (change: SideChange.deleted, why: 'deleted');

  final etag = remote.etag;
  final rowEtag = row.remoteEtag;
  if ((capabilities?.fileEtags ?? false) && etag != null && rowEtag != null) {
    return etag == rowEtag
        ? (change: SideChange.unchanged, why: 'same etag')
        : (change: SideChange.changed, why: 'etag $rowEtag→$etag');
  }

  if (remote.size != null && remote.size != row.remoteSize) {
    return (
      change: SideChange.changed,
      why: 'size ${row.remoteSize}→${remote.size}',
    );
  }
  final modified = remote.modified?.millisecondsSinceEpoch;
  if (modified != null && modified != row.remoteMtimeMs) {
    return (
      change: SideChange.changed,
      why: 'mtime ${row.remoteMtimeMs}→$modified',
    );
  }
  final doubt = modified == null
      ? 'no mtime from the server'
      : remote.size == null
      ? 'no size from the server'
      : row.remoteUnverified
      ? 'possible same-second rewrite'
      : null;
  if (doubt == null) {
    return (change: SideChange.unchanged, why: 'same size and mtime');
  }
  if (remoteSha256 == null) {
    return (change: SideChange.needsHash, why: '$doubt, not hashed');
  }
  return remoteSha256 == row.localSha256
      ? (change: SideChange.unchanged, why: '$doubt, same sha')
      : (
          change: SideChange.changed,
          why: '$doubt, sha ${_short(row.localSha256)}→${_short(remoteSha256)}',
        );
}

/// What the engine does with a path.
enum SyncActionKind {
  /// Both sides match the row.
  nothing,

  /// The content agrees but the row is stale (a touched file, a hash that
  /// cleared a doubt, both sides created identically): rewrite the row
  /// from the current metadata, transfer nothing.
  record,

  /// Put the local file on the server.
  upload,

  /// Fetch the remote file (snapshot `sync` first when it overwrites a
  /// note).
  download,

  /// Delete the file on the server.
  deleteRemote,

  /// Move the local file into `.trash/`.
  trashLocal,

  /// Both sides deleted it: drop the row.
  dropRow,

  /// Both sides changed (or were created differently): download the
  /// remote, record it when the content turns out equal, merge otherwise
  /// — 3-way on the pinned base when there is one.
  conflict,

  /// Hash the local file, then decide again.
  hashLocal,

  /// Download the remote file to hash it, then decide again.
  hashRemote,

  /// `MOVE` the remote file from `fromPath` (a local rename or move).
  moveRemote,

  /// Rename the local file from `fromPath` (a remote rename found by
  /// file id).
  moveLocal,
}

/// The decision for one path.
@immutable
final class SyncDecision {
  /// [kind] for [path], explained by [why].
  const new({
    required this.path,
    required this.kind,
    required this.why,
    this.fromPath,
    this.ifMatch,
    this.ifNoneMatch = false,
    this.checkRemoteFirst = false,
    this.baseVersion,
  });

  /// The library-relative path the action applies to (the target of a
  /// move).
  final String path;

  /// What to do.
  final SyncActionKind kind;

  /// Both sides' evidence, for the log.
  final String why;

  /// The source of a move.
  final String? fromPath;

  /// For `upload` / `deleteRemote` over an existing remote: the ETag to
  /// send as `If-Match`, when the server honors it.
  final String? ifMatch;

  /// For an `upload` onto a path that should not exist remotely: send
  /// `If-None-Match: *` (the server honors it).
  final bool ifNoneMatch;

  /// The server cannot guard this write with a precondition: PROPFIND the
  /// item right before it and decide again if it moved.
  final bool checkRemoteFirst;

  /// For a `conflict`: the history version pinned as the merge base.
  final int? baseVersion;

  /// Whether the action removes a file on either side.
  bool get isDestructive =>
      kind == SyncActionKind.deleteRemote || kind == SyncActionKind.trashLocal;

  @override
  String toString() =>
      '${kind.name} $path${fromPath == null ? '' : ' from $fromPath'}: $why';
}

/// Decides [path]: the file on disk ([local]), on the server ([remote],
/// files only) and the agreed [row], with [capabilities] (null =
/// compatible mode) and the hashes the engine computed when an earlier
/// decision asked.
///
/// The table (docs/dev/sync.md):
///
/// | local \ remote | unchanged | changed | deleted | absent | created |
/// |---|---|---|---|---|---|
/// | unchanged | nothing | download | trashLocal | | |
/// | changed | upload | conflict | upload | | |
/// | deleted | deleteRemote | download | dropRow | | |
/// | absent | | | | nothing | download |
/// | created | | | | upload | conflict |
///
/// A changed file wins over a deletion on the other side, so an edit is
/// never lost. With no row there is nothing to delete, which is why a
/// first sync never deletes. Hashing comes first: a side that needs its
/// hash is resolved before anything is decided.
///
/// The [libraryStateFiles] are never deleted: where the table says
/// `deleteRemote` they download, and where it says `trashLocal` they
/// upload.
SyncDecision reconcilePath({
  required String path,
  required LocalFileState? local,
  required WebDavResource? remote,
  required SyncItem? row,
  WebDavCapabilities? capabilities,
  String? remoteSha256,
}) {
  final l = classifyLocal(local, row);
  final r = classifyRemote(
    remote,
    row,
    capabilities,
    remoteSha256: remoteSha256,
  );
  final why = 'local ${l.why}; remote ${r.why}';
  SyncDecision decide(
    SyncActionKind kind, {
    String? ifMatch,
    bool ifNoneMatch = false,
    bool checkRemoteFirst = false,
  }) => SyncDecision(
    path: path,
    kind: kind,
    why: why,
    ifMatch: ifMatch,
    ifNoneMatch: ifNoneMatch,
    checkRemoteFirst: checkRemoteFirst,
    baseVersion: kind == SyncActionKind.conflict ? row?.baseVersion : null,
  );

  if (l.change == SideChange.needsHash) return decide(SyncActionKind.hashLocal);
  // Every row of the table needs a definite remote verdict too: a local
  // deletion is a remote delete or a download depending on it.
  if (r.change == SideChange.needsHash) {
    return decide(SyncActionKind.hashRemote);
  }

  final guardIfMatch = capabilities?.ifMatch ?? false;
  final guardIfNoneMatch = capabilities?.ifNoneMatch ?? false;
  final etag = remote?.etag;
  SyncDecision overwriteRemote(SyncActionKind kind) => decide(
    kind,
    ifMatch: guardIfMatch ? etag : null,
    checkRemoteFirst: !guardIfMatch || etag == null,
  );
  SyncDecision createRemote() => decide(
    SyncActionKind.upload,
    ifNoneMatch: guardIfNoneMatch,
    checkRemoteFirst: !guardIfNoneMatch,
  );

  final kept = libraryStateFiles.contains(path);
  return switch ((l.change, r.change)) {
    (SideChange.unchanged, SideChange.unchanged) => decide(
      _rowIsCurrent(local!, remote!, row!, remoteSha256)
          ? SyncActionKind.nothing
          : SyncActionKind.record,
    ),
    (SideChange.changed, SideChange.unchanged) => overwriteRemote(
      SyncActionKind.upload,
    ),
    (SideChange.unchanged, SideChange.changed) => decide(
      SyncActionKind.download,
    ),
    (SideChange.changed, SideChange.changed) => decide(SyncActionKind.conflict),
    (SideChange.deleted, SideChange.unchanged) =>
      kept
          ? decide(SyncActionKind.download)
          : overwriteRemote(SyncActionKind.deleteRemote),
    (SideChange.unchanged, SideChange.deleted) =>
      kept ? createRemote() : decide(SyncActionKind.trashLocal),
    (SideChange.deleted, SideChange.changed) => decide(SyncActionKind.download),
    (SideChange.changed, SideChange.deleted) => createRemote(),
    (SideChange.deleted, SideChange.deleted) => decide(SyncActionKind.dropRow),
    (SideChange.created, SideChange.absent) => createRemote(),
    (SideChange.absent, SideChange.created) => decide(SyncActionKind.download),
    (SideChange.created, SideChange.created) => decide(SyncActionKind.conflict),
    (SideChange.absent, SideChange.absent) => decide(SyncActionKind.nothing),
    // Unreachable: a row makes both sides row-relative, no row makes both
    // absolute; needsHash returned above.
    _ => throw StateError('impossible combination for $path: $why'),
  };
}

/// Whether [row] already records what both sides hold, so an unchanged
/// path needs no write at all.
bool _rowIsCurrent(
  LocalFileState local,
  WebDavResource remote,
  SyncItem row,
  String? remoteSha256,
) =>
    local.mtimeMs == row.localMtimeMs &&
    local.size == row.localSize &&
    (remote.etag == null || remote.etag == row.remoteEtag) &&
    // A hash that settled a doubt clears the doubt in the row.
    !(row.remoteUnverified && remoteSha256 != null);

/// The decisions for a whole library, with the move pairing and the
/// mass-deletion guard applied.
@immutable
final class SyncPlan {
  /// A plan of [decisions] over [rowCount] agreed rows.
  new(Iterable<SyncDecision> decisions, {required this.rowCount})
    : decisions = List.unmodifiable(decisions);

  /// One decision per path that needs anything (no `nothing` entries),
  /// in path order.
  final List<SyncDecision> decisions;

  /// How many rows the library had.
  final int rowCount;

  /// How many decisions of [kind] the plan holds.
  int count(SyncActionKind kind) =>
      decisions.where((d) => d.kind == kind).length;

  /// Whether some decision still waits for a hash.
  bool get needsHashes => decisions.any(
    (d) =>
        d.kind == SyncActionKind.hashLocal ||
        d.kind == SyncActionKind.hashRemote,
  );

  /// How many files the plan would remove on either side.
  int get destructiveCount => decisions.where((d) => d.isDestructive).length;

  /// Whether the plan deletes so much that the likelier story is a wrong
  /// URL, an unmounted share or an emptied folder — more than
  /// [massDeletionMinimum] files and more than half of what was synced.
  /// The engine stops and asks instead of carrying it out.
  bool get looksLikeMassDeletion =>
      destructiveCount > massDeletionMinimum && destructiveCount * 2 > rowCount;

  /// Below this many deletions a plan never counts as a mass deletion.
  static const massDeletionMinimum = 10;

  /// One line per kind, for the log: `upload 3, download 1, …`.
  String summary() {
    final parts = [
      for (final kind in SyncActionKind.values)
        if (count(kind) > 0) '${kind.name} ${count(kind)}',
    ];
    return parts.isEmpty ? 'nothing to do' : parts.join(', ');
  }
}

/// Decides every syncable path of a library.
///
/// [local] and [remote] hold files only, by library-relative path;
/// [rows] the agreed items. [localSha256] and [remoteSha256] carry the
/// hashes computed for earlier `hashLocal` / `hashRemote` decisions —
/// the engine loops until [SyncPlan.needsHashes] is false.
///
/// Then pairs renames (docs/dev/sync.md, "Server capabilities"):
///
/// - a `deleteRemote` of A and an `upload` of a new B whose content is
///   A's agreed content become one `moveRemote` A→B, when the server has
///   `MOVE` and the content is unique on both sides;
/// - a `trashLocal` of A and a `download` of a new B carrying A's
///   `oc:fileid` become one `moveLocal` A→B, when the server has file ids.
///
/// A quick sync plans a few paths with only their [rows]; [rowCount] then
/// passes the library's whole row count, which the mass-deletion guard
/// measures against.
SyncPlan planSync({
  required Map<String, LocalFileState> local,
  required Map<String, WebDavResource> remote,
  required Map<String, SyncItem> rows,
  WebDavCapabilities? capabilities,
  Map<String, String> localSha256 = const {},
  Map<String, String> remoteSha256 = const {},
  int? rowCount,
}) {
  final paths = {
    ...local.keys,
    ...remote.keys,
    ...rows.keys,
  }.where(isSyncablePath).toList()..sort();
  final decisions = <String, SyncDecision>{};
  for (final path in paths) {
    final disk = local[path];
    final hashed = localSha256[path];
    final decision = reconcilePath(
      path: path,
      local: disk == null || hashed == null || disk.sha256 != null
          ? disk
          : LocalFileState(
              size: disk.size,
              mtimeMs: disk.mtimeMs,
              sha256: hashed,
            ),
      remote: remote[path],
      row: rows[path],
      capabilities: capabilities,
      remoteSha256: remoteSha256[path],
    );
    if (decision.kind != SyncActionKind.nothing) decisions[path] = decision;
  }

  if (capabilities?.move ?? false) {
    _pairRemoteMoves(decisions, local, rows, localSha256);
  }
  if (capabilities?.fileIds ?? false) {
    _pairLocalMoves(decisions, remote, rows);
  }
  return SyncPlan(
    paths.map((path) => decisions[path]).nonNulls,
    rowCount: rowCount ?? rows.keys.where(isSyncablePath).length,
  );
}

void _pairRemoteMoves(
  Map<String, SyncDecision> decisions,
  Map<String, LocalFileState> local,
  Map<String, SyncItem> rows,
  Map<String, String> localSha256,
) {
  // Content → the single path on each side, or null when not unique.
  final deletedBySha = <String, String?>{};
  final createdBySha = <String, String?>{};
  for (final decision in decisions.values) {
    final path = decision.path;
    if (decision.kind == SyncActionKind.deleteRemote) {
      final sha = rows[path]!.localSha256;
      deletedBySha[sha] = deletedBySha.containsKey(sha) ? null : path;
    } else if (decision.kind == SyncActionKind.upload && rows[path] == null) {
      final sha = local[path]?.sha256 ?? localSha256[path];
      if (sha == null) continue;
      createdBySha[sha] = createdBySha.containsKey(sha) ? null : path;
    }
  }
  for (final MapEntry(key: sha, value: from) in deletedBySha.entries) {
    final to = createdBySha[sha];
    if (from == null || to == null) continue;
    final deletion = decisions.remove(from)!;
    decisions[to] = SyncDecision(
      path: to,
      kind: SyncActionKind.moveRemote,
      fromPath: from,
      why: 'same content ${_short(sha)} deleted at $from and new here',
      ifMatch: deletion.ifMatch,
      checkRemoteFirst: true,
    );
  }
}

void _pairLocalMoves(
  Map<String, SyncDecision> decisions,
  Map<String, WebDavResource> remote,
  Map<String, SyncItem> rows,
) {
  final trashedById = <String, String?>{};
  final downloadedById = <String, String?>{};
  for (final decision in decisions.values) {
    final path = decision.path;
    if (decision.kind == SyncActionKind.trashLocal) {
      final id = rows[path]!.remoteFileId;
      if (id == null) continue;
      trashedById[id] = trashedById.containsKey(id) ? null : path;
    } else if (decision.kind == SyncActionKind.download && rows[path] == null) {
      final id = remote[path]?.fileId;
      if (id == null) continue;
      downloadedById[id] = downloadedById.containsKey(id) ? null : path;
    }
  }
  for (final MapEntry(key: id, value: from) in trashedById.entries) {
    final to = downloadedById[id];
    if (from == null || to == null) continue;
    decisions.remove(from);
    decisions[to] = SyncDecision(
      path: to,
      kind: SyncActionKind.moveLocal,
      fromPath: from,
      why: 'remote file id $id moved from $from',
    );
  }
}

String _short(String? sha) {
  if (sha == null) return '?';
  return sha.length <= 8 ? sha : sha.substring(0, 8);
}
