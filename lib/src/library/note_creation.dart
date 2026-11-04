import 'dart:convert';
import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:path/path.dart' as p;

/// Makes what is new in the library: notes, folders, a copy of a file, and
/// the text added to the end of a note. Each one is written on disk first
/// and then read into the index, in a turn of the op chain [serialize]
/// hands it of its own.
final class NoteCreation {
  /// Creates the maker of the library at [root].
  new({
    required this.root,
    required this.dao,
    required this.indexer,
    required this.serialize,
    required this.hint,
    required this.find,
  });

  /// Absolute path of the library root.
  final String root;

  /// The library's index, asked for the folders already there.
  final NoteDao dao;

  /// The shared indexer; every new file reaches the index through it.
  final Indexer indexer;

  /// The op chain of the library's operations.
  final Serializer serialize;

  /// Where the maker reports the paths it changed.
  final SyncHintSink hint;

  /// The indexed row at a path; throws when there is none.
  final Future<Note> Function(String path) find;

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// Creates a `<name>.md` note in [parentPath] with [content] as its
  /// initial content, uniquifying the name. Returns the indexed row.
  Future<Note> createNote({
    required String parentPath,
    required String name,
    String content = '',
  }) {
    return serialize(() async {
      final clean = sanitizeName(name, fallback: defaultNoteName);
      final dir = Directory(_abs(parentPath));
      final unique = await uniqueFileName(dir, clean, '.md');
      final file = File(_abs(resolvePath(parentPath, unique)));
      await writeFileAtomically(file, utf8.encode(content));
      hint(resolvePath(parentPath, unique), SyncOpKind.changed);
      await indexer.applyEvents(root, [file.path]);
      return await find(resolvePath(parentPath, unique));
    });
  }

  /// Copies the file at [path] beside itself, under a unique name
  /// (`note.md` → `note_1.md`), and returns the indexed row (#1100).
  ///
  /// The bytes are copied as they are, so a picture, a PDF or an audio file
  /// duplicates whole rather than being re-encoded. Only a file: a folder
  /// holds a tree of its own, and no menu offers the action for one.
  Future<Note> duplicate(String path) {
    return serialize(() async {
      final row = await find(path);
      if (row.isDir) {
        throw ArgumentError('duplicate was given a folder: "$path"');
      }
      final parent = parentOf(path);
      final name = p.basename(path);
      final ext = p.extension(name);
      final base = ext.isEmpty
          ? name
          : name.substring(0, name.length - ext.length);
      final dir = Directory(_abs(parent));
      final unique = await uniqueFileName(dir, base, ext);
      final rel = resolvePath(parent, unique);
      final copy = File(_abs(rel));
      await writeFileAtomically(copy, await File(_abs(path)).readAsBytes());
      hint(rel, SyncOpKind.changed);
      await indexer.applyEvents(root, [copy.path]);
      return await find(rel);
    });
  }

  /// The folder at [path], created with its parents if missing.
  ///
  /// No uniquifying: the caller named a folder, not a wish for one. A folder
  /// the library already holds under another spelling is that folder, unless
  /// the exact spelling is there too, which wins (#857) —
  /// `[[Projects/Three laws]]` lands in the `projects` that is there, as
  /// `[[Note]]` opens `note.md` — and the path is canonicalized segment by
  /// segment, so a folder made below a reused one sits inside the spelled
  /// one (#847).
  Future<Note> ensureFolder(String path) {
    return serialize(() async {
      final clean = cleanFolderPath(path, '');
      if (clean.isEmpty) {
        // The root is not a row, and "make sure the root exists" is not
        // a thing a caller can mean.
        throw ArgumentError('ensureFolder was given no folder: "$path"');
      }
      final segments = <String>[];
      for (final segment in clean.split('/')) {
        final existing = await dao.folderIgnoringCase(
          resolvePath(segments.join('/'), segment),
        );
        segments.add(existing?.name ?? segment);
      }
      final canonical = segments.join('/');
      final dir = Directory(_abs(canonical));
      // The async form runs off the UI isolate (#875).
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        // Every folder on the way is new too, so the index hears about
        // the whole chain rather than only its last link.
        final made = <String>[
          for (var i = 1; i <= segments.length; i++)
            _abs(segments.take(i).join('/')),
        ];
        await indexer.applyEvents(root, made);
      }
      return await find(canonical);
    });
  }

  /// Adds [content] to the end of the note at [path], creating it when it
  /// is not there.
  Future<Note> appendToNote(String path, String content) {
    return serialize(() async {
      final file = File(_abs(path));
      final existing = await file.exists() ? await file.readAsString() : '';
      final joined = existing.isEmpty
          ? content
          : '${_endingInABlankLine(existing)}$content';
      await writeFileAtomically(file, utf8.encode(joined));
      hint(path, SyncOpKind.changed);
      await indexer.applyEvents(root, [file.path]);
      return await find(path);
    });
  }

  /// [text] with exactly one blank line at its end, so what follows
  /// starts a paragraph of its own.
  static String _endingInABlankLine(String text) {
    final eol = text.contains('\r\n') ? '\r\n' : '\n';
    final trimmed = text.replaceFirst(RegExp(r'\s+$'), '');
    return '$trimmed$eol$eol';
  }

  /// Creates a folder in [parentPath], uniquifying the name.
  Future<Note> createFolder({
    required String parentPath,
    required String name,
  }) {
    return serialize(() async {
      final clean = sanitizeName(name, fallback: defaultFolderName);
      final dir = Directory(_abs(parentPath));
      final unique = await uniqueFolderName(dir, clean);
      final newDir = Directory(_abs(resolvePath(parentPath, unique)));
      await newDir.create(recursive: true);
      await indexer.applyEvents(root, [newDir.path]);
      return await find(resolvePath(parentPath, unique));
    });
  }
}
