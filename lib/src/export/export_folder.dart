/// Where the save dialog of an export opens (#1286): wherever the system
/// opens it, or in the library's own folder — the library's setting
/// ([ExportFolder]).
///
/// The desktops' dialogs on Linux and Windows open where they are told.
/// Android's picker is the system's (SAF), which takes a place only as a
/// hint, and only as one of its documents: the library's folder on the
/// device's shared storage is named so for a file's save, and its folder
/// picker takes no hint at all. A Mac's and an iPhone's dialogs are not
/// told by the plugin that opens them: there, the system chooses — a
/// decision for now, written in `docs/user/platforms.md`.
library;

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show ExportFolder;
import 'package:path/path.dart' as p;

/// The place an export's dialog is told to open in, for [choice] in the
/// library at [root] (absolute); null leaves it to the system.
///
/// [android] and [desktop] say which platform asks, the host's by default:
/// a test describes each.
String? exportStartFolder(
  ExportFolder choice,
  String root, {
  bool? android,
  bool? desktop,
}) {
  if (choice == ExportFolder.system || root.isEmpty) return null;
  final pinned = debugExportDialogsOpenWhereTold;
  if (android ?? (pinned == null && Platform.isAndroid)) {
    return androidDocumentOf(root);
  }
  final opens = desktop ?? pinned ?? (Platform.isLinux || Platform.isWindows);
  return opens ? root : null;
}

/// Pins whether this host's export dialogs open where they are told, for a
/// test that describes a desktop whatever it runs on; null follows the
/// host.
@visibleForTesting
bool? debugExportDialogsOpenWhereTold;

/// The device's shared storage, where a library on Android lives.
const String androidSharedStorage = '/storage/emulated/0';

/// [path] as the document of Android's external storage provider that SAF
/// opens on, `content://com.android.externalstorage.documents/document/
/// primary%3ANotes%2FWork`; null for a path outside the shared storage,
/// which the provider does not name.
String? androidDocumentOf(String path) {
  final normalized = p.posix.normalize(path);
  if (normalized != androidSharedStorage &&
      !p.posix.isWithin(androidSharedStorage, normalized)) {
    return null;
  }
  final relative = normalized == androidSharedStorage
      ? ''
      : p.posix.relative(normalized, from: androidSharedStorage);
  return 'content://com.android.externalstorage.documents/document/'
      '${Uri.encodeComponent('primary:$relative')}';
}
