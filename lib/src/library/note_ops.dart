import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/core/settings/library_config_repo.dart';
import 'package:copist/src/db/dao.dart';
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/db/indexer.dart';
import 'package:copist/src/frontmatter/edit.dart';
import 'package:copist/src/library/session.dart';
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

/// Creates / renames / moves / deletes notes and folders on disk, and keeps
/// the index in step through the shared [indexer] (T-M1-05, T-M1-07).
///
/// Deletes move into `.trash/` while the trash toggle is on; with it off
/// they hard-delete. Trash contents are tracked in a manifest file so items
/// can be restored to their original location.
final class NoteOps implements NoteOperations {
  /// Creates the ops for the library at [root].
  ///
  /// [config] is the session's own reader of `.copist/settings.json`, not
  /// a second one: the session resolves the overridable settings through
  /// the same cache these four go through (T-ML-10).
  new({
    required this.root,
    required IndexDatabase db,
    required this.indexer,
    required this.config,
  }) : _dao = NoteDao(db);

  /// Absolute path of the library root.
  final String root;

  /// The shared indexer; every op funnels its disk change through it.
  final Indexer indexer;

  /// The library's `.copist/settings.json`, shared with the session so
  /// both read one cached copy.
  final LibraryConfigRepo config;

  final NoteDao _dao;

  /// The name of the trash manifest inside `.trash/`.
  static const manifestFileName = '.copist-trash.json';

  Future<void> _chain = Future<void>.value();

  /// Runs [fn] serially with every other op.
  Future<T> _synchronized<T>(Future<T> Function() fn) {
    final next = _chain.then((_) => fn());
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// The indexed note/folder at library-relative [path], or null.
  @override
  Future<Note?> find(String path) => _dao.find(path);

  Future<Note> _mustFind(String path) async {
    final row = await _dao.find(path);
    if (row == null) throw StateError('No indexed note at "$path"');
    return row;
  }

  /// The current trash toggle for this library.
  @override
  Future<bool> get trashEnabled async => (await config.config).trashEnabled;

  /// Sets the trash toggle: `true` = deletes move into `.trash/`.
  @override
  Future<void> setTrashEnabled({required bool enabled}) =>
      config.update((c) => c.copyWith(trashEnabled: enabled));

  /// The list-note folder (library-relative).
  @override
  Future<String> get listNoteFolder async =>
      (await config.config).listNoteFolder;

  /// Sets the list-note folder (sanitized; an empty result falls back to
  /// the default).
  @override
  Future<void> setListNoteFolder({required String folder}) =>
      config.update((c) => c.copyWith(listNoteFolder: cleanListFolder(folder)));

  /// The folder holding the note templates (default `Templates`).
  @override
  Future<String> get templateFolder async =>
      (await config.config).templateFolder;

  /// Sets the template folder (sanitized; an empty result falls back to
  /// the default).
  @override
  Future<void> setTemplateFolder({required String folder}) => config.update(
    (c) => c.copyWith(templateFolder: cleanTemplateFolder(folder)),
  );

  /// The user-chosen quick note, or null for the default.
  @override
  Future<String?> get quickNotePath async =>
      (await config.config).quickNotePath;

  /// Sets (or clears) the user-chosen quick note.
  @override
  Future<void> setQuickNotePath({required String? path}) => config.update(
    (c) => c.copyWith(quickNotePath: path, clearQuickNotePath: path == null),
  );

  /// Creates a `<name>.md` note in [parentPath] with [content] as its
  /// initial content, uniquifying the name. Returns the indexed row.
  @override
  Future<Note> createNote({
    required String parentPath,
    required String name,
    String content = '',
  }) {
    return _synchronized(() async {
      final clean = sanitizeName(name, fallback: defaultNoteName);
      final dir = Directory(_abs(parentPath));
      final unique = await uniqueFileName(dir, clean, '.md');
      final file = File(_abs(resolvePath(parentPath, unique)));
      await writeFileAtomically(file, utf8.encode(content));
      await indexer.applyEvents(root, [file.path]);
      return await _mustFind(resolvePath(parentPath, unique));
    });
  }

  /// Creates a folder in [parentPath], uniquifying the name.
  @override
  Future<Note> createFolder({
    required String parentPath,
    required String name,
  }) {
    return _synchronized(() async {
      final clean = sanitizeName(name, fallback: defaultFolderName);
      final dir = Directory(_abs(parentPath));
      final unique = await uniqueFolderName(dir, clean);
      final newDir = Directory(_abs(resolvePath(parentPath, unique)));
      await newDir.create(recursive: true);
      await indexer.applyEvents(root, [newDir.path]);
      return await _mustFind(resolvePath(parentPath, unique));
    });
  }

  /// Renames the note or folder at [path] to [newName].
  ///
  /// Notes are always stored as `<name>.md`; a trailing `.md` in [newName]
  /// is treated as redundant. Names are uniquified against the new parent
  /// (self excluded). Returns the updated row.
  @override
  Future<Note> rename(String path, String newName) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      final parent = parentOf(path);
      final parentDir = Directory(_abs(parent));
      var base = newName;
      if (base.endsWith('.md')) base = base.substring(0, base.length - 3);
      String target;
      if (row.isDir) {
        final clean = sanitizeName(base, fallback: defaultFolderName);
        target = await uniqueFolderName(parentDir, clean, exclude: _abs(path));
      } else {
        final clean = sanitizeName(base, fallback: defaultNoteName);
        target = await uniqueFileName(
          parentDir,
          clean,
          '.md',
          exclude: _abs(path),
        );
      }
      final newRel = resolvePath(parent, target);
      if (newRel == path) return row;
      final oldAbs = _abs(path);
      if (row.isDir) {
        await Directory(oldAbs).rename(_abs(newRel));
      } else {
        await File(oldAbs).rename(_abs(newRel));
      }
      await indexer.applyEvents(root, [oldAbs, _abs(newRel)]);
      return await _mustFind(newRel);
    });
  }

  /// Moves the note or folder at [path] into [targetParent], keeping its
  /// name (uniquified in the target). Returns the updated row.
  ///
  /// Throws [ArgumentError] when [targetParent] is [path] itself or inside
  /// it — a folder cannot be renamed onto its own subtree.
  @override
  Future<Note> move(String path, String targetParent) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      if (resolvePath(targetParent, p.basename(path)) == path) return row;
      if (targetParent == path || isUnder(path, targetParent)) {
        throw ArgumentError(
          'Cannot move "$path" into itself or its own subtree',
        );
      }
      final name = p.basename(path);
      final targetDir = Directory(_abs(targetParent));
      String target;
      if (row.isDir) {
        target = await uniqueFolderName(targetDir, name);
      } else {
        final parts = splitFileName(name);
        target = await uniqueFileName(targetDir, parts.base, parts.ext);
      }
      final newRel = resolvePath(targetParent, target);
      final oldAbs = _abs(path);
      if (row.isDir) {
        await Directory(oldAbs).rename(_abs(newRel));
      } else {
        await File(oldAbs).rename(_abs(newRel));
      }
      await indexer.applyEvents(root, [oldAbs, _abs(newRel)]);
      return await _mustFind(newRel);
    });
  }

  /// The text of the note at [path], decoded leniently (a note with a
  /// broken byte is still a note) and without its BOM.
  @override
  Future<String> readNote(String path) async {
    await _mustFind(path);
    final bytes = await File(_abs(path)).readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);
    return text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
        ? text.substring(1)
        : text;
  }

  /// Pins or unpins the note at [path] by editing its frontmatter.
  ///
  /// Unpinning removes the key rather than writing `pinned: false`: the
  /// file goes back to what it looked like before, instead of collecting
  /// a line that says nothing.
  ///
  /// Re-indexed through [Indexer.rescanFiles], not `applyEvents`: the
  /// rewrite can leave the size unchanged within the same second, which
  /// the (size, mtime) shortcut would read as "nothing happened".
  @override
  Future<Note> setPinned(String path, {required bool pinned}) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      // The pin lives in the note's frontmatter, so only a note can carry
      // one. Pinning a `todo.txt` wrote a YAML block into a file that has
      // no such thing, and every todo.txt reader — this app's included —
      // then read the three lines as tasks. Unpinning stays allowed
      // whatever the file is, so a block already written can be taken
      // back out.
      if (row.isDir || (pinned && !isMarkdownNote(row.name))) {
        throw ArgumentError('Only Markdown notes can be pinned, not "$path"');
      }
      final file = File(_abs(path));
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      final updated = pinned
          ? setFrontmatterKey(text, 'pinned', 'true')
          : removeFrontmatterKey(text, 'pinned');
      if (updated == text) return row;
      await writeFileAtomically(file, utf8.encode(updated));
      await indexer.rescanFiles(root, [file.path]);
      return await _mustFind(path);
    });
  }

  /// Deletes [path]: into `.trash/` when the trash toggle is on, hard
  /// delete otherwise.
  @override
  Future<void> delete(String path) {
    return _synchronized(() async {
      final row = await _mustFind(path);
      final oldAbs = _abs(path);
      final trash = await trashEnabled;
      String? trashAbs;
      if (trash) {
        final trashDir = Directory(_abs('.trash'));
        if (!trashDir.existsSync()) {
          await trashDir.create(recursive: true);
        }
        final name = p.basename(path);
        String target;
        if (row.isDir) {
          target = await trashDirName(trashDir, name);
        } else {
          final parts = splitFileName(name);
          target = await trashFileName(trashDir, parts.base, parts.ext);
        }
        trashAbs = _abs('.trash/$target');
        if (row.isDir) {
          await Directory(oldAbs).rename(trashAbs);
        } else {
          await File(oldAbs).rename(trashAbs);
        }
        await _manifestAdd(trashDir, target, path);
      } else {
        if (row.isDir) {
          await Directory(oldAbs).delete(recursive: true);
        } else {
          await File(oldAbs).delete();
        }
      }
      final events = <String>[oldAbs];
      if (trashAbs != null) events.add(trashAbs);
      await indexer.applyEvents(root, events);
    });
  }

  /// Lists the managed trash items (manifest-backed), in deletion order.
  @override
  Future<List<TrashItem>> trashItems() {
    return _synchronized(() async {
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
  @override
  Future<Note> restoreTrash(String trashName) {
    return _synchronized(() async {
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
      await indexer.applyEvents(root, [trashAbs, _abs(newRel)]);
      return await _mustFind(newRel);
    });
  }

  /// Permanently deletes the trash item [trashName] (no restore possible).
  @override
  Future<void> deleteTrashPermanently(String trashName) {
    return _synchronized(() async {
      final manifest = await _readManifest();
      if (manifest.remove(trashName) == null) {
        throw StateError('Not a managed trash item: "$trashName"');
      }
      final trashAbs = _abs('.trash/$trashName');
      if (Directory(trashAbs).existsSync()) {
        await Directory(trashAbs).delete(recursive: true);
      } else if (File(trashAbs).existsSync()) {
        await File(trashAbs).delete();
      }
      await _writeManifest(manifest);
    });
  }

  /// Permanently deletes every managed trash item.
  @override
  /// Deletes every entry in `.trash/`, not just the items Copist put
  /// there: the trash screen promises to empty the folder, and that
  /// includes anything a user moved into it by hand. Ends with an empty
  /// manifest.
  Future<void> emptyTrash() {
    return _synchronized(() async {
      final trashDir = Directory(_abs('.trash'));
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
    });
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
