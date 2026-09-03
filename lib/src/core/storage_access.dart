import 'dart:io';

import 'package:flutter/services.dart';

/// Gate for the Android "All files access" permission
/// (`MANAGE_EXTERNAL_STORAGE`).
///
/// On Android 11+ an app without the permission gets a filtered FUSE view
/// of `/storage/emulated/0`: directories are visible, files are not —
/// which is exactly why a shared-storage library used to index zero notes.
/// Desktop platforms have no such restriction and always pass.
final class StorageAccess {
  /// Creates the gate; use the static methods.
  const StorageAccess._();

  static const MethodChannel _channel = MethodChannel('copist/storage');

  /// Whether shared storage is fully readable right now.
  ///
  /// Always `true` on non-Android platforms.
  static Future<bool> hasAllFilesAccess() async {
    if (!Platform.isAndroid) return true;
    final granted =
        await _channel.invokeMethod<bool>('hasManageStorageAccess');
    return granted ?? false;
  }

  /// [hasAllFilesAccess], prompting the user first when needed.
  ///
  /// On Android without the permission, opens the system "All files
  /// access" settings screen and completes once the user returns, with
  /// the grant state at that point.
  static Future<bool> ensureAllFilesAccess() async {
    if (await hasAllFilesAccess()) return true;
    final granted =
        await _channel.invokeMethod<bool>('requestManageStorageAccess');
    return granted ?? false;
  }
}
