import 'package:meta/meta.dart';
import 'package:niman/src/sync/webdav/webdav_client.dart';

/// What it takes to build a [WebDavClient] again somewhere else: the
/// destination's URL, the credentials, the one certificate fingerprint the
/// user confirmed (#454) and the timeout. Plain strings and numbers, so it
/// can be sent to another isolate, where the sync's transfer worker builds
/// a client of its own from it (#1107).
///
/// Holds the password in memory, as the client does; it is never logged.
@immutable
final class WebDavClientConfig {
  /// A client for the folder at [url], with the same meaning for every field
  /// as `WebDavClient.new`.
  const new({
    required this.url,
    this.username = '',
    this.password = '',
    this.trustedCertificateFingerprint,
    this.timeoutMs = 30000,
  });

  /// The destination folder's URL, as the client was given it.
  final String url;

  /// The user name; empty means no authentication.
  final String username;

  /// The password.
  final String password;

  /// The SHA-256 fingerprint of the one certificate this destination may
  /// present when the device cannot verify it, or null (#454).
  final String? trustedCertificateFingerprint;

  /// The client's timeout, in milliseconds.
  final int timeoutMs;

  /// A client built from this configuration, over a connection pool of its
  /// own.
  WebDavClient build() => WebDavClient(
    url: Uri.parse(url),
    username: username,
    password: password,
    trustedCertificateFingerprint: trustedCertificateFingerprint,
    timeout: Duration(milliseconds: timeoutMs),
  );
}
