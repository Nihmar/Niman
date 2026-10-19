import 'package:niman/src/sync/webdav/webdav_client.dart';

/// The bulk transfers of a sync run — the downloads and the uploads, the
/// requests that carry a file's bytes — apart from the small requests
/// (`PROPFIND`, `MKCOL`, `DELETE`, `MOVE`), which stay on the run's own
/// [WebDavClient] (#1107).
///
/// What moves bytes is the one thing a sync run does that costs per-chunk
/// work (the socket reads, the hash, the file writes), so it is the one
/// thing worth taking off the isolate that also renders the app. Two
/// implementations: `InlineSyncTransfers` runs on the client it is given,
/// wherever that is; `IsolateSyncTransfers` runs on a worker isolate of its
/// own. Both fail with the same `WebDavFailure` subtypes the client throws,
/// so the engine handles a failed transfer the same way either runs it.
abstract interface class SyncTransfers {
  /// `GET`s [path] into the file at [tempPath], which is written and
  /// closed — its handle gone, so Windows can rename it — before this
  /// answers. Nothing is left at [tempPath] when it fails.
  Future<WebDavDownload> download(String path, String tempPath);

  /// The sha256 of the server's copy of [path], downloaded and dropped.
  Future<String> hashRemote(String path);

  /// `PUT`s the file at [filePath] to [path]; [ifMatch], [ifNoneMatch] and
  /// [modified] go with it as they are. The answer carries the digest of
  /// the bytes actually sent ([WebDavUpload.sha256]).
  Future<WebDavUpload> upload(
    String path,
    String filePath, {
    String? ifMatch,
    bool ifNoneMatch = false,
    DateTime? modified,
  });

  /// Body bytes these transfers sent on connections of their own, which the
  /// run's [WebDavClient] never saw; zero for transfers that run on that
  /// client, whose counters already hold them.
  int get bytesSent;

  /// Body bytes these transfers received and kept, on connections of their
  /// own (see [bytesSent]).
  int get bytesReceived;

  /// Body bytes these transfers downloaded only to hash them, on
  /// connections of their own (see [bytesSent]).
  int get bytesHashed;

  /// Stops the requests in flight: each fails as a retryable transfer and
  /// leaves nothing behind. The run is over, or about to be; nothing is
  /// asked of the transfers afterwards but [close].
  void cancel();

  /// Ends the transfers and releases what they hold. The byte counters are
  /// final once it completes.
  Future<void> close();
}
