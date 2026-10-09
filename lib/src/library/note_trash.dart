import 'dart:convert';
import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_config_repo.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/note_history.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

/// One item in `.trash/`, mapped back to its library-relative origin.
final class TrashItem {
  /// Creates a trash listing entry.
  const new({
    required this.name,
    required this.originalPath,
    required this.deletedAt,
  });

  /// Name inside `.trash/` (timestamped when a collision was resolved).
  final String name;

  /// Library-relative path before the delete.
  final String originalPath;

  /// When the item was deleted.
  final DateTime deletedAt;
}

/// The library's `.trash/`: deletes, restores and empties it, and keeps
/// the manifest that maps each item back to where it came from.
///
/// Deletes move into `.trash/` while the trash toggle is on; with it off
/// they hard-delete. Every operation runs in the op chain [serialize]
/// hands it, and reports what it changed to [hint].
final class NoteTrash {
  /// Creates the trash of the library at [root].
  new({
    required this.root,
    required this.indexer,
    required this.history,
    required this.config,
    required this.serialize,
    required this.hint,
    required this.find,
  });

  /// The name of the trash manifest inside `.trash/`.
  static const manifestFileName = '.niman-trash.json';

  /// Absolute path of the library root.
  final String root;

  /// The shared indexer; every change to the trash goes through it.
  final Indexer indexer;

  /// The library's `.history/`, dropped with an item deleted for good.
  final NoteHistory history;

  /// The library settings, holding the trash toggle.
  final LibraryConfigRepo config;

  /// The op chain of the library's operations.
  final Serializer serialize;

  /// Where the trash reports the paths it changed.
  final SyncHintSink hint;

  /// The indexed row at a path; throws when there is none.
  final Future<Note> Function(String path) find;

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// Deletes [path]: into `.trash/` when the trash toggle is on, hard
  /// delete otherwise.
  Future<void> delete(String path) {
    return serialize(() async {
      final row = await find(path);
      final oldAbs = _abs(path);
      final trash = (await config.config).trashEnabled;
      String? trashAbs;
      if (trash) {
        trashAbs = await moveIntoTrash(path, isDir: row.isDir);
      } else {
        if (row.isDir) {
          await Directory(oldAbs).delete(recursive: true);
        } else {
          await File(oldAbs).delete();
        }
        // No trash to come back from: the history goes with the note.
        await history.deleted(path, isDir: row.isDir);
      }
      hint(path, SyncOpKind.deleted);
      final events = <String>[oldAbs];
      if (trashAbs != null) events.add(trashAbs);
      await indexer.applyEvents(root, events);
    });
  }

  /// Moves [path] into `.trash/` under a collision-safe name and records
  /// it in the manifest; returns the absolute trash path. The history
  /// stays at [path] (a restore brings it back).
  ///
  /// Not serialized itself: the caller runs it inside the op chain.
  Future<String> moveIntoTrash(String path, {required bool isDir}) async {
    final trashDir = Directory(_abs('.trash'));
    if (!trashDir.existsSync()) {
      await trashDir.create(recursive: true);
    }
    final name = p.basename(path);
    String target;
    if (isDir) {
      target = await trashDirName(trashDir, name);
    } else {
      final parts = splitFileName(name);
      target = await trashFileName(trashDir, parts.base, parts.ext);
    }
    final trashAbs = _abs('.trash/$target');
    if (isDir) {
      await Directory(_abs(path)).rename(trashAbs);
    } else {
      await File(_abs(path)).rename(trashAbs);
    }
    await _manifestAdd(trashDir, target, path);
    return trashAbs;
  }

  /// Lists the managed trash items (manifest-backed), in deletion order.
  Future<List<TrashItem>> items() {
    return serialize(() async {
      final manifest = await _readManifest();
      return [
        for (final entry in manifest.entries)
          if (_existsInTrash(entry.key))
            TrashItem(
              name: entry.key,
              originalPath: entry.value.originalPath,
              deletedAt: entry.value.deletedAt,
            ),
      ];
    });
  }

  /// Restores the trash item [trashName] to its original parent when that
  /// folder still exists, otherwise to the library root.
  ///
  /// The item comes back under its original name (uniquified only on a
  /// real collision), which is taken from the manifest's `originalPath` —
  /// never from the name inside `.trash/`, which carries a collision
  /// timestamp and would survive the restore.
  Future<Note> restore(String trashName) {
    return serialize(() async {
      final manifest = await _readManifest();
      final entry = manifest[trashName];
      if (entry == null) {
        throw StateError('Not a managed trash item: "$trashName"');
      }
      final trashAbs = _abs('.trash/$trashName');
      final isDir = Directory(trashAbs).existsSync();
      final originalName = p.basename(entry.originalPath);
      final originalParent = parentOf(entry.originalPath);
      final originalDir = Directory(_abs(originalParent));
      final restoreParent = originalDir.existsSync() ? originalParent : '';
      final parentDirObj = Directory(_abs(restoreParent));
      String target;
      if (isDir) {
        target = await uniqueFolderName(parentDirObj, originalName);
      } else {
        final parts = splitFileName(originalName);
        target = await uniqueFileName(parentDirObj, parts.base, parts.ext);
      }
      final newRel = resolvePath(restoreParent, target);
      if (isDir) {
        await Directory(trashAbs).rename(_abs(newRel));
      } else {
        await File(trashAbs).rename(_abs(newRel));
      }
      manifest.remove(trashName);
      await _writeManifest(manifest);
      hint(newRel, SyncOpKind.changed);
      // The history stayed at the original path while the item was in the
      // trash; it follows only when the item came back somewhere else.
      await history.moved(entry.originalPath, newRel, isDir: isDir);
      await indexer.applyEvents(root, [trashAbs, _abs(newRel)]);
      return await find(newRel);
    });
  }

  /// Permanently deletes the trash item [trashName] (no restore possible).
  Future<void> deletePermanently(String trashName) {
    return serialize(() async {
      final manifest = await _readManifest();
      final entry = manifest.remove(trashName);
      if (entry == null) {
        throw StateError('Not a managed trash item: "$trashName"');
      }
      final trashAbs = _abs('.trash/$trashName');
      final isDir = Directory(trashAbs).existsSync();
      if (isDir) {
        await Directory(trashAbs).delete(recursive: true);
      } else if (File(trashAbs).existsSync()) {
        await File(trashAbs).delete();
      }
      await _writeManifest(manifest);
      await _dropTrashedHistory(entry.originalPath, isDir: isDir);
    });
  }

  /// Deletes every entry in `.trash/`, not just the items Niman put
  /// there: the trash screen promises to empty the folder, and that
  /// includes anything a user moved into it by hand. Ends with an empty
  /// manifest.
  Future<void> empty() {
    return serialize(() async {
      final trashDir = Directory(_abs('.trash'));
      // Read before the items go: the manifest is what knows where each
      // one came from, and so whose history is now orphaned.
      final origins = [
        for (final entry in (await _readManifest()).entries)
          (
            entry.value.originalPath,
            Directory(_abs('.trash/${entry.key}')).existsSync(),
          ),
      ];
      if (trashDir.existsSync()) {
        for (final entry in trashDir.listSync()) {
          if (entry is Directory) {
            await entry.delete(recursive: true);
          } else {
            await entry.delete();
          }
        }
      }
      await _writeManifest(<String, _ManifestEntry>{});
      for (final (originalPath, isDir) in origins) {
        await _dropTrashedHistory(originalPath, isDir: isDir);
      }
    });
  }

  /// Removes the history a permanently deleted trash item left at
  /// [originalPath] — unless a note lives there again, whose history it
  /// now is.
  Future<void> _dropTrashedHistory(
    String originalPath, {
    required bool isDir,
  }) async {
    final abs = _abs(originalPath);
    if (File(abs).existsSync() || Directory(abs).existsSync()) return;
    await history.deleted(originalPath, isDir: isDir);
  }

  bool _existsInTrash(String name) {
    final abs = _abs('.trash/$name');
    return Directory(abs).existsSync() || File(abs).existsSync();
  }

  // -- manifest --------------------------------------------------------

  /// Reads the trash manifest, surviving a torn or partially corrupt file:
  /// a whole file that is not a JSON object yields an empty manifest, and
  /// individual entries that do not decode are skipped, so one bad entry
  /// can never take the trash screen down.
  Future<Map<String, _ManifestEntry>> _readManifest() async {
    final file = File(_abs('.trash/$manifestFileName'));
    if (!file.existsSync()) return <String, _ManifestEntry>{};
    final raw = file.readAsStringSync();
    if (raw.trim().isEmpty) return <String, _ManifestEntry>{};
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return <String, _ManifestEntry>{};
    }
    if (decoded is! Map) return <String, _ManifestEntry>{};
    final manifest = <String, _ManifestEntry>{};
    for (final entry in decoded.entries) {
      final name = entry.key;
      if (name is! String) continue;
      final parsed = _parseManifestEntry(entry.value);
      if (parsed != null) manifest[name] = parsed;
    }
    return manifest;
  }

  static _ManifestEntry? _parseManifestEntry(Object? json) {
    if (json is! Map) return null;
    final originalPath = json['originalPath'];
    final deletedAt = json['deletedAt'];
    if (originalPath is! String || deletedAt is! int) return null;
    return _ManifestEntry(
      originalPath: originalPath,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(deletedAt),
    );
  }

  /// Writes the manifest, dropping entries whose item is no longer on disk
  /// so the file converges with `.trash/` even when something removed an
  /// item without going through the ops.
  Future<void> _writeManifest(Map<String, _ManifestEntry> manifest) async {
    final trashDir = Directory(_abs('.trash'));
    if (!trashDir.existsSync()) await trashDir.create(recursive: true);
    final kept = {
      for (final entry in manifest.entries)
        if (_existsInTrash(entry.key)) entry.key: entry.value,
    };
    final payload = jsonEncode({
      for (final entry in kept.entries) entry.key: entry.value.toJson(),
    });
    await writeFileAtomically(
      File(_abs('.trash/$manifestFileName')),
      utf8.encode(payload),
    );
  }

  Future<void> _manifestAdd(
    Directory trashDir,
    String name,
    String originalPath,
  ) async {
    final manifest = await _readManifest();
    manifest[name] = _ManifestEntry(
      originalPath: originalPath,
      deletedAt: DateTime.now(),
    );
    await _writeManifest(manifest);
  }
}

/// One manifest entry: where a trash item came from.
final class _ManifestEntry {
  /// Creates a manifest entry.
  const new({required this.originalPath, required this.deletedAt});

  /// Library-relative path before the delete.
  final String originalPath;

  /// When the item was deleted.
  final DateTime deletedAt;

  /// Serializes the entry for the manifest file.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'originalPath': originalPath,
    'deletedAt': deletedAt.millisecondsSinceEpoch,
  };
}
