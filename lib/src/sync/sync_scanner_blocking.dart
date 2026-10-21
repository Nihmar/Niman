import 'dart:io';

import 'package:niman/src/sync/reconcile.dart';
import 'package:path/path.dart' as p;

// The local scan of `sync_scanner.dart`: it walks the library with
// synchronous stats, so it runs on a background isolate (a `statSync` or
// `existsSync` is a FUSE round trip on Android, #1143), which
// `ui_isolate_io_test.dart` holds this file to.

/// Whether a folder at library-relative [path] is walked: not a dot
/// folder, except `.niman` at the root (for its two synced files).
bool syncDescends(String path) {
  if (path == '.niman') return true;
  return !path.split('/').any((s) => s.startsWith('.'));
}

/// Every syncable file under [root] — or only under its folder [under] —
/// with size and mtime (no hashes).
///
/// Top-level so `Isolate.run` can take it. Symlinks are not followed.
Future<Map<String, LocalFileState>> scanLocalFiles(
  String root, {
  String under = '',
}) async {
  final files = <String, LocalFileState>{};
  if (under.isNotEmpty &&
      (!syncDescends(under) || !Directory(p.join(root, under)).existsSync())) {
    return files;
  }
  final queue = [under];
  while (queue.isNotEmpty) {
    final folder = queue.removeLast();
    final dir = Directory(folder.isEmpty ? root : p.join(root, folder));
    await for (final entity in dir.list(followLinks: false)) {
      final name = p.basename(entity.path);
      final rel = folder.isEmpty ? name : '$folder/$name';
      if (entity is Directory) {
        if (syncDescends(rel)) queue.add(rel);
      } else if (entity is File && isSyncablePath(rel)) {
        final stat = entity.statSync();
        files[rel] = LocalFileState(
          size: stat.size,
          mtimeMs: stat.modified.millisecondsSinceEpoch,
        );
      }
    }
  }
  return files;
}
