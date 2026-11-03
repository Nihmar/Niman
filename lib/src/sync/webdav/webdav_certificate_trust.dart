import 'dart:io';

import 'package:niman/src/sync/webdav/webdav_failure.dart';
import 'package:niman/src/sync/webdav/webdav_fingerprint.dart';
import 'package:niman/src/sync/webdav/webdav_paths.dart';

/// Which server certificate a WebDAV client accepts when the device cannot
/// verify it, and the failure it names when it refuses one (#366, #454).
final class WebDavCertificateTrust {
  /// Trust for the destination at [baseUrl]: only
  /// [trustedCertificateFingerprint], and only from that destination's own
  /// host; null trusts nothing beyond the device's own certificate store.
  new({required this.baseUrl, String? trustedCertificateFingerprint})
    : _trustedFingerprint = _fingerprintKey(trustedCertificateFingerprint);

  /// The destination folder whose host is the only one trust is offered for.
  final Uri baseUrl;

  /// The only certificate fingerprint this client accepts when the device
  /// cannot verify it (hex digits only, uppercased), or null when it
  /// accepts none (#454).
  final String? _trustedFingerprint;

  /// The last certificate the callback refused, with the host and port
  /// that presented it, so the failure can name what it refused — and
  /// where — even where the exception does not.
  ({String host, int port, String fingerprint})? _refused;

  /// Forgets the last refused certificate, before a new attempt.
  void forgetRefused() => _refused = null;

  /// Whether the device may proceed with a certificate it could not verify:
  /// true only for the one fingerprint the user confirmed for this
  /// destination, presented by the destination's own host, and false for
  /// everything else (#454), which leaves the failure [WebDavFailure] #366
  /// already described. Called by `dart:io` only when verification failed.
  bool onBadCertificate(X509Certificate certificate, String host, int port) {
    final fingerprint = sha256Fingerprint(certificate.der);
    final trusted = _trustedFingerprint;
    if (trusted != null &&
        _isDestinationHost(host) &&
        _fingerprintKey(fingerprint) == trusted) {
      return true;
    }
    _refused = (host: host, port: port, fingerprint: fingerprint);
    return false;
  }

  /// Whether [host] is the destination's own — the only host whose
  /// certificate the user can be asked to trust (#454).
  bool _isDestinationHost(String host) =>
      host.toLowerCase() == baseUrl.host.toLowerCase();

  /// The failure for a refused certificate, or null when [e] is TLS
  /// trouble of another kind (a version mismatch, a dropped handshake).
  ///
  /// A fingerprint the callback caught is the certificate itself and is
  /// preferred over one guessed out of the exception's text; when the
  /// callback never ran (an injected client in tests), the text is all
  /// there is.
  ///
  /// [at] is the URL the refused request went to (the destination when
  /// null): a redirect can lead to another host, whose certificate is not
  /// the destination's. That one is named as its own host's and carries
  /// no fingerprint — trust is offered for the destination's host only,
  /// and a fingerprint confirmed under the destination's name for another
  /// host's certificate would never be accepted there.
  WebDavCertificateFailure? certificateFailure(
    String method,
    String path,
    TlsException e, {
    Uri? at,
  }) {
    final refused = _refused;
    if (refused == null && !_certificateRefused(e)) return null;
    final where = at ?? baseUrl;
    final presenter = refused?.host ?? where.host;
    if (!_isDestinationHost(presenter)) {
      final port = refused?.port ?? where.port;
      return WebDavCertificateFailure(
        '$method ${webDavShowPath(path)}: the certificate for '
        '$presenter:$port, a redirect target, is not trusted',
        host: presenter,
      );
    }
    final fingerprint = refused?.fingerprint ?? _fingerprintIn(e);
    final host = baseUrl.host;
    final authority = baseUrl.hasPort ? '$host:${baseUrl.port}' : host;
    final digest = fingerprint == null ? '' : ', fingerprint $fingerprint';
    return WebDavCertificateFailure(
      '$method ${webDavShowPath(path)}: the certificate for $authority is '
      'not trusted$digest',
      host: host,
      fingerprint: fingerprint,
    );
  }

  /// Whether [e] is the device refusing the server's certificate, rather
  /// than any other TLS failure.
  ///
  /// The Dart VM raises [HandshakeException] from BoringSSL, whose text
  /// carries `CERTIFICATE_VERIFY_FAILED`; the named cases below cover a
  /// platform that words it differently.
  static bool _certificateRefused(TlsException e) {
    final text = '${e.message} ${e.osError?.message ?? ''}'.toLowerCase();
    return text.contains('certificate_verify_failed') ||
        (text.contains('certificate') &&
            (text.contains('self signed') ||
                text.contains('self-signed') ||
                text.contains('selfsigned') ||
                text.contains('untrusted') ||
                text.contains('not trusted') ||
                text.contains('verify failed')));
  }

  /// The certificate's fingerprint, when [e]'s text carries a digest.
  ///
  /// [TlsException] has no certificate field: the Dart VM's does not
  /// expose one, so this is null unless the platform put a digest in the
  /// message. A fingerprint is a long chain of hex bytes, which is what
  /// the pattern looks for.
  static String? _fingerprintIn(TlsException e) {
    final text = '${e.message} ${e.osError?.message ?? ''}';
    final match = RegExp(
      // A digest starts at a boundary: the `56` of a `SHA256:` label is
      // hex too, and must not be taken for the first byte.
      '(?<![0-9a-f])[0-9a-f]{2}(?::[0-9a-f]{2}){15,}'
      '|(?<![0-9a-f])[0-9a-f]{40,}',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(0)?.toUpperCase();
  }

  /// The comparison form of a certificate fingerprint: the hex digits
  /// alone, uppercased, so a stored `AB:CD:…` matches one written without
  /// the separators. An empty or separator-only string is no fingerprint.
  static String? _fingerprintKey(String? fingerprint) {
    if (fingerprint == null) return null;
    final digits = fingerprint.replaceAll(RegExp('[^0-9A-Fa-f]'), '');
    return digits.isEmpty ? null : digits.toUpperCase();
  }
}
