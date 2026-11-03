/// How a connection test ended (mockups S3, S3b).
enum SyncTestOutcome {
  /// The folder is a usable WebDAV collection.
  ok,

  /// The address is not a valid `http(s)://host/…` URL, or carries
  /// credentials.
  invalidUrl,

  /// No answer (network, VPN, timeout).
  offline,

  /// 401 / 403.
  authentication,

  /// The folder does not exist.
  notFound,

  /// The server answers but is not WebDAV, or refuses what sync needs.
  unsupported,

  /// The server's TLS certificate is not trusted (#366, #454): the user
  /// may confirm it, by fingerprint, for this destination.
  certificate,

  /// Anything else (a TLS failure that is not the certificate, an
  /// unexpected answer).
  failed,
}
