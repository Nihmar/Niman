// Gate for the Android "All files access" permission
// (`MANAGE_EXTERNAL_STORAGE`).
//
// Copist reads and writes the library with plain file I/O: the indexer
// walks it, the watcher watches it, notes are opened by path. On Android
// an app without this permission gets a filtered FUSE view of
// `/storage/emulated/0` — directories are listable, files it did not
// create are invisible and refuse to open (EACCES) — which is why a
// shared-storage library indexed zero notes.
//
// A Storage Access Framework tree grant does not replace it: that grant
// only opens the DocumentsProvider (`content://` URIs read through
// `ContentResolver`), and leaves the filesystem view untouched. The
// directory picker therefore only *chooses* the root; this permission is
// what makes it readable.

import 'dart:io';

import 'package:flutter/services.dart';

/// Whether Copist may read every file on shared storage.
final class StorageAccess {
  /// Creates the gate; use the static methods.
  const StorageAccess._();

  static const MethodChannel _channel = MethodChannel('copist/storage');

  /// Whether shared storage is fully readable right now.
  ///
  /// Always `true` off Android, where there is no such restriction.
  static Future<bool> hasAllFilesAccess() async {
    if (!Platform.isAndroid) return true;
    final granted =
        await _channel.invokeMethod<bool>('hasManageStorageAccess');
    return granted ?? false;
  }

  /// [hasAllFilesAccess], sending the user to grant it first when needed.
  ///
  /// On Android without the permission, opens Copist's page in the system
  /// "All files access" settings and completes once the user returns, with
  /// the grant state at that point. The permission is not a runtime
  /// permission: it can only be flipped there.
  static Future<bool> ensureAllFilesAccess() async {
    if (await hasAllFilesAccess()) return true;
    final granted =
        await _channel.invokeMethod<bool>('requestManageStorageAccess');
    return granted ?? false;
  }
}
