import 'package:meta/meta.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';

/// What a finished `PUT` reported.
@immutable
final class WebDavUpload {
  /// An upload that [created] the item (or replaced it).
  const new({
    required this.created,
    this.etag,
    this.mtimeAccepted = false,
    this.sha256,
  });

  /// 201: the item did not exist before.
  final bool created;

  /// The new `ETag` (or `OC-ETag`) when the server returned one; many
  /// servers do not, and the caller PROPFINDs instead.
  final String? etag;

  /// Whether the server kept the `X-OC-Mtime` sent with the upload.
  final bool mtimeAccepted;

  /// The sha256 of the bytes sent, when the caller streamed a file
  /// ([WebDavClient.uploadFile]): what the row records, and what a plan
  /// compares its own hash against to tell whether the write it planned is
  /// the write the server got (#723).
  final String? sha256;
}
