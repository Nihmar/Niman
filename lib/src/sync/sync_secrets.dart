import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:niman/src/core/logging.dart';
import 'package:path/path.dart' as p;

/// Where a library's WebDAV password lives (docs/dev/sync.md,
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
/// Credential Manager, libsecret on Linux.
///
/// One entry per library under `sync.<normalized library path>`.
final class SecureSyncSecretStore implements SyncSecretStore {
  /// A store over the given storage (the platform's default when omitted).
  new([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _log = AppLogger(name: 'sync');

  /// The storage key of [libraryPath]'s password.
  static String keyOf(String libraryPath) => 'sync.${p.normalize(libraryPath)}';

  @override
  Future<String?> read(String libraryPath) async {
    final value = await _storage.read(key: keyOf(libraryPath));
    _log.debug(
      'secret: read for $libraryPath: ${value == null ? 'none' : 'present'}',
    );
    return value;
  }

  @override
  Future<void> write(String libraryPath, String password) async {
    await _storage.write(key: keyOf(libraryPath), value: password);
    _log.info('secret: stored for $libraryPath');
  }

  @override
  Future<void> delete(String libraryPath) async {
    await _storage.delete(key: keyOf(libraryPath));
    _log.info('secret: deleted for $libraryPath');
  }
}
