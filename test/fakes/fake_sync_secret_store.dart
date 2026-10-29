import 'package:niman/src/sync/sync_secrets.dart';
import 'package:path/path.dart' as p;

/// An in-memory [SyncSecretStore] for tests.
final class FakeSyncSecretStore implements SyncSecretStore {
  /// The stored passwords, by normalized library path.
  final Map<String, String> secrets = {};

  /// What [write] throws instead of storing, when set — a keychain that
  /// refuses the entry (#1244).
  Exception? writeFailure;

  @override
  Future<String?> read(String libraryPath) async =>
      secrets[p.normalize(libraryPath)];

  @override
  Future<void> write(String libraryPath, String password) async {
    final failure = writeFailure;
    if (failure != null) throw failure;
    secrets[p.normalize(libraryPath)] = password;
  }

  @override
  Future<void> delete(String libraryPath) async {
    secrets.remove(p.normalize(libraryPath));
  }
}
