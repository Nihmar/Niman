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

/// The other names of the device's shared storage, `/storage/emulated/0`
/// where a library on Android lives: the same files, reached by another
/// path (a library opened through one of them is the same place).
const List<String> _sharedStorageAliases = [
  '/sdcard',
  '/mnt/sdcard',
  '/storage/self/primary',
];

/// A user's or a work profile's own shared storage, `/storage/emulated/10`,
/// which that profile's provider names as its `primary` as well.
final RegExp _userStorage = RegExp(r'^/storage/emulated/(?:0|[1-9][0-9]*)$');

/// A removable volume, an SD card or a USB drive, by the id the system gives
/// it — `/storage/1234-ABCD` — which the provider names it by.
final RegExp _volume = RegExp(r'^/storage/([0-9A-Fa-f]{4}-[0-9A-Fa-f]{4})$');

/// [path] as the document of Android's external storage provider that SAF
/// opens on, `content://com.android.externalstorage.documents/document/
/// primary%3ANotes%2FWork`; null for a path on no storage the provider
/// names — an app's private folder.
///
/// The shared storage is the provider's `primary`, whichever of its paths
/// [path] is under; a removable volume is its id, `1234-ABCD:Notes`.
String? androidDocumentOf(String path) {
  final normalized = p.posix.normalize(path);
  final segments = p.posix.split(normalized);
  // `/storage/emulated/<user>` and `/storage/<volume>`, when the path
  // opens with as many segments.
  final user = segments.length >= 4 ? p.posix.joinAll(segments.take(4)) : '';
  final volume = segments.length >= 3 ? p.posix.joinAll(segments.take(3)) : '';
  for (final root in [
    ..._sharedStorageAliases,
    if (_userStorage.hasMatch(user)) user,
  ]) {
    final relative = _under(root, normalized);
    if (relative != null) return _document('primary', relative);
  }
  final id = _volume.firstMatch(volume)?.group(1);
  if (id == null) return null;
  return _document(id, _under(volume, normalized)!);
}

/// [path] relative to [root], `''` for [root] itself; null when it is not
/// under it.
String? _under(String root, String path) {
  if (path == root) return '';
  if (!p.posix.isWithin(root, path)) return null;
  return p.posix.relative(path, from: root);
}

/// The provider's document for [relative] on the storage named [root].
String _document(String root, String relative) =>
    'content://com.android.externalstorage.documents/document/'
    '${Uri.encodeComponent('$root:$relative')}';
