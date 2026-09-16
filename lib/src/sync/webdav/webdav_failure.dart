/// Why a WebDAV request failed (docs/dev/sync.md, "The client").
///
/// Messages carry a verb, a library-relative path and a status — never
/// a URL with credentials, a header or file content — so they are safe
/// to log and to show.
sealed class WebDavFailure implements Exception {
  /// A failure described by [message], with the HTTP [status] when the
  /// server answered.
  const new(this.message, {this.status});

  /// What went wrong, safe to log.
  final String message;

  /// The HTTP status, or null when no response arrived.
  final int? status;

  @override
  String toString() =>
      'WebDavFailure(${status == null ? '' : '$status, '}$message)';
}

/// 401 or 403: the credentials are wrong or lack access. Retrying without
/// new credentials cannot help.
final class WebDavAuthFailure extends WebDavFailure {
  /// See [WebDavFailure.new].
  const new(super.message, {super.status});
}

/// 404, or 409 on a write whose parent folder does not exist.
final class WebDavNotFound extends WebDavFailure {
  /// See [WebDavFailure.new].
  const new(super.message, {super.status});
}

/// 412: an `If-Match` / `If-None-Match` condition, or `Overwrite: F`,
/// did not hold — someone else changed the item.
final class WebDavPrecondition extends WebDavFailure {
  /// See [WebDavFailure.new].
  const new(super.message, {super.status});
}

/// A failure worth retrying later: the network, a timeout, a busy or
/// locked server (408, 423, 425, 429, 500, 502, 503, 504).
final class WebDavRetryable extends WebDavFailure {
  /// See [WebDavFailure.new]; [retryAfter] is the server's `Retry-After`.
  const new(super.message, {super.status, this.retryAfter});

  /// How long the server asked to wait, when it said.
  final Duration? retryAfter;
}

/// The folder answers HTTP but is not a usable WebDAV collection (no
/// `DAV:` header, or a verb the sync needs is refused).
final class WebDavUnsupported extends WebDavFailure {
  /// See [WebDavFailure.new].
  const new(super.message, {super.status});
}

/// Any other answer the client does not expect: a bad redirect, an
/// unparsable multistatus, a status with no meaning here, a TLS failure.
final class WebDavProtocolFailure extends WebDavFailure {
  /// See [WebDavFailure.new].
  const new(super.message, {super.status});
}
