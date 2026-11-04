import 'dart:io';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/note_op_seams.dart';
import 'package:niman/src/library/note_relocation.dart';
import 'package:niman/src/todo/task_link_rewrites.dart';
import 'package:path/path.dart' as p;

/// Picks the path a renamed or moved note or folder takes — its name
/// uniquified where it lands — and hands the move itself to [relocator],
/// in a turn of the op chain [serialize] hands it of its own.
final class NoteRenamer {
  /// Creates the renamer of the library at [root].
  new({
    required this.root,
    required this.relocator,
    required this.serialize,
    required this.find,
  });

  /// Absolute path of the library root.
  final String root;

  /// Moves on disk and carries along what named what moved.
  final NoteRelocator relocator;

  /// The op chain of the library's operations.
  final Serializer serialize;

  /// The indexed row at a path; throws when there is none.
  final Future<Note> Function(String path) find;

  /// The absolute path for library-relative [rel] ('' = root).
  String _abs(String rel) => p.join(root, rel);

  /// Renames the note or folder at [path] to [newName].
  ///
  /// Notes are always stored as `<name>.md`; a trailing `.md` in [newName]
  /// is treated as redundant. Names are uniquified against the new parent
  /// (self excluded). A name that comes out as the one the note has moves
  /// nothing.
  Future<Relocated> rename(
    String path,
    String newName,
    FlushOpenNotes? flushOpen,
    TaskLinkRewrites? taskLinks,
  ) {
    return serialize(() async {
      final row = await find(path);
      final parent = parentOf(path);
      final parentDir = Directory(_abs(parent));
      // A file keeps its extension: a note its `.md`, a picture or a book
      // its own — a PDF renamed is still a PDF, not `book.pdf.md`. Typed
      // again at the end of the new name, it is not doubled.
      final ext = row.isDir
          ? ''
          : path.toLowerCase().endsWith('.md')
          ? '.md'
          : p.extension(path);
      var base = newName;
      if (ext.isNotEmpty && base.toLowerCase().endsWith(ext.toLowerCase())) {
        base = base.substring(0, base.length - ext.length);
      }
      String target;
      if (row.isDir) {
        final clean = sanitizeName(base, fallback: defaultFolderName);
        target = await uniqueFolderName(parentDir, clean, exclude: _abs(path));
      } else {
        final clean = sanitizeName(base, fallback: defaultNoteName);
        target = await uniqueFileName(
          parentDir,
          clean,
          ext,
          exclude: _abs(path),
        );
      }
      final newRel = resolvePath(parent, target);
      if (newRel == path) return (row: row, pending: null);
      return await relocator.relocate(
        row,
        path,
        newRel,
        flushOpen: flushOpen,
        taskLinks: taskLinks,
      );
    });
  }

  /// Moves the note or folder at [path] into [targetParent], keeping its
  /// name (uniquified in the target).
  ///
  /// Throws [ArgumentError] when [targetParent] is [path] itself or inside
  /// it — a folder cannot be renamed onto its own subtree.
  Future<Relocated> move(
    String path,
    String targetParent,
    FlushOpenNotes? flushOpen,
    TaskLinkRewrites? taskLinks,
  ) {
    return serialize(() async {
      final row = await find(path);
      if (resolvePath(targetParent, p.basename(path)) == path) {
        return (row: row, pending: null);
      }
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
      return await relocator.relocate(
        row,
        path,
        newRel,
        flushOpen: flushOpen,
        taskLinks: taskLinks,
      );
    });
  }
}
