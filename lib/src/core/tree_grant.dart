// Takes the persistent Storage Access Framework grant on a picked tree
// URI.
//
// `file_picker`'s SAF options are supposed to do this, but in
// android_file_picker 1.1.0 (the latest) the Dart side nests the
// options under a `safOptions` key the Kotlin side never reads, so the
// grant is silently skipped. The transient grant from the pick result
// is still held by the activity, so we take the persistent grant
// ourselves right after the pick.

import 'dart:io';

import 'package:flutter/services.dart';

/// Takes the persistent SAF grant on a tree URI.
final class TreeGrant {
  const TreeGrant._();

  static const MethodChannel _channel = MethodChannel('copist/storage');

  /// Takes the persistent read+write grant on [uri].
  ///
  /// Returns false when the grant could not be taken; always true off
  /// Android, where there is nothing to grant.
  static Future<bool> takePersistent(String uri) async {
    if (!Platform.isAndroid) {
      return true;
    }
    final ok = await _channel.invokeMethod<bool>(
      'takeTreeGrant',
      {'uri': uri},
    );
    return ok ?? false;
  }
}
