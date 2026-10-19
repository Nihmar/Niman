import 'dart:async';
import 'dart:io';

import 'package:niman/src/sync/webdav/webdav_client.dart';

/// `GET`s [path] through [client] into the file at [tempPath], and closes
/// that file before answering; a failure leaves no file there.
///
/// The one place a download meets the disk, whichever isolate runs it.
Future<WebDavDownload> downloadToFile(
  WebDavClient client,
  String path,
  String tempPath,
) async {
  final temp = File(tempPath);
  try {
    // Opened once here, before any request: a file that cannot be opened
    // fails as the local failure it is, not as a transfer that broke, and
    // not as an error on the sink's `done` that nobody listens to yet — an
    // uncaught one ends a worker isolate.
    await (await temp.open(mode: FileMode.write)).close();
    // The sink is ours, not the client's (issue #103). Handing
    // `temp.openWrite()` straight in left its closing to whatever the
    // consumer did with it, and the file the download had just written
    // then went into a rename that never returned on Windows — where,
    // unlike POSIX, a file with a handle still on it cannot be
    // renamed. A note never hit it because its temp is written by
    // `writeAsBytes`, which closes on its own.
    final sink = temp.openWrite();
    unawaited(sink.done.then<void>((_) {}, onError: (Object _) {}));
    final WebDavDownload download;
    try {
      download = await client.download(path, sink);
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
    return download;
  } on Object {
    if (temp.existsSync()) await temp.delete();
    rethrow;
  }
}

/// The sha256 of the server's copy of [path], downloaded through [client]
/// and dropped.
Future<String> hashRemoteFile(WebDavClient client, String path) async =>
    (await client.download(path, _DiscardSink(), hashOnly: true)).sha256;

/// `PUT`s the file at [filePath] to [path] through [client], the length and
/// the bytes from one open handle (#723).
Future<WebDavUpload> uploadFromFile(
  WebDavClient client,
  String path,
  String filePath, {
  String? ifMatch,
  bool ifNoneMatch = false,
  DateTime? modified,
}) => client.uploadFile(
  path,
  File(filePath),
  ifMatch: ifMatch,
  ifNoneMatch: ifNoneMatch,
  modified: modified,
);

final class _DiscardSink implements StreamConsumer<List<int>> {
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<void> close() async {}
}
