import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/sync/reconcile.dart';
import 'package:niman/src/sync/sync_sides.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_multistatus.dart';
import 'package:niman/src/sync/webdav/webdav_probe.dart';
import 'package:path/path.dart' as p;

/// What a scan found: files on both sides, the remote folders known to
/// exist, and the agreed rows in scope.
typedef SyncScan = ({
  Map<String, LocalFileState> local,
  Map<String, WebDavResource> remote,
  Set<String> folders,
  Map<String, SyncItem> rows,
});

/// Looks at both sides before a run plans: what the server can do, the
/// files on either side — the whole trees, or only a quick sync's queued
/// paths — and the hashes a plan asks for.
final class SyncScanner {
  /// A scanner for the library at [root]; [_now] is the device clock the
  /// capabilities are dated with.
  new({
    required this.root,
    required this.store,
    required this.sides,
    required this._now,
  });

  /// Absolute path of the library root.
  final String root;

  /// The sync state, where probed capabilities are kept.
  final SyncStore store;

  /// The local stat and both sides' hashes.
  final SyncSides sides;

  final DateTime Function() _now;

  static const _log = AppLogger(name: 'sync');

  // --- capabilities ---------------------------------------------------

  /// What the server at [destination] can do: as stored, or probed again
  /// through [client] when never probed or stale.
  Future<WebDavCapabilities> capabilities(
    WebDavClient client,
    SyncDestination destination,
  ) async {
    final stored = WebDavCapabilities.decode(destination.capabilities);
    if (stored != null && !stored.isStale(_now())) {
      _log.debug('capabilities: stored, ${stored.describe()}');
      return stored;
    }
    _log.info(
      'capabilities: ${stored == null ? 'never probed' : 'stale'}, probing',
    );
    final probed = await probeWebDav(client, now: _now);
    await store.setCapabilities(root, probed);
    return probed;
  }

  // --- scanning -------------------------------------------------------

  /// Every syncable local file — or only those under the folder [under] —
  /// with size and mtime, listed off the UI isolate.
  Future<Map<String, LocalFileState>> scanLocal({String under = ''}) =>
      _scanLocal(root, under: under);

  static Future<Map<String, LocalFileState>> _scanLocal(
    String root, {
    String under = '',
  }) => Isolate.run(() => scanLocalFiles(root, under: under));

  /// The sides of the queued [hints]' paths only: each path (and a move's
  /// source) is a file or a folder on either side; a folder brings every
  /// file under it, locally, remotely and in the rows. One `PROPFIND
  /// Depth: 0` per path, plus the walk of the folders among them.
  Future<SyncScan> scanQuick(
    WebDavClient client,
    List<SyncOp> hints,
    Map<String, SyncItem> allRows,
  ) async {
    // A missing destination must stop the run, not read as "every hinted
    // file is gone remotely".
    final top = await client.stat('', collection: true);
    if (top == null || !top.isCollection) {
      throw const WebDavNotFound('the destination folder is gone');
    }
    final scope = <String>{
      for (final hint in hints) ...[hint.path, ?hint.fromPath],
    }..removeWhere((path) => path.isEmpty || !_inSyncScope(path));
    final local = <String, LocalFileState>{};
    final remote = <String, WebDavResource>{};
    final rows = <String, SyncItem>{};
    final folders = <String>{''};
    for (final path in scope) {
      final under = '$path/';
      for (final entry in allRows.entries) {
        if (entry.key == path || entry.key.startsWith(under)) {
          rows[entry.key] = entry.value;
        }
      }
      final localDir = Directory(p.join(root, path)).existsSync();
      if (localDir) {
        local.addAll(await scanLocal(under: path));
      } else {
        final state = await sides.stat(path);
        if (state != null && isSyncablePath(path)) local[path] = state;
      }
      final folderLike =
          localDir || allRows.keys.any((key) => key.startsWith(under));
      final item = await client.stat(path, collection: folderLike);
      if (item == null) continue;
      _addFolderChain(folders, _parentOf(path));
      if (item.isCollection) {
        final walked = await scanRemote(client, from: path);
        remote.addAll(walked.files);
        folders.addAll(walked.folders);
      } else if (isSyncablePath(path)) {
        remote[path] = item;
      }
    }
    return (local: local, remote: remote, folders: folders, rows: rows);
  }

  /// Whether [path] can hold syncable files: a syncable file, or a folder
  /// the scans walk.
  static bool _inSyncScope(String path) =>
      isSyncablePath(path) || _descends(path);

  static String _parentOf(String path) {
    final slash = path.lastIndexOf('/');
    return slash < 0 ? '' : path.substring(0, slash);
  }

  static void _addFolderChain(Set<String> folders, String folder) {
    var current = folder;
    while (current.isNotEmpty && folders.add(current)) {
      current = _parentOf(current);
    }
  }

  /// The syncable remote files and the walked folders, from the folder
  /// [from] down (the whole destination by default).
  Future<({Map<String, WebDavResource> files, Set<String> folders})> scanRemote(
    WebDavClient client, {
    String from = '',
  }) async {
    final files = <String, WebDavResource>{};
    final folders = <String>{from};
    final queue = [from];
    while (queue.isNotEmpty) {
      final folder = queue.removeLast();
      for (final item in await client.list(folder)) {
        if (item.isCollection) {
          if (_descends(item.path)) {
            folders.add(item.path);
            queue.add(item.path);
          }
        } else if (isSyncablePath(item.path)) {
          files[item.path] = item;
        }
      }
    }
    // The library's own files live in a dot folder, and some servers — or
    // the proxy in front of them — leave dot entries out of a folder listing
    // while still serving them by path. The listing then says the file is not
    // there, the check before the upload finds it, and the upload is skipped
    // as "changed during the sync" on every run. So a walk from the root that
    // did not see their folder asks for them by name: at most four `Depth: 0`
    // requests, and only when the listing hid them.
    if (from.isEmpty) {
      for (final path in libraryStateFiles) {
        if (files.containsKey(path) || folders.contains(_parentOf(path))) {
          continue;
        }
        final item = await client.stat(path);
        if (item == null || item.isCollection) continue;
        files[path] = item;
        _addFolderChain(folders, _parentOf(path));
      }
    }
    return (files: files, folders: folders);
  }

  // --- hashing --------------------------------------------------------

  /// Hashes the local and remote paths [plan] is waiting for into
  /// [localSha] and [remoteSha]; a remote file gone since the listing
  /// stays unhashed.
  Future<void> hash(
    WebDavClient client,
    SyncPlan plan,
    Map<String, String> localSha,
    Map<String, String> remoteSha,
  ) async {
    final clock = Stopwatch()..start();
    final localPaths = [
      for (final d in plan.decisions)
        if (d.kind == SyncActionKind.hashLocal) d.path,
    ];
    if (localPaths.isNotEmpty) {
      localSha.addAll(await sides.hashLocal(localPaths));
    }
    final remotePaths = [
      for (final d in plan.decisions)
        if (d.kind == SyncActionKind.hashRemote) d.path,
    ];
    for (final path in remotePaths) {
      try {
        remoteSha[path] = await sides.remoteSha(client, path);
      } on WebDavNotFound {
        // Gone since the listing: it stays unhashed and fails as a path,
        // not as a missing destination.
        _log.info('hash: remote $path vanished since the listing');
      }
    }
    _log.info(
      'hash: ${localPaths.length} local, ${remotePaths.length} remote '
      '(${clock.elapsedMilliseconds} ms)',
    );
  }
}

/// Whether a folder at library-relative [path] is walked: not a dot
/// folder, except `.niman` at the root (for its two synced files).
bool _descends(String path) {
  if (path == '.niman') return true;
  return !path.split('/').any((s) => s.startsWith('.'));
}

/// Every syncable file under [root] — or only under its folder [under] —
/// with size and mtime (no hashes).
///
/// Top-level so `Isolate.run` can take it. Symlinks are not followed.
Future<Map<String, LocalFileState>> scanLocalFiles(
  String root, {
  String under = '',
}) async {
  final files = <String, LocalFileState>{};
  if (under.isNotEmpty &&
      (!_descends(under) || !Directory(p.join(root, under)).existsSync())) {
    return files;
  }
  final queue = [under];
  while (queue.isNotEmpty) {
    final folder = queue.removeLast();
    final dir = Directory(folder.isEmpty ? root : p.join(root, folder));
    await for (final entity in dir.list(followLinks: false)) {
      final name = p.basename(entity.path);
      final rel = folder.isEmpty ? name : '$folder/$name';
      if (entity is Directory) {
        if (_descends(rel)) queue.add(rel);
      } else if (entity is File && isSyncablePath(rel)) {
        final stat = entity.statSync();
        files[rel] = LocalFileState(
          size: stat.size,
          mtimeMs: stat.modified.millisecondsSinceEpoch,
        );
      }
    }
  }
  return files;
}
