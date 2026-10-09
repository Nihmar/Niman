import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/sync/conflict_texts.dart';
import 'package:niman/src/sync/sync_failure.dart';
import 'package:niman/src/sync/sync_report.dart';
import 'package:niman/src/sync/sync_run_context.dart';
import 'package:niman/src/sync/sync_sides.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:path/path.dart' as p;

/// A library's destination and a client for it.
typedef SyncConnection = ({SyncDestination destination, WebDavClient client});

/// Resolves conflicts one file at a time, outside a run: reads a
/// conflicted path's texts for the merge screen, and writes the user's
/// decision — a merged text, or one whole side — on both sides.
///
/// Each call takes the engine's turn through `exclusively`, so it never
/// overlaps a run, and connects through `connect`, which throws a
/// [SyncFailure] when the library has no destination or no password.
final class SyncResolver {
  /// A resolver for the library at [root].
  new({
    required this.root,
    required this.ops,
    required this.store,
    required this.sides,
    required this._exclusively,
    required this._connect,
    required this._capabilities,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's operations: the resolved texts are written through
  /// them, and the merge base read.
  final NoteOps ops;

  /// The sync state, where the agreed rows go.
  final SyncStore store;

  /// Reads, checks and records both sides of a path.
  final SyncSides sides;

  final Future<T> Function<T>(Future<T> Function() body) _exclusively;
  final Future<SyncConnection> Function() _connect;
  final Future<WebDavCapabilities> Function(
    WebDavClient client,
    SyncDestination destination,
  )
  _capabilities;

  static const _log = AppLogger(name: 'sync');

  /// The texts of a conflicted [path]: the local file, the server's copy,
  /// and the version both last agreed on when history still has it — what
  /// the merge view needs, and which versions they were, for the
  /// resolution to check against. Decoded as UTF-8 (malformed bytes
  /// replaced). Throws [SyncFailure].
  Future<ConflictTexts> conflictTexts(String path) => _exclusively(() async {
    final connection = await _connect();
    try {
      final localBytes = await File(p.join(root, path)).readAsBytes();
      // The listing's ETag, read first: it is what the resolution compares
      // with, and what its upload's If-Match sends.
      final listed = await connection.client.stat(path);
      final remoteBytes = await connection.client.readBytes(path);
      final base = await _baseText(path);
      _log.info(
        'conflict $path: read ${localBytes.length} b local, '
        '${remoteBytes.length} b remote, '
        '${base == null ? 'no base' : '${base.length} chars of base'}',
      );
      return ConflictTexts(
        local: decodeNoteText(localBytes),
        remote: decodeNoteText(remoteBytes),
        base: base,
        localSha256: sha256.convert(localBytes).toString(),
        remoteSha256: sha256.convert(remoteBytes).toString(),
        remoteEtag: listed?.etag,
      );
    } on WebDavFailure catch (e) {
      throw SyncFailure.of(e);
    } on FileSystemException catch (e) {
      throw SyncFailure(SyncAbort.failed, 'local: ${e.message}');
    } finally {
      connection.client.close();
    }
  });

  /// The text of the history version pinned as the sync base of [path],
  /// or null when there is none (or it rotated away).
  Future<String?> _baseText(String path) async {
    final row = await store.item(root, path);
    final version = row?.baseVersion;
    if (version == null || !NoteOps.keepsHistory(path)) return null;
    try {
      return await ops.readNoteVersion(path, version);
    } on Object catch (e) {
      _log.info('conflict $path: base v$version unreadable ($e)');
      return null;
    }
  }

  /// Resolves a conflicted [path] with the merged [text] the user put
  /// together from the versions [shown]: it is written here (the replaced
  /// text becomes a `sync` history version) and uploaded, and the row
  /// records the agreement. Throws [SyncFailure], a `moved` one when
  /// either side is no longer what [shown] holds.
  Future<void> resolveMerged(
    String path,
    String text, {
    required ConflictTexts shown,
  }) => _resolve(
    path,
    intent: 'merged text (${text.length} chars)',
    outcome: 'merged',
    shown: shown,
    (c, remote) async {
      await ops.syncMerge(path, text);
      final local = await sides.stat(path);
      if (local == null) {
        throw SyncFailure(SyncAbort.failed, '$path is gone here');
      }
      final sha = (await sides.hashLocal([path]))[path]!;
      await sides.uploadAndRecord(
        c,
        path,
        sha: sha,
        local: local,
        notListed: SyncFailure(SyncAbort.failed, '$path uploaded, not listed'),
        ifMatch: c.capabilities.ifMatch ? remote?.guardEtag : null,
      );
    },
  );

  /// Resolves a conflict at [path] by keeping one whole side: with
  /// [keepLocal] the local file is uploaded over the server's (guarded by
  /// `If-Match` where the server honors it); otherwise the server's copy
  /// replaces the local file, whose text becomes a `sync` history
  /// version. Either way the agreed row and the merge base are recorded.
  /// With [shown], the versions the user decided on, a side that moved
  /// since fails as a `moved` [SyncFailure] and nothing is written.
  /// Throws [SyncFailure].
  Future<void> resolveConflict(
    String path, {
    required bool keepLocal,
    ConflictTexts? shown,
  }) => _resolve(
    path,
    intent: 'keep ${keepLocal ? 'local' : 'remote'}',
    outcome: 'done',
    shown: shown,
    (c, remote) async {
      if (keepLocal) {
        final local = await sides.stat(path);
        if (local == null) {
          throw SyncFailure(SyncAbort.failed, '$path is gone here');
        }
        final sha = (await sides.hashLocal([path]))[path]!;
        await sides.uploadAndRecord(
          c,
          path,
          sha: sha,
          local: local,
          notListed: SyncFailure(
            SyncAbort.failed,
            '$path uploaded, not listed',
          ),
          ifMatch: c.capabilities.ifMatch ? remote?.guardEtag : null,
          ifNoneMatch: remote == null && c.capabilities.ifNoneMatch,
        );
      } else {
        if (remote == null) {
          throw SyncFailure(SyncAbort.failed, '$path is gone on the server');
        }
        final fetched = await sides.fetch(c, path);
        if (shown != null && fetched.download.sha256 != shown.remoteSha256) {
          // Rewritten between the check and this read.
          await fetched.temp.delete();
          throw SyncFailure.stale('$path changed on the server');
        }
        await ops.syncReplace(path, fetched.temp.path);
        final local = await sides.stat(path);
        if (local == null) {
          throw SyncFailure(SyncAbort.failed, '$path not on disk');
        }
        await store.putItems([
          await sides.row(
            c,
            path,
            sha: fetched.download.sha256,
            local: local,
            remote: sides.remoteFrom(c, path, fetched.download),
          ),
        ]);
      }
    },
  );

  /// Runs a conflict resolution of [path] on its own: logs [intent],
  /// connects, lists the server's copy, refuses a side that moved since
  /// [shown] (when given), and hands [body] a context of that one path
  /// and the listing; logs [outcome] when it went through. A WebDAV or a
  /// local failure is thrown as a [SyncFailure].
  Future<void> _resolve(
    String path,
    Future<void> Function(SyncRunContext c, WebDavResource? remote) body, {
    required String intent,
    required String outcome,
    ConflictTexts? shown,
  }) => _exclusively(() async {
    final clock = Stopwatch()..start();
    _log.info('resolve $path: $intent');
    final connection = await _connect();
    final client = connection.client;
    try {
      final capabilities = await _capabilities(client, connection.destination);
      final remote = await client.stat(path);
      if (shown != null) await _stillAsShown(client, path, shown, remote);
      final c = SyncRunContext(
        client: client,
        capabilities: capabilities,
        local: const {},
        remote: {path: ?remote},
        rows: const {},
        localSha: const {},
        remoteSha: const {},
        folders: {''},
        report: SyncReport(),
      );
      await body(c, remote);
      _log.info('resolve $path: $outcome (${clock.elapsedMilliseconds} ms)');
    } on WebDavFailure catch (e) {
      _log.warning('resolve $path failed: ${e.message}');
      throw SyncFailure.of(e);
    } on FileSystemException catch (e) {
      _log.warning('resolve $path failed: ${e.message}');
      throw SyncFailure(SyncAbort.failed, 'local: ${e.message}');
    } finally {
      client.close();
    }
  });

  /// Throws a `moved` [SyncFailure] unless both sides of [path] are
  /// still the versions [shown]: the local bytes by hash, the server's
  /// copy ([remote], just listed) by ETag when both have one, else by
  /// hashing a fresh download.
  Future<void> _stillAsShown(
    WebDavClient client,
    String path,
    ConflictTexts shown,
    WebDavResource? remote,
  ) async {
    final localSha = (await sides.hashLocal([path]))[path];
    if (localSha != shown.localSha256) {
      _log.info('resolve $path: refused, changed here since it was shown');
      throw SyncFailure.stale('$path changed on this device');
    }
    final String? remoteSha;
    if (remote == null) {
      remoteSha = null;
    } else if (shown.remoteEtag != null && remote.etag != null) {
      remoteSha = remote.etag == shown.remoteEtag ? shown.remoteSha256 : null;
    } else {
      remoteSha = await sides.remoteSha(client, path);
    }
    if (remoteSha != shown.remoteSha256) {
      _log.info('resolve $path: refused, changed on the server since shown');
      throw SyncFailure.stale('$path changed on the server');
    }
  }
}
