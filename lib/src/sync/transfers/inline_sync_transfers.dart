import 'package:niman/src/sync/transfers/sync_transfers.dart';
import 'package:niman/src/sync/transfers/transfer_ops.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';

/// Transfers that run on the [WebDavClient] they are given, in the isolate
/// that calls them: what a sync run did before #1107, and what a client
/// built over an injected `HttpClient` (a test's, which cannot cross an
/// isolate) is left with. The client's own counters hold every byte, so
/// these report none.
final class InlineSyncTransfers implements SyncTransfers {
  /// Transfers over the run's client.
  const new(this._client);

  final WebDavClient _client;

  @override
  Future<WebDavDownload> download(String path, String tempPath) =>
      downloadToFile(_client, path, tempPath);

  @override
  Future<String> hashRemote(String path) => hashRemoteFile(_client, path);

  @override
  Future<WebDavUpload> upload(
    String path,
    String filePath, {
    String? ifMatch,
    bool ifNoneMatch = false,
    DateTime? modified,
  }) => uploadFromFile(
    _client,
    path,
    filePath,
    ifMatch: ifMatch,
    ifNoneMatch: ifNoneMatch,
    modified: modified,
  );

  @override
  int get bytesSent => 0;

  @override
  int get bytesReceived => 0;

  @override
  int get bytesHashed => 0;

  @override
  void cancel() {}

  @override
  Future<void> close() async {}
}
