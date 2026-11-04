import 'package:crypto/crypto.dart';

/// The SHA-256 fingerprint of a DER-encoded certificate: uppercase hex
/// bytes joined with `:`, the way `openssl x509 -fingerprint -sha256`
/// prints it. This is the value a destination stores and compares against
/// (#454), so it is computed from the certificate's own bytes rather than
/// from anything a message says.
String sha256Fingerprint(List<int> der) =>
    _formatFingerprint(sha256.convert(der).bytes);

/// [digest] as uppercase hex bytes joined with `:`.
String _formatFingerprint(List<int> digest) => [
  for (final byte in digest)
    byte.toRadixString(16).padLeft(2, '0').toUpperCase(),
].join(':');
