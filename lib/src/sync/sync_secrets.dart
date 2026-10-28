import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// Where a library's WebDAV password lives (docs/records/sync.md,
/// "Configuration"): never in the database, never in a log.
abstract interface class SyncSecretStore {
  /// The password of [libraryPath]'s destination, or null when none is
  /// stored.
  Future<String?> read(String libraryPath);

  /// Stores [password] for [libraryPath], replacing any previous one.
  Future<void> write(String libraryPath, String password);

  /// Removes [libraryPath]'s password (no-op when there is none).
  Future<void> delete(String libraryPath);
}

/// [SyncSecretStore] on the OS secure storage: Android Keystore, Windows
/// Credential Manager, libsecret on Linux, the Keychain on Apple.
///
/// One entry per library under `sync.<normalized library path>`.
///
/// macOS: the entry goes to the data protection keychain, which needs the
/// `keychain-access-groups` entitlement that only a signed build carries.
/// A build signed ad hoc — every local `niman.sh macos` build without an
/// Apple Developer membership (docs/records/apple-platforms.md, "Builds,
/// flavors, signing") — is answered `errSecMissingEntitlement` (-34018)
/// instead, and the entry is kept in the login keychain, which needs no
/// entitlement (#1244).
final class SecureSyncSecretStore implements SyncSecretStore {
  /// A store over the given storage (the platform's default when omitted).
  ///
  /// On macOS it also holds the login keychain, to fall back to: the plugin
  /// picks its options by [defaultTargetPlatform] too, so the two agree on
  /// which Mac is which.
  new([this._storage = const FlutterSecureStorage()])
    : _loginKeychain = defaultTargetPlatform == TargetPlatform.macOS
          ? _loginKeychainOfMac
          : null;

  /// The login keychain: the same API with the data protection keychain
  /// switched off.
  static const _loginKeychainOfMac = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  final FlutterSecureStorage _storage;

  /// Where a build without the entitlement stores the entry on macOS.
  final FlutterSecureStorage? _loginKeychain;

  /// Whether this build cannot reach the data protection keychain: the
  /// first write it refused, or an entry found in the login keychain. For
  /// the rest of the process the login keychain is the one used.
  bool _onLoginKeychain = false;

  static const _log = AppLogger(name: 'sync');

  /// The storage key of [libraryPath]'s password.
  static String keyOf(String libraryPath) => 'sync.${p.normalize(libraryPath)}';

  /// `errSecMissingEntitlement`: the app is not signed for the keychain it
  /// asked, so no request of this build is ever answered by it.
  static bool _missingEntitlement(Object error) =>
      error is PlatformException &&
      (error.code == '-34018' || error.code == 'errSecMissingEntitlement');

  @override
  Future<String?> read(String libraryPath) async {
    final value = await _read(keyOf(libraryPath));
    _log.debug(
      'secret: read for $libraryPath: ${value == null ? 'none' : 'present'}',
    );
    return value;
  }

  Future<String?> _read(String key) async {
    final login = _loginKeychain;
    if (login == null || _onLoginKeychain) {
      return await (login ?? _storage).read(key: key);
    }
    final value = await _storage.read(key: key);
    if (value != null) return value;
    // Written by a build without the entitlement, or on this Mac before
    // there was one signed for the data protection keychain: the entry
    // there is the destination's, and this build keeps using that keychain.
    final stored = await login.read(key: key);
    if (stored != null) {
      _onLoginKeychain = true;
      _log.info('secret: found in the login keychain');
    }
    return stored;
  }

  @override
  Future<void> write(String libraryPath, String password) async {
    final key = keyOf(libraryPath);
    final login = _loginKeychain;
    if (login == null) {
      await _storage.write(key: key, value: password);
    } else {
      if (!_onLoginKeychain) {
        try {
          await _storage.write(key: key, value: password);
        } on PlatformException catch (e) {
          if (!_missingEntitlement(e)) rethrow;
          _onLoginKeychain = true;
          _log.warning(
            'secret: this build is not signed for the data protection '
            'keychain (${e.code}), the login keychain takes the entry',
          );
        }
      }
      if (_onLoginKeychain) await login.write(key: key, value: password);
    }
    _log.info('secret: stored for $libraryPath');
  }

  @override
  Future<void> delete(String libraryPath) async {
    final key = keyOf(libraryPath);
    final login = _loginKeychain;
    if (login == null) {
      await _storage.delete(key: key);
    } else {
      // Both: the entry may be in either, written by this build or by one
      // signed differently, and "forget it" means forget it everywhere.
      if (!_onLoginKeychain) {
        try {
          await _storage.delete(key: key);
        } on PlatformException catch (e) {
          if (!_missingEntitlement(e)) rethrow;
          // No request of this build reaches it: do not ask again.
          _onLoginKeychain = true;
        }
      }
      await login.delete(key: key);
    }
    _log.info('secret: deleted for $libraryPath');
  }
}
