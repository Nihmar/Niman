import 'package:meta/meta.dart';

/// What a finished `GET` delivered.
@immutable
final class WebDavDownload {
  /// A download of [bytes] bytes hashing to [sha256].
  const new({
    required this.bytes,
    required this.sha256,
    this.etag,
    this.modified,
  });

  /// Bytes received (and checked against `Content-Length` when sent).
  final int bytes;

  /// Lowercase hex sha256 of those bytes, computed while streaming.
  final String sha256;

  /// The response's `ETag`, or null.
  final String? etag;

  /// The response's `Last-Modified` (UTC), or null.
  final DateTime? modified;
}
