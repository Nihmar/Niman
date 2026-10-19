import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/sync/sync_sides.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/sync/transfers/sync_transfers.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';

/// Settles the downloads a run that was killed left half written
/// (docs/records/sync.md, "How a new file is written").
///
/// A new file is written straight to its final name, so a process killed in
/// the middle of it — by an antivirus, a crash, a power cut — leaves a
/// partial file there under the real name, which the next scan would take
/// for a new local file and upload over the good copy. The sync marks every
/// such path before it writes (`SyncNewFileDownload`); this runs first
/// thing in the next run, before the scan, and for each mark:
///
/// - no file at the path: nothing was written, the mark goes;
/// - a file that is the server's copy, whole: it stays, the mark goes, and
///   the run's plan records it like any file both sides hold with the same
///   content;
/// - any other file — shorter, or the right size with other bytes, or the
///   server's copy gone — moves to the library trash (never deleted), the
///   mark goes, and the plan downloads the path again.
final class SyncDownloadRecovery {
  /// Recovery for the library at [root].
  new({
    required this.root,
    required this.ops,
    required this.store,
    required this.sides,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's operations: a partial file is trashed through them.
  final NoteOps ops;

  /// The sync state, where the marks are.
  final SyncStore store;

  /// Reads the local files.
  final SyncSides sides;

  static const _log = AppLogger(name: 'sync');

  /// Settles every mark of the library; [client] looks at the server's copy
  /// and [transfers] hashes it when the sizes agree. A failure of the server
  /// ends the recovery with the marks left for the next run.
  Future<void> recover(WebDavClient client, SyncTransfers transfers) async {
    final marked = await store.pendingDownloads.pending(root);
    if (marked.isEmpty) return;
    _log.info(
      'recovery: ${marked.length} downloads did not finish in an earlier run',
    );
    for (final path in marked) {
      await _settle(client, transfers, path);
    }
  }

  Future<void> _settle(
    WebDavClient client,
    SyncTransfers transfers,
    String path,
  ) async {
    final local = await sides.stat(path);
    if (local == null) {
      _log.info('recovery: "$path" was not written, mark dropped');
    } else if (await _isWhole(client, transfers, path, local.size)) {
      _log.info('recovery: "$path" is the server\'s copy, kept');
    } else {
      // Always the trash: the file may be the only trace of a download
      // that was nearly done, and it is a file this run did not make.
      await ops.syncTrash(path);
      _log.warning(
        'recovery: "$path" is a partial download (${local.size} bytes), '
        'moved to the trash; it is downloaded again',
      );
    }
    await store.pendingDownloads.clear(root, path);
  }

  /// Whether the file at [path], of [size] bytes, is the server's copy: the
  /// listing's size first, and the content when the sizes agree.
  Future<bool> _isWhole(
    WebDavClient client,
    SyncTransfers transfers,
    String path,
    int size,
  ) async {
    final remote = await client.stat(path);
    if (remote == null) return false;
    final listed = remote.size;
    if (listed != null && listed != size) return false;
    final local = (await sides.hashLocal([path]))[path];
    if (local == null) return false;
    return local == await sides.remoteSha(transfers, path);
  }
}
