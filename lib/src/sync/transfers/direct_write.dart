import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';
import 'package:niman/src/sync/webdav/webdav_failure.dart';

/// The largest new file a sync download holds in memory before it writes it
/// (16 MiB): up to it the body is received whole, checked, and only then
/// written to its final name in one go; past it the body streams into the
/// final name as it arrives.
const int kSyncDirectWriteMaxBytes = 16 << 20;

/// How a download put its bytes on the disk.
enum SyncWriteMode {
  /// A new file, received into memory and written to its final name once
  /// the checks passed, with no temp file and no rename.
  directMemory,

  /// A new file too large for memory, streamed into its final name, with no
  /// temp file and no rename.
  directStream,

  /// Into a hidden temp next to the target, renamed over it when the
  /// checks passed: the way a file that exists already is replaced, so the
  /// version the user has stays whole until the new one is complete.
  tempRename,
}

/// What a download of a new file delivered, and how it was written.
typedef NewFileDownload = ({WebDavDownload download, SyncWriteMode mode});

/// The final name of a new file was taken by something else before the
/// download could create it: nothing was written, nothing was overwritten.
final class DirectWriteRefused extends FileSystemException {
  /// The file at [path] exists already.
  new(String path, [OSError? osError])
    : super('Already exists, not overwritten', path, osError);
}

/// Checks a download of [path] against what the listing said of it: a
/// chunked answer carries no `Content-Length`, so the size is compared with
/// the listing's too — unless the ETag says the file was rewritten since,
/// which makes a different size legitimate.
void checkAgainstListing(
  String path,
  WebDavDownload download, {
  required int? listedSize,
  required String? listedEtag,
}) {
  final rewritten = download.etag != null && download.etag != listedEtag;
  if (listedSize != null && download.bytes != listedSize && !rewritten) {
    throw WebDavProtocolFailure(
      'GET $path: ${download.bytes} bytes, the listing said $listedSize',
    );
  }
}

const _log = AppLogger(name: 'sync');

/// `GET`s [path] through [client] into [targetPath], a file that must not
/// exist yet, without a temp file or a rename.
///
/// A new file is not a version of anything: there is nothing for a temp to
/// protect, and a rename onto a name per file is the pattern a ransomware
/// monitor looks for. So the body goes straight to its final name:
///
/// - a file the listing puts at [memoryLimit] bytes or less is received into
///   memory, checked against the listing, and only then created and written
///   in one go ([SyncWriteMode.directMemory]); a download that fails leaves
///   nothing on disk. A body that outgrows [memoryLimit] on the way fails as
///   a retryable error (the listing was stale; the next run lists it
///   again);
/// - a larger file, or one the listing gives no size for, is streamed into
///   it as it arrives ([SyncWriteMode.directStream]), and removed again if
///   the transfer or the checks fail.
///
/// The file is created exclusively: if anything exists at [targetPath] by
/// then, the download fails with [DirectWriteRefused] and that file is left
/// as it is. The bytes are flushed to storage and the handle closed before
/// this answers, so nothing can find the file open.
Future<NewFileDownload> downloadNewFile(
  WebDavClient client,
  String path,
  String targetPath, {
  required int? listedSize,
  required String? listedEtag,
  int memoryLimit = kSyncDirectWriteMaxBytes,
}) async {
  final inMemory = listedSize != null && listedSize <= memoryLimit;
  final download = inMemory
      ? await _viaMemory(
          client,
          path,
          targetPath,
          listedSize: listedSize,
          listedEtag: listedEtag,
          memoryLimit: memoryLimit,
        )
      : await _viaStream(
          client,
          path,
          targetPath,
          listedSize: listedSize,
          listedEtag: listedEtag,
        );
  final mode = inMemory
      ? SyncWriteMode.directMemory
      : SyncWriteMode.directStream;
  _log.info(
    'write: "$path" ${mode.name}, ${download.bytes} bytes '
    '(new file, no temp, no rename)',
  );
  return (download: download, mode: mode);
}

Future<WebDavDownload> _viaMemory(
  WebDavClient client,
  String path,
  String targetPath, {
  required int? listedSize,
  required String? listedEtag,
  required int memoryLimit,
}) async {
  final sink = _MemorySink(path, memoryLimit);
  final download = await client.download(path, sink);
  checkAgainstListing(
    path,
    download,
    listedSize: listedSize,
    listedEtag: listedEtag,
  );
  final file = File(targetPath);
  await _createExclusively(file);
  try {
    final handle = await file.open(mode: FileMode.writeOnly);
    try {
      await handle.writeFrom(sink.takeBytes());
      await handle.flush();
    } finally {
      await handle.close();
    }
  } on Object {
    await _removeQuietly(file);
    rethrow;
  }
  return download;
}

Future<WebDavDownload> _viaStream(
  WebDavClient client,
  String path,
  String targetPath, {
  required int? listedSize,
  required String? listedEtag,
}) async {
  final file = File(targetPath);
  await _createExclusively(file);
  RandomAccessFile? handle;
  try {
    // Opened before any request: a file that cannot be opened fails as the
    // local failure it is, not as a transfer that broke.
    handle = await file.open(mode: FileMode.writeOnly);
    final download = await client.download(path, _HandleSink(handle));
    checkAgainstListing(
      path,
      download,
      listedSize: listedSize,
      listedEtag: listedEtag,
    );
    await handle.flush();
    final done = handle;
    handle = null;
    await done.close();
    return download;
  } on Object {
    // Closed before the delete: a file with a handle on it cannot be
    // removed on Windows (#103, #495).
    try {
      await handle?.close();
    } on Object {
      // Nothing more to do with a handle that will not close.
    }
    await _removeQuietly(file);
    rethrow;
  }
}

/// Creates the empty [file] only if nothing exists there; otherwise throws
/// [DirectWriteRefused] and touches nothing.
Future<void> _createExclusively(File file) async {
  try {
    await file.create(exclusive: true);
  } on FileSystemException catch (e) {
    final there = await FileStat.stat(file.path);
    if (there.type != FileSystemEntityType.notFound) {
      throw DirectWriteRefused(file.path, e.osError);
    }
    rethrow;
  }
}

/// Deletes [file], and says nothing when it cannot: the failure that got us
/// here is the one to report, and a leftover is found by the pending mark
/// the run keeps for it.
Future<void> _removeQuietly(File file) async {
  try {
    await file.delete();
  } on Object {
    // Already gone, or not ours to remove any more.
  }
}

/// Collects a body in memory, failing past its limit.
final class _MemorySink implements StreamConsumer<List<int>> {
  new(this._path, this._limit);

  final String _path;
  final int _limit;
  final BytesBuilder _bytes = BytesBuilder(copy: false);

  Uint8List takeBytes() => _bytes.takeBytes();

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _bytes.add(chunk);
      if (_bytes.length > _limit) {
        throw WebDavRetryable(
          'GET $_path: the body outgrew the $_limit bytes held in memory '
          '(the listing was stale)',
          status: 200,
        );
      }
    }
  }

  @override
  Future<void> close() async {}
}

/// Writes a body to an open file, one chunk after the other; closing the
/// file is the caller's.
final class _HandleSink implements StreamConsumer<List<int>> {
  new(this._handle);

  final RandomAccessFile _handle;

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      await _handle.writeFrom(chunk);
    }
  }

  @override
  Future<void> close() async {}
}
